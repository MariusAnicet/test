# src/dao/db_connection.py
from __future__ import annotations

import os
import dotenv
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from typing import Generator, Optional

from utils.singleton import Singleton


class DBConnection(metaclass=Singleton):
    """
    Connexion PostgreSQL unique (Singleton).
    - Charge .env (une seule fois)
    - Valide les variables d'env (messages clairs)
    - Gère keepalive (connexion longue)
    - Reconnecte si la connexion est fermée
    - Fournit un context manager cursor() pratique
    """

    def __init__(self):
        dotenv.load_dotenv()  # OK même si appelé 1x
        self.__conn: Optional[psycopg2.extensions.connection] = None
        self.__connect()

    # ---------- Public API ----------
    @property
    def connection(self):
        """Retourne une connexion ouverte; reconnecte si nécessaire."""
        if self.__conn is None or self.__conn.closed != 0:
            self.__connect()
        return self.__conn

    @contextmanager
    def cursor(self) -> Generator[psycopg2.extensions.cursor, None, None]:
        """
        Usage:
            with DBConnection().cursor() as cur:
                cur.execute("SELECT 1")
                rows = cur.fetchall()
        Commit implicite si pas d'exception, rollback sinon.
        """
        conn = self.connection
        cur = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cur
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            cur.close()

    def close(self):
        """Ferme explicitement la connexion (ex: à l’arrêt de l’app)."""
        if self.__conn and self.__conn.closed == 0:
            self.__conn.close()
            self.__conn = None

    # ---------- Internals ----------
    def __connect(self):
        host = _require_env("POSTGRES_HOST")
        port = int(os.getenv("POSTGRES_PORT", "5432"))
        db   = _require_env("POSTGRES_DATABASE")
        user = _require_env("POSTGRES_USER")
        pwd  = _require_env("POSTGRES_PASSWORD")

        # search_path facultatif
        schema = os.getenv("POSTGRES_SCHEMA")
        options = None
        if schema:
            # Accepte plusieurs schémas: "schema1,schema2"
            options = f"-c search_path={schema}"

        # Paramètres de keepalive (évite les timeouts réseau)
        keepalive_kwargs = dict(
            keepalives=1,
            keepalives_idle=int(os.getenv("PG_KEEPALIVES_IDLE", "30")),
            keepalives_interval=int(os.getenv("PG_KEEPALIVES_INTERVAL", "10")),
            keepalives_count=int(os.getenv("PG_KEEPALIVES_COUNT", "5")),
        )

        # SSL optionnel (ex: "require")
        sslmode = os.getenv("POSTGRES_SSLMODE")  # None, 'require', 'disable', etc.

        try:
            self.__conn = psycopg2.connect(
                host=host,
                port=port,
                dbname=db,
                user=user,
                password=pwd,
                options=options,
                application_name=os.getenv("APP_NAME", "yaboya-api"),
                sslmode=sslmode,
                **keepalive_kwargs,
            )
            # Par défaut, psycopg2 est en autocommit=False -> on garde ce comportement.
            # Si tu veux forcer l'autocommit:
            # self.__conn.autocommit = True
        except KeyError as e:
            # Variables manquantes déjà gérées par _require_env, garde le except par sécurité
            raise RuntimeError(f"Variable d'environnement manquante: {e}") from e
        except Exception as e:
            raise RuntimeError(f"Échec de connexion PostgreSQL: {e}") from e


def _require_env(name: str) -> str:
    val = os.getenv(name)
    if not val:
        raise RuntimeError(
            f"Variable d'environnement '{name}' manquante. "
            f"Vérifie ton fichier .env / variables système."
        )
    return val

from __future__ import annotations

from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from typing import Optional, Dict, Any

from ..base_types import Sport, Privacy
from ..errors import ValidationError


@dataclass
class Activite:
    """
    Entité abstraite d'activité.
    Implémente les champs communs + comportements génériques (maj, suppression logique).
    Les sous-classes peuvent ajouter des méthodes de calcul spécifiques (pace, etc.).
    """
    id: Optional[int]
    user_id: int
    sport: Sport
    titre: str
    start_time: datetime
    duration_s: int
    distance_m: int
    elevation_gain_m: int = 0

    description: Optional[str] = None
    avg_speed_mps: Optional[float] = None
    max_speed_mps: Optional[float] = None
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    calories_kcal: Optional[int] = None

    gpx_file_id: Optional[int] = None
    privacy: Privacy = Privacy.PRIVATE

    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    deleted_at: Optional[datetime] = None

    # ---------- Validation de base ----------

    def __post_init__(self) -> None:
        if self.duration_s < 0:
            raise ValidationError("duration_s doit être >= 0")
        if self.distance_m < 0:
            raise ValidationError("distance_m doit être >= 0")
        if self.elevation_gain_m < 0:
            raise ValidationError("elevation_gain_m doit être >= 0")
        if self.avg_speed_mps is not None and self.avg_speed_mps < 0:
            raise ValidationError("avg_speed_mps doit être >= 0")
        if self.max_speed_mps is not None and self.max_speed_mps < 0:
            raise ValidationError("max_speed_mps doit être >= 0")
        if self.avg_hr is not None and not (0 <= self.avg_hr <= 255):
            raise ValidationError("avg_hr doit être dans [0,255]")
        if self.max_hr is not None and not (0 <= self.max_hr <= 255):
            raise ValidationError("max_hr doit être dans [0,255]")

    # ---------- Comportements métier ----------

    def mettre_a_jour(self, meta: Dict[str, Any]) -> None:
        """
        Met à jour des attributs existants en vérifiant les règles simples.
        Ne fait pas de persistance : c'est la responsabilité d'un DAO/Service.
        """
        for k, v in meta.items():
            if not hasattr(self, k):
                raise ValidationError(f"Attribut inconnu: {k}")
            setattr(self, k, v)
        self.__post_init__()
        self.updated_at = datetime.now(timezone.utc)

    def remplacer_gpx(self, nouveau_gpx_file_id: int,
                      metrics: Optional[Dict[str, Any]] = None) -> None:
        """
        Associe un nouveau GPX (déjà stocké via la couche DAO) et,
        si fourni, applique des métriques calculées par un service technique.
        """
        self.gpx_file_id = nouveau_gpx_file_id
        if metrics:
            autorises = {
                "duration_s", "distance_m", "elevation_gain_m",
                "avg_speed_mps", "max_speed_mps",
                "avg_hr", "max_hr", "calories_kcal", "start_time"
            }
            for k, v in metrics.items():
                if k in autorises:
                    setattr(self, k, v)
        self.__post_init__()
        self.updated_at = datetime.now(timezone.utc)

    def supprimer(self) -> None:
        """Suppression logique (soft delete)."""
        self.deleted_at = datetime.now(timezone.utc)
        self.updated_at = self.deleted_at

    def restaurer(self) -> None:
        """Annule la suppression logique."""
        self.deleted_at = None
        self.updated_at = datetime.now(timezone.utc)

    def calc_avg_speed_if_missing(self) -> None:
        """Calcule la vitesse moyenne (m/s) si absente et si données dispo."""
        if self.avg_speed_mps is None and self.duration_s > 0 and self.distance_m >= 0:
            self.avg_speed_mps = float(self.distance_m) / float(self.duration_s)
            self.updated_at = datetime.now(timezone.utc)

    # ---------- Aides de sérialisation ----------

    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        # Sérialiser les enums et datetimes en chaînes utiles à l’API
        d["sport"] = self.sport.value
        d["privacy"] = self.privacy.value
        for key in ("start_time", "created_at", "updated_at", "deleted_at"):
            val = d.get(key)
            d[key] = val.isoformat() if isinstance(val, datetime) and val.tzinfo else (val.isoformat() + "Z" if isinstance(val, datetime) else None)
        return d

    # ---------- Utilitaires ----------
    def speed_kmh(self) -> Optional[float]:
        """Vitesse moyenne en km/h si disponible (sinon None)."""
        self.calc_avg_speed_if_missing()
        return None if self.avg_speed_mps is None else self.avg_speed_mps * 3.6

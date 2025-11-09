-- =========================================
-- init_db.sql — Schéma de base pour F1
-- PostgreSQL 13+
-- =========================================

BEGIN;

-- Extensions utiles (facultatives mais recommandées)
CREATE EXTENSION IF NOT EXISTS citext;     -- emails/usernames insensibles à la casse
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- pour digest() SHA-256 si besoin

-- Nettoyage idempotent (si ré-exécution)
DROP TABLE IF EXISTS activite CASCADE;
DROP TABLE IF EXISTS gpx_file CASCADE;
DROP TABLE IF EXISTS utilisateur CASCADE;

DROP TYPE IF EXISTS sport_t;
DROP TYPE IF EXISTS privacy_t;

-- Types énumérés (polymorphisme au niveau code, mais valeurs bornées en base)
CREATE TYPE sport_t   AS ENUM ('running','cycling','hiking','swimming');
CREATE TYPE privacy_t AS ENUM ('private','friends','public');

-- =======================
-- Table des utilisateurs
-- =======================
CREATE TABLE utilisateur (
  id             BIGSERIAL PRIMARY KEY,
  username       CITEXT UNIQUE NOT NULL,
  email          CITEXT UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ======================
-- Table des fichiers GPX
-- ======================
-- Deux modes de stockage :
--  - contenu en base (content BYTEA)
--  - ou clé/chemin externe (storage_key TEXT)
-- Une des deux colonnes doit être non nulle.
CREATE TABLE gpx_file (
  id           BIGSERIAL PRIMARY KEY,
  filename     TEXT NOT NULL,
  content      BYTEA,                 -- nullable si storage_key est renseigné
  storage_key  TEXT,                  -- ex: 's3://bucket/…' ou chemin local
  sha256       CHAR(64),              -- facultatif; peut être auto-calculé si content non NULL
  size_bytes   INTEGER CHECK (size_bytes IS NULL OR size_bytes >= 0),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT gpx_content_xor_key CHECK (
    (content IS NOT NULL) <> (storage_key IS NOT NULL)
  )
);

-- Unicité du hash si présent (index partiel)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_gpx_sha256
  ON gpx_file(sha256) WHERE sha256 IS NOT NULL;

-- =====================
-- Table des activités
-- =====================
CREATE TABLE activite (
  id                BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  sport             sport_t NOT NULL,
  titre             TEXT NOT NULL,
  description       TEXT,
  start_time        TIMESTAMPTZ NOT NULL,
  duration_s        INTEGER NOT NULL CHECK (duration_s >= 0),
  distance_m        INTEGER NOT NULL CHECK (distance_m >= 0),
  elevation_gain_m  INTEGER NOT NULL DEFAULT 0 CHECK (elevation_gain_m >= 0),

  avg_speed_mps     NUMERIC(8,3) CHECK (avg_speed_mps IS NULL OR avg_speed_mps >= 0),
  max_speed_mps     NUMERIC(8,3) CHECK (max_speed_mps IS NULL OR max_speed_mps >= 0),
  avg_hr            SMALLINT CHECK (avg_hr IS NULL OR (avg_hr BETWEEN 0 AND 255)),
  max_hr            SMALLINT CHECK (max_hr IS NULL OR (max_hr BETWEEN 0 AND 255)),
  calories_kcal     INTEGER CHECK (calories_kcal IS NULL OR calories_kcal >= 0),

  gpx_file_id       BIGINT REFERENCES gpx_file(id) ON DELETE SET NULL,
  privacy           privacy_t NOT NULL DEFAULT 'private',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at        TIMESTAMPTZ
);

-- Index utiles pour les listes/filtrages
CREATE INDEX IF NOT EXISTS idx_act_user_time
  ON activite (user_id, start_time DESC) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_act_user_sport_time
  ON activite (user_id, sport, start_time DESC) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_act_user_distance
  ON activite (user_id, distance_m) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_act_user_duration
  ON activite (user_id, duration_s) WHERE deleted_at IS NULL;

-- ===========================================
-- Triggers génériques pour updated_at & GPX
-- ===========================================

-- Met à jour automatiquement la colonne updated_at
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER utilisateur_set_updated_at
BEFORE UPDATE ON utilisateur
FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER activite_set_updated_at
BEFORE UPDATE ON activite
FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Si on stocke le contenu GPX en BYTEA, calcule sha256/size par défaut
CREATE OR REPLACE FUNCTION trg_gpx_defaults()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.content IS NOT NULL THEN
    IF NEW.size_bytes IS NULL THEN
      NEW.size_bytes := octet_length(NEW.content);
    END IF;
    IF NEW.sha256 IS NULL THEN
      NEW.sha256 := encode(digest(NEW.content, 'sha256'), 'hex');
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER gpx_file_biud_defaults
BEFORE INSERT OR UPDATE ON gpx_file
FOR EACH ROW EXECUTE FUNCTION trg_gpx_defaults();

COMMIT;

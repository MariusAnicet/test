-- =========================================================
-- init_db.sql  (PostgreSQL)
-- Schéma minimal pour F1 : CRUD d'activités + filtres
-- =========================================================

-- (Optionnel) Tout mettre dans une transaction
BEGIN;

-- Extension utile pour emails insensibles à la casse
CREATE EXTENSION IF NOT EXISTS citext;

-- =========================================================
-- 1) UTILISATEURS
-- =========================================================
CREATE TABLE IF NOT EXISTS users (
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT        NOT NULL,
  email           CITEXT      NOT NULL UNIQUE,
  password_hash   TEXT        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 2) SPORTS (référentiel simple)
-- =========================================================
CREATE TABLE IF NOT EXISTS sports (
  id        SMALLSERIAL PRIMARY KEY,
  label     TEXT NOT NULL UNIQUE
);

-- (Optionnel) Quelques sports par défaut
INSERT INTO sports (label) VALUES
  ('course_a_pied'),
  ('velo'),
  ('marche'),
  ('randonnee'),
  ('natation')
ON CONFLICT DO NOTHING;

-- =========================================================
-- 3) ACTIVITES
-- =========================================================
CREATE TABLE IF NOT EXISTS activities (
  id               BIGSERIAL PRIMARY KEY,
  user_id          BIGINT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id         SMALLINT  REFERENCES sports(id),
  title            TEXT,
  description      TEXT,
  started_at       TIMESTAMPTZ NOT NULL,                -- début de l'activité
  duration_sec     INTEGER     NOT NULL CHECK (duration_sec >= 0),
  distance_m       INTEGER     NOT NULL CHECK (distance_m >= 0),
  elev_gain_m      INTEGER     NOT NULL DEFAULT 0 CHECK (elev_gain_m >= 0),
  elev_loss_m      INTEGER     NOT NULL DEFAULT 0 CHECK (elev_loss_m >= 0),
  avg_speed_ms     NUMERIC(6,3),                        -- optionnel (peut être dérivé)
  gpx_path         TEXT        NOT NULL,                -- chemin/URL du fichier GPX
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index pour les listes et filtres courants
CREATE INDEX IF NOT EXISTS idx_activities_user_started ON activities(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_user_sport   ON activities(user_id, sport_id);
CREATE INDEX IF NOT EXISTS idx_activities_user_dist    ON activities(user_id, distance_m);

-- Déclencheur pour maintenir updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_activities_set_updated ON activities;
CREATE TRIGGER trg_activities_set_updated
BEFORE UPDATE ON activities
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 4) POINTS DE TRACE (OPTIONNEL)
--    Utile si vous affichez une carte / profil altimétrique.
-- =========================================================
CREATE TABLE IF NOT EXISTS activity_points (
  activity_id   BIGINT NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  seq           INTEGER NOT NULL,                         -- ordre dans la trace
  tstamp        TIMESTAMPTZ,
  lat           DOUBLE PRECISION NOT NULL,
  lon           DOUBLE PRECISION NOT NULL,
  elevation_m   DOUBLE PRECISION,
  dist_cum_m    INTEGER,
  PRIMARY KEY (activity_id, seq)
);

CREATE INDEX IF NOT EXISTS idx_points_activity ON activity_points(activity_id);

COMMIT;

-- =========================================================
-- Fin du script
-- =========================================================

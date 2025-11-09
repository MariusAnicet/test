-- =========================================
-- pop_db.sql — Jeu de données d'exemple F1
-- Réinitialise puis insère quelques lignes.
-- À exécuter APRÈS init_db.sql
-- =========================================

BEGIN;

-- On vide les tables et on remet les séquences à 1
TRUNCATE TABLE activite, gpx_file, utilisateur RESTART IDENTITY CASCADE;

-- ================
-- Utilisateurs
-- ================
INSERT INTO utilisateur (username, email, password_hash)
VALUES 
  ('alice',   'alice@example.com',   '$2b$12$alicehashdemonstration...............'),
  ('bob',     'bob@example.com',     '$2b$12$bobhashdemonstration.................'),
  ('charlie', 'charlie@example.com', '$2b$12$charliehashdemonstration.............');

-- ================
-- Fichiers GPX
-- ================
-- Ici on choisit le mode "storage_key" pour éviter d'injecter du BYTEA.
-- Les filenames servent de clé naturelle pour les joindre ensuite.
INSERT INTO gpx_file (filename, storage_key, sha256, size_bytes)
VALUES
  ('run-2025-11-01.gpx',      'local://gpx/alice/run-2025-11-01.gpx', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 123456),
  ('ride-2025-10-30.gpx',     'local://gpx/bob/ride-2025-10-30.gpx',  'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 234567),
  ('hike-2025-10-20.gpx',     'local://gpx/charlie/hike-2025-10-20.gpx','cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', 98765),
  ('swim-2025-11-03.gpx',     'local://gpx/alice/swim-2025-11-03.gpx', 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd', 45678);

-- =================
-- Activités (F1)
-- =================
-- On calcule avg_speed_mps à l'insertion (distance_m / duration_s).
-- On fait référence au gpx_file via une sous-requête sur filename.

-- 1) Course à pied (Alice)
INSERT INTO activite (
  user_id, sport, titre, description, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, max_speed_mps, avg_hr, max_hr,
  calories_kcal, gpx_file_id, privacy
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'alice'),
  'running',
  'Sortie footing Parc',
  'Footing tranquille au parc',
  TIMESTAMPTZ '2025-11-01 08:45:00+01',
  3600,                 -- 1h
  10000,                -- 10 km
  120,
  10000.0/3600.0,       -- avg_speed_mps
  5.200,                -- max speed (m/s)
  152, 178,
  650,
  (SELECT id FROM gpx_file WHERE filename = 'run-2025-11-01.gpx'),
  'private'
);

-- 2) Cyclisme (Bob)
INSERT INTO activite (
  user_id, sport, titre, description, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, max_speed_mps,
  calories_kcal, gpx_file_id, privacy
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'bob'),
  'cycling',
  'Sortie vélo vallonnée',
  'Boucle de 50 km avec dénivelé',
  TIMESTAMPTZ '2025-10-30 07:30:00+01',
  7200,                 -- 2h
  50000,                -- 50 km
  650,
  50000.0/7200.0,
  14.800,
  1400,
  (SELECT id FROM gpx_file WHERE filename = 'ride-2025-10-30.gpx'),
  'friends'
);

-- 3) Randonnée (Charlie)
INSERT INTO activite (
  user_id, sport, titre, description, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, calories_kcal, gpx_file_id, privacy
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'charlie'),
  'hiking',
  'Rando en forêt',
  'Boucle familiale',
  TIMESTAMPTZ '2025-10-20 10:00:00+02',
  14400,                -- 4h
  14000,                -- 14 km
  420,
  14000.0/14400.0,
  900,
  (SELECT id FROM gpx_file WHERE filename = 'hike-2025-10-20.gpx'),
  'public'
);

-- 4) Natation (Alice)
INSERT INTO activite (
  user_id, sport, titre, description, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, calories_kcal, gpx_file_id, privacy
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'alice'),
  'swimming',
  'Piscine - endurance',
  'Séries longues',
  TIMESTAMPTZ '2025-11-03 19:10:00+01',
  2700,                 -- 45 min
  2000,                 -- 2 km
  0,
  2000.0/2700.0,
  350,
  (SELECT id FROM gpx_file WHERE filename = 'swim-2025-11-03.gpx'),
  'private'
);

-- 5) Deuxième sortie course (Bob), sans GPX (ex: saisie manuelle)
INSERT INTO activite (
  user_id, sport, titre, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, privacy
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'bob'),
  'running',
  'Fractionné 8x400m',
  TIMESTAMPTZ '2025-11-02 18:00:00+01',
  3000,                 -- 50 min
  8000,                 -- 8 km
  60,
  8000.0/3000.0,
  'friends'
);

-- 6) Activité soft-deleted (exemple de suppression logique)
INSERT INTO activite (
  user_id, sport, titre, start_time,
  duration_s, distance_m, elevation_gain_m,
  avg_speed_mps, privacy, deleted_at
)
VALUES (
  (SELECT id FROM utilisateur WHERE username = 'charlie'),
  'cycling',
  'Ancienne sortie à retirer',
  TIMESTAMPTZ '2025-09-15 09:00:00+02',
  5400,
  30000,
  300,
  30000.0/5400.0,
  'private',
  now() - INTERVAL '1 day'
);

COMMIT;

-- Vérifications rapides possibles :
-- SELECT username, count(*) FROM utilisateur u JOIN activite a ON a.user_id=u.id AND a.deleted_at IS NULL GROUP BY 1;
-- SELECT sport, count(*) FROM activite WHERE deleted_at IS NULL GROUP BY 1;

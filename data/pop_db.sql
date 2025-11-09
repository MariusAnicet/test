-- =========================================================
-- pop_db.sql  (PostgreSQL)
-- Données de démonstration pour F1
-- A exécuter APRES init_db.sql
-- =========================================================

BEGIN;

-- Rendez le script idempotent pour les tests
TRUNCATE TABLE activity_points RESTART IDENTITY CASCADE;
TRUNCATE TABLE activities RESTART IDENTITY CASCADE;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;

-- (Ré)assure le référentiel sports (le même que dans init_db.sql)
-- Laisser tel quel : si déjà présent, ON CONFLICT évite le doublon
INSERT INTO sports (label) VALUES
  ('course_a_pied'),
  ('velo'),
  ('marche'),
  ('randonnee'),
  ('natation')
ON CONFLICT DO NOTHING;

-- =========================================
-- Utilisateurs
-- =========================================
INSERT INTO users (name, email, password_hash, created_at) VALUES
  ('Alice Martin', 'alice@example.com', '$2b$12$hashalice', now() - interval '30 days'),
  ('Bob Dupont',   'bob@example.com',   '$2b$12$hashbob',   now() - interval '25 days'),
  ('Chloe Leroy',  'chloe@example.com', '$2b$12$hashchloe', now() - interval '20 days'),
  ('David N''Guyen','david@example.com','$2b$12$hashdavid', now() - interval '10 days');

-- =========================================
-- Activités (exemples réalistes)
-- Remarque: sport_id récupéré par sous-select sur sports.label
--           user_id récupéré par sous-select sur users.email
-- =========================================

-- Alice - course à pied, vélo
INSERT INTO activities
(user_id, sport_id, title, description, started_at, duration_sec, distance_m,
 elev_gain_m, elev_loss_m, avg_speed_ms, gpx_path, created_at, updated_at)
VALUES
(
  (SELECT id FROM users WHERE email='alice@example.com'),
  (SELECT id FROM sports WHERE label='course_a_pied'),
  'Footing matinal au parc', 'Sortie tranquille en endurance fondamentale',
  (date_trunc('day', now()) - interval '14 days') + time '06:45',
  45*60, 8200, 60, 60, ROUND(8200.0/(45*60),3),
  '/data/gpx/alice_footing_park.gpx', now(), now()
),
(
  (SELECT id FROM users WHERE email='alice@example.com'),
  (SELECT id FROM sports WHERE label='velo'),
  'Sortie vélo du dimanche', 'Boucle vallonnée',
  (date_trunc('day', now()) - interval '7 days') + time '09:05',
  2*3600+15*60, 52500, 420, 420, ROUND(52500.0/(2*3600+15*60),3),
  '/data/gpx/alice_velo_dimanche.gpx', now(), now()
),
(
  (SELECT id FROM users WHERE email='alice@example.com'),
  (SELECT id FROM sports WHERE label='course_a_pied'),
  'Intervalles 6x800m', 'Séance piste',
  (date_trunc('day', now()) - interval '2 days') + time '18:20',
  58*60, 11200, 40, 40, ROUND(11200.0/(58*60),3),
  '/data/gpx/alice_intervalles.gpx', now(), now()
);

-- Bob - marche, randonnée
INSERT INTO activities
(user_id, sport_id, title, description, started_at, duration_sec, distance_m,
 elev_gain_m, elev_loss_m, avg_speed_ms, gpx_path, created_at, updated_at)
VALUES
(
  (SELECT id FROM users WHERE email='bob@example.com'),
  (SELECT id FROM sports WHERE label='marche'),
  'Marche active', 'Boucle urbaine rapide',
  (date_trunc('day', now()) - interval '10 days') + time '12:30',
  50*60, 6100, 30, 30, ROUND(6100.0/(50*60),3),
  '/data/gpx/bob_marche_active.gpx', now(), now()
),
(
  (SELECT id FROM users WHERE email='bob@example.com'),
  (SELECT id FROM sports WHERE label='randonnee'),
  'Rando crêtes', 'Super panorama, sentier technique',
  (date_trunc('day', now()) - interval '6 days') + time '08:15',
  4*3600+20*60, 15300, 860, 860, ROUND(15300.0/(4*3600+20*60),3),
  '/data/gpx/bob_rando_cretes.gpx', now(), now()
);

-- Chloé - natation, course à pied
INSERT INTO activities
(user_id, sport_id, title, description, started_at, duration_sec, distance_m,
 elev_gain_m, elev_loss_m, avg_speed_ms, gpx_path, created_at, updated_at)
VALUES
(
  (SELECT id FROM users WHERE email='chloe@example.com'),
  (SELECT id FROM sports WHERE label='natation'),
  'Séance piscine', '4x400m pull, 8x50m éducatif',
  (date_trunc('day', now()) - interval '9 days') + time '19:05',
  55*60, 2500, 0, 0, ROUND(2500.0/(55*60),3),
  '/data/gpx/chloe_natation.gpx', now(), now()
),
(
  (SELECT id FROM users WHERE email='chloe@example.com'),
  (SELECT id FROM sports WHERE label='course_a_pied'),
  'SL 20km', 'Sortie longue en bord de rivière',
  (date_trunc('day', now()) - interval '1 day') + time '08:40',
  1*3600+45*60, 20000, 120, 120, ROUND(20000.0/(1*3600+45*60),3),
  '/data/gpx/chloe_sl_20k.gpx', now(), now()
);

-- David - vélo, course à pied
INSERT INTO activities
(user_id, sport_id, title, description, started_at, duration_sec, distance_m,
 elev_gain_m, elev_loss_m, avg_speed_ms, gpx_path, created_at, updated_at)
VALUES
(
  (SELECT id FROM users WHERE email='david@example.com'),
  (SELECT id FROM sports WHERE label='velo'),
  'Home-trainer', 'Séance sweet spot',
  (date_trunc('day', now()) - interval '3 days') + time '07:10',
  1*3600+10*60, 35000, 0, 0, ROUND(35000.0/(1*3600+10*60),3),
  '/data/gpx/david_ht.gpx', now(), now()
),
(
  (SELECT id FROM users WHERE email='david@example.com'),
  (SELECT id FROM sports WHERE label='course_a_pied'),
  'Jog léger', 'Récupération',
  (date_trunc('day', now()) - interval '0 days') + time '17:30',
  35*60, 5600, 20, 20, ROUND(5600.0/(35*60),3),
  '/data/gpx/david_jog_light.gpx', now(), now()
);

-- =========================================
-- Points de trace (exemples simples, facultatif)
-- Lier à une activité insérée ci-dessus via un SELECT par titre
-- =========================================

-- Points pour l’activité "Footing matinal au parc" (Alice)
WITH a AS (
  SELECT id AS activity_id
  FROM activities
  WHERE title = 'Footing matinal au parc'
    AND user_id = (SELECT id FROM users WHERE email='alice@example.com')
)
INSERT INTO activity_points (activity_id, seq, tstamp, lat, lon, elevation_m, dist_cum_m)
SELECT activity_id, seq, tstamp, lat, lon, elevation_m, dist_cum_m
FROM (
  VALUES
    (1, (date_trunc('day', now()) - interval '14 days') + time '06:45:00', 48.1110, -1.6800, 35.0,   0),
    (2, (date_trunc('day', now()) - interval '14 days') + time '06:55:00', 48.1125, -1.6780, 35.5, 3000),
    (3, (date_trunc('day', now()) - interval '14 days') + time '07:05:00', 48.1150, -1.6765, 36.0, 6000),
    (4, (date_trunc('day', now()) - interval '14 days') + time '07:10:00', 48.1165, -1.6750, 36.5, 8200)
) AS p(seq, tstamp, lat, lon, elevation_m, dist_cum_m)
CROSS JOIN a;

-- Points pour "Rando crêtes" (Bob)
WITH a AS (
  SELECT id AS activity_id
  FROM activities
  WHERE title = 'Rando crêtes'
    AND user_id = (SELECT id FROM users WHERE email='bob@example.com')
)
INSERT INTO activity_points (activity_id, seq, tstamp, lat, lon, elevation_m, dist_cum_m)
SELECT activity_id, seq, tstamp, lat, lon, elevation_m, dist_cum_m
FROM (
  VALUES
    (1, (date_trunc('day', now()) - interval '6 days') + time '08:15:00', 45.0000, 6.0000,  520.0,    0),
    (2, (date_trunc('day', now()) - interval '6 days') + time '09:45:00', 45.0050, 6.0100,  980.0,  7000),
    (3, (date_trunc('day', now()) - interval '6 days') + time '11:30:00', 45.0120, 6.0220, 1450.0, 12000),
    (4, (date_trunc('day', now()) - interval '6 days') + time '12:35:00', 45.0180, 6.0300,  860.0, 15300)
) AS p(seq, tstamp, lat, lon, elevation_m, dist_cum_m)
CROSS JOIN a;

COMMIT;

-- =========================================================
-- Fin du script
-- =========================================================

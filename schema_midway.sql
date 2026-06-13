-- ============================================================
-- MIDWAY 1942 — Schéma de base de données v1
-- Convention temps : toutes les heures en heure locale Midway (GMT-12),
--   format ISO 8601 'YYYY-MM-DDTHH:MM:SS-12:00'. L'heure d'origine de
--   chaque source est conservée dans claims.original_value.
-- Convention espace : lat/lon WGS84 en degrés décimaux.
-- Granularité aérienne : escadrille (squadron).
-- ============================================================
PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- 1. SOURÇAGE
-- ------------------------------------------------------------
CREATE TABLE sources (
  source_id     TEXT PRIMARY KEY,          -- ex: 'SRC-SHATTERED-SWORD'
  type          TEXT NOT NULL CHECK (type IN ('primary_official','scholarly','secondary','online_db','testimony','wreck_survey','map')),
  author        TEXT,
  title         TEXT NOT NULL,
  year          INTEGER,
  grade         TEXT NOT NULL CHECK (grade IN ('A','B','C','D')),  -- cf. méthodologie §4.1
  time_reference TEXT,                     -- référentiel horaire de la source: 'GMT-12','GMT+9','mixte'
  url           TEXT,
  notes         TEXT
);

-- Toute donnée = une affirmation sourcée. Plusieurs claims peuvent
-- porter sur le même champ ; une seule est retenue (is_accepted=1).
CREATE TABLE claims (
  claim_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_table  TEXT NOT NULL,             -- table cible (ex: 'events')
  entity_id     TEXT NOT NULL,             -- id de la ligne cible
  field         TEXT NOT NULL,             -- champ concerné (ex: 'ts')
  value         TEXT NOT NULL,             -- valeur normalisée (convention BDD)
  original_value TEXT,                     -- valeur telle qu'écrite dans la source (heure Tokyo, deg-min...)
  source_id     TEXT NOT NULL REFERENCES sources(source_id),
  page_ref      TEXT,
  is_accepted   INTEGER NOT NULL DEFAULT 0,
  status        TEXT NOT NULL DEFAULT 'single_source'
                CHECK (status IN ('verified','single_source','conflicting','estimated','gap')),
  resolution_note TEXT                     -- justification de l'arbitrage si conflit
);
CREATE INDEX idx_claims_entity ON claims(entity_table, entity_id, field);

-- ------------------------------------------------------------
-- 2. RÉFÉRENTIEL STATIQUE
-- ------------------------------------------------------------
CREATE TABLE formations (                  -- task forces, kantai, escadres, base
  formation_id  TEXT PRIMARY KEY,          -- ex: 'TF-16', 'KIDO-BUTAI', 'MIDWAY-BASE'
  name          TEXT NOT NULL,
  side          TEXT NOT NULL CHECK (side IN ('USN','IJN')),
  parent_formation_id TEXT REFERENCES formations(formation_id),
  commander_id  TEXT,                      -- FK persons (déclarée après)
  notes         TEXT
);

CREATE TABLE persons (
  person_id     TEXT PRIMARY KEY,          -- ex: 'PR-NAGUMO'
  name          TEXT NOT NULL,
  rank          TEXT,
  side          TEXT NOT NULL CHECK (side IN ('USN','IJN','USMC','USAAF')),
  role          TEXT,                      -- ex: 'Commandant 1er Kōkū Kantai'
  notes         TEXT
);

CREATE TABLE ships (
  ship_id       TEXT PRIMARY KEY,          -- ex: 'SH-AKAGI', 'SH-CV6', 'SH-MIDWAY'
  name          TEXT NOT NULL,
  side          TEXT NOT NULL CHECK (side IN ('USN','IJN')),
  ship_type     TEXT NOT NULL CHECK (ship_type IN ('CV','CVL','BB','CA','CL','DD','SS','AO','AP','AV','base')),
  class         TEXT,
  formation_id  TEXT REFERENCES formations(formation_id),
  captain_id    TEXT REFERENCES persons(person_id),
  max_speed_kn  REAL,
  cruise_speed_kn REAL,
  fuel_capacity_t REAL,
  endurance_nm  REAL,                      -- rayon d'action à vitesse de croisière
  aa_rating     TEXT,                      -- description DCA (détaillable plus tard)
  fate          TEXT,                      -- 'survécu' / 'coulé 04/06...' etc.
  notes         TEXT
);

-- Contraintes physiques propres aux plateformes aériennes (7 CV + Midway)
CREATE TABLE carrier_constraints (
  ship_id             TEXT PRIMARY KEY REFERENCES ships(ship_id),
  flight_deck_length_m REAL,
  flight_deck_width_m  REAL,
  elevators_count      INTEGER,
  elevator_cycle_s     INTEGER,            -- temps d'un cycle hangar<->pont
  hangar_capacity      INTEGER,            -- nb d'appareils en hangar
  max_spot             INTEGER,            -- nb max d'appareils spottés pour un lancement
  arming_crews         INTEGER,            -- équipes d'armement disponibles
  fueling_crews        INTEGER,
  rearm_location       TEXT CHECK (rearm_location IN ('hangar','deck','both')), -- doctrine IJN: hangar ; USN: both
  launch_interval_s    INTEGER,            -- intervalle moyen entre 2 décollages
  recovery_interval_s  INTEGER,
  notes               TEXT
);

CREATE TABLE aircraft_types (
  type_id        TEXT PRIMARY KEY,         -- ex: 'AC-B5N2', 'AC-SBD3'
  designation    TEXT NOT NULL,            -- 'Nakajima B5N2 "Kate"'
  side           TEXT NOT NULL CHECK (side IN ('USN','IJN','USMC','USAAF')),
  role           TEXT NOT NULL CHECK (role IN ('fighter','dive_bomber','torpedo_bomber','level_bomber','recon','patrol')),
  crew           INTEGER,
  cruise_speed_kn REAL,
  max_speed_kn   REAL,
  combat_radius_nm REAL,                   -- avec emport standard
  ferry_range_nm REAL,
  fuel_capacity_l REAL,
  climb_rate_mps REAL,
  ceiling_m      REAL,
  notes          TEXT
);

CREATE TABLE ordnance_types (
  ordnance_id    TEXT PRIMARY KEY,         -- ex: 'ORD-TYPE91', 'ORD-MK13', 'ORD-800KG'
  name           TEXT NOT NULL,
  category       TEXT NOT NULL CHECK (category IN ('torpedo','bomb_ap','bomb_he','bomb_gp','depth_charge')),
  weight_kg      REAL,
  release_constraints TEXT,                -- ex Mk13: '<110 kn, <30 m' -> vulnérabilité du porteur
  reliability_note TEXT,
  notes          TEXT
);

-- Emports possibles par type d'avion (n-n)
CREATE TABLE aircraft_ordnance (
  type_id      TEXT NOT NULL REFERENCES aircraft_types(type_id),
  ordnance_id  TEXT NOT NULL REFERENCES ordnance_types(ordnance_id),
  quantity     INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (type_id, ordnance_id)
);

-- Unité de simulation aérienne
CREATE TABLE squadrons (
  squadron_id   TEXT PRIMARY KEY,          -- ex: 'SQ-VT8', 'SQ-HIRYU-KANBAKU'
  name          TEXT NOT NULL,
  side          TEXT NOT NULL CHECK (side IN ('USN','IJN','USMC','USAAF')),
  ship_id       TEXT REFERENCES ships(ship_id),   -- navire-mère ou SH-MIDWAY
  type_id       TEXT REFERENCES aircraft_types(type_id),
  strength_0406 INTEGER,                   -- appareils opérationnels au 04/06 04:00
  commander_id  TEXT REFERENCES persons(person_id),
  experience    TEXT CHECK (experience IN ('elite','veteran','average','green')),
  notes         TEXT
);

-- ------------------------------------------------------------
-- 3. DYNAMIQUE — le film de la bataille
-- ------------------------------------------------------------
CREATE TABLE events (
  event_id      TEXT PRIMARY KEY,          -- ex: 'EV-0604-1022-A'
  ts            TEXT NOT NULL,             -- ISO 8601 GMT-12
  time_uncertainty_min INTEGER DEFAULT 0,
  event_type    TEXT NOT NULL CHECK (event_type IN (
    'sighting','report','receipt','decision','launch_start','launch_end',
    'recovery_start','recovery_end','spot','rearm_start','rearm_end',
    'attack','hit','miss','damage','fire','sinking','scuttling',
    'course_change','collision','refuel','weather_obs','other')),
  side          TEXT CHECK (side IN ('USN','IJN','both')),
  summary       TEXT NOT NULL,
  lat           REAL,
  lon           REAL,
  position_error_nm REAL,
  phase         TEXT,                      -- ex: 'J3-approche','J4-matin','J4-contre-attaque','J5-retraite','J6-poursuite'
  notes         TEXT
);
CREATE INDEX idx_events_ts ON events(ts);

CREATE TABLE event_participants (
  event_id     TEXT NOT NULL REFERENCES events(event_id),
  entity_table TEXT NOT NULL,              -- 'ships' | 'squadrons' | 'persons' | 'formations'
  entity_id    TEXT NOT NULL,
  role         TEXT,                       -- 'actor','target','observer','decider'
  PRIMARY KEY (event_id, entity_table, entity_id, role)
);

-- Pistes reconstruites = MONDE RÉEL
CREATE TABLE positions (
  position_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_table TEXT NOT NULL,              -- 'ships' | 'formations' | 'missions'
  entity_id    TEXT NOT NULL,
  ts           TEXT NOT NULL,
  lat          REAL NOT NULL,
  lon          REAL NOT NULL,
  course_deg   REAL,
  speed_kn     REAL,
  method       TEXT NOT NULL CHECK (method IN ('observed','interpolated','estimated','verified')), -- verified = ancré épave
  position_error_nm REAL,
  source_id    TEXT REFERENCES sources(source_id),
  notes        TEXT
);
CREATE INDEX idx_positions ON positions(entity_table, entity_id, ts);

-- Raids aériens (une mission = un raid cohérent multi-escadrilles)
CREATE TABLE missions (
  mission_id    TEXT PRIMARY KEY,          -- ex: 'MS-0604-TOMONAGA'
  side          TEXT NOT NULL CHECK (side IN ('USN','IJN','USMC','USAAF')),
  origin_ship_id TEXT REFERENCES ships(ship_id),
  mission_type  TEXT CHECK (mission_type IN ('strike','cap','search','asw','ferry')),
  target_desc   TEXT,
  launch_start_ts TEXT,
  launch_end_ts  TEXT,
  attack_ts      TEXT,
  recovery_ts    TEXT,
  outcome        TEXT,
  notes          TEXT
);

CREATE TABLE mission_squadrons (
  mission_id   TEXT NOT NULL REFERENCES missions(mission_id),
  squadron_id  TEXT NOT NULL REFERENCES squadrons(squadron_id),
  aircraft_committed INTEGER,
  aircraft_lost      INTEGER,
  ordnance_id  TEXT REFERENCES ordnance_types(ordnance_id),
  notes        TEXT,
  PRIMARY KEY (mission_id, squadron_id)
);

CREATE TABLE mission_legs (                -- segments de trajet d'un raid
  leg_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  mission_id   TEXT NOT NULL REFERENCES missions(mission_id),
  seq          INTEGER NOT NULL,
  start_ts     TEXT, end_ts TEXT,
  start_lat    REAL, start_lon REAL,
  end_lat      REAL, end_lon REAL,
  course_deg   REAL, speed_kn REAL, altitude_m REAL,
  method       TEXT CHECK (method IN ('observed','interpolated','estimated')),
  notes        TEXT
);

-- MONDE PERÇU : ce que chaque camp croyait savoir
CREATE TABLE contact_reports (
  report_id     TEXT PRIMARY KEY,          -- ex: 'CR-TONE4-0728'
  reporter_table TEXT NOT NULL,            -- 'squadrons' | 'ships'
  reporter_id   TEXT NOT NULL,
  ts_observed   TEXT,
  ts_sent       TEXT,
  ts_received   TEXT,                      -- réception par le décideur
  recipient_id  TEXT REFERENCES persons(person_id),
  reported_lat  REAL, reported_lon REAL,   -- position RAPPORTÉE (souvent fausse)
  reported_composition TEXT,               -- '10 navires, apparemment ennemis'
  actual_event_id TEXT REFERENCES events(event_id), -- lien vers la réalité
  position_error_actual_nm REAL,           -- erreur réelle calculée a posteriori
  notes         TEXT
);

CREATE TABLE messages (                    -- ordres et communications non-contact
  message_id   TEXT PRIMARY KEY,
  ts_sent      TEXT, ts_received TEXT,
  sender_id    TEXT REFERENCES persons(person_id),
  recipient_id TEXT REFERENCES persons(person_id),
  channel      TEXT,                       -- 'radio','signal_flags','blinker','voice'
  content      TEXT NOT NULL,
  notes        TEXT
);

-- Support de F3 : les décisions comme entités
CREATE TABLE decisions (
  decision_id   TEXT PRIMARY KEY,          -- ex: 'DC-NAGUMO-D1'
  ts            TEXT NOT NULL,
  decider_id    TEXT NOT NULL REFERENCES persons(person_id),
  event_id      TEXT REFERENCES events(event_id),
  summary       TEXT NOT NULL,
  options_considered TEXT,                 -- alternatives identifiées (JSON ou texte)
  decision_taken TEXT NOT NULL,
  rationale_historical TEXT,               -- justification du décideur (telle que documentée)
  consequences  TEXT,
  controversy_note TEXT,                   -- cf. méthodologie §4.3
  notes         TEXT
);

-- Information disponible pour un décideur à un instant donné
CREATE TABLE knowledge_states (
  ks_id        INTEGER PRIMARY KEY AUTOINCREMENT,
  decision_id  TEXT NOT NULL REFERENCES decisions(decision_id),
  item         TEXT NOT NULL,              -- fait connu ex: 'PA ennemi signalé relèvement 010, 240 nm'
  known_since_ts TEXT,
  via          TEXT,                       -- 'CR-TONE4-0728' / 'MSG-...' / 'doctrine' / 'hypothèse'
  accuracy     TEXT CHECK (accuracy IN ('exact','approximate','wrong','assumption')),
  notes        TEXT
);

-- État des escadrilles par pas de temps (le tableau de bord de l'ordonnancement)
CREATE TABLE squadron_status (
  status_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  squadron_id  TEXT NOT NULL REFERENCES squadrons(squadron_id),
  ts           TEXT NOT NULL,
  location     TEXT NOT NULL CHECK (location IN ('deck','hangar','airborne_cap','airborne_strike','airborne_search','recovering','lost')),
  current_ordnance_id TEXT REFERENCES ordnance_types(ordnance_id),
  fuel_state   TEXT CHECK (fuel_state IN ('full','partial','low','empty')),
  available    INTEGER,                    -- nb d'appareils opérationnels
  damaged      INTEGER,
  notes        TEXT
);
CREATE INDEX idx_sq_status ON squadron_status(squadron_id, ts);

CREATE TABLE damage_states (               -- avaries des navires dans le temps
  damage_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  ship_id      TEXT NOT NULL REFERENCES ships(ship_id),
  ts           TEXT NOT NULL,
  event_id     TEXT REFERENCES events(event_id),
  description  TEXT NOT NULL,              -- '3 bombes; chaudières 1-3 HS; 19 nds max'
  speed_limit_kn REAL,
  flight_ops   TEXT CHECK (flight_ops IN ('normal','degraded','impossible')),
  notes        TEXT
);

CREATE TABLE weather_obs (
  wx_id        INTEGER PRIMARY KEY AUTOINCREMENT,
  ts           TEXT NOT NULL,
  lat          REAL, lon REAL,
  wind_dir_deg REAL, wind_speed_kn REAL,
  cloud_cover  TEXT,                       -- '3/10 cumulus base 500 m' ; front nuageux au NO = cachette de la Kido Butai
  visibility_nm REAL,
  source_id    TEXT REFERENCES sources(source_id),
  notes        TEXT
);

-- ------------------------------------------------------------
-- 4. MODÈLE — la physique de l'ordonnancement
-- ------------------------------------------------------------
CREATE TABLE process_templates (
  template_id  TEXT PRIMARY KEY,           -- ex: 'PT-REARM-B5N-TORP2BOMB'
  name         TEXT NOT NULL,
  applies_to   TEXT,                       -- type d'avion / navire / doctrine concernés
  description  TEXT,
  notes        TEXT
);

CREATE TABLE process_steps (
  step_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  template_id  TEXT NOT NULL REFERENCES process_templates(template_id),
  seq          INTEGER NOT NULL,
  name         TEXT NOT NULL,              -- 'retrait torpille', 'cycle ascenseur'...
  duration_min_s INTEGER,                  -- borne basse
  duration_typ_s INTEGER,                  -- valeur typique
  duration_max_s INTEGER,                  -- borne haute
  resources    TEXT,                       -- ressources consommées: 'elevator','arming_crew','deck','fueling_crew'
  source_id    TEXT REFERENCES sources(source_id),
  notes        TEXT
);

-- Paramètres globaux du modèle (calibrage F2/F3)
CREATE TABLE constraint_params (
  param_id     TEXT PRIMARY KEY,           -- ex: 'P-HIT-PROB-SBD-CV-1942'
  category     TEXT,                       -- 'combat','deck_ops','comms','fuel'
  description  TEXT NOT NULL,
  value        REAL,
  unit         TEXT,
  distribution TEXT,                       -- 'beta(a,b)', 'triangular(min,typ,max)'...
  calibration_note TEXT,                   -- engagements historiques utilisés pour calibrer
  source_id    TEXT REFERENCES sources(source_id)
);

-- ------------------------------------------------------------
-- 5. VUES DE CONTRÔLE QUALITÉ
-- ------------------------------------------------------------
-- Part de la base vérifiée / conflictuelle / estimée
CREATE VIEW v_data_quality AS
SELECT entity_table, status, COUNT(*) AS n
FROM claims GROUP BY entity_table, status;

-- Trous chronologiques > 30 min sur la journée du 4 juin
CREATE VIEW v_timeline_gaps_j4 AS
SELECT e1.event_id, e1.ts,
       (julianday(e2.ts) - julianday(e1.ts)) * 1440 AS gap_min,
       e2.event_id AS next_event
FROM events e1
JOIN events e2 ON e2.ts = (SELECT MIN(ts) FROM events WHERE ts > e1.ts)
WHERE e1.ts LIKE '1942-06-04%'
  AND (julianday(e2.ts) - julianday(e1.ts)) * 1440 > 30;

-- Événements sans aucune claim (donnée non sourcée = à traiter)
CREATE VIEW v_unsourced_events AS
SELECT e.* FROM events e
LEFT JOIN claims c ON c.entity_table='events' AND c.entity_id=e.event_id
WHERE c.claim_id IS NULL;

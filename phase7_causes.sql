-- ============================================================
-- PHASE 7a : causalité des mouvements + infrastructure d'inférence
-- Principe : chaque waypoint d'une piste est rattaché à l'ÉVÉNEMENT
-- qui a fixé le cap courant (ordre, décision, avarie, doctrine),
-- avec source. Les ajustements de reconstruction, eux, vont dans
-- position_inferences + claims (jamais dans events).
-- ============================================================

ALTER TABLE positions ADD COLUMN cause_event_id TEXT REFERENCES events(event_id);
ALTER TABLE positions ADD COLUMN inference_id INTEGER;

CREATE TABLE position_inferences (
  inference_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  run_ts        TEXT NOT NULL,             -- date d'exécution du moteur
  constraint_type TEXT NOT NULL CHECK (constraint_type IN
    ('wreck_anchor','flight_time_out','flight_time_return','ship_speed',
     'contact_residual','bearing_distance','triangulation')),
  entity_table  TEXT, entity_id TEXT, ts TEXT,   -- waypoint concerné
  inputs        TEXT NOT NULL,             -- événements/missions/claims utilisés (ids)
  expected      TEXT,                      -- valeur attendue par la contrainte
  observed      TEXT,                      -- valeur dans la base
  residual_nm   REAL,                      -- écart en nm (ou minutes selon type)
  action        TEXT NOT NULL CHECK (action IN ('ok','adjusted','flagged')),
  shift_nm      REAL DEFAULT 0,            -- amplitude de l'ajustement appliqué
  justification TEXT NOT NULL,             -- explication lisible, sourcée
  source_ids    TEXT                       -- sources des données d'entrée
);

-- ------------------------------------------------------------
-- Nouveaux événements de changement de cap (historiques, sourcés)
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0603-0001-MIPLAN','1942-06-03T00:01:00-12:00',0,'other','IJN','Plan MI: route d''approche du groupe de transport vers Midway (débarquement prévu le 6); cap ENE ~10 nds','J3-approche'),
 ('EV-0604-1031-KBNE','1942-06-04T10:31:00-12:00',15,'course_change','IJN','Le reliquat de la KB (Hiryū + escorte, Abe puis Yamaguchi) maintient le cap N-NE: continuer le combat et garder la portée de frappe','J4-hiryu'),
 ('EV-0604-1800-KBNW','1942-06-04T18:00:00-12:00',30,'course_change','IJN','Retraite générale de la force de Nagumo vers le NO au crépuscule (regroupement prévu avec le corps principal)','J4-soir'),
 ('EV-0605-0530-TF16W','1942-06-05T05:30:00-12:00',30,'course_change','USN','TF-16 reprend la poursuite vers l''ouest au matin (rapports de CV en flammes + contacts de la nuit)','J5-retraite'),
 ('EV-0605-1200-SALVAGE','1942-06-05T12:00:00-12:00',60,'decision','USN','Décision de sauver le Yorktown: équipe de sauvetage à bord, remorquage par le Vireo, escorte constituée','J5-retraite'),
 ('EV-0606-0645-SCOUT','1942-06-06T06:45:00-12:00',15,'sighting','USN','Reconnaissance matinale de l''Enterprise relocalise Mogami/Mikuma et leurs 2 DD; TF-16 met le cap dessus','J6-poursuite'),
 ('EV-0606-1907-RETIRE','1942-06-06T19:07:00-12:00',30,'course_change','USN','Spruance rompt la poursuite (carburant des destroyers, proximité de Wake) et fait route NE vers le ravitaillement','J6-poursuite');

INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-1800-KBNW','ts','1942-06-04T18:00:00-12:00','SRC-SHATTERED-SWORD',1,'single_source','Heure approximative du début de retraite cohérente'),
 ('events','EV-0605-0530-TF16W','ts','1942-06-05T05:30:00-12:00','SRC-CINCPAC-01849',1,'single_source',NULL),
 ('events','EV-0606-0645-SCOUT','ts','1942-06-06T06:45:00-12:00','SRC-ENTERPRISE-AR',1,'single_source',NULL),
 ('events','EV-0606-1907-RETIRE','ts','1942-06-06T19:07:00-12:00','SRC-CINCPAC-01849',1,'single_source',NULL),
 ('events','EV-0604-1031-KBNE','ts','1942-06-04T10:31:00-12:00','SRC-NAGUMO-REPORT',1,'single_source','Intention de poursuivre le combat documentée dans le rapport');

-- La décision U8 (sauvetage) pointe maintenant sur son événement
UPDATE decisions SET event_id='EV-0605-1200-SALVAGE' WHERE decision_id='DC-USN-U8-SALVAGE';

-- ------------------------------------------------------------
-- Rattachement waypoint -> événement-cause (justification du cap)
-- ------------------------------------------------------------
-- Kidō Butai
UPDATE positions SET cause_event_id='EV-0604-0430-LAUNCH'  WHERE entity_id='KIDO-BUTAI' AND ts IN ('1942-06-04T04:30:00-12:00','1942-06-04T07:00:00-12:00'); -- cap SE: fermer Midway pour récupérer + 2e frappe
UPDATE positions SET cause_event_id='EV-0604-0917-TURNNE'  WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T09:17:00-12:00';
UPDATE positions SET cause_event_id='EV-0604-0920-VT8'     WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T10:22:00-12:00'; -- manœuvres évasives sous attaques VT continues
UPDATE positions SET cause_event_id='EV-0604-1800-KBNW'    WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T18:00:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-0255-CANCEL'  WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-05T05:00:00-12:00';
-- TF-16/17 approche (2-3 juin)
UPDATE positions SET cause_event_id='EV-0602-1530-POINTLUCK' WHERE entity_id IN ('TF-16','TF-17') AND ts IN ('1942-06-02T15:30:00-12:00','1942-06-02T18:00:00-12:00','1942-06-03T06:00:00-12:00','1942-06-03T10:00:00-12:00');
UPDATE positions SET cause_event_id='EV-0603-1950-TURNSOUTH' WHERE entity_id IN ('TF-16','TF-17') AND ts='1942-06-03T18:00:00-12:00';
-- TF-16
UPDATE positions SET cause_event_id='EV-0604-0607-FLETCHER' WHERE entity_id='TF-16' AND ts IN ('1942-06-04T06:00:00-12:00','1942-06-04T07:06:00-12:00','1942-06-04T10:30:00-12:00');
UPDATE positions SET cause_event_id='EV-0604-1530-E6LAUNCH' WHERE entity_id='TF-16' AND ts='1942-06-04T15:30:00-12:00';
UPDATE positions SET cause_event_id='EV-0604-1915-SPRUANCE' WHERE entity_id='TF-16' AND ts='1942-06-04T19:07:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-0530-TF16W'    WHERE entity_id='TF-16' AND ts IN ('1942-06-05T06:00:00-12:00','1942-06-05T18:00:00-12:00');
UPDATE positions SET cause_event_id='EV-0606-0645-SCOUT'    WHERE entity_id='TF-16' AND ts IN ('1942-06-06T09:00:00-12:00','1942-06-06T15:00:00-12:00');
UPDATE positions SET cause_event_id='EV-0606-1907-RETIRE'   WHERE entity_id='TF-16' AND ts='1942-06-07T08:00:00-12:00';
-- TF-17 / Yorktown
UPDATE positions SET cause_event_id='EV-0604-0838-TF17LAUNCH' WHERE entity_id='TF-17' AND ts='1942-06-04T08:38:00-12:00';
UPDATE positions SET cause_event_id='EV-0604-1500-ABANDON'    WHERE entity_id='TF-17' AND ts='1942-06-04T16:00:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-1200-SALVAGE'    WHERE entity_id='TF-17' AND ts IN ('1942-06-05T12:00:00-12:00','1942-06-06T13:00:00-12:00');
UPDATE positions SET cause_event_id='EV-0604-1205-KOBAYASHI'  WHERE entity_id='SH-CV5' AND ts='1942-06-04T12:11:00-12:00';
UPDATE positions SET cause_event_id='EV-0604-1430-TOMOATK'    WHERE entity_id='SH-CV5' AND ts='1942-06-04T14:43:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-1200-SALVAGE'    WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00';
UPDATE positions SET cause_event_id='EV-0607-0701-YKSINK'     WHERE entity_id='SH-CV5' AND ts='1942-06-07T07:01:00-12:00';
-- Hiryū
UPDATE positions SET cause_event_id='EV-0604-1031-KBNE'    WHERE entity_id='SH-HIRYU' AND ts IN ('1942-06-04T10:54:00-12:00','1942-06-04T14:30:00-12:00','1942-06-04T17:01:00-12:00');
UPDATE positions SET cause_event_id='EV-0605-0912-HIRYUSINK' WHERE entity_id='SH-HIRYU' AND ts='1942-06-05T09:12:00-12:00';
-- CruDiv 7
UPDATE positions SET cause_event_id='EV-0605-0215-TAMBOR'  WHERE entity_id='CRUDIV7' AND ts='1942-06-05T02:23:00-12:00'; -- virage d'urgence (cause de la collision)
UPDATE positions SET cause_event_id='EV-0605-0255-CANCEL'  WHERE entity_id='CRUDIV7' AND ts IN ('1942-06-05T08:05:00-12:00','1942-06-06T09:50:00-12:00'); -- retraite O après annulation
UPDATE positions SET cause_event_id='EV-0606-1930-MIKUMASINK' WHERE entity_id='CRUDIV7' AND ts='1942-06-06T19:30:00-12:00';
-- Transports
UPDATE positions SET cause_event_id='EV-0603-0001-MIPLAN'  WHERE entity_id='TRANSPORT-GROUP';
-- Épaves -> événement de naufrage
UPDATE positions SET cause_event_id='EV-0604-1925-KAGASINK'   WHERE entity_id='SH-KAGA'    AND ts='1942-06-04T19:25:00-12:00';
UPDATE positions SET cause_event_id='EV-0604-1913-SORYUSINK'  WHERE entity_id='SH-SORYU'   AND ts='1942-06-04T19:13:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-0500-AKAGISINK'  WHERE entity_id='SH-AKAGI'   AND ts='1942-06-05T05:20:00-12:00';
UPDATE positions SET cause_event_id='EV-0605-0912-HIRYUSINK'  WHERE entity_id='SH-HIRYU'   AND ts='1942-06-05T09:12:00-12:00';
UPDATE positions SET cause_event_id='EV-0606-1336-I168'       WHERE entity_id='SH-HAMMANN';
UPDATE positions SET cause_event_id='EV-0606-1930-MIKUMASINK' WHERE entity_id='SH-MIKUMA';

-- ============================================================
-- PHASE 7c : virages explicites de TF-16 (constat: deux changements
-- de cap étaient couverts par des événements-proxy ou absents)
-- ============================================================
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-1455-TF16NW','1942-06-04T14:55:00-12:00',15,'course_change','USN',
  'TF-16 vient au NO pour fermer la distance sur le Hiryū localisé par VS-5 (rapport Adams 14:45) avant de lancer','J4-hiryu'),
 ('EV-0605-0001-TF16N','1942-06-05T00:01:00-12:00',20,'course_change','USN',
  'Minuit: fin de la jambe est défensive; TF-16 vient au nord puis à l''ouest (plan annoncé de Spruance) pour être en position de frapper à l''aube','J5-retraite');

INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-1455-TF16NW','ts','1942-06-04T14:55:00-12:00','SRC-ENTERPRISE-AR',1,'single_source','Déduit: réception du rapport Adams (14:45-14:50) + lancement 15:30 cap 300'),
 ('events','EV-0605-0001-TF16N','ts','1942-06-05T00:01:00-12:00','SRC-CINCPAC-01849',1,'single_source','Intention documentée dans le rapport de Spruance (course east until midnight)');

-- Re-rattachement: le waypoint 15:30 est causé par le virage, pas par le lancement
UPDATE positions SET cause_event_id='EV-0604-1455-TF16NW'
 WHERE entity_id='TF-16' AND ts='1942-06-04T15:30:00-12:00';
-- Le waypoint 06:00 du 5 juin reste causé par EV-0605-0530-TF16W (poursuite O),
-- mais le segment nocturne 19:07->06:00 est désormais documenté par EV-0605-0001-TF16N.

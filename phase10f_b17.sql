-- ============================================================
-- PHASE 10f : trajet réel des B-17 du 4 juin au matin (constat
-- replay). Partis à 04:15 CONTRE LE CONVOI (mission planifiée la
-- veille), déroutés en vol vers la Kidō Butai après les contacts
-- PBY de 05:34-05:52. Le tracé direct était une simplification.
-- ============================================================

-- L'événement de déroutement (la cause du crochet)
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-0615-B17DIVERT','1942-06-04T06:15:00-12:00',20,'course_change','USN',
  'Les 15 B-17 de Sweeney, en route vers le convoi de transport, sont déroutés vers les porte-avions japonais signalés par les PBY','J4-matin');
INSERT INTO event_participants VALUES
 ('EV-0604-0615-B17DIVERT','squadrons','SQ-B17-MIDWAY','actor');
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-0615-B17DIVERT','ts','1942-06-04T06:15:00-12:00','SRC-CINCPAC-01849',1,'single_source',
  'Heure du déroutement à préciser (rapport 7th Air Force); borne: après le rapport de 05:52, avant l''attaque de 08:10');

-- Le trajet en crochet remplace la ligne droite
UPDATE mission_legs SET seq=3 WHERE mission_id='MS-0604-B17AM' AND seq=2;  -- le retour devient seq 3
UPDATE mission_legs SET end_ts='1942-06-04T06:15:00-12:00', end_lat=27.00, end_lon=-180.50,
  course_deg=250, notes='Cap initial SO vers le convoi de transport (mission planifiée la veille)'
 WHERE mission_id='MS-0604-B17AM' AND seq=1;
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-B17AM',2,'1942-06-04T06:15:00-12:00','1942-06-04T08:10:00-12:00',27.00,-180.50,30.60,-179.20,18,125,6000,'estimated',
  'DÉROUTEMENT vers la Kidō Butai (EV-0604-0615-B17DIVERT) — ~227 nm');

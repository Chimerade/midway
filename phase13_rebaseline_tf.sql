-- phase13_rebaseline_tf.sql
-- Recalage TF-16/TF-17 sur les positions journalisées (document de reconstruction).
-- Heures en Zone+12 (doc Zone+10 converti -2h). Couche d'UPDATE appliquée APRÈS les INSERT,
-- donc elle écrase les estimations antérieures. Les bouts de legs ancrés sur les TF
-- (lancements, retours) suivent; les bouts ancrés sur la cible (KB/Hiryū/Mogami) restent fixes.
-- TF-16
UPDATE positions SET lat=31.650,lon=-176.233,course_deg=198 WHERE entity_id='TF-16' AND ts='1942-06-04T06:00:00-12:00';
UPDATE positions SET lat=31.366,lon=-176.343,course_deg=195 WHERE entity_id='TF-16' AND ts='1942-06-04T07:06:00-12:00';
UPDATE positions SET lat=30.597,lon=-176.581,course_deg=114 WHERE entity_id='TF-16' AND ts='1942-06-04T10:30:00-12:00';
UPDATE positions SET lat=30.587,lon=-176.555,course_deg=114 WHERE entity_id='TF-16' AND ts='1942-06-04T10:45:00-12:00';
UPDATE positions SET lat=30.518,lon=-176.373,course_deg=114 WHERE entity_id='TF-16' AND ts='1942-06-04T12:30:00-12:00';
UPDATE positions SET lat=30.399,lon=-176.060,course_deg=123 WHERE entity_id='TF-16' AND ts='1942-06-04T15:30:00-12:00';
UPDATE positions SET lat=30.252,lon=-175.795,course_deg=175 WHERE entity_id='TF-16' AND ts='1942-06-04T19:07:00-12:00';
UPDATE positions SET lat=30.041,lon=-175.775,course_deg=175 WHERE entity_id='TF-16' AND ts='1942-06-05T00:01:00-12:00';
UPDATE positions SET lat=29.783,lon=-175.750,course_deg=281 WHERE entity_id='TF-16' AND ts='1942-06-05T06:00:00-12:00';
UPDATE positions SET lat=30.425,lon=-179.707,course_deg=271 WHERE entity_id='TF-16' AND ts='1942-06-05T18:00:00-12:00';
UPDATE positions SET lat=30.488,lon=-184.233,course_deg=218 WHERE entity_id='TF-16' AND ts='1942-06-06T09:00:00-12:00';
UPDATE positions SET lat=29.670,lon=-184.973,course_deg=155 WHERE entity_id='TF-16' AND ts='1942-06-06T15:00:00-12:00';
-- TF-17
UPDATE positions SET lat=31.218,lon=-176.278,course_deg=146 WHERE entity_id='TF-17' AND ts='1942-06-04T08:38:00-12:00';
UPDATE positions SET lat=30.867,lon=-176.000,course_deg=327 WHERE entity_id='TF-17' AND ts='1942-06-04T16:00:00-12:00';
-- Origines de lancement et retours des frappes embarquées, ré-ancrés sur les TF recalées
UPDATE mission_legs SET start_lat=31.107,start_lon=-176.443 WHERE mission_id='MS-0604-CV6AM' AND seq=1;
UPDATE mission_legs SET end_lat=30.534,end_lon=-176.416 WHERE mission_id='MS-0604-CV6AM' AND seq=5;
UPDATE mission_legs SET start_lat=31.188,start_lon=-176.253 WHERE mission_id='MS-0604-CV5AM' AND seq=1;
UPDATE mission_legs SET end_lat=30.538,end_lon=-176.425 WHERE mission_id='MS-0604-CV5AM' AND seq=3;
UPDATE mission_legs SET start_lat=31.133,start_lon=-176.433 WHERE mission_id='MS-0604-VT6' AND seq=1;
UPDATE mission_legs SET end_lat=30.577,end_lon=-176.529 WHERE mission_id='MS-0604-VT6' AND seq=2;
UPDATE mission_legs SET start_lat=30.389,start_lon=-176.034 WHERE mission_id='MS-0604-E6PM' AND seq=1;
UPDATE mission_legs SET end_lat=30.278,end_lon=-175.798 WHERE mission_id='MS-0604-E6PM' AND seq=2;
UPDATE mission_legs SET start_lat=30.592,start_lon=-183.917 WHERE mission_id='MS-0606-STRIKE1' AND seq=1;
UPDATE mission_legs SET end_lat=29.702,end_lon=-184.441 WHERE mission_id='MS-0606-STRIKE1' AND seq=2;
UPDATE mission_legs SET start_lat=30.042,start_lon=-184.495 WHERE mission_id='MS-0606-STRIKE2' AND seq=1;
UPDATE mission_legs SET end_lat=29.613,end_lon=-184.709 WHERE mission_id='MS-0606-STRIKE2' AND seq=2;
UPDATE mission_legs SET start_lat=29.613,start_lon=-184.709 WHERE mission_id='MS-0606-STRIKE3' AND seq=1;
UPDATE mission_legs SET end_lat=29.717,end_lon=-185.193 WHERE mission_id='MS-0606-STRIKE3' AND seq=2;
UPDATE mission_legs SET start_ts='1942-06-04T08:05:00-12:00',start_lat=31.112,start_lon=-176.442 WHERE mission_id='MS-0604-VT8' AND seq=1;
-- Note recalée: la frappe anti-Hiryū part désormais de la TF-16 journalisée (plus à l'est) -> ~180 nm
UPDATE mission_legs SET notes='~180 nm (TF-16 recalée à l''est, journaux de bord) + montée et mise en place de l''attaque' WHERE mission_id='MS-0604-E6PM' AND seq=1;
-- Creux sud de la poursuite du 5 (position journal de bord à midi) : ajout d'un waypoint + recalage du cap amont
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes)
 VALUES ('formations','TF-16','1942-06-05T10:00:00-12:00',29.083,-177.333,303,15,'estimated',30,'EV-0605-0530-TF16W','Creux sud de la poursuite (position journal de bord, midi Z+10 = 10:00 Z+12)');
UPDATE positions SET course_deg=243 WHERE entity_id='TF-16' AND ts='1942-06-05T06:00:00-12:00';

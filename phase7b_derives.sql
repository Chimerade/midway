-- ============================================================
-- PHASE 7b : pistes de dérive propres des navires frappés
-- Constat du moteur d'inférence (wreck_anchor FAIL): les CV en
-- flammes ne suivent PAS la piste de la formation qui retraite.
-- Chaque navire frappé reçoit sa piste: point d'impact -> épave.
-- ============================================================
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes) VALUES
 ('ships','SH-KAGA','1942-06-04T10:26:00-12:00',30.55,-179.15,NULL,0,'estimated',20,'EV-0604-1022-KAGA','Stoppé en flammes au point d''impact; dérive ensuite (~1.5 nds) vers la position de naufrage'),
 ('ships','SH-SORYU','1942-06-04T10:28:00-12:00',30.57,-179.13,NULL,0,'estimated',20,'EV-0604-1025-SORYU','Stoppé 10:40; abandon 10:45; dérive courte'),
 ('ships','SH-AKAGI','1942-06-04T10:26:00-12:00',30.53,-179.12,NULL,2,'estimated',20,'EV-0604-1026-AKAGI','Gouvernail bloqué 10:42 (cercles), puis dérive E ~1.3 nds sur 19 h jusqu''au point de sabordage'),
 ('ships','SH-AKAGI','1942-06-04T19:00:00-12:00',30.52,-178.95,NULL,1,'estimated',20,'EV-0604-1026-AKAGI','Équipage évacué progressivement; remorquage envisagé puis abandonné');

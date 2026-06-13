-- ============================================================
-- PHASE 8c : recherche PBY du 3 juin (ligne de Reid) + correction
-- de la distance du contact (constat utilisateur sur le replay).
-- "700 nm" était le RAYON de recherche, pas la distance du contact.
-- Arbitrage: Wikipédia/récits "500 nm OSO" vs géométrie (attaque
-- B-17 à ~385 nm à 16:24, convoi <=11-13 nds) -> ~450 nm retenu.
-- ============================================================

UPDATE events SET summary='PBY de VP-44 (Ens. Reid) repère le groupe de transport à ~450 nm OSO de Midway (relèvement ~253°); rapporté à tort comme "Main Body"'
 WHERE event_id='EV-0603-0900-PBY';

UPDATE positions SET lat=26.10, lon=-185.30,
  notes='Contact Reid ~450 nm OSO — distance arbitrée par la géométrie (convoi 10-11 nds jusqu''au point d''attaque B-17 de 16:24)'
 WHERE entity_id='TRANSPORT-GROUP' AND ts='1942-06-03T09:00:00-12:00';

INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0603-0900-PBY','contact_distance_nm','450','500 nm OSO (récits usuels); 700 nm = rayon de recherche','SRC-CRESSMAN',1,'conflicting',
  'Les récits donnent 500-700 nm; la contrainte de vitesse du convoi (<=13 nds) entre le contact (09:00) et l''attaque B-17 (16:24, ~385 nm) impose ~430-470 nm. Valeur retenue: 450 nm. À trancher avec le rapport VP-44 / CINCPAC.');

-- Mission de recherche du 3 juin (ligne de Reid, représentative de l'éventail du jour)
INSERT INTO missions VALUES
 ('MS-0603-PBY-SEARCH','USN','SH-MIDWAY','search','Recherche quotidienne OSO (ligne de Reid, VP-44, relèvement ~253°)',
  '1942-06-03T04:15:00-12:00','1942-06-03T04:30:00-12:00',NULL,'1942-06-03T18:15:00-12:00',
  '09:00: contact "Main Body" (en réalité les transports); Reid maintient le contact ~2h',
  'Une ligne représentative; l''éventail complet du 3 juin (~22 PBY) sera tracé avec le schéma CINCPAC');
INSERT INTO mission_squadrons VALUES
 ('MS-0603-PBY-SEARCH','SQ-PBY-MIDWAY',1,0,NULL,'PBY 44-P-4 (Reid)');
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0603-PBY-SEARCH',1,'1942-06-03T04:15:00-12:00','1942-06-03T11:15:00-12:00',28.21,-177.37,24.80,-189.83,253,100,300,'estimated','aller 700 nm — contact à ~450 nm vers 09:00'),
 ('MS-0603-PBY-SEARCH',2,'1942-06-03T11:15:00-12:00','1942-06-03T18:15:00-12:00',24.80,-189.83,28.21,-177.37,73,100,300,'estimated','retour (avec ~2h de pistage du convoi: simplifié)');

-- ============================================================
-- PHASE 4b : corrections issues du premier audit de cohérence
-- (audit_coherence.py — 1 FAIL / 22 WARN du 12/06/2026)
-- ============================================================

-- [FAIL B1] Le raid PBY de nuit décollait le 3 juin au soir, pas le 4
UPDATE missions SET launch_start_ts='1942-06-03T21:15:00-12:00',
  notes='4 PBY-5A radar; décollage le 3 juin au soir, attaque 01:43 le 4 (corrigé audit B1)'
 WHERE mission_id='MS-0604-PBYNIGHT';

-- [WARN C3] Position rapportée manquante du 2e rapport Tone n°4
UPDATE contact_reports SET reported_lat=31.80, reported_lon=-176.70,
  notes='Position approx. (suivi de la TF depuis 07:28); l''original donne relèvement/distance depuis sa position estimée — à raffiner'
 WHERE report_id='CR-TONE4-0820';

-- [WARN J1] Renommage id événement (heure encodée fausse)
UPDATE events SET event_id='EV-0606-1930-MIKUMASINK' WHERE event_id='EV-0606-1900-MIKUMASINK';

-- ------------------------------------------------------------
-- [Recoupement épaves] Piste KB trop au NO: recalée pour que la
-- distance Midway<->KB colle aux positions de naufrage (~160-170 nm)
-- et aux durées de vol des raids de Midway (~150-170 nm)
-- ------------------------------------------------------------
UPDATE positions SET lat=31.00, lon=-179.60, notes='Point de lancement recalé (~200 nm NO de Midway) — cohérent épaves + durées de vol'
 WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T04:30:00-12:00';
UPDATE positions SET lat=30.70, lon=-179.30
 WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T07:00:00-12:00';
UPDATE positions SET lat=30.50, lon=-179.10
 WHERE entity_id='KIDO-BUTAI' AND ts='1942-06-04T09:17:00-12:00';
-- (10:22 inchangé: 30.55,-179.15, ancré sur le groupe d'épaves)

-- Trajets Tomonaga recalés en conséquence
UPDATE mission_legs SET start_lat=31.00, start_lon=-179.60 WHERE mission_id='MS-0604-TOMONAGA' AND seq=1;
UPDATE mission_legs SET end_lat=30.65, end_lon=-179.20 WHERE mission_id='MS-0604-TOMONAGA' AND seq=3;

-- ------------------------------------------------------------
-- [WARN H2] Couverture des pistes 4 juin soir -> 7 juin
-- ------------------------------------------------------------
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,notes) VALUES
 -- Kidō Butai (reliquat: Nagara, escorte, remorquage des CV en flammes) — retraite NO
 ('formations','KIDO-BUTAI','1942-06-04T18:00:00-12:00',31.10,-179.70,310,12,'estimated',30,'Reliquat (Nagara + escorte), retraite NO avec les CV en flammes'),
 ('formations','KIDO-BUTAI','1942-06-05T05:00:00-12:00',31.80,-180.80,300,14,'estimated',35,'Zone de sabordage Akagi/Hiryū — grossier'),
 -- TF-16: nuit à l'est, poursuite O le 5, SO-O le 6
 ('formations','TF-16','1942-06-05T06:00:00-12:00',31.40,-177.40,270,15,'estimated',25,'Retour O après la nuit défensive à l''est'),
 ('formations','TF-16','1942-06-05T18:00:00-12:00',30.80,-179.60,280,18,'estimated',30,'Poursuite; frappe Tanikaze au crépuscule'),
 ('formations','TF-16','1942-06-06T09:00:00-12:00',29.50,-183.50,250,20,'estimated',35,'À portée de CruDiv 7 (~95 nm)'),
 ('formations','TF-16','1942-06-06T15:00:00-12:00',29.40,-184.50,260,15,'estimated',35,'3e frappe lancée'),
 -- TF-17: après l'abandon du Yorktown, escorte/sauvetage
 ('formations','TF-17','1942-06-04T16:00:00-12:00',31.55,-176.80,90,15,'estimated',25,'Après abandon du Yorktown; Fletcher sur l''Astoria'),
 ('formations','TF-17','1942-06-05T12:00:00-12:00',31.00,-176.10,100,12,'estimated',30,'Retrait E; éléments détachés vers le sauvetage'),
 ('formations','TF-17','1942-06-06T13:00:00-12:00',30.85,-176.60,0,5,'estimated',20,'Écran autour du groupe de sauvetage Yorktown'),
 -- Yorktown: dérive puis remorquage lent vers l'est
 ('ships','SH-CV5','1942-06-06T13:36:00-12:00',30.85,-176.60,90,2,'estimated',15,'Sous remorque du Vireo au moment de l''attaque d''I-168'),
 -- CruDiv 7 (Mogami/Mikuma + 2 DD): fuite O à ~9-12 nds
 ('formations','CRUDIV7','1942-06-05T08:05:00-12:00',28.40,-181.00,280,11,'estimated',40,'Attaque VMSB-241 (crash de Fleming sur le Mikuma)'),
 ('formations','CRUDIV7','1942-06-06T09:50:00-12:00',29.20,-185.20,290,9,'estimated',40,'Sous les frappes successives de TF-16'),
 ('formations','CRUDIV7','1942-06-06T19:30:00-12:00',29.47,-186.82,290,8,'estimated',30,'Le Mikuma coule; Mogami + 2 DD continuent vers Wake/Truk'),
 ('formations','TF-16','1942-06-07T08:00:00-12:00',29.80,-182.50,80,15,'estimated',40,'Fin de poursuite (limite carburant des DD); route de retour NE'),
 -- Groupe de transport (3 juin): approche depuis l'O-SO
 ('formations','TRANSPORT-GROUP','1942-06-03T09:00:00-12:00',26.50,-184.80,80,10,'estimated',40,'Contact PBY (Reid) ~700 nm de Midway'),
 ('formations','TRANSPORT-GROUP','1942-06-03T16:24:00-12:00',26.80,-184.00,80,10,'estimated',40,'Attaque B-17 (aucun coup)'),
 ('formations','TRANSPORT-GROUP','1942-06-04T01:43:00-12:00',27.20,-182.80,80,10,'estimated',40,'Attaque de nuit des PBY (Akebono Maru touché)');

-- ------------------------------------------------------------
-- [WARN H3] Segments de trajet manquants (missions inaffichables)
-- ------------------------------------------------------------
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0603-B17',1,'1942-06-03T12:45:00-12:00','1942-06-03T16:24:00-12:00',28.21,-177.37,26.80,-184.00,255,160,3500,'estimated','~390 nm; vitesse-déplacement basse = inclut montée/regroupement'),
 ('MS-0604-PBYNIGHT',1,'1942-06-03T21:15:00-12:00','1942-06-04T01:43:00-12:00',28.21,-177.37,27.20,-182.80,255,95,300,'estimated','Approche de nuit au ras de l''eau'),
 ('MS-0604-VT8DET',1,'1942-06-04T06:00:00-12:00','1942-06-04T07:10:00-12:00',28.21,-177.37,30.62,-179.20,325,140,1200,'estimated','~165 nm — TBF à régime élevé'),
 ('MS-0604-B26',1,'1942-06-04T06:00:00-12:00','1942-06-04T07:10:00-12:00',28.21,-177.37,30.62,-179.20,325,150,800,'estimated',NULL),
 ('MS-0604-VMSB-SBD',1,'1942-06-04T06:10:00-12:00','1942-06-04T07:55:00-12:00',28.21,-177.37,30.68,-179.27,325,100,2500,'estimated','Formation lente, montée en route'),
 ('MS-0604-B17AM',1,'1942-06-04T04:15:00-12:00','1942-06-04T08:10:00-12:00',28.21,-177.37,30.60,-179.20,325,90,6000,'estimated','Déroutés en vol depuis la mission transports: déplacement net faible'),
 ('MS-0604-SB2U',1,'1942-06-04T06:15:00-12:00','1942-06-04T08:20:00-12:00',28.21,-177.37,30.55,-179.05,325,85,2000,'estimated','Attaque le Haruna en périphérie de la KB'),
 ('MS-0604-VT6',1,'1942-06-04T08:00:00-12:00','1942-06-04T09:38:00-12:00',31.40,-177.10,30.47,-179.05,245,95,500,'estimated','Approche basse; déplacement net < distance volée (recherche)'),
 ('MS-0606-STRIKE1',1,'1942-06-06T08:00:00-12:00','1942-06-06T09:50:00-12:00',29.55,-183.40,29.20,-185.20,250,110,4000,'estimated',NULL),
 ('MS-0606-STRIKE2',1,'1942-06-06T10:45:00-12:00','1942-06-06T12:00:00-12:00',29.50,-183.80,29.25,-185.50,250,120,4000,'estimated',NULL),
 ('MS-0606-STRIKE3',1,'1942-06-06T13:30:00-12:00','1942-06-06T14:45:00-12:00',29.42,-184.30,29.35,-186.20,255,125,4000,'estimated',NULL);

-- ------------------------------------------------------------
-- [INFO I1] Premières observations météo (le front NO = acteur tactique)
-- ------------------------------------------------------------
INSERT INTO weather_obs (ts,lat,lon,wind_dir_deg,wind_speed_kn,cloud_cover,visibility_nm,source_id,notes) VALUES
 ('1942-06-04T06:00:00-12:00',30.8,-179.3,110,5,'6-8/10 cumulus fragmentés, base ~450 m',25,'SRC-SHATTERED-SWORD','Zone KB: couverture partielle — cache la force aux B-17 et complique les recherches US'),
 ('1942-06-04T06:00:00-12:00',31.5,-176.9,120,8,'2-3/10',40,'SRC-ENTERPRISE-AR','Zone TF-16/17: temps clair — asymétrie météo en faveur des Japonais le matin'),
 ('1942-06-04T06:00:00-12:00',28.2,-177.4,100,9,'1-2/10',45,'SRC-CINCPAC-01849','Midway: clair; vent E-SE faible — vent apparent insuffisant: les CV doivent courir à pleine vitesse pour lancer'),
 ('1942-06-05T12:00:00-12:00',31.0,-179.0,140,12,'8-10/10, grains épars',8,'SRC-SHATTERED-SWORD','Le front couvre la retraite japonaise le 5 — frappes US de l''après-midi gênées');

-- Claims sur le recalage de piste (traçabilité de l'arbitrage)
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('positions','KIDO-BUTAI','track_0604','recalée -20nm vers Midway','SRC-COMBINEDFLEET',1,'estimated',
  'Arbitrage audit 4b: triangulation épaves (Kaga/Sōryū ~160-165 nm de Midway) + durées de vol des raids de Midway (60-105 min) incompatibles avec la piste initiale (~190-200 nm à 07:00). Géoréférencement des cartes SS requis pour trancher finement.');

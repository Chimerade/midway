-- ============================================================
-- PHASE 14 : vérifications sur sources officielles (lot 1, 2026-10-03)
-- Générée par generer_phase14_verifications.py — ne pas éditer à la main.
-- Heures en zone +12 ; rapports de TF-16/TF-17 en zone +10 convertis (-2 h).
-- ============================================================

-- ------------------------------------------------------------
-- 0. Sources primaires consultées
-- ------------------------------------------------------------
INSERT INTO sources (source_id,type,author,title,year,grade,time_reference,url,notes) VALUES
 ('SRC-DESRON6-AR','primary_official','Commander Destroyer Squadron Six','Battle of Midway — action report (Balch, Benham)',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-DesRon6.html',
  'Seul fix relatif chiffré de TF-17 au moment de l''attaque Kobayashi: fumée et DCA « bearing 315° (T), distance about 12 miles » depuis TF-16'),
 ('SRC-CTF16-AR','primary_official','Commander Task Force 16 (Spruance)','Battle of Midway — TF 16 action report',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-Carriers.html',
  '« All times given are zone plus ten »; à la 1re attaque, le Yorktown est « nearly out of sight of us to the northwestward »'),
 ('SRC-BUSHIPS-WDR','primary_official','Bureau of Ships','U.S.S. Yorktown (CV-5) — Loss in Action, Midway, June 4-7, 1942 (War Damage Report)',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/WDR/U.S.S.%20YORKTOWN%20(CV-5),%20BOMB%20AND%20TORPEDO%20DAMAGE%20-%20Midway,%20June%204%20to%207,%201942%20(LOST%20IN%20ACTION).pdf',
  'Chronologie des avaries à la minute (zone +10): bombes 1414, stoppé 1440, 20 nds dispo 1550, torpilles 1645, abandon 1702, survivants recueillis 1918, naufrage 0701'),
 ('SRC-ONI-CN-1943','primary_official','Office of Naval Intelligence','The Battle of Midway, June 3-6, 1942 (Combat Narrative)',1943,'A','GMT-12',
  'https://www.ibiblio.org/hyperwar/USN/USN-CN-Midway/index.html',
  'Récit officiel contemporain établi d''après les rapports d''action');
UPDATE sources SET url='https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-CinCPac.html'
 WHERE source_id='SRC-CINCPAC-01849' AND url IS NULL;

-- ------------------------------------------------------------
-- 1. Nouveaux événements (chronologie des actions vérifiées)
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-0940-CV8TURN','1942-06-04T09:40:00-12:00',10,'course_change','USN',
  'Flight to nowhere: VS-8 fait demi-tour vers le Hornet, Ring poursuit seul vers l''ouest puis rentre; VB-8 se déroute sur Midway (2 SBD amerris dans le lagon); les 10 F4F de VF-8 amerrissent à court d''essence (8 pilotes récupérés)','J4-matin'),
 ('EV-0604-1130-VS5LAUNCH','1942-06-04T11:30:00-12:00',20,'launch_start','USN',
  'Le Yorktown lance 10 SBD de VS-5 (1 bombe de 1 000 lb chacun) en recherche sur 280°-020° à 200 nm pour trouver le 4e porte-avions','J4-hiryu'),
 ('EV-0604-1402-YKREPART','1942-06-04T14:02:00-12:00',10,'course_change','USN',
  'Feux éteints et conduits réparés: le Yorktown repart cap 090 et remonte à 19-20 nds; Pensacola, Vincennes, Balch et Benham, détachés de TF-16, ont rallié son écran','J4-hiryu'),
 ('EV-0604-1718-YKRESCUE','1942-06-04T17:18:00-12:00',15,'other','USN',
  'Fin du recueil des survivants du Yorktown: TF-17 se retire vers l''est, le Hughes reste seul auprès du porte-avions abandonné','J4-hiryu');
INSERT INTO event_participants (event_id,entity_table,entity_id,role) VALUES
 ('EV-0604-0940-CV8TURN','squadrons','SQ-VS8','actor'),('EV-0604-0940-CV8TURN','squadrons','SQ-VB8','actor'),
 ('EV-0604-0940-CV8TURN','squadrons','SQ-VF8','actor'),
 ('EV-0604-1130-VS5LAUNCH','ships','SH-CV5','actor'),('EV-0604-1130-VS5LAUNCH','squadrons','SQ-VS5','actor'),
 ('EV-0604-1402-YKREPART','ships','SH-CV5','actor'),
 ('EV-0604-1718-YKRESCUE','formations','TF-17','actor'),('EV-0604-1718-YKRESCUE','ships','SH-HUGHES','actor');

-- ------------------------------------------------------------
-- 2. Contact d'Adams : 14:30, pas 14:45 (CINCPAC « at 1430 », ONI « 1430 »,
--    Yorktown « about 1630 » en zone +10). L'identifiant encode l'heure : on renomme.
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,lat,lon,position_error_nm,phase,notes)
 SELECT 'EV-0604-1430-ADAMS','1942-06-04T14:30:00-12:00',10,event_type,side,
  'SBD de VS-5 (Adams, éventail lancé par le Yorktown 3 h plus tôt) localise le Hiryū: "1 CV, 2 BB, 3 CA, 4 DD, 31°15''N 179°05''W"',
  lat,lon,position_error_nm,phase,notes FROM events WHERE event_id='EV-0604-1445-ADAMS';
UPDATE event_participants SET event_id='EV-0604-1430-ADAMS' WHERE event_id='EV-0604-1445-ADAMS';
UPDATE claims SET entity_id='EV-0604-1430-ADAMS', value='1942-06-04T14:30:00-12:00',
  resolution_note='Le rapport Yorktown confirme mot pour mot composition et position du contact Adams; heure: « about 1630 » (zone +10) = 14:30'
 WHERE entity_table='events' AND entity_id='EV-0604-1445-ADAMS';
INSERT INTO contact_reports (report_id,reporter_table,reporter_id,ts_observed,ts_sent,ts_received,recipient_id,
                             reported_lat,reported_lon,reported_composition,actual_event_id,position_error_actual_nm,notes)
 SELECT 'CR-0604-1430-ADAMS',reporter_table,reporter_id,'1942-06-04T14:30:00-12:00','1942-06-04T14:30:00-12:00','1942-06-04T14:35:00-12:00',
  recipient_id,reported_lat,reported_lon,reported_composition,'EV-0604-1430-ADAMS',position_error_actual_nm,notes
 FROM contact_reports WHERE report_id='CR-0604-1445-ADAMS';
DELETE FROM contact_reports WHERE report_id='CR-0604-1445-ADAMS';
DELETE FROM events WHERE event_id='EV-0604-1445-ADAMS';
UPDATE events SET summary=REPLACE(summary,'(rapport Adams 14:45)','(rapport Adams 14:30)') WHERE event_id='EV-0604-1455-TF16NW';
UPDATE claims SET resolution_note=REPLACE(resolution_note,'rapport Adams (14:45-14:50)','rapport Adams (14:30-14:35)')
 WHERE resolution_note LIKE '%rapport Adams (14:45-14:50)%';
UPDATE decisions SET consequences=REPLACE(consequences,'le Hiryū à 14:45','le Hiryū à 14:30')
 WHERE consequences LIKE '%le Hiryū à 14:45%';
UPDATE squadron_status SET notes=REPLACE(notes,'le Hiryū à 14:45','le Hiryū à 14:30')
 WHERE squadron_id='SQ-VS5' AND notes LIKE '%le Hiryū à 14:45%';

-- ------------------------------------------------------------
-- 3. Recherche VS-5 : lancée à 11:30 (13:30 était l'heure du bord non convertie)
-- ------------------------------------------------------------
UPDATE missions SET launch_start_ts='1942-06-04T11:30:00-12:00', launch_end_ts='1942-06-04T11:40:00-12:00',
  recovery_ts='1942-06-04T16:12:00-12:00', outcome='14:30: Adams localise le Hiryū',
  notes='10 SBD en éventail 200 nm sur 280°-020° (la réserve de Fletcher paie); récupérés par TF-16, le Yorktown étant hors de combat'
 WHERE mission_id='MS-0604-VS5SEARCH';
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-VS5SEARCH',1,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,31.900,-180.147,290,115,1500,'estimated','Ligne 290° — 200 nm'),
 ('MS-0604-VS5SEARCH',2,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',31.900,-180.147,31.339,-180.312,194,105,1500,'estimated','Ligne 290° — crochet vers 280° (35 nm)'),
 ('MS-0604-VS5SEARCH',3,'1942-06-04T13:44:00-12:00','1942-06-04T16:09:00-12:00',31.339,-180.312,30.373,-176.012,105,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat): Adams repère le Hiryū sur ce trajet'),
 ('MS-0604-VS5SEARCH',4,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,32.427,-179.869,300,115,1500,'estimated','Ligne 300° — 200 nm'),
 ('MS-0604-VS5SEARCH',5,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',32.427,-179.869,31.900,-180.147,204,105,1500,'estimated','Ligne 300° — crochet vers 290° (35 nm)'),
 ('MS-0604-VS5SEARCH',6,'1942-06-04T13:44:00-12:00','1942-06-04T16:10:00-12:00',31.900,-180.147,30.372,-176.011,113,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',7,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,32.903,-179.485,310,115,1500,'estimated','Ligne 310° — 200 nm'),
 ('MS-0604-VS5SEARCH',8,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',32.903,-179.485,32.427,-179.869,214,105,1500,'estimated','Ligne 310° — crochet vers 300° (35 nm)'),
 ('MS-0604-VS5SEARCH',9,'1942-06-04T13:44:00-12:00','1942-06-04T16:11:00-12:00',32.427,-179.869,30.371,-176.010,122,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',10,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,33.313,-179.008,320,115,1500,'estimated','Ligne 320° — 200 nm'),
 ('MS-0604-VS5SEARCH',11,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',33.313,-179.008,32.903,-179.485,224,105,1500,'estimated','Ligne 320° — crochet vers 310° (34 nm)'),
 ('MS-0604-VS5SEARCH',12,'1942-06-04T13:44:00-12:00','1942-06-04T16:12:00-12:00',32.903,-179.485,30.371,-176.009,131,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',13,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,33.647,-178.450,330,115,1500,'estimated','Ligne 330° — 200 nm'),
 ('MS-0604-VS5SEARCH',14,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',33.647,-178.450,33.313,-179.008,234,105,1500,'estimated','Ligne 330° — crochet vers 320° (34 nm)'),
 ('MS-0604-VS5SEARCH',15,'1942-06-04T13:44:00-12:00','1942-06-04T16:11:00-12:00',33.313,-179.008,30.371,-176.010,139,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',16,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,33.892,-177.829,340,115,1500,'estimated','Ligne 340° — 200 nm'),
 ('MS-0604-VS5SEARCH',17,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',33.892,-177.829,33.647,-178.450,245,105,1500,'estimated','Ligne 340° — crochet vers 330° (34 nm)'),
 ('MS-0604-VS5SEARCH',18,'1942-06-04T13:44:00-12:00','1942-06-04T16:11:00-12:00',33.647,-178.450,30.371,-176.010,148,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',19,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,34.043,-177.166,350,115,1500,'estimated','Ligne 350° — 200 nm'),
 ('MS-0604-VS5SEARCH',20,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',34.043,-177.166,33.892,-177.829,255,105,1500,'estimated','Ligne 350° — crochet vers 340° (34 nm)'),
 ('MS-0604-VS5SEARCH',21,'1942-06-04T13:44:00-12:00','1942-06-04T16:10:00-12:00',33.892,-177.829,30.372,-176.011,156,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',22,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,34.093,-176.480,0,115,1500,'estimated','Ligne 000° — 200 nm'),
 ('MS-0604-VS5SEARCH',23,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',34.093,-176.480,34.043,-177.166,265,105,1500,'estimated','Ligne 000° — crochet vers 350° (34 nm)'),
 ('MS-0604-VS5SEARCH',24,'1942-06-04T13:44:00-12:00','1942-06-04T16:08:00-12:00',34.043,-177.166,30.373,-176.014,165,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',25,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,34.043,-175.794,10,115,1500,'estimated','Ligne 010° — 200 nm'),
 ('MS-0604-VS5SEARCH',26,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',34.043,-175.794,34.093,-176.480,275,105,1500,'estimated','Ligne 010° — crochet vers 000° (34 nm)'),
 ('MS-0604-VS5SEARCH',27,'1942-06-04T13:44:00-12:00','1942-06-04T16:06:00-12:00',34.093,-176.480,30.375,-176.016,174,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)'),
 ('MS-0604-VS5SEARCH',28,'1942-06-04T11:40:00-12:00','1942-06-04T13:24:00-12:00',30.760,-176.480,33.892,-175.131,20,115,1500,'estimated','Ligne 020° — 200 nm'),
 ('MS-0604-VS5SEARCH',29,'1942-06-04T13:24:00-12:00','1942-06-04T13:44:00-12:00',33.892,-175.131,34.043,-175.794,285,105,1500,'estimated','Ligne 020° — crochet vers 010° (34 nm)'),
 ('MS-0604-VS5SEARCH',30,'1942-06-04T13:44:00-12:00','1942-06-04T16:03:00-12:00',34.043,-175.794,30.377,-176.020,183,95,1000,'estimated','retour vers TF-16 (Yorktown hors de combat)');

-- ------------------------------------------------------------
-- 4. Vol du Hornet (« flight to nowhere ») : cap 265°, pertes réelles
-- ------------------------------------------------------------
UPDATE missions SET notes='34 SBD + 10 F4F; cap 265° retenu contre 239° du rapport officiel (voir claims)'
 WHERE mission_id='MS-0604-CV8AM';
UPDATE mission_squadrons SET aircraft_lost=2,
  notes='13 SBD vers Midway faute d''essence: 2 amerris dans le lagon, 11 ravitaillés puis rentrés sur le Hornet à 15:27'
 WHERE mission_id='MS-0604-CV8AM' AND squadron_id='SQ-VB8';
UPDATE mission_squadrons SET notes='Les 10 F4F amerrissent à court d''essence; 8 pilotes récupérés'
 WHERE mission_id='MS-0604-CV8AM' AND squadron_id='SQ-VF8';
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-CV8AM',1,'1942-06-04T08:06:00-12:00','1942-06-04T09:40:00-12:00',31.140,-176.413,30.867,-180.055,265,120,6000,'estimated','Cap 265° (radar CXAM du Hornet, pilotes; NHHC H-Gram 006) et non 239° du rapport: passe au nord de la KB sans la voir'),
 ('MS-0604-CV8AM',2,'1942-06-04T09:40:00-12:00','1942-06-04T11:20:00-12:00',30.867,-180.055,30.564,-176.494,96,111,3000,'estimated','VS-8 fait demi-tour à 09:40; Ring, resté seul, suit; récupérés de justesse par le Hornet'),
 ('MS-0604-CV8AM',3,'1942-06-04T09:40:00-12:00','1942-06-04T11:30:00-12:00',30.867,-180.055,28.210,-177.370,139,116,3000,'estimated','VB-8 se déroute sur Midway faute d''essence; 2 SBD amerrissent dans le lagon');

-- ------------------------------------------------------------
-- 5. Yorktown et TF-17 le 4 juin : un seul et même point jusqu'à la fin du sauvetage.
--    Ancienne position du Yorktown (31.65N 176.85W) attribuée au rapport Yorktown,
--    qui ne donne aucune position pour les attaques : 71 nm au NNO de TF-16,
--    incompatible avec CTF-16 et DesRon 6 (12 milles au NO).
-- ------------------------------------------------------------
UPDATE positions SET lat=30.67, lon=-176.57, speed_kn=0, position_error_nm=15, source_id='SRC-DESRON6-AR',
  notes='Stoppé après les 3 bombes. Fix relatif: 12 milles au 315° de TF-16 (DesRon 6), « nearly out of sight to the northwestward » (CTF-16)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-04T12:11:00-12:00';
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,cause_event_id,notes) VALUES
 ('ships','SH-CV5','1942-06-04T14:02:00-12:00',30.67,-176.57,90,19,'estimated',15,'SRC-CINCPAC-01849','EV-0604-1402-YKREPART',
  'Repart cap 090 (CINCPAC); la position chiffrée du rapport (33-51 N) est écartée, voir claims');
UPDATE positions SET lat=30.67, lon=-176.42, speed_kn=0, position_error_nm=15,
  notes='2 torpilles à 14:45, sans énergie, gîte 23°; abandon à 15:00. ~7 nm à l''est du point d''attaque (cap 090 depuis 14:02)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-04T14:43:00-12:00';
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,cause_event_id,notes) VALUES
 ('formations','TF-17','1942-06-04T09:06:00-12:00',31.06,-176.15,223,10,'estimated',20,NULL,'EV-0604-0838-TF17LAUNCH',
  'Fin du lancement (cap 146 face au vent); route nette vers le point d''attaque de 12:11'),
 ('formations','TF-17','1942-06-04T12:11:00-12:00',30.67,-176.57,90,0,'estimated',15,'SRC-DESRON6-AR','EV-0604-1205-KOBAYASHI',
  'Écran en cercle autour du Yorktown stoppé (12 milles au 315° de TF-16)'),
 ('formations','TF-17','1942-06-04T14:02:00-12:00',30.67,-176.57,90,19,'estimated',15,'SRC-CINCPAC-01849','EV-0604-1402-YKREPART',
  'Le Yorktown repart cap 090 avec son écran renforcé par TF-16'),
 ('formations','TF-17','1942-06-04T14:43:00-12:00',30.67,-176.42,NULL,0,'estimated',15,NULL,'EV-0604-1430-TOMOATK',
  'Écran autour du Yorktown torpillé; recueil des survivants jusqu''à 17:18');
UPDATE positions SET ts='1942-06-04T17:18:00-12:00', lat=30.67, lon=-176.42, course_deg=40,
  cause_event_id='EV-0604-1718-YKRESCUE',
  notes='Fin du recueil des survivants (BuShips: 1918 zone +10); Fletcher sur l''Astoria. Remplace le point de 16:00 de la phase 13 (30.867N 176.0W), 25 nm à l''ENE alors que l''écran recueillait encore les naufragés'
 WHERE entity_id='TF-17' AND ts='1942-06-04T16:00:00-12:00';

-- Frappes du Hiryū : points d'attaque et départs du retour sur le Yorktown recalé
UPDATE mission_legs SET end_lat=30.67, end_lon=-176.57 WHERE mission_id='MS-0604-HIRYU1' AND seq=1;
UPDATE mission_legs SET start_lat=30.67, start_lon=-176.57 WHERE mission_id='MS-0604-HIRYU1' AND seq=2;
UPDATE mission_legs SET end_lat=30.67, end_lon=-176.47 WHERE mission_id='MS-0604-HIRYU2' AND seq=1;
UPDATE mission_legs SET start_lat=30.67, start_lon=-176.42 WHERE mission_id='MS-0604-HIRYU2' AND seq=2;
-- Frappe du Yorktown : départ au point de fin de lancement
UPDATE mission_legs SET start_lat=31.06, start_lon=-176.15 WHERE mission_id='MS-0604-CV5AM' AND seq=1;

-- ------------------------------------------------------------
-- 6. Naufrage du Yorktown : 05:01 à 30°36'N 176°34'W (CINCPAC, zone +12).
--    07:01 était l'heure du bord (zone +10) ; on renomme l'événement.
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,lat,lon,position_error_nm,phase,notes)
 SELECT 'EV-0607-0501-YKSINK','1942-06-07T05:01:00-12:00',time_uncertainty_min,event_type,side,
  'Le Yorktown chavire et coule à l''aube par 30°36''N 176°34''W',lat,lon,position_error_nm,phase,notes
 FROM events WHERE event_id='EV-0607-0701-YKSINK';
UPDATE positions SET ts='1942-06-07T05:01:00-12:00', lat=30.6, lon=-176.567, cause_event_id='EV-0607-0501-YKSINK',
  source_id='SRC-CINCPAC-01849',
  notes='CINCPAC: « at 0501, 7 June, in about 30-36 N, 176-34 W, Yorktown sank ». Le rapport du bord donne 0701 (zone +10) et 30°46''N 167°24''W (longitude impossible)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-07T07:01:00-12:00';
UPDATE claims SET entity_id='EV-0607-0501-YKSINK', value='1942-06-07T05:01:00-12:00', original_value='0501',
  status='verified', resolution_note='CINCPAC (zone +12) 0501 = BuShips et rapport du bord 0701 (zone +10)'
 WHERE entity_table='events' AND entity_id='EV-0607-0701-YKSINK';
DELETE FROM events WHERE event_id='EV-0607-0701-YKSINK';
UPDATE claims SET value='30.6,-176.567', original_value='about 30-36 N, 176-34 W', is_accepted=1, status='conflicting',
  resolution_note='Retenu: source A en zone +12, à 9 nm du point d''abandon reconstruit. La valeur antérieure (30.77) lisait 30-46, latitude du rapport du bord'
 WHERE entity_table='ships' AND entity_id='SH-CV5' AND field='sinking_position' AND source_id='SRC-CINCPAC-01849';
UPDATE claims SET is_accepted=0
 WHERE entity_table='positions' AND entity_id='SH-CV5' AND field='sinking_position' AND source_id='SRC-YORKTOWN-AR';
-- Le Hammann coule bord à bord avec le Yorktown (13:40 le 6) : même point que le Yorktown à 13:36
UPDATE positions SET lat=(SELECT lat FROM positions WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00'),
  lon=(SELECT lon FROM positions WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00'),
  notes='Coule le long du Yorktown (BuShips: « HAMMANN which was alongside »)'
 WHERE entity_id='SH-HAMMANN' AND ts='1942-06-06T13:40:00-12:00';

-- ------------------------------------------------------------
-- 7. Claims (valeur d'origine, source, arbitrage)
-- ------------------------------------------------------------
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('positions','SH-CV5','position_0604_1211','30.67,-176.57','Heavy smoke (oil fire) and A.A. bursts, bearing 315° (T), distance about 12 miles','SRC-DESRON6-AR','détachement de 1434 (zone +10)',1,'conflicting',
  'Fix relatif appliqué à TF-16 journalisée (phase 13) à 12:10. Corroboré par CTF-16 (« to the northwestward ») et par le naufrage CINCPAC à 9 nm'),
 ('positions','SH-CV5','position_0604_1211','au NO de TF-16, presque hors de vue','When the first attack was made on the Yorktown, she was nearly out of sight of us to the northwestward','SRC-CTF16-AR',NULL,0,'conflicting','Concorde qualitativement avec DesRon 6'),
 ('positions','SH-CV5','position_0604_1211','~150 milles NE de Midway','YORKTOWN was operating 150 miles northeast of Midway as a part of a task force','SRC-BUSHIPS-WDR','Section II §3',0,'conflicting','Compatible: le point retenu est à ~158 nm au 012° de Midway'),
 ('positions','SH-CV5','position_0604_1402','33.85,-176.0','Latitude 33-51 N, Longitude 176 W, course 090°','SRC-CINCPAC-01849','attaque du Yorktown',0,'conflicting',
  'Écarté (règle 2, cohérence physique): 340 nm au N de Midway, contredit BuShips (~150 milles), DesRon 6 et CTF-16. Probable coquille'),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:30:00-12:00','about 1330 (zone +10)','SRC-YORKTOWN-AR','section AIR',1,'conflicting',
  '11:30 retenu (rapport du bord et ONI concordent) contre 11:50 (CINCPAC). L''ancienne valeur 13:30 était l''heure du bord non convertie'),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:30:00-12:00','At 1130','SRC-ONI-CN-1943','attaque du Yorktown',0,'conflicting',NULL),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:50:00-12:00','at 1150','SRC-CINCPAC-01849',NULL,0,'conflicting',NULL),
 ('missions','MS-0604-VS5SEARCH','secteur','280-020 / 200 nm','search the area from bearing 280° T. to 020° for a distance of 200 miles','SRC-YORKTOWN-AR','section AIR',1,'conflicting','ONI concorde; CINCPAC écrit 280-030'),
 ('events','EV-0604-1430-ADAMS','ts','1942-06-04T14:30:00-12:00','at 1430','SRC-CINCPAC-01849',NULL,1,'verified','CINCPAC, ONI (1430) et rapport du bord (about 1630, zone +10) concordent'),
 ('events','EV-0604-1430-ADAMS','ts','1942-06-04T14:30:00-12:00','Three hours later (1430)','SRC-ONI-CN-1943','attaque du Yorktown',0,'verified',NULL),
 ('missions','MS-0604-CV8AM','course_out','239','The objective, enemy carriers, was calculated to be 155 miles distant, bearing 239° T.','SRC-HORNET-AR',NULL,0,'conflicting',
  'Cap de l''objectif calculé, pas la route volée; le rapport et sa carte sont tenus pour un camouflage (NHHC)'),
 ('missions','MS-0604-CV8AM','course_out','265','as far as the CXAM radar could track the air group, it had flown outbound on a course of 265 degrees','SRC-NHHC','H-Gram 006',1,'conflicting',
  'Retenu malgré le grade (règle 2): au 239°, le groupe aurait trouvé la KB comme VT-8, alors que toutes les sources A attestent l''absence de contact'),
 ('events','EV-0604-0940-CV8TURN','ts','1942-06-04T09:40:00-12:00','At 0940, the skipper of VS-8 unilaterally turned back toward Hornet','SRC-NHHC','H-Gram 006',1,'single_source',NULL),
 ('mission_squadrons','MS-0604-CV8AM/SQ-VB8','aircraft_lost','2','two of these ran out of gas and landed in the Lagoon at Midway','SRC-HORNET-AR',NULL,1,'verified',
  'CINCPAC (« All but 2 of the dive bombers ») et ONI (« 2 landed in the lagoon ») concordent; NHHC en compte 3 (grade C), non retenu'),
 ('mission_squadrons','MS-0604-CV8AM/SQ-VF8','pilots_rescued','8','All 10 of the fighters were forced down for lack of gas and lost at sea, though 8 of the pilots have been recovered','SRC-CINCPAC-01849',NULL,1,'verified',
  'ONI concorde (8 pilotes); le rapport du Hornet, plus précoce, en compte 5'),
 ('events','EV-0604-1402-YKREPART','ts','1942-06-04T14:02:00-12:00','At 1402 ... Yorktown was able to go ahead','SRC-CINCPAC-01849',NULL,1,'verified','BuShips: 20 nds disponibles à 1550 (zone +10) = 13:50'),
 ('events','EV-0604-1718-YKRESCUE','ts','1942-06-04T17:18:00-12:00','By 1918 all survivors were rescued (zone +10)','SRC-BUSHIPS-WDR','Section II §12',1,'single_source',NULL),
 ('events','EV-0607-0501-YKSINK','ts','1942-06-07T05:01:00-12:00','At 0701 YORKTOWN turned over on her port side and sank (zone +10)','SRC-BUSHIPS-WDR','Section II §16',0,'verified',NULL);


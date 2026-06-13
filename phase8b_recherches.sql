-- ============================================================
-- PHASE 8b : lignes de recherche (générées par generer_phase8_recherches.py)
-- ============================================================
INSERT INTO squadrons (squadron_id,name,side,ship_id,type_id,strength_0406,experience,notes) VALUES
 ('SQ-HARUNA-RECON','Hydravions du Haruna (E8N2)','IJN','SH-HARUNA','AC-E8N2',3,'average','Ligne de recherche courte (150 nm) du 4 juin');

INSERT INTO missions VALUES
 ('MS-0604-SEARCH-AKAGI','IJN',NULL,'search','Ligne akagi — relèvement 181°, 300 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T09:19:00-12:00','RAS','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-KAGA','IJN',NULL,'search','Ligne kaga — relèvement 158°, 300 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T09:19:00-12:00','RAS','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-TONE1','IJN',NULL,'search','Ligne tone1 — relèvement 123°, 300 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T10:07:00-12:00','RAS','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-TONE4','IJN',NULL,'search','Ligne tone4 — relèvement 100°, 300 nm + crochet','1942-06-04T05:00:00-12:00','1942-06-04T05:00:00-12:00',NULL,'1942-06-04T10:37:00-12:00','CONTACT: TF US trouvée 07:28','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-CHIKUMA1','IJN',NULL,'search','Ligne chikuma1 — relèvement 77°, 300 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T10:07:00-12:00','RAS','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-CHIKUMA5','IJN',NULL,'search','Ligne chikuma5 — relèvement 54°, 300 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T10:07:00-12:00','passée près de TF-17 sans la voir (nuages)','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1'),
 ('MS-0604-SEARCH-HARUNA','IJN',NULL,'search','Ligne haruna — relèvement 142°, 150 nm + crochet','1942-06-04T04:30:00-12:00','1942-06-04T04:30:00-12:00',NULL,'1942-06-04T08:15:00-12:00','RAS','Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1');

INSERT INTO mission_squadrons VALUES
 ('MS-0604-SEARCH-AKAGI','SQ-AKAGI-KANKO',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-KAGA','SQ-KAGA-KANKO',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-TONE1','SQ-TONE-RECON',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-TONE4','SQ-TONE-RECON',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-CHIKUMA1','SQ-CHIKUMA-RECON',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-CHIKUMA5','SQ-CHIKUMA-RECON',1,0,NULL,'1 appareil'),
 ('MS-0604-SEARCH-HARUNA','SQ-HARUNA-RECON',1,0,NULL,'1 appareil');

INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-SEARCH-AKAGI',1,'1942-06-04T04:30:00-12:00','1942-06-04T06:38:00-12:00',31.0,-179.6,26.0,-179.7,181,140,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-AKAGI',2,'1942-06-04T06:38:00-12:00','1942-06-04T07:04:00-12:00',26.0,-179.7,25.98,-178.59,91,140,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-AKAGI',3,'1942-06-04T07:04:00-12:00','1942-06-04T09:19:00-12:00',25.98,-178.59,30.70,-179.30,1,140,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-KAGA',1,'1942-06-04T04:30:00-12:00','1942-06-04T06:38:00-12:00',31.0,-179.6,26.36,-177.46,158,140,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-KAGA',2,'1942-06-04T06:38:00-12:00','1942-06-04T07:04:00-12:00',26.36,-177.46,26.73,-176.42,68,140,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-KAGA',3,'1942-06-04T07:04:00-12:00','1942-06-04T09:19:00-12:00',26.73,-176.42,30.70,-179.30,338,140,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-TONE1',1,'1942-06-04T04:30:00-12:00','1942-06-04T07:00:00-12:00',31.0,-179.6,28.28,-174.78,123,120,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-TONE1',2,'1942-06-04T07:00:00-12:00','1942-06-04T07:30:00-12:00',28.28,-174.78,29.12,-174.16,33,120,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-TONE1',3,'1942-06-04T07:30:00-12:00','1942-06-04T10:07:00-12:00',29.12,-174.16,30.70,-179.30,303,120,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-TONE4',1,'1942-06-04T05:00:00-12:00','1942-06-04T07:30:00-12:00',31.0,-179.6,30.13,-173.88,100,120,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-TONE4',2,'1942-06-04T07:30:00-12:00','1942-06-04T08:00:00-12:00',30.13,-173.88,31.11,-173.68,10,120,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-TONE4',3,'1942-06-04T08:00:00-12:00','1942-06-04T10:37:00-12:00',31.11,-173.68,30.70,-179.30,280,120,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-CHIKUMA1',1,'1942-06-04T04:30:00-12:00','1942-06-04T07:00:00-12:00',31.0,-179.6,32.12,-173.88,77,120,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-CHIKUMA1',2,'1942-06-04T07:00:00-12:00','1942-06-04T07:30:00-12:00',32.12,-173.88,33.09,-174.15,347,120,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-CHIKUMA1',3,'1942-06-04T07:30:00-12:00','1942-06-04T10:07:00-12:00',33.09,-174.15,30.70,-179.30,257,120,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-CHIKUMA5',1,'1942-06-04T04:30:00-12:00','1942-06-04T07:00:00-12:00',31.0,-179.6,33.94,-174.81,54,120,500,'estimated','aller 300 nm'),
 ('MS-0604-SEARCH-CHIKUMA5',2,'1942-06-04T07:00:00-12:00','1942-06-04T07:30:00-12:00',33.94,-174.81,34.75,-175.52,324,120,500,'estimated','crochet 60 nm à gauche'),
 ('MS-0604-SEARCH-CHIKUMA5',3,'1942-06-04T07:30:00-12:00','1942-06-04T10:07:00-12:00',34.75,-175.52,30.70,-179.30,234,120,500,'estimated','retour vers la force (position ~07:00-09:30)'),
 ('MS-0604-SEARCH-HARUNA',1,'1942-06-04T04:30:00-12:00','1942-06-04T06:10:00-12:00',31.0,-179.6,29.03,-177.82,142,90,500,'estimated','aller 150 nm'),
 ('MS-0604-SEARCH-HARUNA',2,'1942-06-04T06:10:00-12:00','1942-06-04T06:30:00-12:00',29.03,-177.82,29.34,-177.37,52,90,500,'estimated','crochet 30 nm à gauche'),
 ('MS-0604-SEARCH-HARUNA',3,'1942-06-04T06:30:00-12:00','1942-06-04T08:15:00-12:00',29.34,-177.37,30.70,-179.30,322,90,500,'estimated','retour vers la force (position ~07:00-09:30)');

INSERT INTO missions VALUES
 ('MS-0604-PBY-SEARCH','USN','SH-MIDWAY','search','Recherche en éventail OSO->NNE, ~700 nm','1942-06-04T04:15:00-12:00','1942-06-04T04:45:00-12:00',NULL,NULL,'05:34: Ady trouve la KB; 05:52: rapport 2 CV (Chase)','22 PBY; 8 lignes représentatives tracées (grade C)');
INSERT INTO mission_squadrons VALUES ('MS-0604-PBY-SEARCH','SQ-PBY-MIDWAY',22,0,NULL,'8 lignes représentatives sur ~16 secteurs réels');

INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-PBY-SEARCH',1,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,19.27,-185.56,220,100,300,'estimated','ligne 220° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',2,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,23.28,-189.11,245,100,300,'estimated','ligne 245° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',3,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,28.21,-190.61,270,100,300,'estimated','ligne 270° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',4,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,33.14,-189.66,295,100,300,'estimated','ligne 295° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',5,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,36.46,-187.13,315,100,300,'estimated','ligne 315° — aller 700 nm — secteur du contact d''Ady (05:34)'),
 ('MS-0604-PBY-SEARCH',6,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,38.31,-184.35,330,100,300,'estimated','ligne 330° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',7,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,39.48,-181.01,345,100,300,'estimated','ligne 345° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',8,'1942-06-04T04:15:00-12:00','1942-06-04T09:30:00-12:00',28.21,-177.37,39.7,-174.93,10,100,300,'estimated','ligne 10° — aller 700 nm'),
 ('MS-0604-PBY-SEARCH',9,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',19.27,-185.56,28.21,-177.37,40,100,300,'estimated','ligne 220° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',10,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',23.28,-189.11,28.21,-177.37,65,100,300,'estimated','ligne 245° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',11,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',28.21,-190.61,28.21,-177.37,90,100,300,'estimated','ligne 270° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',12,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',33.14,-189.66,28.21,-177.37,115,100,300,'estimated','ligne 295° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',13,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',36.46,-187.13,28.21,-177.37,135,100,300,'estimated','ligne 315° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',14,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',38.31,-184.35,28.21,-177.37,150,100,300,'estimated','ligne 330° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',15,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',39.48,-181.01,28.21,-177.37,165,100,300,'estimated','ligne 345° — retour vers Midway (réalité variable: déroutements, suivis de contact)'),
 ('MS-0604-PBY-SEARCH',16,'1942-06-04T09:30:00-12:00','1942-06-04T18:30:00-12:00',39.7,-174.93,28.21,-177.37,190,100,300,'estimated','ligne 10° — retour vers Midway (réalité variable: déroutements, suivis de contact)');
UPDATE missions SET recovery_ts='1942-06-04T18:30:00-12:00' WHERE mission_id='MS-0604-PBY-SEARCH';

INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('missions','MS-0604-SEARCH-TONE4','bearing','100','SRC-SHATTERED-SWORD',1,'single_source','Relèvement de la ligne n°4 du Tone; à confirmer sur le schéma du rapport Nagumo (OPNAV P32-1002)'),
 ('missions','MS-0604-SEARCH-CHIKUMA5','bearing','54','SRC-SHATTERED-SWORD',1,'single_source','Ligne passée près de TF-17 sous plafond nuageux sans contact'),
 ('missions','MS-0604-PBY-SEARCH','plan','22 PBY, secteur OSO-NNE, 700 nm','SRC-CINCPAC-01849',1,'single_source','Schéma précis des 16 secteurs à reprendre du rapport CINCPAC');

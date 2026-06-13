-- ============================================================
-- PHASE 4 : positions, pistes et missions aériennes
-- AVERTISSEMENT : hors positions de naufrage (TROM/CINCPAC) et
-- positions rapportées textuellement, les pistes ci-dessous sont
-- des VALEURS GROSSIÈRES (method='estimated', erreur 20-50 nm)
-- destinées à tester le pipeline carte. Le géoréférencement des
-- cartes de Shattered Sword / CINCPAC les remplacera.
-- ============================================================

-- ------------------------------------------------------------
-- POINTS FIXES ET ANCRES (naufrages = meilleures ancres publiées)
-- ------------------------------------------------------------
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,notes) VALUES
 ('ships','SH-MIDWAY','1942-06-03T00:00:00-12:00',28.21,-177.37,NULL,0,'verified',0,NULL,'Atoll fixe (Sand + Eastern Island)'),
 -- Naufrages (positions historiques publiées; les surveys 2019/2023 affineront)
 ('ships','SH-KAGA','1942-06-04T19:25:00-12:00',30.38,-179.28,NULL,0,'estimated',10,'SRC-COMBINEDFLEET','Position TROM (30°23''N 179°17''W); épave localisée 2019 (Petrel)'),
 ('ships','SH-SORYU','1942-06-04T19:13:00-12:00',30.63,-179.22,NULL,0,'estimated',10,'SRC-COMBINEDFLEET','TROM 30°38''N 179°13''W'),
 ('ships','SH-AKAGI','1942-06-05T05:20:00-12:00',30.50,-178.67,NULL,0,'estimated',10,'SRC-COMBINEDFLEET','TROM ~30°30''N 178°40''W; épave 2019'),
 ('ships','SH-HIRYU','1942-06-05T09:12:00-12:00',31.45,-179.38,NULL,0,'estimated',10,'SRC-COMBINEDFLEET','TROM ~31°27''N 179°23''W'),
 ('ships','SH-CV5','1942-06-07T07:01:00-12:00',30.77,-176.57,NULL,0,'estimated',5,'SRC-CINCPAC-01849','~30°46''N 176°34''W; épave localisée 1998 (Ballard)'),
 ('ships','SH-HAMMANN','1942-06-06T13:40:00-12:00',30.77,-176.57,NULL,0,'estimated',5,'SRC-CINCPAC-01849','Coule le long du Yorktown'),
 ('ships','SH-MIKUMA','1942-06-06T19:30:00-12:00',29.47,173.18,NULL,0,'estimated',15,'SRC-COMBINEDFLEET','TROM ~29°28''N 173°11''E — NB: longitude EST (au-delà de la ligne de changement de date)');

-- ------------------------------------------------------------
-- PISTE KIDŌ BUTAI — 4 juin (grossière, à géoréférencer)
-- ------------------------------------------------------------
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,notes) VALUES
 ('formations','KIDO-BUTAI','1942-06-04T04:30:00-12:00',31.40,-179.80,135,24,'estimated',25,'SRC-SHATTERED-SWORD','Point de lancement frappe Tomonaga (~240 nm NO de Midway)'),
 ('formations','KIDO-BUTAI','1942-06-04T07:00:00-12:00',30.95,-179.25,135,20,'estimated',25,NULL,'Descente SE vers Midway; vitesse moyenne réduite par les manœuvres AA'),
 ('formations','KIDO-BUTAI','1942-06-04T09:17:00-12:00',30.60,-179.00,70,28,'estimated',25,NULL,'Virage au 070 vers les PA US'),
 ('formations','KIDO-BUTAI','1942-06-04T10:22:00-12:00',30.55,-179.15,NULL,25,'estimated',20,NULL,'Position au moment des impacts (manœuvres évasives VT depuis 09:20)'),
 ('ships','SH-HIRYU','1942-06-04T10:54:00-12:00',30.70,-179.00,30,30,'estimated',25,NULL,'Le Hiryū file N-NE avec l''escorte après 10:26'),
 ('ships','SH-HIRYU','1942-06-04T14:30:00-12:00',31.00,-178.80,350,28,'estimated',25,NULL,NULL),
 ('ships','SH-HIRYU','1942-06-04T17:01:00-12:00',31.25,-179.05,310,30,'estimated',20,NULL,'Position aux impacts de 17:01');

-- ------------------------------------------------------------
-- PISTES TF-16 / TF-17 — 4 juin (grossières)
-- ------------------------------------------------------------
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,notes) VALUES
 -- Phase de ralliement/approche 2-3 juin (synthèse journaux de bord; heures converties Zone+10 -> Zone+12)
 ('formations','TF-16','1942-06-02T15:30:00-12:00',32.07,-172.75,283,15,'estimated',25,'SRC-ENTERPRISE-AR','Point Luck (32N 173W, 045/325 de Midway): jonction TF-16/17'),
 ('formations','TF-16','1942-06-02T18:00:00-12:00',32.22,-173.53,281,11,'estimated',25,'SRC-ENTERPRISE-AR','Approche ouest (journal Hornet)'),
 ('formations','TF-16','1942-06-03T06:00:00-12:00',32.60,-175.88,352,11,'estimated',25,'SRC-ENTERPRISE-AR','Route O-NO (journal Hornet)'),
 ('formations','TF-16','1942-06-03T10:00:00-12:00',33.12,-175.97,48,11,'estimated',25,'SRC-ENTERPRISE-AR','Station d''attente zone Point Luck (journal Hornet)'),
 ('formations','TF-16','1942-06-03T18:00:00-12:00',33.27,-175.77,206,13,'estimated',25,'SRC-ENTERPRISE-AR','Position nocturne, avant virage au 210 pour le lancement de l''aube (journal Enterprise)'),
 ('formations','TF-17','1942-06-02T15:30:00-12:00',32.24,-172.75,283,15,'estimated',25,'SRC-YORKTOWN-AR','Point Luck: le Yorktown aperçoit la TF-16 à 10 nm au sud'),
 ('formations','TF-17','1942-06-02T18:00:00-12:00',32.39,-173.53,281,11,'estimated',25,'SRC-YORKTOWN-AR','~10 nm N de la TF-16'),
 ('formations','TF-17','1942-06-03T06:00:00-12:00',32.77,-175.88,352,11,'estimated',25,'SRC-YORKTOWN-AR','~10 nm N de la TF-16'),
 ('formations','TF-17','1942-06-03T10:00:00-12:00',33.28,-175.97,46,11,'estimated',25,'SRC-YORKTOWN-AR','~10 nm N de la TF-16'),
 ('formations','TF-17','1942-06-03T18:00:00-12:00',33.44,-175.77,202,13,'estimated',25,'SRC-YORKTOWN-AR','Position nocturne (~10 nm N TF-16), avant le lancement de l''aube'),
 ('formations','TF-16','1942-06-04T06:00:00-12:00',31.55,-176.75,240,25,'estimated',20,'SRC-ENTERPRISE-AR','"Point Luck" puis route SO d''interception'),
 ('formations','TF-16','1942-06-04T07:06:00-12:00',31.45,-176.95,240,25,'estimated',20,NULL,'Point de lancement (~155 nm de la position estimée de la KB)'),
 ('formations','TF-16','1942-06-04T10:30:00-12:00',31.05,-177.70,240,25,'estimated',25,NULL,'Fermeture pendant la matinée'),
 ('formations','TF-16','1942-06-04T15:30:00-12:00',31.30,-177.30,300,20,'estimated',25,NULL,'Lancement de la frappe anti-Hiryū (~90-110 nm de la cible); TF-16 a dérivé E pendant les récupérations'),
 ('formations','TF-16','1942-06-04T19:07:00-12:00',31.10,-177.00,90,15,'estimated',25,NULL,'Route est pour la nuit (décision Spruance)'),
 ('formations','TF-17','1942-06-04T08:38:00-12:00',31.70,-176.60,225,25,'estimated',20,'SRC-YORKTOWN-AR','Lancement du groupe Yorktown'),
 ('ships','SH-CV5','1942-06-04T12:11:00-12:00',31.65,-176.85,NULL,0,'estimated',20,'SRC-YORKTOWN-AR','Stoppé après les 3 bombes'),
 ('ships','SH-CV5','1942-06-04T14:43:00-12:00',31.60,-176.90,NULL,5,'estimated',20,NULL,'2 torpilles; gîte 23°, abandon à 15:00'),
 -- CruDiv 7 (nuit 4-5: collision)
 ('formations','CRUDIV7','1942-06-05T02:23:00-12:00',28.20,-179.90,280,16,'estimated',50,NULL,'Zone de collision Mogami/Mikuma (retraite O après annulation du bombardement) — TRÈS grossier');

-- Positions rapportées (monde perçu) — mise à jour des contact_reports
UPDATE contact_reports SET reported_lat=30.50, reported_lon=-179.55,
  position_error_actual_nm=35,
  notes='Position calculée depuis "bearing 320 distance 180" — erreur réelle ~30-40 nm (la KB était plus au N-O)'
 WHERE report_id='CR-0604-0552-PBY';
UPDATE contact_reports SET reported_lat=32.10, reported_lon=-176.50,
  notes='Position calculée depuis "relèvement 010, 240 nm de Midway". Escadrille SQ-TONE-RECON désormais référencée.'
 WHERE report_id='CR-TONE4-0728';

-- ------------------------------------------------------------
-- MISSIONS AÉRIENNES — composition et résultats
-- ------------------------------------------------------------
INSERT INTO missions VALUES
 ('MS-0603-B17','USAAF','SH-MIDWAY','strike','Groupe de transport (rapporté "Main Body")','1942-06-03T12:30:00-12:00','1942-06-03T12:45:00-12:00','1942-06-03T16:24:00-12:00','1942-06-03T18:50:00-12:00','Aucun coup au but','9 B-17'),
 ('MS-0604-PBYNIGHT','USN','SH-MIDWAY','strike','Groupe de transport (attaque de nuit à la torpille)','1942-06-04T21:15:00-12:00',NULL,'1942-06-04T01:43:00-12:00',NULL,'1 torpille: Akebono Maru','4 PBY-5A radar; décollage 3 juin 21:15 — heures à vérifier'),
 ('MS-0604-TOMONAGA','IJN',NULL,'strike','Installations de Midway','1942-06-04T04:30:00-12:00','1942-06-04T04:45:00-12:00','1942-06-04T06:30:00-12:00','1942-06-04T09:10:00-12:00','Dégâts importants; pistes utilisables; "2e frappe nécessaire"','108 appareils des 4 CV; origin_ship NULL = multi-porte-avions'),
 ('MS-0604-SEARCH-IJN','IJN',NULL,'search','Recherche secteurs E-S (7 lignes)','1942-06-04T04:30:00-12:00','1942-06-04T05:00:00-12:00',NULL,NULL,'Tone n°4 trouve TF-16/17 à 07:28','Plan monophasé léger (D0)'),
 ('MS-0604-VT8DET','USN','SH-MIDWAY','strike','Kidō Butai','1942-06-04T06:00:00-12:00',NULL,'1942-06-04T07:10:00-12:00',NULL,'Aucun coup; 5/6 perdus','Premier engagement du TBF'),
 ('MS-0604-B26','USAAF','SH-MIDWAY','strike','Kidō Butai (torpilles)','1942-06-04T06:00:00-12:00',NULL,'1942-06-04T07:10:00-12:00',NULL,'Aucun coup; 2/4 perdus','Un B-26 frôle la passerelle de l''Akagi'),
 ('MS-0604-VMSB-SBD','USMC','SH-MIDWAY','strike','Kidō Butai','1942-06-04T06:10:00-12:00',NULL,'1942-06-04T07:55:00-12:00',NULL,'Aucun coup; 8/16 perdus (Henderson tué)','Glide-bombing (équipages non qualifiés piqué)'),
 ('MS-0604-B17AM','USAAF','SH-MIDWAY','strike','Kidō Butai','1942-06-04T04:15:00-12:00',NULL,'1942-06-04T08:10:00-12:00',NULL,'Aucun coup','Déroutés de la mission transports vers la KB'),
 ('MS-0604-SB2U','USMC','SH-MIDWAY','strike','Haruna','1942-06-04T06:15:00-12:00',NULL,'1942-06-04T08:20:00-12:00',NULL,'Aucun coup','SB2U trop lents pour atteindre les CV'),
 ('MS-0604-CV6AM','USN','SH-CV6','strike','Kidō Butai','1942-06-04T07:06:00-12:00','1942-06-04T08:06:00-12:00','1942-06-04T10:22:00-12:00','1942-06-04T12:05:00-12:00','Kaga 4-5 bombes, Akagi 1+1 — fatals','33 SBD (VB-6+VS-6+CEAG); VT-6 et VF-6 séparés en route'),
 ('MS-0604-VT6','USN','SH-CV6','strike','Kidō Butai','1942-06-04T07:06:00-12:00',NULL,'1942-06-04T09:38:00-12:00',NULL,'Aucun coup; 10/14 perdus','Attaque en tenaille non aboutie'),
 ('MS-0604-CV8AM','USN','SH-HORNET','strike','Kidō Butai','1942-06-04T07:06:00-12:00','1942-06-04T08:06:00-12:00',NULL,'1942-06-04T11:20:00-12:00','"Flight to nowhere": aucun contact (sauf VT-8)','34 SBD + 10 F4F; cap controversé (DC-USN-U4)'),
 ('MS-0604-VT8','USN','SH-HORNET','strike','Kidō Butai','1942-06-04T07:06:00-12:00',NULL,'1942-06-04T09:20:00-12:00',NULL,'Aucun coup; 15/15 perdus (1 survivant)','Waldron quitte le groupe (~08:25) et va droit sur la KB'),
 ('MS-0604-CV5AM','USN','SH-CV5','strike','Kidō Butai','1942-06-04T08:38:00-12:00','1942-06-04T09:06:00-12:00','1942-06-04T10:25:00-12:00','1942-06-04T12:00:00-12:00','Sōryū: 3 coups (VB-3); VT-3 décimé','Lancement tardif mais navigation directe: arrivée simultanée avec McClusky (hasard)'),
 ('MS-0604-HIRYU1','IJN','SH-HIRYU','strike','Porte-avions US (Yorktown)','1942-06-04T10:54:00-12:00','1942-06-04T10:58:00-12:00','1942-06-04T12:05:00-12:00','1942-06-04T13:30:00-12:00','3 bombes sur le Yorktown; 13/18 D3A + 3/6 A6M perdus','Suit les avions US au retour'),
 ('MS-0604-HIRYU2','IJN','SH-HIRYU','strike','"2e porte-avions" (en fait le Yorktown réparé)','1942-06-04T13:31:00-12:00','1942-06-04T13:35:00-12:00','1942-06-04T14:30:00-12:00','1942-06-04T15:40:00-12:00','2 torpilles sur le Yorktown; 5/10 B5N (dont Tomonaga) + 2/6 A6M perdus',NULL),
 ('MS-0604-VS5SEARCH','USN','SH-CV5','search','Localiser le 4e CV (Hiryū)','1942-06-04T13:30:00-12:00',NULL,NULL,NULL,'14:45: Adams localise le Hiryū','10 SBD en éventail 200 nm (la réserve de Fletcher paie)'),
 ('MS-0604-E6PM','USN','SH-CV6','strike','Hiryū','1942-06-04T15:30:00-12:00','1942-06-04T15:45:00-12:00','1942-06-04T17:01:00-12:00','1942-06-04T18:30:00-12:00','4 coups: Hiryū condamné','24 SBD dont 10 ex-VB-3 (Yorktown)'),
 ('MS-0606-STRIKE1','USN','SH-HORNET','strike','Mogami/Mikuma','1942-06-06T08:00:00-12:00',NULL,'1942-06-06T09:50:00-12:00',NULL,'Coups sur les 2 croiseurs',NULL),
 ('MS-0606-STRIKE2','USN','SH-CV6','strike','Mogami/Mikuma','1942-06-06T10:45:00-12:00',NULL,'1942-06-06T12:00:00-12:00',NULL,'Mikuma dévasté',NULL),
 ('MS-0606-STRIKE3','USN','SH-HORNET','strike','Mogami/Mikuma','1942-06-06T13:30:00-12:00',NULL,'1942-06-06T14:45:00-12:00',NULL,'Mikuma coule dans la soirée; Mogami s''échappe',NULL);

-- Composition des missions principales
INSERT INTO mission_squadrons VALUES
 -- Frappe Tomonaga: 36 B5N niveau (Hiryū+Sōryū), 36 D3A (Akagi+Kaga), 36 A6M (9/CV)
 ('MS-0604-TOMONAGA','SQ-HIRYU-KANKO',18,1,'ORD-800KG','Bombardement horizontal (config bombe terrestre); pertes totales du raid ~11 + nombreux endommagés — répartition par escadrille à préciser'),
 ('MS-0604-TOMONAGA','SQ-SORYU-KANKO',18,1,'ORD-800KG',NULL),
 ('MS-0604-TOMONAGA','SQ-AKAGI-KANBAKU',18,1,'ORD-250KG',NULL),
 ('MS-0604-TOMONAGA','SQ-KAGA-KANBAKU',18,4,'ORD-250KG',NULL),
 ('MS-0604-TOMONAGA','SQ-AKAGI-KANSEN',9,0,NULL,NULL),
 ('MS-0604-TOMONAGA','SQ-KAGA-KANSEN',9,2,NULL,NULL),
 ('MS-0604-TOMONAGA','SQ-SORYU-KANSEN',9,0,NULL,NULL),
 ('MS-0604-TOMONAGA','SQ-HIRYU-KANSEN',9,1,NULL,NULL),
 ('MS-0604-VT8DET','SQ-VT8-DET',6,5,'ORD-MK13',NULL),
 ('MS-0604-B26','SQ-B26-DET',4,2,'ORD-MK13',NULL),
 ('MS-0604-VMSB-SBD','SQ-VMSB241-SBD',16,8,'ORD-500LB',NULL),
 ('MS-0604-B17AM','SQ-B17-MIDWAY',15,0,'ORD-500LB','14-16 selon sources'),
 ('MS-0604-SB2U','SQ-VMSB241-SB2U',11,3,'ORD-500LB',NULL),
 ('MS-0604-CV6AM','SQ-VB6',15,9,'ORD-1000LB','Pertes incluant pannes sèches au retour'),
 ('MS-0604-CV6AM','SQ-VS6',16,9,'ORD-500LB','+2 SBD section CEAG (McClusky)'),
 ('MS-0604-VT6','SQ-VT6',14,10,'ORD-MK13',NULL),
 ('MS-0604-CV8AM','SQ-VB8',19,0,'ORD-1000LB','Aucun contact; certains se déroutent sur Midway'),
 ('MS-0604-CV8AM','SQ-VS8',15,0,'ORD-500LB',NULL),
 ('MS-0604-CV8AM','SQ-VF8',10,10,NULL,'Toutes pertes = amerrissages panne sèche'),
 ('MS-0604-VT8','SQ-VT8',15,15,'ORD-MK13','1 survivant (Ens. Gay)'),
 ('MS-0604-CV5AM','SQ-VB3',17,0,'ORD-1000LB','4 bombes larguées prématurément (défaut armement électrique)'),
 ('MS-0604-CV5AM','SQ-VT3',12,10,'ORD-MK13',NULL),
 ('MS-0604-CV5AM','SQ-VF3',6,1,NULL,'Thach Weave'),
 ('MS-0604-HIRYU1','SQ-HIRYU-KANBAKU',18,13,'ORD-250KG','Kobayashi tué'),
 ('MS-0604-HIRYU1','SQ-HIRYU-KANSEN',6,3,NULL,NULL),
 ('MS-0604-HIRYU2','SQ-HIRYU-KANKO',10,5,'ORD-TYPE91','Tomonaga tué'),
 ('MS-0604-HIRYU2','SQ-HIRYU-KANSEN',6,2,NULL,NULL),
 ('MS-0604-VS5SEARCH','SQ-VS5',10,0,NULL,NULL),
 ('MS-0604-E6PM','SQ-VB6',7,1,'ORD-1000LB','Composition mixte VB-6/VS-6/VB-3: répartition à préciser'),
 ('MS-0604-E6PM','SQ-VS6',7,1,'ORD-500LB',NULL),
 ('MS-0604-E6PM','SQ-VB3',10,1,'ORD-1000LB','Ex-Yorktown, récupérés par l''Enterprise');

-- Segments de trajet des missions clés (grossiers — pour le pipeline carte)
INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 ('MS-0604-TOMONAGA',1,'1942-06-04T04:45:00-12:00','1942-06-04T06:16:00-12:00',31.40,-179.80,28.21,-177.37,142,125,3500,'estimated','Aller (~210 nm); intercepté par VMF-221 à ~30 nm de Midway'),
 ('MS-0604-TOMONAGA',2,'1942-06-04T06:30:00-12:00','1942-06-04T06:43:00-12:00',28.21,-177.37,28.21,-177.37,NULL,NULL,3000,'observed','Attaque de Midway'),
 ('MS-0604-TOMONAGA',3,'1942-06-04T07:00:00-12:00','1942-06-04T08:37:00-12:00',28.21,-177.37,30.75,-179.10,322,120,2000,'estimated','Retour vers la KB (qui a fait route SE entre-temps)'),
 ('MS-0604-CV6AM',1,'1942-06-04T08:06:00-12:00','1942-06-04T09:20:00-12:00',31.45,-176.95,30.40,-179.30,240,130,5800,'estimated','Cap d''interception sur position PBY corrigée — océan vide à l''arrivée'),
 ('MS-0604-CV6AM',2,'1942-06-04T09:20:00-12:00','1942-06-04T09:55:00-12:00',30.40,-179.30,30.10,-179.80,240,130,5800,'estimated','Recherche en crochet (déplacement net << distance volée ~75 nm: ne pas valider ce segment sur la vitesse-déplacement)'),
 ('MS-0604-CV6AM',3,'1942-06-04T09:55:00-12:00','1942-06-04T10:22:00-12:00',30.10,-179.80,30.55,-179.15,35,135,5800,'estimated','Remontée NE sur le sillage de l''Arashi jusqu''à la KB'),
 ('MS-0604-CV6AM',4,'1942-06-04T10:22:00-12:00','1942-06-04T10:32:00-12:00',30.55,-179.15,30.53,-179.12,200,12,4000,'estimated','Sur cible (loiter d''attaque): Kaga touché 10:22, section Best en piqué sur Akagi 10:26'),
 ('MS-0604-VT8',1,'1942-06-04T08:25:00-12:00','1942-06-04T09:20:00-12:00',31.10,-177.80,30.55,-179.10,245,100,500,'estimated','Waldron quitte le groupe Ring et va droit sur la KB'),
 ('MS-0604-CV5AM',1,'1942-06-04T09:06:00-12:00','1942-06-04T10:15:00-12:00',31.70,-176.60,30.58,-179.05,240,120,4500,'estimated','Navigation directe — arrivée quasi simultanée avec McClusky'),
 ('MS-0604-CV5AM',2,'1942-06-04T10:15:00-12:00','1942-06-04T10:40:00-12:00',30.58,-179.05,30.56,-179.13,210,12,3000,'estimated','Sur cible (loiter d''attaque): VT-3 aux torpilles à l''arrivée (10:15) puis VB-3 en piqué sur Sōryū (10:25)'),
 ('MS-0604-HIRYU1',1,'1942-06-04T10:58:00-12:00','1942-06-04T12:05:00-12:00',30.70,-179.00,31.65,-176.85,65,140,4000,'estimated','Suit les SBD US au retour vers TF-17'),
 ('MS-0604-HIRYU2',1,'1942-06-04T13:35:00-12:00','1942-06-04T14:30:00-12:00',31.00,-178.80,31.60,-176.90,70,140,2500,'estimated',NULL),
 ('MS-0604-E6PM',1,'1942-06-04T15:45:00-12:00','1942-06-04T17:01:00-12:00',31.30,-177.30,31.25,-179.05,275,130,4500,'estimated','~90 nm + montée et mise en place de l''attaque');

-- Claims sur les positions d'ancrage
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('ships','SH-KAGA','sinking_position','30.38,-179.28','SRC-COMBINEDFLEET',1,'single_source','Position 2019 (Petrel) non publiée précisément: garder TROM'),
 ('ships','SH-CV5','sinking_position','30.77,-176.57','SRC-CINCPAC-01849',1,'single_source','Épave relocalisée 1998 puis 2023 — coordonnées exactes à rechercher'),
 ('ships','SH-MIKUMA','sinking_position','29.47,173.18','SRC-COMBINEDFLEET',1,'single_source','Longitude EST: bien gérer le franchissement de l''antiméridien dans le code carte');

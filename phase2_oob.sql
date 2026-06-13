-- ============================================================
-- PHASE 1-2 : bibliothèque de sources + ordre de bataille complet
-- Valeurs de travail. Statut des claims = état réel de vérification.
-- ============================================================

-- ------------------------------------------------------------
-- SOURCES (complément)
-- ------------------------------------------------------------
INSERT INTO sources VALUES
 ('SRC-CRESSMAN','scholarly','Cressman R. et al.','A Glorious Page in Our History: The Battle of Midway',1990,'B','GMT-12',NULL,'Très détaillé côté US'),
 ('SRC-SYMONDS','scholarly','Symonds C.','The Battle of Midway',2011,'B','GMT-12',NULL,'Synthèse moderne'),
 ('SRC-SENSHI-SOSHO','scholarly','Bōeichō Bōei Kenshūjo','Senshi Sōsho vol. 43 (Middowē kaisen)',1971,'B','GMT+9',NULL,'Histoire officielle japonaise; non traduite intégralement'),
 ('SRC-MORISON','secondary','Morison S.E.','History of US Naval Operations in WWII, vol. IV',1949,'C','GMT-12',NULL,'Classique; certaines heures/positions corrigées depuis'),
 ('SRC-PRANGE','secondary','Prange G.','Miracle at Midway',1982,'C','GMT-12',NULL,NULL),
 ('SRC-LORD','secondary','Lord W.','Incredible Victory',1967,'C','GMT-12',NULL,'Riche en témoignages; à recouper'),
 ('SRC-NHHC','online_db','Naval History & Heritage Command','history.navy.mil (action reports numérisés, H-grams)',NULL,'C',NULL,'https://www.history.navy.mil','Donne accès aux sources A'),
 ('SRC-CV6ORG','online_db','—','cv6.org (USS Enterprise, logs et rapports transcrits)',NULL,'C','GMT-12','http://www.cv6.org','Transcriptions de rapports d''action (sources A)'),
 ('SRC-ROUNDTABLE','online_db','Battle of Midway Roundtable','midway42.org',NULL,'C',NULL,'https://www.midway42.org','Témoignages vétérans + analyses'),
 ('SRC-ENTERPRISE-AR','primary_official','USS Enterprise','CV-6 Action Report, Battle of Midway, 8 June 1942',1942,'A','GMT-12','https://www.ibiblio.org/hyperwar/USN/ships/logs/CV/cv6-Midway.html',NULL),
 ('SRC-HORNET-AR','primary_official','USS Hornet','CV-8 Action Report, 13 June 1942',1942,'A','GMT-12','https://ibiblio.org/hyperwar/USN/ships/logs/CV/cv8-Midway.html','Cap du groupe aérien controversé: rapport incomplet/contesté'),
 ('SRC-YORKTOWN-AR','primary_official','USS Yorktown','CV-5 Action Report, 18 June 1942',1942,'A','GMT-12','https://www.ibiblio.org/hyperwar/USN/ships/logs/CV/cv5-Midway.html',NULL),
 ('SRC-PETREL-2019','wreck_survey','R/V Petrel (Vulcan Inc.)','Localisation des épaves Kaga et Akagi',2019,'A',NULL,NULL,'Vérité terrain pour l''ancrage des trajectoires finales'),
 ('SRC-NOAA-2023','wreck_survey','NOAA Ocean Exploration / E/V Nautilus','Survey épaves Midway (Akagi, Kaga, Yorktown)',2023,'A',NULL,NULL,NULL),
 ('SRC-WIKI','online_db','Wikipédia (en)','Battle of Midway',NULL,'D',NULL,'https://en.wikipedia.org/wiki/Battle_of_Midway','Index utile, jamais source finale');

-- ------------------------------------------------------------
-- PERSONNES
-- ------------------------------------------------------------
INSERT INTO persons VALUES
 -- IJN
 ('PR-YAMAMOTO','Yamamoto Isoroku','Amiral','IJN','CinC Flotte Combinée (Corps principal)',NULL),
 ('PR-KUSAKA','Kusaka Ryūnosuke','Contre-amiral','IJN','Chef d''état-major 1er Kōkū Kantai',NULL),
 ('PR-GENDA','Genda Minoru','Capitaine de frégate','IJN','Officier opérations aériennes Kidō Butai',NULL),
 ('PR-KONDO','Kondō Nobutake','Vice-amiral','IJN','Commandant force d''invasion (2e Flotte)',NULL),
 ('PR-KURITA','Kurita Takeo','Contre-amiral','IJN','Commandant CruDiv 7 (Mogami, Mikuma, Suzuya, Kumano)',NULL),
 ('PR-TANAKA','Tanaka Raizō','Contre-amiral','IJN','Commandant groupe de transport',NULL),
 ('PR-ABE','Abe Hiroaki','Contre-amiral','IJN','Commandant CruDiv 8 (Tone, Chikuma); prend le cdt de la KB après l''Akagi',NULL),
 ('PR-AOKI','Aoki Taijirō','Capitaine de vaisseau','IJN','Commandant Akagi',NULL),
 ('PR-OKADA','Okada Jisaku','Capitaine de vaisseau','IJN','Commandant Kaga (tué le 04/06)',NULL),
 ('PR-YANAGIMOTO','Yanagimoto Ryūsaku','Capitaine de vaisseau','IJN','Commandant Sōryū (resté à bord)',NULL),
 ('PR-KAKU','Kaku Tomeo','Capitaine de vaisseau','IJN','Commandant Hiryū (resté à bord)',NULL),
 ('PR-KOBAYASHI','Kobayashi Michio','Lieutenant','IJN','Chef 1re frappe du Hiryū (D3A) — tué',NULL),
 ('PR-HASHIMOTO','Hashimoto Toshio','Lieutenant','IJN','2e frappe du Hiryū (B5N), rapporte la perte de Tomonaga',NULL),
 ('PR-ITAYA','Itaya Shigeru','Capitaine de corvette','IJN','Chef kansen Akagi',NULL),
 ('PR-TANABE','Tanabe Yahachi','Capitaine de corvette','IJN','Commandant I-168 (coule Yorktown et Hammann)',NULL),
 ('PR-AMARI','Amari Yōji','Premier maître','IJN','Pilote hydravion n°4 du Tone',NULL),
 -- USN / USMC / USAAF
 ('PR-NIMITZ','Nimitz Chester W.','Amiral','USN','CINCPAC',NULL),
 ('PR-BROWNING','Browning Miles','Capitaine de vaisseau','USN','Chef d''état-major TF-16',NULL),
 ('PR-MITSCHER','Mitscher Marc A.','Capitaine de vaisseau','USN','Commandant Hornet',NULL),
 ('PR-MURRAY','Murray George D.','Capitaine de vaisseau','USN','Commandant Enterprise',NULL),
 ('PR-BUCKMASTER','Buckmaster Elliott','Capitaine de vaisseau','USN','Commandant Yorktown',NULL),
 ('PR-RING','Ring Stanhope C.','Capitaine de frégate','USN','CHAG (Hornet Air Group) — cap controversé',NULL),
 ('PR-WALDRON','Waldron John C.','Capitaine de corvette','USN','VT-8 (tué le 04/06)',NULL),
 ('PR-LINDSEY','Lindsey Eugene E.','Capitaine de corvette','USN','VT-6 (tué le 04/06)',NULL),
 ('PR-MASSEY','Massey Lance E.','Capitaine de corvette','USN','VT-3 (tué le 04/06)',NULL),
 ('PR-LESLIE','Leslie Maxwell F.','Capitaine de corvette','USN','VB-3',NULL),
 ('PR-THACH','Thach John S.','Capitaine de corvette','USN','VF-3 (Thach Weave testé le 04/06)',NULL),
 ('PR-GRAY','Gray James S.','Lieutenant','USN','VF-6',NULL),
 ('PR-BEST','Best Richard H.','Lieutenant','USN','VB-6 (touche Akagi puis Hiryū le même jour)',NULL),
 ('PR-GALLAHER','Gallaher W. Earl','Lieutenant','USN','VS-6',NULL),
 ('PR-SHORT','Short Wallace C.','Lieutenant','USN','VS-5 (embarqué Yorktown, ex-VB-5)',NULL),
 ('PR-RODEE','Rodee Walter F.','Capitaine de corvette','USN','VS-8',NULL),
 ('PR-JOHNSON','Johnson Robert R.','Capitaine de corvette','USN','VB-8',NULL),
 ('PR-MITCHELL','Mitchell Samuel G.','Capitaine de corvette','USN','VF-8',NULL),
 ('PR-SIMARD','Simard Cyril T.','Capitaine de vaisseau','USN','Commandant NAS Midway',NULL),
 ('PR-PARKS','Parks Floyd B.','Major','USMC','VMF-221 (tué le 04/06)',NULL),
 ('PR-HENDERSON','Henderson Lofton R.','Major','USMC','VMSB-241 (tué le 04/06; Henderson Field nommé pour lui)',NULL),
 ('PR-NORRIS','Norris Benjamin W.','Major','USMC','VMSB-241 (SB2U; tué le 04/06 soir)',NULL),
 ('PR-FIEBERLING','Fieberling Langdon K.','Lieutenant','USN','Dét. VT-8 (TBF) de Midway (tué)',NULL),
 ('PR-SWEENEY','Sweeney Walter C.','Lt-Colonel','USAAF','B-17 de Midway (431st BS)',NULL),
 ('PR-COLLINS','Collins James F.','Capitaine','USAAF','Dét. B-26 (torpilles)',NULL),
 ('PR-ADY','Ady Howard P.','Lieutenant','USN','PBY VP-23 — premier contact Kidō Butai 05:34',NULL),
 ('PR-ENGLISH','English Robert H.','Contre-amiral','USN','ComSubPac (19 sous-marins)',NULL),
 ('PR-BROCKMAN','Brockman William H.','Capitaine de corvette','USN','Commandant Nautilus (SS-168)',NULL),
 ('PR-MURPHY','Murphy John W.','Capitaine de corvette','USN','Commandant Tambor (SS-198)',NULL);

-- ------------------------------------------------------------
-- FORMATIONS (complément + hiérarchie)
-- ------------------------------------------------------------
INSERT INTO formations VALUES
 ('CARDIV1','1re division de porte-avions (Akagi, Kaga)','IJN','KIDO-BUTAI','PR-NAGUMO',NULL),
 ('CARDIV2','2e division de porte-avions (Sōryū, Hiryū)','IJN','KIDO-BUTAI','PR-YAMAGUCHI',NULL),
 ('CRUDIV8','8e division de croiseurs (Tone, Chikuma)','IJN','KIDO-BUTAI','PR-ABE','Fournit la recherche hydravions du 4 juin'),
 ('KB-SCREEN','Écran de la Kidō Butai (Nagara + 12 DD, Haruna, Kirishima)','IJN','KIDO-BUTAI',NULL,NULL),
 ('MAIN-BODY','Corps principal (Yamamoto)','IJN',NULL,'PR-YAMAMOTO','~300 nm derrière la KB; pèse sur les décisions, peu sur la cinématique'),
 ('MI-INVASION','Force d''invasion MI (Kondō, 2e Flotte)','IJN',NULL,'PR-KONDO',NULL),
 ('CRUDIV7','7e division de croiseurs (Kurita)','IJN','MI-INVASION','PR-KURITA','Mogami/Mikuma: collision nuit 4-5, frappes US 5-6 juin'),
 ('TRANSPORT-GROUP','Groupe de transport (Tanaka, ~12 AP)','IJN','MI-INVASION','PR-TANAKA','Repéré le 3 juin par PBY'),
 ('IJN-SUBS','Sous-marins (cordons K + I-168)','IJN',NULL,NULL,'Cordons arrivés trop tard: TF US déjà passées'),
 ('SUBPAC','Sous-marins US (19 boats autour de Midway)','USN',NULL,'PR-ENGLISH',NULL),
 ('YORKTOWN-SALVAGE','Groupe de sauvetage du Yorktown (5-7 juin)','USN',NULL,'PR-BUCKMASTER','Hammann le long du bord le 6 juin');

UPDATE formations SET commander_id='PR-SPRUANCE' WHERE formation_id='TF-16';
UPDATE formations SET commander_id='PR-FLETCHER' WHERE formation_id='TF-17';
UPDATE formations SET commander_id='PR-SIMARD'   WHERE formation_id='MIDWAY-BASE';

-- ------------------------------------------------------------
-- NAVIRES — IJN
-- ------------------------------------------------------------
INSERT INTO ships (ship_id,name,side,ship_type,class,formation_id,captain_id,max_speed_kn,fate,notes) VALUES
 ('SH-KAGA','Kaga','IJN','CV','Kaga','CARDIV1','PR-OKADA',28.0,'Coulé 04/06 ~19:25 (4-5 bombes 10:22)','Le plus lent des 4 CV: contraint la vitesse de la force'),
 ('SH-SORYU','Sōryū','IJN','CV','Sōryū','CARDIV2','PR-YANAGIMOTO',34.5,'Sabordé 04/06 ~19:13 (3 bombes VB-3 10:25)','Porte les 2 D4Y de reconnaissance'),
 ('SH-HARUNA','Haruna','IJN','BB','Kongō','KB-SCREEN',NULL,30.0,'Survécu','Cible des B-17 (aucun coup)'),
 ('SH-KIRISHIMA','Kirishima','IJN','BB','Kongō','KB-SCREEN',NULL,30.0,'Survécu',NULL),
 ('SH-TONE','Tone','IJN','CA','Tone','CRUDIV8',NULL,35.0,'Survécu','Hydravion n°4: le contact décisif'),
 ('SH-CHIKUMA','Chikuma','IJN','CA','Tone','CRUDIV8',NULL,35.0,'Survécu','Hydravion n°5: ligne de recherche passée près de TF-17 sans la voir (plafond nuageux)'),
 ('SH-NAGARA','Nagara','IJN','CL','Nagara','KB-SCREEN',NULL,36.0,'Survécu','Navire amiral de Nagumo après l''évacuation de l''Akagi (~10:46)'),
 ('SH-ARASHI','Arashi','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu','Grenade le Nautilus; son sillage guide McClusky vers la KB'),
 ('SH-NOWAKI','Nowaki','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-HAGIKAZE','Hagikaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu','Torpille le Kaga (sabordage)'),
 ('SH-MAIKAZE','Maikaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-ISOKAZE','Isokaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu','Sabordage Sōryū'),
 ('SH-HAMAKAZE','Hamakaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-URAKAZE','Urakaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-TANIKAZE','Tanikaze','IJN','DD','Kagerō','KB-SCREEN',NULL,35.0,'Survécu','Attaqué par ~58 SBD + B-17 le 5 juin sans être touché'),
 ('SH-KAZAGUMO','Kazagumo','IJN','DD','Yūgumo','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-YUGUMO','Yūgumo','IJN','DD','Yūgumo','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-MAKIGUMO','Makigumo','IJN','DD','Yūgumo','KB-SCREEN',NULL,35.0,'Survécu','Sabordage Hiryū'),
 ('SH-AKIGUMO','Akigumo','IJN','DD','Yūgumo','KB-SCREEN',NULL,35.0,'Survécu',NULL),
 ('SH-YAMATO','Yamato','IJN','BB','Yamato','MAIN-BODY',NULL,27.0,'Survécu','Navire amiral de Yamamoto'),
 ('SH-NAGATO','Nagato','IJN','BB','Nagato','MAIN-BODY',NULL,25.0,'Survécu',NULL),
 ('SH-MUTSU','Mutsu','IJN','BB','Nagato','MAIN-BODY',NULL,25.0,'Survécu',NULL),
 ('SH-HOSHO','Hōshō','IJN','CVL','Hōshō','MAIN-BODY',NULL,25.0,'Survécu','8 B4Y; son avion photographie le Hiryū en flammes le 5 juin'),
 ('SH-MOGAMI','Mogami','IJN','CA','Mogami','CRUDIV7',NULL,35.0,'Gravement endommagé (collision + bombes 6 juin), survécu','Proue détruite par collision avec Mikuma'),
 ('SH-MIKUMA','Mikuma','IJN','CA','Mogami','CRUDIV7',NULL,35.0,'Coulé 06/06 (SBD TF-16)','Première perte de croiseur lourd IJN de la guerre'),
 ('SH-SUZUYA','Suzuya','IJN','CA','Mogami','CRUDIV7',NULL,35.0,'Survécu',NULL),
 ('SH-KUMANO','Kumano','IJN','CA','Mogami','CRUDIV7',NULL,35.0,'Survécu','Navire amiral CruDiv7; ordonne la manœuvre d''évitement du Tambor'),
 ('SH-ARASHIO','Arashio','IJN','DD','Asashio','CRUDIV7',NULL,35.0,'Endommagé 6 juin','Escorte Mogami/Mikuma'),
 ('SH-ASASHIO','Asashio','IJN','DD','Asashio','CRUDIV7',NULL,35.0,'Endommagé 6 juin',NULL),
 ('SH-AKEBONO-MARU','Akebono Maru','IJN','AO',NULL,'TRANSPORT-GROUP',NULL,12.0,'Endommagé (torpille PBY, nuit 3-4 juin)','Seul succès aérien US de la nuit'),
 ('SH-I168','I-168','IJN','SS','KD6','IJN-SUBS','PR-TANABE',23.0,'Survécu (coulé 1943)','Bombarde Midway nuit du 4; coule Yorktown + Hammann le 6');

-- ------------------------------------------------------------
-- NAVIRES — USN
-- ------------------------------------------------------------
INSERT INTO ships (ship_id,name,side,ship_type,class,formation_id,captain_id,max_speed_kn,fate,notes) VALUES
 ('SH-HORNET','USS Hornet','USN','CV','Yorktown (mod.)','TF-16','PR-MITSCHER',32.5,'Survécu','Groupe aérien neuf; vol pour rien le 4 juin matin'),
 ('SH-NEWORLEANS','USS New Orleans','USN','CA','New Orleans','TF-16',NULL,32.0,'Survécu',NULL),
 ('SH-MINNEAPOLIS','USS Minneapolis','USN','CA','New Orleans','TF-16',NULL,32.0,'Survécu',NULL),
 ('SH-VINCENNES','USS Vincennes','USN','CA','New Orleans','TF-16',NULL,32.0,'Survécu',NULL),
 ('SH-NORTHAMPTON','USS Northampton','USN','CA','Northampton','TF-16',NULL,32.0,'Survécu',NULL),
 ('SH-PENSACOLA','USS Pensacola','USN','CA','Pensacola','TF-16',NULL,32.0,'Survécu','Détaché en renfort de TF-17 le 4 juin après-midi'),
 ('SH-ATLANTA','USS Atlanta','USN','CL','Atlanta','TF-16',NULL,32.5,'Survécu','Croiseur AA'),
 ('SH-PHELPS','USS Phelps','USN','DD','Porter','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-WORDEN','USS Worden','USN','DD','Farragut','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-MONAGHAN','USS Monaghan','USN','DD','Farragut','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-AYLWIN','USS Aylwin','USN','DD','Farragut','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-BALCH','USS Balch','USN','DD','Porter','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-CONYNGHAM','USS Conyngham','USN','DD','Mahan','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-BENHAM','USS Benham','USN','DD','Benham','TF-16',NULL,35.0,'Survécu','Recueille les survivants du Hammann'),
 ('SH-ELLET','USS Ellet','USN','DD','Benham','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-MAURY','USS Maury','USN','DD','Gridley','TF-16',NULL,35.0,'Survécu',NULL),
 ('SH-ASTORIA','USS Astoria','USN','CA','New Orleans','TF-17',NULL,32.0,'Survécu','Fletcher y transfère sa marque le 4 juin après-midi'),
 ('SH-PORTLAND','USS Portland','USN','CA','Portland','TF-17',NULL,32.0,'Survécu',NULL),
 ('SH-HAMMANN','USS Hammann','USN','DD','Sims','TF-17',NULL,35.0,'Coulé 06/06 ~13:36 (I-168), 4 min','Le long du Yorktown pendant le sauvetage'),
 ('SH-HUGHES','USS Hughes','USN','DD','Sims','TF-17',NULL,35.0,'Survécu','Garde le Yorktown abandonné la nuit du 4-5'),
 ('SH-MORRIS','USS Morris','USN','DD','Sims','TF-17',NULL,35.0,'Survécu',NULL),
 ('SH-ANDERSON','USS Anderson','USN','DD','Sims','TF-17',NULL,35.0,'Survécu',NULL),
 ('SH-RUSSELL','USS Russell','USN','DD','Sims','TF-17',NULL,35.0,'Survécu',NULL),
 ('SH-VIREO','USS Vireo','USN','AV','Lapwing (AT)','YORKTOWN-SALVAGE',NULL,14.0,'Survécu','Remorque le Yorktown (très lentement) — type réel: remorqueur'),
 ('SH-NAUTILUS','USS Nautilus','USN','SS','Narwhal','SUBPAC','PR-BROCKMAN',17.0,'Survécu','Harcèle la KB; torpille (raté/non explosé) le Kaga; cause indirecte du guidage Arashi-McClusky'),
 ('SH-TAMBOR','USS Tambor','USN','SS','Tambor','SUBPAC','PR-MURPHY',20.0,'Survécu','Son contact nuit 4-5 provoque la collision Mogami/Mikuma'),
 ('SH-CIMARRON','USS Cimarron','USN','AO','Cimarron','TF-16',NULL,18.0,'Survécu','Ravitaillement: contrainte dure de la poursuite'),
 ('SH-PLATTE','USS Platte','USN','AO','Cimarron','TF-16',NULL,18.0,'Survécu',NULL);

-- ------------------------------------------------------------
-- CONTRAINTES PLATEFORMES (complément 5 CV)
-- ------------------------------------------------------------
INSERT INTO carrier_constraints VALUES
 ('SH-KAGA',248.6,30.5,3,NULL,NULL,NULL,NULL,NULL,'hangar',NULL,NULL,'Valeurs à vérifier Phase 2'),
 ('SH-SORYU',216.9,26.0,3,NULL,NULL,NULL,NULL,NULL,'hangar',NULL,NULL,'Pont plus court: spot max réduit'),
 ('SH-HIRYU',216.9,27.0,3,NULL,NULL,NULL,NULL,NULL,'hangar',NULL,NULL,'Île à bâbord'),
 ('SH-HORNET',246.0,34.0,3,NULL,NULL,NULL,NULL,NULL,'both',NULL,NULL,NULL),
 ('SH-CV5',244.4,34.0,3,NULL,NULL,NULL,NULL,NULL,'both',NULL,NULL,'Vitesse réduite par avaries Coral Sea');

-- ------------------------------------------------------------
-- TYPES D'AVIONS (complément) + MUNITIONS
-- ------------------------------------------------------------
INSERT INTO aircraft_types (type_id,designation,side,role,crew,cruise_speed_kn,combat_radius_nm,notes) VALUES
 ('AC-D4Y1','Yokosuka D4Y1 (proto reco)','IJN','recon',2,230,400,'2 exemplaires sur Sōryū'),
 ('AC-E13A1','Aichi E13A1 "Jake"','IJN','recon',3,120,290,'Hydravion croiseurs — recherche longue'),
 ('AC-E8N2','Nakajima E8N2 "Dave"','IJN','recon',2,90,150,'Hydravion court rayon (lignes de recherche proches)'),
 ('AC-B4Y1','Yokosuka B4Y1 "Jean"','IJN','torpedo_bomber',3,85,250,'8 sur Hōshō (obsolète)'),
 ('AC-SBD2','Douglas SBD-2 Dauntless','USMC','dive_bomber',2,125,220,'VMSB-241'),
 ('AC-SB2U3','Vought SB2U-3 Vindicator','USMC','dive_bomber',2,115,200,'Obsolescent; attaque en glide-bombing'),
 ('AC-F2A3','Brewster F2A-3 Buffalo','USMC','fighter',1,140,250,'Surclassé par le Zero (massacre VMF-221)'),
 ('AC-F4F3','Grumman F4F-3 Wildcat','USMC','fighter',1,145,180,'7 chez VMF-221'),
 ('AC-TBF1','Grumman TBF-1 Avenger','USN','torpedo_bomber',3,125,260,'Premier engagement du type (dét. VT-8, 5/6 perdus)'),
 ('AC-B26','Martin B-26 Marauder','USAAF','torpedo_bomber',7,180,500,'4 porteurs de torpilles improvisés (2 perdus)'),
 ('AC-B17E','Boeing B-17E Flying Fortress','USAAF','level_bomber',10,160,800,'Bombardement haute altitude: 0 coup au but sur navires en manœuvre');

INSERT INTO ordnance_types VALUES
 ('ORD-250KG','Bombe 250 kg','bomb_he',250,NULL,NULL,'Emport D3A1'),
 ('ORD-60KG','Bombe 60 kg','bomb_gp',60,NULL,NULL,'Emport secondaire'),
 ('ORD-1000LB','Bombe 1000 lb','bomb_gp',454,NULL,NULL,'SBD frappe principale'),
 ('ORD-500LB','Bombe 500 lb','bomb_gp',227,NULL,NULL,'SBD/SB2U'),
 ('ORD-100LB','Bombe 100 lb','bomb_gp',45,NULL,NULL,'Emport d''appoint');

INSERT INTO aircraft_ordnance VALUES
 ('AC-D3A1','ORD-250KG',1),('AC-SBD3','ORD-1000LB',1),('AC-SBD3','ORD-500LB',1),
 ('AC-SBD2','ORD-500LB',1),('AC-SB2U3','ORD-500LB',1),('AC-TBF1','ORD-MK13',1),
 ('AC-B26','ORD-MK13',1),('AC-B17E','ORD-500LB',8);

-- ------------------------------------------------------------
-- ESCADRILLES
-- ------------------------------------------------------------
-- Correction de l'amorce: VT-8 appartient au Hornet
UPDATE squadrons SET ship_id='SH-HORNET', type_id='AC-TBD1', commander_id='PR-WALDRON',
  notes='Détruite le 04/06 (15 TBD, 1 survivant: Ens. Gay)' WHERE squadron_id='SQ-VT8';
UPDATE squadrons SET commander_id='PR-BEST' WHERE squadron_id='SQ-VB6';

INSERT INTO squadrons (squadron_id,name,side,ship_id,type_id,strength_0406,commander_id,experience,notes) VALUES
 -- Enterprise
 ('SQ-VF6','VF-6','USN','SH-CV6','AC-F4F4',27,'PR-GRAY','veteran',NULL),
 ('SQ-VS6','VS-6','USN','SH-CV6','AC-SBD3',19,'PR-GALLAHER','veteran','SBD-2/3 mélangés'),
 ('SQ-VT6','VT-6','USN','SH-CV6','AC-TBD1',14,'PR-LINDSEY','veteran','10 perdus le 04/06'),
 -- Hornet
 ('SQ-VF8','VF-8','USN','SH-HORNET','AC-F4F4',27,'PR-MITCHELL','green','Escorte égarée; amerrissages par panne sèche'),
 ('SQ-VB8','VB-8','USN','SH-HORNET','AC-SBD3',19,'PR-JOHNSON','green',NULL),
 ('SQ-VS8','VS-8','USN','SH-HORNET','AC-SBD3',18,'PR-RODEE','green',NULL),
 -- Yorktown
 ('SQ-VF3','VF-3','USN','SH-CV5','AC-F4F4',25,'PR-THACH','elite','Pilotes mélangés VF-3/VF-42'),
 ('SQ-VB3','VB-3','USN','SH-CV5','AC-SBD3',18,'PR-LESLIE','veteran','Frappe Sōryū; 4 bombes perdues par défaut d''armement électrique'),
 ('SQ-VS5','VS-5 (ex-VB-5)','USN','SH-CV5','AC-SBD3',19,'PR-SHORT','veteran','Retenue à bord le matin (décision Fletcher); recherche l''après-midi'),
 ('SQ-VT3','VT-3','USN','SH-CV5','AC-TBD1',13,'PR-MASSEY','veteran','12 engagés le 04/06'),
 -- Midway (USMC/USN/USAAF)
 ('SQ-VMF221-F2A','VMF-221 (F2A-3)','USMC','SH-MIDWAY','AC-F2A3',21,'PR-PARKS','green','13 abattus/HS le 04/06 matin'),
 ('SQ-VMF221-F4F','VMF-221 (F4F-3)','USMC','SH-MIDWAY','AC-F4F3',7,'PR-PARKS','green',NULL),
 ('SQ-VMSB241-SBD','VMSB-241 (SBD-2)','USMC','SH-MIDWAY','AC-SBD2',16,'PR-HENDERSON','green','Attaque en glide (équipages non formés au piqué)'),
 ('SQ-VMSB241-SB2U','VMSB-241 (SB2U-3)','USMC','SH-MIDWAY','AC-SB2U3',11,'PR-NORRIS','green',NULL),
 ('SQ-VT8-DET','Dét. VT-8 (TBF-1)','USN','SH-MIDWAY','AC-TBF1',6,'PR-FIEBERLING','green','5 perdus le 04/06 matin'),
 ('SQ-B26-DET','Dét. B-26 (18th RS / 69th BS)','USAAF','SH-MIDWAY','AC-B26',4,'PR-COLLINS','green','2 perdus; l''un frôle la passerelle de l''Akagi'),
 ('SQ-B17-MIDWAY','B-17E (431st BS et dét.)','USAAF','SH-MIDWAY','AC-B17E',17,'PR-SWEENEY','average','Effectif variable 3-6 juin (rotations Hawaï)'),
 ('SQ-PBY-MIDWAY','PBY (VP-23/24/44/51)','USN','SH-MIDWAY','AC-PBY5',31,NULL,'average','Recherche en éventail 700 nm; 1 victoire torpille nuit 3-4'),
 -- Kidō Butai
 ('SQ-AKAGI-KANSEN','Akagi kansentai (A6M2)','IJN','SH-AKAGI','AC-A6M2',18,'PR-ITAYA','elite',NULL),
 ('SQ-AKAGI-KANBAKU','Akagi kanbakutai (D3A1)','IJN','SH-AKAGI','AC-D3A1',18,NULL,'elite',NULL),
 ('SQ-KAGA-KANSEN','Kaga kansentai (A6M2)','IJN','SH-KAGA','AC-A6M2',18,NULL,'elite',NULL),
 ('SQ-KAGA-KANBAKU','Kaga kanbakutai (D3A1)','IJN','SH-KAGA','AC-D3A1',18,NULL,'elite',NULL),
 ('SQ-KAGA-KANKO','Kaga kankōtai (B5N2)','IJN','SH-KAGA','AC-B5N2',27,NULL,'elite','Plus grosse escadrille de torpilleurs de la KB'),
 ('SQ-SORYU-KANSEN','Sōryū kansentai (A6M2)','IJN','SH-SORYU','AC-A6M2',18,NULL,'elite',NULL),
 ('SQ-SORYU-KANBAKU','Sōryū kanbakutai (D3A1)','IJN','SH-SORYU','AC-D3A1',16,NULL,'elite',NULL),
 ('SQ-SORYU-KANKO','Sōryū kankōtai (B5N2)','IJN','SH-SORYU','AC-B5N2',18,NULL,'elite',NULL),
 ('SQ-SORYU-D4Y','Sōryū dét. reco (D4Y1)','IJN','SH-SORYU','AC-D4Y1',2,NULL,'elite','Suit la TF US l''après-midi du 4'),
 ('SQ-HIRYU-KANSEN','Hiryū kansentai (A6M2)','IJN','SH-HIRYU','AC-A6M2',18,NULL,'elite',NULL),
 ('SQ-HIRYU-KANKO','Hiryū kankōtai (B5N2)','IJN','SH-HIRYU','AC-B5N2',18,'PR-TOMONAGA','elite','2e frappe anti-Yorktown (10 B5N)'),
 ('SQ-6KU','6e Kōkūtai (A6M2, en transit pour Midway)','IJN',NULL,'AC-A6M2',21,NULL,'average','Répartis sur les 4 CV (6/9/3/3); utilisés en CAP'),
 ('SQ-TONE-RECON','Hydravions du Tone (E13A/E8N)','IJN','SH-TONE','AC-E13A1',5,NULL,'average','N°4 (Amari): le contact décisif, lancé avec ~30 min de retard'),
 ('SQ-CHIKUMA-RECON','Hydravions du Chikuma (E13A/E8N)','IJN','SH-CHIKUMA','AC-E13A1',5,NULL,'average','N°5: passe près de TF-17 sans la voir'),
 ('SQ-HOSHO-B4Y','Hōshō hikōtai (B4Y1)','IJN','SH-HOSHO','AC-B4Y1',8,NULL,'average',NULL);

-- ------------------------------------------------------------
-- CLAIMS — effectifs (multi-sourçage)
-- ------------------------------------------------------------
-- US: action reports / cv6.org (transcriptions de sources A)
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('squadrons','SQ-VF6','strength_0406','27','SRC-CV6ORG',1,'single_source','À confirmer sur SRC-ENTERPRISE-AR'),
 ('squadrons','SQ-VB6','strength_0406','19','SRC-CV6ORG',1,'single_source',NULL),
 ('squadrons','SQ-VS6','strength_0406','19','SRC-CV6ORG',1,'single_source',NULL),
 ('squadrons','SQ-VT6','strength_0406','14','SRC-CV6ORG',1,'single_source',NULL),
 ('squadrons','SQ-VF8','strength_0406','27','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VB8','strength_0406','19','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VS8','strength_0406','18','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VT8','strength_0406','15','SRC-NHHC',1,'verified','Confirmé par H-072-1 (NHHC) et récit VT-8 standard'),
 ('squadrons','SQ-VF3','strength_0406','25','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VB3','strength_0406','18','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VS5','strength_0406','19','SRC-NHHC',1,'single_source',NULL),
 ('squadrons','SQ-VT3','strength_0406','13','SRC-NHHC',1,'single_source','12 engagés le 04/06'),
 -- IJN: valeurs P&T (organisation par escadrille)
 ('squadrons','SQ-AKAGI-KANKO','strength_0406','18','SRC-SHATTERED-SWORD',1,'single_source','À recouper Senshi Sōsho'),
 ('squadrons','SQ-KAGA-KANKO','strength_0406','27','SRC-SHATTERED-SWORD',1,'single_source',NULL),
 ('squadrons','SQ-SORYU-KANBAKU','strength_0406','16','SRC-SHATTERED-SWORD',1,'single_source',NULL),
 ('squadrons','SQ-6KU','strength_0406','21','SRC-SHATTERED-SWORD',1,'single_source','Répartition 6/9/3/3 à confirmer');

-- Exemple de CONFLIT documenté: total embarqué du Kaga
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('ships','SH-KAGA','air_group_total','72','SRC-SHATTERED-SWORD',1,'conflicting','18+18+27 propres + 9 du 6e Ku = 72. Retenu provisoirement (organisation détaillée).'),
 ('ships','SH-KAGA','air_group_total','74','SRC-WIKI',0,'conflicting','Wikipédia agrège 248 (60/74/57/57) sans détail par escadrille. Écart de 2 non résolu — vérifier l''appendice de Shattered Sword et le rapport Nagumo.');

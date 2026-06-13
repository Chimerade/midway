-- Données d'amorçage (exemples montrant le mode de saisie attendu).
-- Toutes les valeurs sont des valeurs initiales de travail à vérifier (méthodologie §4.2).

-- Sources de référence
INSERT INTO sources VALUES
 ('SRC-SHATTERED-SWORD','scholarly','Parshall J. & Tully A.','Shattered Sword: The Untold Story of the Battle of Midway',2005,'B','GMT-12',NULL,'Référence moderne côté japonais'),
 ('SRC-NAGUMO-REPORT','primary_official','1er Kōkū Kantai','Japanese Story of the Battle of Midway (OPNAV P32-1002, trad. du rapport Nagumo)',1947,'A','GMT+9',NULL,'Heures en heure de Tokyo: conversion -21h obligatoire'),
 ('SRC-FIRST-TEAM','scholarly','Lundstrom J.','The First Team: Pacific Naval Air Combat from Pearl Harbor to Midway',1984,'B','GMT-12',NULL,'Minute par minute des opérations de chasse US'),
 ('SRC-CINCPAC-01849','primary_official','CINCPAC','Battle of Midway report, serial 01849',1942,'A','GMT-12',NULL,NULL),
 ('SRC-COMBINEDFLEET','online_db','Hackett & Kingsepp','combinedfleet.com — TROMs',1997,'C',NULL,'http://www.combinedfleet.com','Mouvements détaillés des navires japonais'),
 ('SRC-FUCHIDA','testimony','Fuchida M. & Okumiya M.','Midway: The Battle That Doomed Japan',1955,'D','mixte',NULL,'Réfuté sur des points clés (cinq minutes fatales). Ne jamais accepter seul.');

-- Personnes (échantillon)
INSERT INTO persons VALUES
 ('PR-NAGUMO','Nagumo Chūichi','Vice-amiral','IJN','Commandant 1er Kōkū Kantai (Kidō Butai)',NULL),
 ('PR-YAMAGUCHI','Yamaguchi Tamon','Contre-amiral','IJN','Commandant 2e Kōkū Sentai (Sōryū, Hiryū)',NULL),
 ('PR-FLETCHER','Fletcher Frank J.','Contre-amiral','USN','Commandant TF-17, commandement tactique',NULL),
 ('PR-SPRUANCE','Spruance Raymond A.','Contre-amiral','USN','Commandant TF-16',NULL),
 ('PR-MCCLUSKY','McClusky C. Wade','Lt-Cdr','USN','CEAG Enterprise',NULL),
 ('PR-TOMONAGA','Tomonaga Jōichi','Lieutenant','IJN','Chef de la frappe sur Midway, hikōtaichō Hiryū',NULL);

-- Formations
INSERT INTO formations VALUES
 ('KIDO-BUTAI','1er Kōkū Kantai','IJN',NULL,'PR-NAGUMO',NULL),
 ('TF-16','Task Force 16','USN',NULL,'PR-SPRUANCE',NULL),
 ('TF-17','Task Force 17','USN',NULL,'PR-FLETCHER',NULL),
 ('MIDWAY-BASE','Garnison aérienne de Midway (NAS + MAG-22 + USAAF)','USN',NULL,NULL,NULL);

-- Navires (échantillon: 1 CV par camp + pseudo-navire Midway)
INSERT INTO ships (ship_id,name,side,ship_type,class,formation_id,max_speed_kn,fate,notes) VALUES
 ('SH-AKAGI','Akagi','IJN','CV','Akagi','KIDO-BUTAI',31.0,'Sabordé 05/06/1942 ~05:00','Navire amiral de Nagumo'),
 ('SH-HIRYU','Hiryū','IJN','CV','Hiryū','KIDO-BUTAI',34.3,'Coulé 05/06/1942 ~09:12','Seul CV opérationnel après 10:26 le 4 juin'),
 ('SH-CV6','USS Enterprise','USN','CV','Yorktown','TF-16',32.5,'Survécu',NULL),
 ('SH-CV5','USS Yorktown','USN','CV','Yorktown','TF-17',30.0,'Coulé 07/06/1942 (I-168)','Réparations Coral Sea en 72h; vitesse réduite'),
 ('SH-MIDWAY','Atoll de Midway (base aérienne)','USN','base',NULL,'MIDWAY-BASE',0,'—','Porte-avions insubmersible; pistes Eastern Island');

-- Contraintes plateformes (valeurs initiales à vérifier — claims associées plus bas)
INSERT INTO carrier_constraints VALUES
 ('SH-AKAGI',249.2,30.5,3,NULL,NULL,NULL,NULL,NULL,'hangar',NULL,NULL,'Doctrine IJN: réarmement en hangar uniquement'),
 ('SH-CV6',246.0,34.0,3,NULL,NULL,NULL,NULL,NULL,'both',NULL,NULL,'Doctrine USN: réarmement pont possible'),
 ('SH-MIDWAY',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,'deck',NULL,NULL,'Pistes fixes; pas de vent apparent généré');

-- Types d'avions (échantillon)
INSERT INTO aircraft_types (type_id,designation,side,role,crew,cruise_speed_kn,combat_radius_nm,notes) VALUES
 ('AC-B5N2','Nakajima B5N2 "Kate"','IJN','torpedo_bomber',3,140,200,'Torpille Type 91 ou bombe 800 kg'),
 ('AC-A6M2','Mitsubishi A6M2 "Zero"','IJN','fighter',1,180,300,NULL),
 ('AC-D3A1','Aichi D3A1 "Val"','IJN','dive_bomber',2,160,240,NULL),
 ('AC-SBD3','Douglas SBD-3 Dauntless','USN','dive_bomber',2,130,225,NULL),
 ('AC-TBD1','Douglas TBD-1 Devastator','USN','torpedo_bomber',3,110,150,'Mk13: largage <110 kn / basse altitude'),
 ('AC-F4F4','Grumman F4F-4 Wildcat','USN','fighter',1,140,175,NULL),
 ('AC-PBY5','Consolidated PBY-5/5A Catalina','USN','patrol',8,100,700,'Structure le plan de recherche de Midway');

-- Munitions (échantillon)
INSERT INTO ordnance_types VALUES
 ('ORD-TYPE91','Torpille aérienne Type 91','torpedo',838,'Largage bas et lent; fiable','Bonne fiabilité 1942',NULL),
 ('ORD-800KG','Bombe 800 kg (perforante, conversion obus)','bomb_ap',800,NULL,NULL,'Emport B5N en config anti-navire alternatif'),
 ('ORD-MK13','Torpille Mk 13','torpedo',1005,'<110 kn, <30 m','Fiabilité médiocre en 1942','Impose le profil suicidaire des TBD');

INSERT INTO aircraft_ordnance VALUES
 ('AC-B5N2','ORD-TYPE91',1),('AC-B5N2','ORD-800KG',1),('AC-TBD1','ORD-MK13',1);

-- Escadrilles (échantillon: 2 US, 2 JP)
INSERT INTO squadrons (squadron_id,name,side,ship_id,type_id,strength_0406,experience,notes) VALUES
 ('SQ-VT8','VT-8 (Torpedo Squadron 8)','USN','SH-CV6',NULL,15,'green','Basée Hornet en réalité — corriger ship_id à la saisie complète; détruite le 04/06 (1 survivant)'),
 ('SQ-VB6','VB-6 (Bombing Squadron 6)','USN','SH-CV6','AC-SBD3',19,'veteran',NULL),
 ('SQ-AKAGI-KANKO','Akagi kankōtai (B5N2)','IJN','SH-AKAGI','AC-B5N2',18,'elite','Unité au cœur du dilemme du réarmement'),
 ('SQ-HIRYU-KANBAKU','Hiryū kanbakutai (D3A1)','IJN','SH-HIRYU','AC-D3A1',18,'elite','1re frappe anti-Yorktown (Kobayashi)');

-- Événements d'ancrage (échantillon)
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-0430-LAUNCH','1942-06-04T04:30:00-12:00',5,'launch_start','IJN','Kidō Butai lance la frappe sur Midway: 108 appareils (Tomonaga)','J4-matin'),
 ('EV-0604-0715-D1','1942-06-04T07:15:00-12:00',5,'decision','IJN','Nagumo ordonne le réarmement des B5N (torpilles -> bombes) pour 2e frappe sur Midway','J4-matin'),
 ('EV-0604-0728-TONE4','1942-06-04T07:28:00-12:00',5,'sighting','IJN','Hydravion n°4 du Tone signale 10 navires ennemis','J4-matin'),
 ('EV-0604-1022-HITS','1942-06-04T10:22:00-12:00',2,'hit','USN','VB-6/VS-6 frappent Kaga et Akagi; VB-3 frappe Sōryū (10:22–10:26)','J4-contre-attaque');

-- Claims: exemple de multi-sourçage d'une même heure
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-0430-LAUNCH','ts','1942-06-04T04:30:00-12:00','0130 (5 juin, heure de Tokyo)','SRC-NAGUMO-REPORT',1,'verified','Conversion GMT+9 -> GMT-12 (-21h). Concorde avec Shattered Sword.'),
 ('events','EV-0604-0430-LAUNCH','ts','1942-06-04T04:30:00-12:00','04:30','SRC-SHATTERED-SWORD',0,'verified',NULL),
 ('events','EV-0604-1022-HITS','ts','1942-06-04T10:22:00-12:00','10:22','SRC-SHATTERED-SWORD',1,'verified','Recoupé rapports d''action US'),
 ('carrier_constraints','SH-AKAGI','flight_deck_length_m','249.2',NULL,'SRC-COMBINEDFLEET',1,'single_source','À recouper avec une 2e source en Phase 2');

-- Décision exemple (support F3)
INSERT INTO decisions VALUES
 ('DC-NAGUMO-D1','1942-06-04T07:15:00-12:00','PR-NAGUMO','EV-0604-0715-D1',
  'Réarmer la 2e vague (B5N torpilles -> bombes terrestres) pour refrapper Midway',
  'A: réarmer pour Midway; B: conserver la config anti-navire en attente de confirmation des recherches; C: lancer une recherche renforcée avant de décider',
  'Option A',
  'Message de Tomonaga (2e frappe nécessaire) + attaques continues depuis Midway + aucun contact naval ennemi signalé à cette heure',
  'Les hangars sont saturés de munitions en transit quand les SBD frappent à 10:22 (incendies fatals)',
  'Chronologie et taux d''avancement réel du réarmement débattus — voir Shattered Sword, app.',
  NULL);

-- Contact report exemple (monde perçu vs monde réel)
INSERT INTO contact_reports VALUES
 ('CR-TONE4-0728','squadrons','SQ-TONE-RECON','1942-06-04T07:28:00-12:00','1942-06-04T07:28:00-12:00','1942-06-04T07:45:00-12:00',
  'PR-NAGUMO',NULL,NULL,'10 navires, apparemment ennemis, relèvement 010, distance 240 nm de Midway, cap 150, vitesse >20 nds',
  'EV-0604-0728-TONE4',NULL,'Position rapportée à compléter; escadrille SQ-TONE-RECON à créer à la saisie complète. Ne mentionne pas de porte-avions avant 08:20.');

-- Gabarit de processus: le réarmement (l'exemple canonique)
INSERT INTO process_templates VALUES
 ('PT-REARM-B5N-T2B','Réarmement B5N: torpille -> bombe 800 kg','B5N2 / CV japonais (hangar)','Cycle complet par appareil, équipes complètes',NULL),
 ('PT-REARM-B5N-B2T','Réarmement B5N: bombe -> torpille (ordre D2)','B5N2 / CV japonais (hangar)','Plus lent: torpilles à remonter des soutes',NULL);

INSERT INTO process_steps (template_id,seq,name,duration_min_s,duration_typ_s,duration_max_s,resources,source_id,notes) VALUES
 ('PT-REARM-B5N-T2B',1,'Retrait de la torpille',180,300,480,'arming_crew','SRC-SHATTERED-SWORD','Durées initiales à calibrer en Phase 5'),
 ('PT-REARM-B5N-T2B',2,'Déplacement de l''armement (chariots)',120,240,420,'arming_crew',NULL,'Goulot: nombre de chariots'),
 ('PT-REARM-B5N-T2B',3,'Installation bombe 800 kg',240,360,600,'arming_crew',NULL,NULL),
 ('PT-REARM-B5N-T2B',4,'Contrôles techniques',120,180,300,'arming_crew',NULL,NULL),
 ('PT-REARM-B5N-T2B',5,'Sécurisation / arrimage',60,120,240,'arming_crew',NULL,NULL),
 ('PT-REARM-B5N-T2B',6,'Ravitaillement carburant',300,480,720,'fueling_crew',NULL,'Parallélisable partiellement');

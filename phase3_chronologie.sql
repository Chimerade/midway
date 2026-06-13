-- ============================================================
-- PHASE 3 : chronologie événementielle 3-7 juin 1942
-- Heures en heure locale Midway (GMT-12). Incertitudes typiques:
-- ±1-5 min (US, action reports) ; ±5-15 min (IJN, reconstruction).
-- Valeurs de travail grade B (principalement Shattered Sword /
-- Lundstrom / action reports) — à recouper claim par claim.
-- ============================================================

-- ------------------------------------------------------------
-- 3 JUIN — approche
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0603-0900-PBY','1942-06-03T09:00:00-12:00',15,'sighting','USN','PBY (Ens. Reid) repère le groupe de transport à ~700 nm O-SO de Midway; rapporté à tort comme "Main Body"','J3-approche'),
 ('EV-0603-1230-B17UP','1942-06-03T12:30:00-12:00',15,'launch_start','USN','Midway lance 9 B-17 (Sweeney) contre le groupe de transport','J3-approche'),
 ('EV-0603-1624-B17ATK','1942-06-03T16:24:00-12:00',15,'attack','USN','B-17 attaquent les transports à haute altitude — aucun coup au but','J3-approche'),
 ('EV-0604-0143-PBYTORP','1942-06-04T01:43:00-12:00',10,'hit','USN','Attaque de nuit de 4 PBY à la torpille; Akebono Maru touché (seul succès aérien torpille US de la bataille)','J3-approche');

-- ------------------------------------------------------------
-- 4 JUIN — matin (frappe sur Midway, fenêtre décisionnelle)
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0602-1530-POINTLUCK','1942-06-02T15:30:00-12:00',30,'other','USN','Jonction TF-16/TF-17 à Point Luck (~32°N 173°W, 045°/325 nm de Midway); Fletcher (Yorktown) prend le commandement tactique; TF-16 prend station à 10 nm au sud','J3-approche'),
 ('EV-0603-1950-TURNSOUTH','1942-06-03T19:50:00-12:00',20,'course_change','USN','Fletcher vire au 210° à 13,5 nœuds pour positionner les TF face aux vents du sud, en vue du lancement de l''aube du 4','J3-approche'),
 ('EV-0604-0445-LAUNCHEND','1942-06-04T04:45:00-12:00',5,'launch_end','IJN','Fin du lancement de la frappe Tomonaga (108 appareils des 4 CV)','J4-matin'),
 ('EV-0604-0430-SEARCH','1942-06-04T04:30:00-12:00',10,'launch_start','IJN','Lancement du plan de recherche (7 appareils, une seule phase); catapulte du Tone en panne','J4-matin'),
 ('EV-0604-0500-TONE4UP','1942-06-04T05:00:00-12:00',10,'launch_end','IJN','Hydravion n°4 du Tone (Amari) lancé avec ~30 min de retard — il couvrira la ligne où se trouvent les TF US','J4-matin'),
 ('EV-0604-0534-ADY','1942-06-04T05:34:00-12:00',3,'sighting','USN','PBY 4V58 (Ady, VP-23) : "enemy carriers" — premier contact sur la Kidō Butai','J4-matin'),
 ('EV-0604-0545-CHASE','1942-06-04T05:45:00-12:00',3,'report','USN','PBY (Lt. W. Chase) en clair : "many planes heading Midway, bearing 320, distance 150" — l''alerte du raid entrant qui précipite le décollage général de Midway','J4-matin'),
 ('EV-0604-1002-MCCLUSKY','1942-06-04T10:02:00-12:00',3,'sighting','USN','McClusky (CEAG, groupe Enterprise) repère la KB à ~35 nm au NE en suivant le sillage de l''Arashi — déclenche l''attaque en piqué','J4-contre-attaque'),
 ('EV-0604-1900-NORRIS','1942-06-04T19:00:00-12:00',15,'other','USN','Recherche du soir de Norris (Vindicators VMSB-241) vers le CV en feu; aucun contact, météo se dégrade — le Vindicator de Norris est perdu (Norris et Pfc Whittington disparus)','J4-soir'),
 ('EV-0604-0552-2CV','1942-06-04T06:03:00-12:00',3,'report','USN','PBY 4V58 (Ady) : "two carriers and battleships bearing 320, distance 180, course 135, speed 25" — amplification du contact de 0534; position erronée de ~30-40 nm; ne signale que 2 CV sur 4','J4-matin'),
 ('EV-0604-0553-MIDWAYRADAR','1942-06-04T05:53:00-12:00',5,'sighting','USN','Radar de Midway détecte le raid entrant ("many planes, 89 miles"); décollage général de tout ce qui vole','J4-matin'),
 ('EV-0604-0607-FLETCHER','1942-06-04T06:07:00-12:00',3,'decision','USN','Fletcher à Spruance : "proceed southwesterly and attack enemy carriers when definitely located" — TF-16 part en avant, TF-17 récupère sa recherche','J4-matin'),
 ('EV-0604-0616-VMF221','1942-06-04T06:16:00-12:00',5,'attack','USN','VMF-221 (Parks) intercepte la frappe Tomonaga: 25 chasseurs vs escorte de 36 Zeros — 13 F2A/F4F perdus, 7 endommagés','J4-matin'),
 ('EV-0604-0630-MIDWAYHIT','1942-06-04T06:30:00-12:00',5,'attack','IJN','La frappe Tomonaga bombarde Midway (06:30-06:43): dégâts importants aux installations, pistes restent utilisables','J4-matin'),
 ('EV-0604-0700-TOMONAGA','1942-06-04T07:00:00-12:00',3,'report','IJN','Tomonaga : "il est nécessaire de procéder à une deuxième attaque" (Kawa·Kawa·Kawa 109)','J4-matin'),
 ('EV-0604-0706-TF16LAUNCH','1942-06-04T07:06:00-12:00',4,'launch_start','USN','TF-16 commence à lancer à ~155 nm de la position estimée de la KB (limite TBD); lancement long (~1h), escadrilles séparées en route','J4-matin'),
 ('EV-0604-0710-TBFB26','1942-06-04T07:10:00-12:00',5,'attack','USN','6 TBF (Fieberling) + 4 B-26 (Collins) attaquent la KB sans escorte: aucun coup, 5 TBF et 2 B-26 perdus; un B-26 frôle la passerelle de l''Akagi','J4-matin'),
 ('EV-0604-0745-D2','1942-06-04T07:45:00-12:00',5,'decision','IJN','Nagumo suspend le réarmement (ordre "préparez-vous à attaquer les unités de flotte; laissez les torpilles aux appareils non encore réarmés") et demande au Tone n°4 de préciser la composition ennemie','J4-matin'),
 ('EV-0604-0755-VMSB','1942-06-04T07:55:00-12:00',5,'attack','USN','16 SBD-2 VMSB-241 (Henderson) attaquent le Hiryū en glide-bombing: aucun coup, 8 perdus dont Henderson','J4-matin'),
 ('EV-0604-0810-B17','1942-06-04T08:10:00-12:00',10,'attack','USN','B-17 (Sweeney) bombardent les CV depuis ~6000 m: aucun coup','J4-matin'),
 ('EV-0604-0820-SB2U','1942-06-04T08:20:00-12:00',10,'attack','USN','11 SB2U (Norris) attaquent le Haruna: aucun coup','J4-matin'),
 ('EV-0604-0820-CARRIER','1942-06-04T08:20:00-12:00',5,'report','IJN','Tone n°4 : "l''ennemi est accompagné de ce qui semble être un porte-avions" — le pivot informationnel de la bataille','J4-matin'),
 ('EV-0604-0830-YAMAGUCHI','1942-06-04T08:30:00-12:00',10,'report','IJN','Yamaguchi (signal au Nagumo) : "considère souhaitable de lancer la force d''attaque immédiatement" — avec les D3A disponibles, sans escorte complète','J4-matin'),
 ('EV-0604-0837-RECOVERY','1942-06-04T08:37:00-12:00',5,'recovery_start','IJN','La KB commence à récupérer la frappe Tomonaga + la CAP (ponts monopolisés ~35 min)','J4-matin'),
 ('EV-0604-0838-TF17LAUNCH','1942-06-04T08:38:00-12:00',5,'launch_start','USN','Yorktown lance: 17 VB-3, 12 VT-3, 6 VF-3 (Fletcher garde VS-5 en réserve) — fin ~09:06','J4-matin'),
 ('EV-0604-0855-D3','1942-06-04T08:55:00-12:00',10,'decision','IJN','Nagumo refuse la frappe immédiate: récupérer d''abord, puis frapper en force constituée vers 10:30 ("fenêtre des 65 minutes")','J4-matin'),
 ('EV-0604-0910-RECOVEND','1942-06-04T09:10:00-12:00',10,'recovery_end','IJN','Récupération terminée; réarmement/ravitaillement généralisé en hangar','J4-matin'),
 ('EV-0604-0917-TURNNE','1942-06-04T09:17:00-12:00',5,'course_change','IJN','La KB vire au 070 (ENE) vers les porte-avions US — la frappe du Hornet (cap 265→240?) la manque en partie','J4-matin');

-- ------------------------------------------------------------
-- 4 JUIN — contre-attaque US
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-0920-VT8','1942-06-04T09:20:00-12:00',5,'attack','USN','VT-8 (Waldron, 15 TBD seuls, sans escorte) attaque: tous abattus (~09:36), 1 survivant (Ens. Gay); aucun coup','J4-contre-attaque'),
 ('EV-0604-0938-VT6','1942-06-04T09:38:00-12:00',5,'attack','USN','VT-6 (Lindsey, 14 TBD) attaque par les deux bords: 10 perdus, aucun coup; la CAP reste tirée à basse altitude','J4-contre-attaque'),
 ('EV-0604-0955-MCCLUSKY','1942-06-04T09:55:00-12:00',10,'decision','USN','McClusky, à sec de réserve, prolonge la recherche puis vire N-O; repère le sillage de l''Arashi (qui regagne la KB après avoir grenadé le Nautilus) et le suit','J4-contre-attaque'),
 ('EV-0604-1000-VT3','1942-06-04T10:15:00-12:00',5,'attack','USN','VT-3 (Massey, 12 TBD) + VF-3 (Thach, 6 F4F) attaquent: 10 TBD perdus, aucun coup; Thach Weave employé pour la première fois; la CAP entière est au ras de l''eau','J4-contre-attaque'),
 ('EV-0604-1020-READY','1942-06-04T10:20:00-12:00',10,'spot','IJN','État réel des ponts (contra Fuchida): frappes encore en hangar, ponts occupés par la CAP; lancement prévu ~10:30-11:00','J4-contre-attaque'),
 ('EV-0604-1022-KAGA','1942-06-04T10:22:00-12:00',2,'hit','USN','VS-6 + VB-6 (McClusky) plongent: Kaga touché 4-5 bombes (10:22-10:26) — hangars pleins de munitions: incendies incontrôlables','J4-contre-attaque'),
 ('EV-0604-1026-AKAGI','1942-06-04T10:26:00-12:00',2,'hit','USN','Section Best (3 SBD VB-6): 1 coup fatal sur l''Akagi (ascenseur central, hangar) + 1 near-miss arrière qui bloque le gouvernail? — incendies','J4-contre-attaque'),
 ('EV-0604-1025-SORYU','1942-06-04T10:25:00-12:00',2,'hit','USN','VB-3 (Leslie): 3 coups sur le Sōryū — en flammes, stoppé à 10:40','J4-contre-attaque'),
 ('EV-0604-1046-NAGARA','1942-06-04T10:46:00-12:00',10,'other','IJN','Nagumo évacue l''Akagi et transfère sa marque sur le Nagara; Abe (CruDiv 8) commande l''intérim','J4-contre-attaque');

-- ------------------------------------------------------------
-- 4 JUIN — riposte du Hiryū et perte du Yorktown
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-1054-HIRYU1','1942-06-04T10:54:00-12:00',5,'launch_start','IJN','Hiryū lance sa 1re frappe: 18 D3A + 6 A6M (Kobayashi), guidés en suivant les avions US au retour','J4-hiryu'),
 ('EV-0604-1152-RADAR','1942-06-04T11:52:00-12:00',5,'sighting','USN','Radar du Yorktown détecte le raid à ~32 nm; CAP renforcée, ravitaillement coupé, SBD éloignés du navire','J4-hiryu'),
 ('EV-0604-1205-KOBAYASHI','1942-06-04T12:05:00-12:00',8,'attack','IJN','Attaque Kobayashi (7 D3A passent la CAP): 3 bombes touchent le Yorktown (12:11-12:16); chaudières stoppées; Kobayashi tué','J4-hiryu'),
 ('EV-0604-1330-YKREPAIR','1942-06-04T13:40:00-12:00',15,'other','USN','Yorktown remis en route ~19 nds, incendies maîtrisés — si bien réparé que la 2e frappe le croira intact (« 2e porte-avions »)','J4-hiryu'),
 ('EV-0604-1331-HIRYU2','1942-06-04T13:31:00-12:00',5,'launch_start','IJN','Hiryū lance sa 2e frappe: 10 B5N + 6 A6M (Tomonaga, réservoir gauche non réparé — aller simple assumé)','J4-hiryu'),
 ('EV-0604-1430-TOMOATK','1942-06-04T14:30:00-12:00',8,'attack','IJN','Attaque Tomonaga: 2 torpilles touchent le Yorktown (~14:43); gîte 23°; Tomonaga abattu','J4-hiryu'),
 ('EV-0604-1445-ADAMS','1942-06-04T14:45:00-12:00',5,'sighting','USN','SBD de VS-5 (Adams, recherche lancée 13:30) localise le Hiryū: "1 CV, 2 BB, 3 CA, 4 DD, 31°15''N 179°05''W"','J4-hiryu'),
 ('EV-0604-1500-ABANDON','1942-06-04T15:00:00-12:00',10,'other','USN','Buckmaster ordonne l''évacuation du Yorktown (crainte de chavirage)','J4-hiryu'),
 ('EV-0604-1530-E6LAUNCH','1942-06-04T15:30:00-12:00',10,'launch_start','USN','Enterprise lance 24 SBD (dont 10 ex-VB-3 du Yorktown) sur le Hiryū','J4-hiryu'),
 ('EV-0604-1701-HIRYUHIT','1942-06-04T17:01:00-12:00',5,'hit','USN','4 bombes sur le Hiryū (avant, ascenseur projeté contre l''îlot); incendies généralisés; attaque Hornet (17:30) et B-17 sans résultat ensuite','J4-hiryu'),
 ('EV-0604-1913-SORYUSINK','1942-06-04T19:13:00-12:00',5,'sinking','IJN','Le Sōryū coule (torpilles de l''Isokaze); Yanagimoto reste à bord (~711 morts)','J4-soir'),
 ('EV-0604-1925-KAGASINK','1942-06-04T19:25:00-12:00',5,'sinking','IJN','Le Kaga coule (torpilles du Hagikaze) (~811 morts — la plus lourde perte humaine des 4 CV)','J4-soir'),
 ('EV-0604-1915-SPRUANCE','1942-06-04T19:07:00-12:00',15,'decision','USN','Spruance refuse la poursuite à l''ouest de nuit et fait route à l''est jusqu''à minuit — évite la tentative d''engagement nocturne de Yamamoto','J4-soir');

-- ------------------------------------------------------------
-- 5 JUIN — retraite japonaise
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0605-0015-YAMANIGHT','1942-06-05T00:15:00-12:00',30,'decision','IJN','Yamamoto ordonne le regroupement pour un engagement de nuit / bombardement de Midway par CruDiv 7 — puis y renonce','J5-retraite'),
 ('EV-0605-0215-TAMBOR','1942-06-05T02:15:00-12:00',10,'sighting','both','Le Tambor est aperçu par CruDiv 7; ordre de virage d''urgence simultané','J5-retraite'),
 ('EV-0605-0223-COLLISION','1942-06-05T02:23:00-12:00',10,'collision','IJN','Le Mogami éperonne le Mikuma: proue détruite, vitesse réduite à ~12 nds; les deux croiseurs + 2 DD restent en arrière','J5-retraite'),
 ('EV-0605-0255-CANCEL','1942-06-05T02:55:00-12:00',15,'decision','IJN','Yamamoto annule l''opération MI; retraite générale','J5-retraite'),
 ('EV-0605-0500-AKAGISINK','1942-06-05T05:00:00-12:00',20,'scuttling','IJN','L''Akagi est sabordé (torpilles de 4 destroyers), coule ~05:20','J5-retraite'),
 ('EV-0605-0510-HIRYUSCUTTLE','1942-06-05T05:10:00-12:00',15,'scuttling','IJN','Le Makigumo torpille le Hiryū (Kaku et Yamaguchi restent à bord); il flotte encore des heures — photographié par un B4Y du Hōshō, des survivants seront repêchés','J5-retraite'),
 ('EV-0605-0800-FLEMING','1942-06-05T08:05:00-12:00',10,'attack','USN','VMSB-241 attaque Mogami/Mikuma; le SBD de Fleming s''écrase sur la tourelle arrière du Mikuma','J5-retraite'),
 ('EV-0605-0912-HIRYUSINK','1942-06-05T09:12:00-12:00',10,'sinking','IJN','Le Hiryū coule','J5-retraite'),
 ('EV-0605-1800-TANIKAZE','1942-06-05T18:00:00-12:00',20,'attack','USN','~58 SBD de TF-16 (puis B-17) attaquent le Tanikaze, seul — aucun coup; il abat 1 SBD','J5-retraite');

-- ------------------------------------------------------------
-- 6-7 JUIN — poursuite et perte du Yorktown
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0606-0800-STRIKE1','1942-06-06T08:00:00-12:00',15,'attack','USN','1re des 3 frappes de TF-16 sur Mogami/Mikuma (~26 SBD Hornet); coups sur les deux croiseurs','J6-poursuite'),
 ('EV-0606-1045-STRIKE2','1942-06-06T10:45:00-12:00',15,'attack','USN','2e frappe (31 SBD Enterprise): Mikuma dévasté, Mogami et DD touchés','J6-poursuite'),
 ('EV-0606-1330-STRIKE3','1942-06-06T13:30:00-12:00',15,'attack','USN','3e frappe (24 SBD Hornet): achève le Mikuma (coule dans la soirée); Mogami s''échappe vers Truk','J6-poursuite'),
 ('EV-0606-1336-I168','1942-06-06T13:36:00-12:00',5,'hit','IJN','I-168 (Tanabe) torpille à travers l''écran: 2 torpilles dans le Yorktown, 1 dans le Hammann (coule en 4 min, explosion de ses grenades ASM)','J6-poursuite'),
 ('EV-0606-1900-MIKUMASINK','1942-06-06T19:30:00-12:00',60,'sinking','IJN','Le Mikuma coule (première perte de croiseur lourd IJN)','J6-poursuite'),
 ('EV-0607-0701-YKSINK','1942-06-07T07:01:00-12:00',30,'sinking','USN','Le Yorktown chavire et coule à l''aube','J7-fin');

-- ------------------------------------------------------------
-- PARTICIPANTS des événements clés (échantillon dense)
-- ------------------------------------------------------------
INSERT INTO event_participants VALUES
 ('EV-0604-0430-LAUNCH','ships','SH-AKAGI','actor'),('EV-0604-0430-LAUNCH','ships','SH-KAGA','actor'),
 ('EV-0604-0430-LAUNCH','ships','SH-SORYU','actor'),('EV-0604-0430-LAUNCH','ships','SH-HIRYU','actor'),
 ('EV-0604-0500-TONE4UP','ships','SH-TONE','actor'),('EV-0604-0500-TONE4UP','squadrons','SQ-TONE-RECON','actor'),
 ('EV-0604-0534-ADY','squadrons','SQ-PBY-MIDWAY','observer'),('EV-0604-0534-ADY','formations','KIDO-BUTAI','target'),
 ('EV-0604-0552-2CV','squadrons','SQ-PBY-MIDWAY','observer'),
 ('EV-0604-1002-MCCLUSKY','squadrons','SQ-VB6','observer'),('EV-0604-1002-MCCLUSKY','formations','KIDO-BUTAI','target'),
 ('EV-0604-0616-VMF221','squadrons','SQ-VMF221-F2A','actor'),('EV-0604-0616-VMF221','squadrons','SQ-VMF221-F4F','actor'),
 ('EV-0604-0630-MIDWAYHIT','ships','SH-MIDWAY','target'),
 ('EV-0604-0706-TF16LAUNCH','ships','SH-CV6','actor'),('EV-0604-0706-TF16LAUNCH','ships','SH-HORNET','actor'),
 ('EV-0604-0710-TBFB26','squadrons','SQ-VT8-DET','actor'),('EV-0604-0710-TBFB26','squadrons','SQ-B26-DET','actor'),
 ('EV-0604-0715-D1','persons','PR-NAGUMO','decider'),('EV-0604-0745-D2','persons','PR-NAGUMO','decider'),
 ('EV-0604-0855-D3','persons','PR-NAGUMO','decider'),('EV-0604-0855-D3','persons','PR-YAMAGUCHI','actor'),
 ('EV-0604-0838-TF17LAUNCH','ships','SH-CV5','actor'),
 ('EV-0604-0920-VT8','squadrons','SQ-VT8','actor'),('EV-0604-0938-VT6','squadrons','SQ-VT6','actor'),
 ('EV-0604-1000-VT3','squadrons','SQ-VT3','actor'),('EV-0604-1000-VT3','squadrons','SQ-VF3','actor'),
 ('EV-0604-0955-MCCLUSKY','persons','PR-MCCLUSKY','decider'),('EV-0604-0955-MCCLUSKY','ships','SH-ARASHI','observer'),
 ('EV-0604-1022-KAGA','squadrons','SQ-VS6','actor'),('EV-0604-1022-KAGA','squadrons','SQ-VB6','actor'),('EV-0604-1022-KAGA','ships','SH-KAGA','target'),
 ('EV-0604-1026-AKAGI','squadrons','SQ-VB6','actor'),('EV-0604-1026-AKAGI','ships','SH-AKAGI','target'),('EV-0604-1026-AKAGI','persons','PR-BEST','actor'),
 ('EV-0604-1025-SORYU','squadrons','SQ-VB3','actor'),('EV-0604-1025-SORYU','ships','SH-SORYU','target'),
 ('EV-0604-1054-HIRYU1','ships','SH-HIRYU','actor'),('EV-0604-1054-HIRYU1','persons','PR-KOBAYASHI','actor'),
 ('EV-0604-1205-KOBAYASHI','ships','SH-CV5','target'),
 ('EV-0604-1331-HIRYU2','ships','SH-HIRYU','actor'),('EV-0604-1331-HIRYU2','persons','PR-TOMONAGA','actor'),
 ('EV-0604-1430-TOMOATK','ships','SH-CV5','target'),
 ('EV-0604-1445-ADAMS','squadrons','SQ-VS5','observer'),('EV-0604-1445-ADAMS','ships','SH-HIRYU','target'),
 ('EV-0604-1701-HIRYUHIT','ships','SH-HIRYU','target'),('EV-0604-1701-HIRYUHIT','squadrons','SQ-VB6','actor'),('EV-0604-1701-HIRYUHIT','squadrons','SQ-VS6','actor'),
 ('EV-0605-0215-TAMBOR','ships','SH-TAMBOR','actor'),('EV-0605-0223-COLLISION','ships','SH-MOGAMI','actor'),('EV-0605-0223-COLLISION','ships','SH-MIKUMA','target'),
 ('EV-0606-1336-I168','ships','SH-I168','actor'),('EV-0606-1336-I168','ships','SH-CV5','target'),('EV-0606-1336-I168','ships','SH-HAMMANN','target');

-- ------------------------------------------------------------
-- MESSAGES clés (délais de transmission = donnée de simulation)
-- ------------------------------------------------------------
INSERT INTO messages VALUES
 ('MSG-0604-0700-TOMONAGA','1942-06-04T07:00:00-12:00','1942-06-04T07:00:00-12:00','PR-TOMONAGA','PR-NAGUMO','radio','Une deuxième attaque sur Midway est nécessaire','Déclencheur de D1'),
 ('MSG-0604-0607-FLETCHER','1942-06-04T06:07:00-12:00','1942-06-04T06:07:00-12:00','PR-FLETCHER','PR-SPRUANCE','radio','Proceed southwesterly and attack enemy carriers when definitely located',NULL),
 ('MSG-0604-0830-YAMAGUCHI','1942-06-04T08:30:00-12:00','1942-06-04T08:30:00-12:00','PR-YAMAGUCHI','PR-NAGUMO','blinker','Considère souhaitable de lancer la force d''attaque immédiatement','Signal projecteur du Hiryū — la route non prise (contre-factuel majeur)');

-- 2e rapport décisif du Tone n°4 (complète CR-TONE4-0728 de l'amorce)
INSERT INTO contact_reports VALUES
 ('CR-TONE4-0820','squadrons','SQ-TONE-RECON','1942-06-04T08:20:00-12:00','1942-06-04T08:20:00-12:00','1942-06-04T08:30:00-12:00',
  'PR-NAGUMO',NULL,NULL,'L''ennemi est accompagné de ce qui semble être un porte-avions (suivi 08:30: +2 croiseurs)',
  'EV-0604-0820-CARRIER',NULL,'Identification tardive et hésitante: la qualité du rapport est elle-même un paramètre de simulation'),
 ('CR-0604-0552-PBY','squadrons','SQ-PBY-MIDWAY','1942-06-04T05:52:00-12:00','1942-06-04T05:52:00-12:00','1942-06-04T06:03:00-12:00',
  'PR-FLETCHER',NULL,NULL,'2 carriers and battleships bearing 320 distance 180 course 135 speed 25',
  'EV-0604-0552-2CV',35,'Erreur de position ~30-40 nm: contribue au vol pour rien du Hornet; seuls 2 CV signalés sur 4'),
 ('CR-0604-1445-ADAMS','squadrons','SQ-VS5','1942-06-04T14:45:00-12:00','1942-06-04T14:45:00-12:00','1942-06-04T14:50:00-12:00',
  'PR-SPRUANCE',31.25,-179.083,'1 CV, 2 BB, 3 CA, 4 DD, cap nord, 31°15''N 179°05''W',
  'EV-0604-1445-ADAMS',NULL,'Le rapport qui permet la frappe fatale sur le Hiryū');

-- ------------------------------------------------------------
-- DÉCISIONS instrumentées (support F3) — complète DC-NAGUMO-D1
-- ------------------------------------------------------------
INSERT INTO decisions VALUES
 ('DC-IJN-D0-SEARCH','1942-06-04T04:30:00-12:00','PR-NAGUMO','EV-0604-0430-SEARCH',
  'Plan de recherche du matin: 7 appareils, une seule phase, secteurs E à S',
  'A: recherche monophasée légère (7 appareils); B: recherche biphasée dense (doctrine post-Midway); C: retarder la frappe Midway jusqu''au retour des recherches',
  'Option A','Doctrine offensive: la reconnaissance ne doit pas amputer la force de frappe; aucune présence US attendue',
  'Couverture tardive et lacunaire du secteur NE; le retard du Tone n°4 aggrave; détection des TF US ~2h trop tard',
  'Le contre-factuel le plus discuté avec D3',NULL),
 ('DC-IJN-D2-SUSPEND','1942-06-04T07:45:00-12:00','PR-NAGUMO','EV-0604-0745-D2',
  'Suspendre le réarmement vers bombes terrestres après le rapport "10 navires"',
  'A: suspendre et attendre confirmation; B: poursuivre le réarmement Midway; C: tout basculer immédiatement anti-navire',
  'Option A','Rapport ambigu (pas de PA signalé); frappe Midway jugée encore nécessaire',
  'Hangars en double configuration, munitions non rangées — vulnérabilité maximale à 10:22',NULL,NULL),
 ('DC-IJN-D3-RECOVER','1942-06-04T08:55:00-12:00','PR-NAGUMO','EV-0604-0855-D3',
  'Récupérer la frappe Tomonaga avant de lancer contre les PA US (vs proposition Yamaguchi 08:30)',
  'A: récupérer d''abord, frapper ~10:30 en force constituée; B: lancer immédiatement les D3A disponibles sans escorte complète ni torpilleurs (Yamaguchi); C: lancer une frappe partielle escortée et récupérer ensuite',
  'Option A','Doctrine de la frappe massive coordonnée; sacrifier Tomonaga (amerrissages) jugé inacceptable; attaques US continues empêchent tout spot serein',
  'La frappe n''est jamais lancée: les SBD arrivent à 10:22. L''option B est LE grand contre-factuel japonais',
  'État réel des ponts/hangars 08:30-10:20 reconstruit par Parshall & Tully contre le récit Fuchida',NULL),
 ('DC-IJN-D4-HIRYU1','1942-06-04T10:50:00-12:00','PR-YAMAGUCHI','EV-0604-1054-HIRYU1',
  'Lancer immédiatement les 18 D3A du Hiryū sur le porte-avions US localisé',
  'A: frapper immédiatement avec ce qui est prêt; B: attendre et constituer une frappe coordonnée D3A+B5N',
  'Option A','Riposte immédiate seule chance de réduire l''écart (1 CV vs 3 signalés progressivement)',
  'Yorktown neutralisé (croyance: coulé); mais frappes successives diluées = Hiryū à sec d''appareils le soir',NULL,NULL),
 ('DC-IJN-D5-TOMONAGA','1942-06-04T13:25:00-12:00','PR-YAMAGUCHI','EV-0604-1331-HIRYU2',
  'Lancer la 2e frappe avec Tomonaga malgré son réservoir non réparé',
  'A: lancer avec Tomonaga (aller simple); B: remplacer l''appareil/le pilote; C: attendre la réparation',
  'Option A','Urgence; Tomonaga refuse de céder sa place',
  '2 torpilles dans le Yorktown; Tomonaga tué',NULL,NULL),
 ('DC-IJN-D6-NIGHT','1942-06-05T00:15:00-12:00','PR-YAMAMOTO','EV-0605-0015-YAMANIGHT',
  'Tenter un engagement de nuit puis annuler l''opération (02:55)',
  'A: regrouper pour bataille de nuit + bombardement de Midway; B: retraite immédiate; C: poursuivre l''invasion sans couverture aérienne',
  'A puis B','Espoir de rattraper TF-16 de nuit; impossible une fois la position US (à l''est) comprise',
  'La retraite sauve le reste de la flotte; CruDiv 7 exposée par l''ordre puis contre-ordre de bombardement',NULL,NULL),
 ('DC-USN-U1-AMBUSH','1942-06-02T12:00:00-12:00','PR-NIMITZ',NULL,
  'Embuscade au "Point Luck" NE de Midway sur la foi du renseignement HYPO (avant-bataille)',
  'A: pré-positionner TF-16/17 au NE (flanc de la KB prévue); B: garder les PA près de Hawaï; C: défense rapprochée de Midway',
  'Option A','Décryptage JN-25: date, cible et axe d''approche connus; Nimitz accepte le risque sur un renseignement non confirmé',
  'Position de flanquement parfaite le 4 juin au matin','Hors fenêtre 3-7 juin mais conditionne tout: à modéliser comme état initial',NULL),
 ('DC-USN-U2-LAUNCH','1942-06-04T07:00:00-12:00','PR-SPRUANCE','EV-0604-0706-TF16LAUNCH',
  'Lancer à ~155 nm (portée limite des TBD) dès 07:00 au lieu d''attendre de réduire la distance',
  'A: lancer tôt et loin (attraper la KB pendant sa récupération); B: fermer la distance 1-2h puis frapper groupé; C: attendre la localisation des 2 CV manquants',
  'Option A','Conseil de Browning: frapper la KB au moment de la récupération de la frappe Midway; risque carburant accepté',
  'Timing finalement parfait (10:22) mais au prix d''un raid décousu et de pertes par panne sèche (VF-6, VT)',NULL,NULL),
 ('DC-USN-U3-PIECEMEAL','1942-06-04T07:45:00-12:00','PR-SPRUANCE',NULL,
  'Envoyer les SBD de l''Enterprise sans attendre le regroupement complet ("proceed on mission assigned")',
  'A: envoyer les escadrilles au fur et à mesure; B: orbiter pour constituer un raid coordonné',
  'Option A','Le lancement prend trop de temps; chaque minute compte',
  'Attaques non coordonnées (les VT seuls = massacre) MAIS séquencement accidentel qui sature la CAP: le grand paradoxe de Midway',NULL,NULL),
 ('DC-USN-U4-RING','1942-06-04T07:55:00-12:00','PR-RING',NULL,
  'Cap de sortie du groupe aérien du Hornet (240 officiel vs ~265 reconstruit)',
  'A: cap ~239-240 vers la position rapportée; B: cap ~265 ouest (hypothèse: chercher les 2 CV manquants au NO)',
  'Option B (selon reconstructions) — rapport officiel: A','Controverse: Mitscher/Ring vs témoignages des pilotes',
  'VB-8/VS-8/VF-8 manquent tout; VT-8 (Waldron désobéit et vire seul vers la KB) anéanti sans soutien',
  'Controverse historiographique majeure — modéliser les DEUX caps en F3',NULL),
 ('DC-USN-U5-MCCLUSKY','1942-06-04T09:55:00-12:00','PR-MCCLUSKY','EV-0604-0955-MCCLUSKY',
  'Prolonger la recherche au-delà du point estimé puis virer NO sur le sillage de l''Arashi',
  'A: continuer/élargir la recherche (carburant limite); B: rentrer; C: descendre sur Midway',
  'Option A','La KB a forcément manœuvré; le sillage du destroyer isolé est un indice de direction',
  'Arrivée simultanée avec VB-3 par pur hasard heureux: 3 CV frappés en 4 min',NULL,NULL),
 ('DC-USN-U6-VS5','1942-06-04T08:38:00-12:00','PR-FLETCHER','EV-0604-0838-TF17LAUNCH',
  'Retenir VS-5 à bord du Yorktown en réserve de reconnaissance/frappe',
  'A: garder la moitié des SBD (2 CV japonais non localisés); B: tout engager',
  'Option A','Leçon de Coral Sea: garder de quoi voir et frapper une force non localisée',
  'C''est VS-5 qui retrouve le Hiryū à 14:45 — la réserve paie',NULL,NULL),
 ('DC-USN-U7-NOPURSUIT','1942-06-04T19:07:00-12:00','PR-SPRUANCE','EV-0604-1915-SPRUANCE',
  'Refuser la poursuite vers l''ouest pendant la nuit du 4 au 5',
  'A: route est jusqu''à minuit puis retour; B: poursuite plein ouest (gagner du terrain pour frapper à l''aube)',
  'Option A','Risque de tomber de nuit sur des cuirassés/torpilles (c''était exactement le plan de Yamamoto); mission = défendre Midway',
  'Évite le piège; critiqué à l''époque, validé depuis',NULL,NULL),
 ('DC-USN-U8-SALVAGE','1942-06-05T12:00:00-12:00','PR-BUCKMASTER',NULL,
  'Retourner à bord du Yorktown abandonné pour le sauver (remorquage Vireo, équipe réduite, Hammann à couple)',
  'A: équipe de sauvetage + remorquage vers Pearl; B: saborder; C: remorquage sans équipe à bord',
  'Option A','Le navire flotte toujours après 36h; valeur stratégique énorme d''un 3e PA réparé',
  'I-168 le trouve le 6: Yorktown et Hammann perdus avec l''équipe à bord',NULL,NULL);

-- ------------------------------------------------------------
-- CLAIMS sur les heures critiques (échantillon de vérification)
-- ------------------------------------------------------------
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-0534-ADY','ts','1942-06-04T05:34:00-12:00','0534','SRC-CINCPAC-01849',1,'verified','Concorde Lundstrom/Cressman'),
 ('events','EV-0604-0715-D1','ts','1942-06-04T07:15:00-12:00','0415 (h. Tokyo)','SRC-NAGUMO-REPORT',1,'verified','Conversion -21h; concorde Shattered Sword'),
 ('events','EV-0604-0820-CARRIER','ts','1942-06-04T08:20:00-12:00','0520 (h. Tokyo)','SRC-NAGUMO-REPORT',1,'verified',NULL),
 ('events','EV-0604-1054-HIRYU1','ts','1942-06-04T10:54:00-12:00',NULL,'SRC-SHATTERED-SWORD',1,'single_source','Recouper rapport Nagumo'),
 ('events','EV-0604-1205-KOBAYASHI','ts','1942-06-04T12:05:00-12:00',NULL,'SRC-YORKTOWN-AR',1,'single_source','Fenêtre 12:05-12:20; heures des 3 impacts à préciser'),
 ('events','EV-0604-1701-HIRYUHIT','ts','1942-06-04T17:01:00-12:00',NULL,'SRC-SHATTERED-SWORD',1,'single_source',NULL),
 ('events','EV-0605-0223-COLLISION','ts','1942-06-05T02:23:00-12:00',NULL,'SRC-SHATTERED-SWORD',1,'single_source','Heure approx.; recouper TROM combinedfleet'),
 ('events','EV-0606-1336-I168','ts','1942-06-06T13:36:00-12:00','1336','SRC-CINCPAC-01849',1,'verified','Concorde récit Tanabe'),
 ('events','EV-0607-0701-YKSINK','ts','1942-06-07T07:01:00-12:00','0701','SRC-CINCPAC-01849',1,'single_source','Certaines sources: ~05:30 début de chavirage');

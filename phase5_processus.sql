-- ============================================================
-- PHASE 5 : la physique de l'ordonnancement
-- Durées = valeurs de travail (min/typ/max) informées par
-- Shattered Sword (opérations de pont japonaises) et les action
-- reports US. Chacune est un paramètre de calibrage, pas un fait.
-- ============================================================

-- ------------------------------------------------------------
-- 1. CONTRAINTES DE PLATEFORME (complétion des champs opérationnels)
-- ------------------------------------------------------------
-- IJN: réarmement en hangar uniquement, ascenseurs = goulot
UPDATE carrier_constraints SET elevator_cycle_s=90, max_spot=30, arming_crews=10, fueling_crews=8,
  launch_interval_s=20, recovery_interval_s=35, hangar_capacity=66
 WHERE ship_id='SH-AKAGI';
UPDATE carrier_constraints SET elevator_cycle_s=90, max_spot=30, arming_crews=10, fueling_crews=8,
  launch_interval_s=20, recovery_interval_s=35, hangar_capacity=72
 WHERE ship_id='SH-KAGA';
UPDATE carrier_constraints SET elevator_cycle_s=80, max_spot=24, arming_crews=8, fueling_crews=6,
  launch_interval_s=20, recovery_interval_s=35, hangar_capacity=57
 WHERE ship_id='SH-SORYU';
UPDATE carrier_constraints SET elevator_cycle_s=80, max_spot=24, arming_crews=8, fueling_crews=6,
  launch_interval_s=20, recovery_interval_s=35, hangar_capacity=57
 WHERE ship_id='SH-HIRYU';
-- USN: réarmement/avitaillement possibles sur le pont, parc avant
UPDATE carrier_constraints SET elevator_cycle_s=75, max_spot=36, arming_crews=12, fueling_crews=10,
  launch_interval_s=28, recovery_interval_s=50, hangar_capacity=80
 WHERE ship_id IN ('SH-CV6','SH-HORNET','SH-CV5');

-- Claims de traçabilité sur ces estimations
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('carrier_constraints','SH-AKAGI','ops_params','elevator 90s / spot 30 / launch 20s / recovery 35s','SRC-SHATTERED-SWORD',1,'estimated','Ordres de grandeur des annexes opérations de pont; à affiner par les récits de cycle réels du 4 juin'),
 ('carrier_constraints','SH-CV6','ops_params','elevator 75s / spot 36 / launch 28s / recovery 50s','SRC-ENTERPRISE-AR',1,'estimated','Déduits des durées de lancement observées (33 SBD en ~25-30 min)');

-- ------------------------------------------------------------
-- 2. GABARITS DE PROCESSUS (complément)
-- ------------------------------------------------------------
INSERT INTO process_templates VALUES
 ('PT-SPOT-IJN','Spot d''une frappe de pont complet (IJN)','CV japonais','Remontée hangar->pont + positionnement + chauffe moteurs; le pont est indisponible pour la CAP pendant toute l''opération',NULL),
 ('PT-LAUNCH-IJN','Lancement d''une frappe spottée (IJN)','CV japonais',NULL,NULL),
 ('PT-RECOVER-IJN','Récupération d''une escadrille (IJN)','CV japonais','Inclut le dégagement des appareils (descente hangar — pas de parc avant durable en opérations)',NULL),
 ('PT-CAP-CYCLE-IJN','Rotation CAP (A6M2)','CV japonais','Récupération, plein, recomplet 20 mm, relancement; cycle entier consomme le pont',NULL),
 ('PT-REARM-D3A','Réarmement D3A (bombe 250 kg)','D3A1 / CV japonais (hangar)',NULL,NULL),
 ('PT-DECK-USN','Cycle de pont US (spot + lancement deckload)','CV américains','Réarmement possible sur le pont; deckload complet puis lancement déferré',NULL),
 ('PT-REFUEL-SQ','Avitaillement d''une escadrille (12-18 appareils)','tous','Parallélisable avec le réarmement (équipes distinctes) sauf consigne sécurité',NULL);

INSERT INTO process_steps (template_id,seq,name,duration_min_s,duration_typ_s,duration_max_s,resources,source_id,notes) VALUES
 -- B5N : bombe -> torpille (ordre D2, l'inverse de T2B) — PLUS LENT
 ('PT-REARM-B5N-B2T',1,'Dépose bombe 800 kg',180,300,480,'arming_crew',NULL,NULL),
 ('PT-REARM-B5N-B2T',2,'Remontée des torpilles des soutes (palans)',300,480,900,'arming_crew','SRC-SHATTERED-SWORD','Goulot principal: les Type 91 ne sont pas pré-positionnées'),
 ('PT-REARM-B5N-B2T',3,'Installation et réglage torpille',300,420,720,'arming_crew',NULL,'Réglages d''immersion/gyroscope'),
 ('PT-REARM-B5N-B2T',4,'Contrôles + arrimage',180,240,420,'arming_crew',NULL,NULL),
 ('PT-REARM-B5N-B2T',5,'Rangement des bombes déposées',120,300,600,'arming_crew',NULL,'ÉTAPE SAUTÉE le 4 juin: bombes laissées en hangar = cause majeure des incendies fatals'),
 -- Spot frappe complète IJN
 ('PT-SPOT-IJN',1,'Remontée des appareils (3 ascenseurs en parallèle)',900,1200,1800,'elevator',NULL,'~30-40 cycles de 80-90 s répartis sur 3 ascenseurs'),
 ('PT-SPOT-IJN',2,'Positionnement/saisinage sur le pont',600,900,1200,'deck',NULL,NULL),
 ('PT-SPOT-IJN',3,'Chauffe moteurs + montée équipages',600,900,1200,'deck',NULL,'Recouvre partiellement l''étape 2'),
 -- Lancement
 ('PT-LAUNCH-IJN',1,'Mise face au vent (manœuvre du navire)',180,300,600,'deck',NULL,'Vent faible le 4 juin: course à pleine vitesse requise'),
 ('PT-LAUNCH-IJN',2,'Décollages (intervalle 15-25 s/avion)',420,600,900,'deck',NULL,'Pour ~30 appareils'),
 -- Récupération
 ('PT-RECOVER-IJN',1,'Mise face au vent + dispositif',180,300,600,'deck',NULL,NULL),
 ('PT-RECOVER-IJN',2,'Appontages (30-45 s/avion)',540,720,1200,'deck',NULL,'Pour ~18 appareils; un crash bloque le pont 5-20 min'),
 ('PT-RECOVER-IJN',3,'Dégagement vers le hangar',600,900,1500,'elevator',NULL,NULL),
 -- CAP
 ('PT-CAP-CYCLE-IJN',1,'Récupération section (3-9 avions)',180,300,600,'deck',NULL,NULL),
 ('PT-CAP-CYCLE-IJN',2,'Plein + recomplet 20 mm (sur le pont)',600,900,1500,'deck,fueling_crew,arming_crew',NULL,'60 obus/canon seulement: les Zeros épuisent les 20 mm en 1-2 passes'),
 ('PT-CAP-CYCLE-IJN',3,'Relancement',120,180,300,'deck',NULL,NULL),
 -- Réarmement D3A
 ('PT-REARM-D3A',1,'Cycle complet bombe 250 kg + plein',900,1500,2400,'arming_crew,fueling_crew',NULL,'Par avion, équipes complètes'),
 -- Cycle US
 ('PT-DECK-USN',1,'Spot deckload (parc arrière)',1200,1800,2700,'deck,elevator','SRC-ENTERPRISE-AR',NULL),
 ('PT-DECK-USN',2,'Lancement deckload (~30-35 appareils)',900,1500,2100,'deck',NULL,'~1h pour le groupe complet le 4 juin (lancement déferré: les premiers orbitent)'),
 ('PT-DECK-USN',3,'Réarmement sur le pont (par division)',900,1200,1800,'deck,arming_crew',NULL,'Avantage doctrinal US: pas de cycle ascenseur obligatoire'),
 -- Avitaillement escadrille
 ('PT-REFUEL-SQ',1,'Plein de 12-18 appareils',1200,1800,2700,'fueling_crew',NULL,'Purge des circuits avant combat = facteur de survie (les CV US purgaient au CO2)');

-- ------------------------------------------------------------
-- 3. AVARIES (damage_states) — l'état des navires dans le temps
-- ------------------------------------------------------------
INSERT INTO damage_states (ship_id,ts,event_id,description,speed_limit_kn,flight_ops,notes) VALUES
 ('SH-KAGA','1942-06-04T10:26:00-12:00','EV-0604-1022-KAGA','4-5 bombes; pont et hangars en feu; passerelle détruite (Okada tué); incendies incontrôlables',6,'impossible','Munitions non rangées en hangar = explosions en chaîne'),
 ('SH-AKAGI','1942-06-04T10:26:00-12:00','EV-0604-1026-AKAGI','1 bombe (ascenseur central -> hangar) + near-miss arrière; incendies hangar; gouvernail bloqué à 10:42',8,'impossible','Une seule bombe suffit: hangars pleins, avions avitaillés'),
 ('SH-SORYU','1942-06-04T10:28:00-12:00','EV-0604-1025-SORYU','3 bombes axiales; hangar soufflé; stoppé à 10:40; abandon 10:45',0,'impossible',NULL),
 ('SH-HIRYU','1942-06-04T17:05:00-12:00','EV-0604-1701-HIRYUHIT','4 bombes avant; ascenseur avant projeté contre l''îlot; incendies',28,'impossible','Machines intactes: file encore 28 nds des heures'),
 ('SH-CV5','1942-06-04T12:16:00-12:00','EV-0604-1205-KOBAYASHI','3 bombes: cheminée, ascenseur av., soute; chaudières stoppées',0,'impossible','CAP recueillie par l''Enterprise'),
 ('SH-CV5','1942-06-04T13:40:00-12:00',NULL,'Réparations: 4 chaudières relancées; en route 19 nds; pont opérationnel',19,'degraded','Si bien réparé que la 2e frappe japonaise le croit intact'),
 ('SH-CV5','1942-06-04T14:45:00-12:00','EV-0604-1430-TOMOATK','2 torpilles bâbord; gîte 23°; sans énergie',0,'impossible','Abandonné 15:00; flotte encore 2,5 jours'),
 ('SH-CV5','1942-06-06T13:38:00-12:00','EV-0606-1336-I168','2 torpilles supplémentaires (I-168)',0,'impossible','Chavire le 7 au matin'),
 ('SH-HAMMANN','1942-06-06T13:37:00-12:00','EV-0606-1336-I168','1 torpille; coule en 4 min; explosion des grenades ASM dans l''eau',0,'impossible','~80 morts'),
 ('SH-MOGAMI','1942-06-05T02:23:00-12:00','EV-0605-0223-COLLISION','Proue écrasée sur 12 m (collision Mikuma)',12,'impossible','Échappera malgré 5-6 bombes le 6'),
 ('SH-MIKUMA','1942-06-06T12:00:00-12:00','EV-0606-1045-STRIKE2','Bombes multiples; torpilles propres explosent; épave flottante',0,'impossible','Coule le soir'),
 ('SH-AKEBONO-MARU','1942-06-04T01:43:00-12:00','EV-0604-0143-PBYTORP','1 torpille à l''avant; 23 morts',8,'impossible','Reste avec le convoi');

-- ------------------------------------------------------------
-- 4. ÉTATS DES ESCADRILLES (squadron_status) — journée du 4 juin
--    Snapshots aux instants décisionnels. available = opérationnels.
-- ------------------------------------------------------------
INSERT INTO squadron_status (squadron_id,ts,location,current_ordnance_id,fuel_state,available,damaged,notes) VALUES
 -- ===== 04:45, après le lancement de la frappe Tomonaga =====
 ('SQ-AKAGI-KANBAKU','1942-06-04T04:45:00-12:00','airborne_strike','ORD-250KG','full',18,0,'Frappe Midway'),
 ('SQ-KAGA-KANBAKU','1942-06-04T04:45:00-12:00','airborne_strike','ORD-250KG','full',18,0,'Frappe Midway'),
 ('SQ-SORYU-KANKO','1942-06-04T04:45:00-12:00','airborne_strike','ORD-800KG','full',18,0,'Bombardement horizontal Midway'),
 ('SQ-HIRYU-KANKO','1942-06-04T04:45:00-12:00','airborne_strike','ORD-800KG','full',18,0,'Bombardement horizontal Midway'),
 ('SQ-AKAGI-KANKO','1942-06-04T04:45:00-12:00','hangar','ORD-TYPE91','full',18,0,'RÉSERVE anti-navire (torpilles)'),
 ('SQ-KAGA-KANKO','1942-06-04T04:45:00-12:00','hangar','ORD-TYPE91','full',27,0,'RÉSERVE anti-navire (torpilles)'),
 ('SQ-SORYU-KANBAKU','1942-06-04T04:45:00-12:00','hangar','ORD-250KG','full',16,0,'RÉSERVE anti-navire'),
 ('SQ-HIRYU-KANBAKU','1942-06-04T04:45:00-12:00','hangar','ORD-250KG','full',18,0,'RÉSERVE anti-navire'),
 ('SQ-AKAGI-KANSEN','1942-06-04T04:45:00-12:00','deck',NULL,'full',9,0,'9 en escorte Tomonaga; 9 en alerte CAP'),
 ('SQ-KAGA-KANSEN','1942-06-04T04:45:00-12:00','deck',NULL,'full',9,0,'9 en escorte; 9 alerte'),
 ('SQ-SORYU-KANSEN','1942-06-04T04:45:00-12:00','deck',NULL,'full',9,0,'9 en escorte; 9 alerte'),
 ('SQ-HIRYU-KANSEN','1942-06-04T04:45:00-12:00','deck',NULL,'full',9,0,'9 en escorte; 9 alerte'),
 ('SQ-6KU','1942-06-04T04:45:00-12:00','hangar',NULL,'full',21,0,'Engagés en CAP au fil de la matinée'),
 -- ===== 07:30, réarmement D1 en cours =====
 ('SQ-AKAGI-KANKO','1942-06-04T07:30:00-12:00','hangar','ORD-800KG','full',18,0,'RÉARMEMENT EN COURS torpilles->bombes (~1/3 fait); bombes ET torpilles présentes en hangar'),
 ('SQ-KAGA-KANKO','1942-06-04T07:30:00-12:00','hangar','ORD-800KG','full',27,0,'Idem; le plus gros volume à traiter'),
 ('SQ-AKAGI-KANSEN','1942-06-04T07:30:00-12:00','airborne_cap',NULL,'partial',11,0,'CAP renforcée (attaques TBF/B-26)'),
 ('SQ-KAGA-KANSEN','1942-06-04T07:30:00-12:00','airborne_cap',NULL,'partial',10,0,NULL),
 ('SQ-6KU','1942-06-04T07:30:00-12:00','airborne_cap',NULL,'partial',12,0,'Le harcèlement continu force des rotations permanentes'),
 -- ===== 09:30, après récupération de la frappe du matin =====
 ('SQ-AKAGI-KANBAKU','1942-06-04T09:30:00-12:00','hangar',NULL,'low',15,3,'De retour; plein + réarmement entamés'),
 ('SQ-KAGA-KANBAKU','1942-06-04T09:30:00-12:00','hangar',NULL,'low',13,4,'4 perdus/abîmés sur Midway'),
 ('SQ-SORYU-KANKO','1942-06-04T09:30:00-12:00','hangar',NULL,'low',16,2,NULL),
 ('SQ-HIRYU-KANKO','1942-06-04T09:30:00-12:00','hangar',NULL,'low',16,2,'Tomonaga: réservoir gauche percé'),
 ('SQ-AKAGI-KANKO','1942-06-04T09:30:00-12:00','hangar','ORD-TYPE91','full',18,0,'CONTRE-ORDRE D2: retour vers torpilles; configuration mixte, munitions non rangées'),
 ('SQ-KAGA-KANKO','1942-06-04T09:30:00-12:00','hangar','ORD-TYPE91','full',27,0,'Idem'),
 -- ===== 10:20, l'instant fatal (état contra-Fuchida) =====
 ('SQ-AKAGI-KANKO','1942-06-04T10:20:00-12:00','hangar','ORD-TYPE91','full',18,0,'EN HANGAR (pas sur le pont): spot prévu 10:30-11:00; bombes 800 kg encore non rangées'),
 ('SQ-KAGA-KANKO','1942-06-04T10:20:00-12:00','hangar','ORD-TYPE91','full',27,0,'Idem'),
 ('SQ-SORYU-KANBAKU','1942-06-04T10:20:00-12:00','hangar','ORD-250KG','full',16,0,'Prêts en hangar, en attente du pont (monopolisé par la CAP)'),
 ('SQ-HIRYU-KANBAKU','1942-06-04T10:20:00-12:00','hangar','ORD-250KG','full',18,0,'Idem'),
 ('SQ-AKAGI-KANSEN','1942-06-04T10:20:00-12:00','airborne_cap',NULL,'partial',8,0,'CAP entière au ras de l''eau (achève VT-3); ZÉRO couverture en altitude'),
 ('SQ-KAGA-KANSEN','1942-06-04T10:20:00-12:00','airborne_cap',NULL,'partial',9,0,NULL),
 ('SQ-SORYU-KANSEN','1942-06-04T10:20:00-12:00','airborne_cap',NULL,'partial',8,0,NULL),
 ('SQ-HIRYU-KANSEN','1942-06-04T10:20:00-12:00','airborne_cap',NULL,'partial',8,0,NULL),
 ('SQ-6KU','1942-06-04T10:20:00-12:00','airborne_cap',NULL,'low',10,0,NULL),
 -- ===== Hiryū seul, après-midi =====
 ('SQ-HIRYU-KANBAKU','1942-06-04T10:50:00-12:00','deck','ORD-250KG','full',18,0,'Spot de la 1re frappe (Kobayashi)'),
 ('SQ-HIRYU-KANBAKU','1942-06-04T13:30:00-12:00','hangar',NULL,'low',5,2,'13/18 perdus sur le Yorktown'),
 ('SQ-HIRYU-KANKO','1942-06-04T13:25:00-12:00','deck','ORD-TYPE91','full',10,2,'Spot 2e frappe (Tomonaga); le 11e part avec réservoir percé'),
 ('SQ-HIRYU-KANKO','1942-06-04T15:45:00-12:00','hangar',NULL,'low',5,1,'5/10 perdus; Hashimoto rapporte "2e CV touché"'),
 ('SQ-HIRYU-KANSEN','1942-06-04T16:45:00-12:00','airborne_cap',NULL,'low',12,0,'CAP composite (+ rescapés des 3 autres CV); submergée à 17:01'),
 -- ===== Côté US (Enterprise/Yorktown, instants clés) =====
 ('SQ-VT6','1942-06-04T08:00:00-12:00','airborne_strike','ORD-MK13','full',14,0,NULL),
 ('SQ-VB6','1942-06-04T08:06:00-12:00','airborne_strike','ORD-1000LB','full',15,0,'+2 SBD CEAG'),
 ('SQ-VS6','1942-06-04T08:06:00-12:00','airborne_strike','ORD-500LB','full',16,0,NULL),
 ('SQ-VF6','1942-06-04T08:06:00-12:00','airborne_cap',NULL,'full',17,0,'10 en escorte (perdent le contact), 17 CAP/pont par rotations'),
 ('SQ-VB6','1942-06-04T12:30:00-12:00','hangar',NULL,'low',6,2,'9 perdus (combat + pannes sèches)'),
 ('SQ-VS6','1942-06-04T12:30:00-12:00','hangar',NULL,'low',7,2,NULL),
 ('SQ-VB3','1942-06-04T12:30:00-12:00','deck',NULL,'low',15,2,'Déroutés sur l''Enterprise (Yorktown touché)'),
 ('SQ-VB6','1942-06-04T15:45:00-12:00','airborne_strike','ORD-1000LB','full',7,0,'2e sortie (frappe Hiryū)'),
 ('SQ-VS6','1942-06-04T15:45:00-12:00','airborne_strike','ORD-500LB','full',7,0,NULL),
 ('SQ-VB3','1942-06-04T15:45:00-12:00','airborne_strike','ORD-1000LB','full',10,0,'2e sortie depuis l''Enterprise'),
 ('SQ-VT8','1942-06-04T09:40:00-12:00','lost',NULL,'empty',0,0,'15/15 abattus; Ens. Gay seul survivant à l''eau'),
 ('SQ-VT6','1942-06-04T10:30:00-12:00','recovering',NULL,'low',4,1,'4 rescapés'),
 ('SQ-VT3','1942-06-04T10:40:00-12:00','lost',NULL,'low',2,2,'2 rescapés sur 12'),
 ('SQ-VF3','1942-06-04T11:00:00-12:00','recovering',NULL,'low',5,1,'Thach: 3 victoires revendiquées; Weave validé'),
 ('SQ-VS5','1942-06-04T13:30:00-12:00','airborne_search',NULL,'full',10,0,'L''éventail qui retrouvera le Hiryū à 14:45');

-- ------------------------------------------------------------
-- 5. PARAMÈTRES STOCHASTIQUES CALIBRÉS (constraint_params)
--    Pour le moteur F2/F3 — distributions, jamais des certitudes.
-- ------------------------------------------------------------
INSERT INTO constraint_params VALUES
 ('P-HIT-SBD-CV','combat','P(coup au but) par SBD attaquant en piqué un CV manœuvrant, CAP supprimée',0.19,'probabilité','triangular(0.10,0.19,0.30)','Calibré Midway 10:22-10:26: ~9 coups / ~47 SBD ayant attaqué; cohérent frappe Hiryū 4/24','SRC-SHATTERED-SWORD'),
 ('P-HIT-SBD-CA','combat','P(coup) par SBD vs croiseur manœuvrant',0.12,'probabilité','triangular(0.05,0.12,0.22)','Calibré 6 juin vs Mogami/Mikuma (~81 sorties, ~10-12 coups)','SRC-CINCPAC-01849'),
 ('P-HIT-MK13','combat','P(coup) torpille Mk13 lancée par TBD/TBF, CAP+DCA actives',0.00,'probabilité','beta(0.5,20)','0 coup / ~50 lancements à Midway; profil de largage suicidaire + duds; ne PAS extrapoler aux conditions calmes','SRC-CINCPAC-01849'),
 ('P-HIT-TYPE91','combat','P(coup) torpille Type 91 par B5N survivant jusqu''au largage',0.35,'probabilité','triangular(0.20,0.35,0.50)','2 coups / ~5-6 largages effectifs sur le Yorktown; équipages d''élite','SRC-SHATTERED-SWORD'),
 ('P-HIT-D3A','combat','P(coup) bombe D3A par appareil ayant percé la CAP',0.40,'probabilité','triangular(0.25,0.40,0.55)','3 coups / 7 D3A ayant attaqué le Yorktown (frappe Kobayashi)','SRC-YORKTOWN-AR'),
 ('P-HIT-LEVEL-B17','combat','P(coup) bombardement horizontal haute altitude vs navire manœuvrant',0.005,'probabilité','beta(0.5,80)','0 coup / ~80+ sorties B-17 sur la bataille','SRC-CINCPAC-01849'),
 ('P-CAP-KILL-TBD','combat','P(destruction) d''un TBD non escorté par passe de Zero',0.45,'probabilité','triangular(0.30,0.45,0.60)','VT-8: 15/15, VT-6: 10/14 — sur 10-20 min d''attaques répétées','SRC-FIRST-TEAM'),
 ('P-CAP-KILL-SBD','combat','P(destruction) d''un SBD par interception (avec mitrailleur arrière)',0.12,'probabilité','triangular(0.05,0.12,0.25)',NULL,'SRC-FIRST-TEAM'),
 ('P-AA-KILL-1942','combat','P(destruction) par la DCA d''un CV+escorte IJN, par passe d''attaque',0.05,'probabilité','triangular(0.02,0.05,0.10)','DCA japonaise 1942 notoirement faible (25 mm)','SRC-SHATTERED-SWORD'),
 ('P-COMM-DELAY-IJN','comms','Délai rapport hydravion -> décideur (émission->réception->décodage)',18,'minutes','triangular(8,18,40)','Tone n°4: émis 07:28, exploité ~07:45-08:00','SRC-NAGUMO-REPORT'),
 ('P-COMM-DELAY-USN','comms','Délai rapport PBY -> TF (via Midway/Pearl)',12,'minutes','triangular(5,12,30)','Rapport 05:52 exploité ~06:03-06:07','SRC-CINCPAC-01849'),
 ('P-RADIO-FAIL-A6M','comms','P(liaison radio inutilisable) chasseur A6M en CAP',0.8,'probabilité','triangular(0.6,0.8,0.95)','Coordination CAP quasi exclusivement visuelle = cause majeure de la saturation','SRC-SHATTERED-SWORD'),
 ('P-DETECT-PBY','detection','P(détection) par ligne de recherche PBY croisant une force navale, temps clair',0.65,'probabilité','triangular(0.4,0.65,0.85)','À moduler par la météo (cf. weather_obs)','SRC-CINCPAC-01849'),
 ('P-DETECT-FLOATPLANE','detection','P(détection) hydravion IJN croisant une TF, plafond nuageux',0.5,'probabilité','triangular(0.3,0.5,0.7)','Chikuma n°5 est passé près de TF-17 sans la voir','SRC-SHATTERED-SWORD'),
 ('P-FUEL-DD-PURSUIT','fuel','Autonomie restante moyenne des DD US au soir du 4 juin',0.45,'fraction','triangular(0.35,0.45,0.55)','Contrainte dure de la poursuite; les DD japonais étaient mieux lotis (pétroliers suivaient)','SRC-CINCPAC-01849');

-- ============================================================
-- PHASE 8a : dépouillement des rapports d'action primaires (ibiblio)
-- Enterprise CV-6 (Murray -> Nimitz) et Yorktown CV-5 (Buckmaster -> Nimitz).
-- Découverte de sourçage: les deux journaux sont en FUSEAU GMT-10
-- (heures du bord = heure de Midway + 2h). Toutes les valeurs d'origine
-- ci-dessous sont citées telles quelles, converties à la saisie.
-- ============================================================

UPDATE sources SET time_reference='GMT-10',
  notes='DÉCOUVERT AU DÉPOUILLEMENT: heures du bord en zone +10 (= Midway +2h). Ex: attaque du Hiryū consignée "1905" = 17:05 GMT-12.'
 WHERE source_id='SRC-ENTERPRISE-AR';
UPDATE sources SET time_reference='GMT-10',
  notes='Zone +10 comme l''Enterprise (torpillage consigné "about 1620" = ~14:20 GMT-12). Original notoirement désorganisé (avertissement ibiblio); lat/lon incohérentes par endroits.'
 WHERE source_id='SRC-YORKTOWN-AR';

-- ------------------------------------------------------------
-- Heures vérifiées par 2e source (rapports A)
-- ------------------------------------------------------------
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-1701-HIRYUHIT','ts','1942-06-04T17:01:00-12:00','1905 (zone +10)','SRC-ENTERPRISE-AR','narratif, entrée 1905',0,'verified','2 sources concordantes (SS + AR): VERIFIED'),
 ('events','EV-0604-1430-TOMOATK','ts','1942-06-04T14:30:00-12:00','about 1620 (zone +10)','SRC-YORKTOWN-AR','narratif torpillage',0,'verified','AR ~14:20 vs SS 14:30-14:45: concordant à ±10 min'),
 ('events','EV-0606-0645-SCOUT','ts','1942-06-06T06:45:00-12:00','0845 (zone +10)','SRC-ENTERPRISE-AR','entrée 0845: "8-B-2 contacted enemy, 1 CV, 5 DD"',1,'verified','L''heure estimée initialement (06:45) tombe EXACTEMENT sur l''entrée du journal: VERIFIED'),
 ('events','EV-0604-1445-ADAMS','ts','1942-06-04T14:45:00-12:00','citation: "1 CV, 2 CA, 4 DD... lat 31-15 N, long 179-05 W"','SRC-YORKTOWN-AR','section AIR',0,'verified','Le rapport Yorktown confirme mot pour mot composition et position du contact Adams');
UPDATE claims SET status='verified' WHERE entity_table='events' AND entity_id IN
 ('EV-0604-1701-HIRYUHIT','EV-0604-1430-TOMOATK') AND is_accepted=1;

-- ------------------------------------------------------------
-- Positions issues des rapports (fixes d'estime des pilotes, grade A
-- mais erreur intrinsèque ~10-20 nm)
-- ------------------------------------------------------------
-- Force du Hiryū à 17:05: "Lat. 31°-40' N, Long. 179°-10' W"
UPDATE positions SET lat=31.67, lon=-179.17, method='observed', position_error_nm=15,
  source_id='SRC-ENTERPRISE-AR',
  notes='Fix du rapport Enterprise (entrée 1905 zone +10): 31°40''N 179°10''W. Cohérent avec l''épave (dérive 19 nm/16h).'
 WHERE entity_id='SH-HIRYU' AND ts='1942-06-04T17:01:00-12:00';
UPDATE mission_legs SET end_lat=31.67, end_lon=-179.17 WHERE mission_id='MS-0604-E6PM' AND seq=1;
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('positions','SH-HIRYU','position_1701','31.67,-179.17','Lat. 31°-40'' N, Long. 179°-10'' W','SRC-ENTERPRISE-AR','entrée 1905',1,'verified','Concorde avec position épave (dérive plausible) — double ancrage'),
-- Position de la KB aux coups de 10:22 selon l'Enterprise: CONFLIT avec les épaves
 ('positions','KIDO-BUTAI','position_1022','30.55,-179.15','Lat. 30° 05'' N, Long. 178° 50'' W','SRC-ENTERPRISE-AR','synthèse attaque matin',0,'conflicting','Fix AR (estime pilotes après ~2h de vol) à ~35 nm au SE du faisceau des épaves. Les épaves (vérité terrain) priment: valeur acceptée inchangée. L''écart documente l''erreur d''estime aérienne US.'),
-- Naufrage du Yorktown: ERREUR DANS LA SOURCE PRIMAIRE (transposition probable)
 ('positions','SH-CV5','sinking_position','30.77,-176.40','Latitude 30°-46'' North, Longitude 167°-24'' West','SRC-YORKTOWN-AR','fin du narratif',1,'conflicting','167°24''W = ~500 nm E de Midway: PHYSIQUEMENT IMPOSSIBLE (remorquage Vireo 2-3 nds, 17h). Transposition probable de 176°24''W -> valeur acceptée 30°46''N 176°24''W. La latitude est conservée telle quelle. Cas d''école: une source A peut contenir une coquille; la physique arbitre.');
UPDATE positions SET lat=30.77, lon=-176.40, position_error_nm=8,
  notes='30°46''N + longitude corrigée 176°24''W (transposition probable du rapport: "167-24"). Épave relocalisée 1998/2023.'
 WHERE entity_id='SH-CV5' AND ts='1942-06-07T07:01:00-12:00';
UPDATE positions SET lat=30.77, lon=-176.40 WHERE entity_id='SH-HAMMANN';

-- ------------------------------------------------------------
-- Contacts du 6 juin (Enterprise AR) -> contact_reports + événements
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0606-0730-SCOUT2','1942-06-06T07:30:00-12:00',10,'sighting','USN','2e contact du matin: "2 CA, 2 DD, 28°55''N 175°10''E, cap 215, 15 nds" (le même groupe Mogami/Mikuma, fixes d''estime divergents)','J6-poursuite');
INSERT INTO event_participants VALUES
 ('EV-0606-0730-SCOUT2','formations','CRUDIV7','target');
INSERT INTO contact_reports VALUES
 ('CR-0606-0845-8B2','squadrons','SQ-VS8','1942-06-06T06:45:00-12:00','1942-06-06T06:45:00-12:00','1942-06-06T06:55:00-12:00',
  'PR-SPRUANCE',29.55,-185.17,'1 CV, 5 DD, cap 270 (8-B-2; "CV" = erreur d''identification: Mogami/Mikuma)',
  'EV-0606-0645-SCOUT',NULL,'Original: "Lat. 29°-33'' N, Long. 174°-50'' E". Erreur d''identification typique à conserver pour le mode perçu'),
 ('CR-0606-0930-SCOUT','squadrons','SQ-VS6','1942-06-06T07:30:00-12:00','1942-06-06T07:30:00-12:00','1942-06-06T07:40:00-12:00',
  'PR-SPRUANCE',28.92,-184.83,'2 CA, 2 DD, cap 215, 15 nds',
  'EV-0606-0730-SCOUT2',NULL,'Original: "Lat. 28°-55'' N, Long. 175°-10'' E". Les 2 fixes du matin divergent de ~40 nm: erreur d''estime aérienne'),
-- Attaque du Tanikaze (5 juin au soir): position du rapport
 ('CR-0605-2030-TANIKAZE','squadrons','SQ-VB6','1942-06-05T18:30:00-12:00','1942-06-05T18:30:00-12:00','1942-06-05T19:00:00-12:00',
  'PR-SPRUANCE',33.00,-183.00,'1 CL attaqué, résultat indéterminé (en réalité le DD Tanikaze, indemne)',
  'EV-0605-1800-TANIKAZE',NULL,'Original: "1 CL position Lat. 33°-00'' N, Long. 177°-00'' E", entrée 2030 zone +10');

INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('contact_reports','CR-0606-0845-8B2','reported_position','29.55,174.83E','Lat. 29°-33'' N, Long. 174°-50'' E','SRC-ENTERPRISE-AR','entrée 0845',1,'verified',NULL),
 ('contact_reports','CR-0605-2030-TANIKAZE','reported_position','33.0,177.0E','entrée 2030: "Attacked 1 CL"','SRC-ENTERPRISE-AR','entrée 2030',1,'single_source','Position élevée en latitude: à recouper avec le TROM du Tanikaze'),
 ('missions','MS-0606-STRIKE2','attack_ts','1942-06-06T12:00:00-12:00','objectif donné "as of 1350" zone +10 = 11:50','SRC-ENTERPRISE-AR','ordre de frappe 31 VSB',1,'verified','Concorde avec la fenêtre historique de la 2e frappe'),
 ('mission_squadrons','MS-0604-CV5AM','composition','17 VB-3 + 12 VT-3 + 6 VF-3','section AIR du rapport','SRC-YORKTOWN-AR','section AIR',1,'verified','Composition confirmée par le rapport du bord'),
 ('events','EV-0605-1800-TANIKAZE','position','33.0,-183.0','Lat. 33°-00'' N, Long. 177°-00'' E','SRC-ENTERPRISE-AR','entrée 2030',1,'single_source','Fixe la frappe du soir du 5 juin ~250 nm NO de TF-16');

UPDATE events SET lat=33.0, lon=-183.0, position_error_nm=25 WHERE event_id='EV-0605-1800-TANIKAZE';

-- VB-3: "at least 7 bomb hits" sur le Sōryū (le rapport surestime: 3 retenus)
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-1025-SORYU','hits','3','"It is estimated that VB-3 obtained at least 7 bomb hits"','SRC-YORKTOWN-AR','section AIR',1,'conflicting','Surestimation classique des équipages (7 revendiqués); 3 coups retenus (SS, analyse de l''épave 2023). Conserver la revendication pour le modèle de fiabilité des rapports.');

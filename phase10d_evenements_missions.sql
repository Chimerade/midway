-- ============================================================
-- PHASE 10d : synchronisation missions <-> chronologie (constat
-- replay: un raid part à 21:15 sans événement dans le fil).
-- Règle: tout départ de mission doit avoir son événement launch_start.
-- + Les événements des frappes du 6 juin confondaient heure de
-- décollage et texte de résultat: scindés en launch_start + attack.
-- ============================================================

-- Départs manquants
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0603-2115-PBYNIGHT','1942-06-03T21:15:00-12:00',15,'launch_start','USN','4 PBY-5A équipés radar décollent de Midway pour l''attaque de nuit à la torpille contre le convoi d''invasion','J3-approche'),
 ('EV-0603-0415-PBYSEARCH','1942-06-03T04:15:00-12:00',15,'launch_start','USN','Recherche quotidienne du 3 juin: les PBY partent en éventail (dont la ligne OSO de Reid, VP-44)','J3-approche');
INSERT INTO event_participants VALUES
 ('EV-0603-2115-PBYNIGHT','squadrons','SQ-PBY-MIDWAY','actor'),
 ('EV-0603-0415-PBYSEARCH','squadrons','SQ-PBY-MIDWAY','actor');
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0603-2115-PBYNIGHT','ts','1942-06-03T21:15:00-12:00','SRC-CINCPAC-01849',1,'single_source','Heure de décollage à préciser au dépouillement (rapport NAS Midway)');

-- Frappes du 6 juin: les événements existants deviennent les DÉPARTS...
UPDATE events SET event_type='launch_start',
 summary='TF-16 lance la 1re frappe sur Mogami/Mikuma (~26 SBD du Hornet)' WHERE event_id='EV-0606-0800-STRIKE1';
UPDATE events SET event_type='launch_start',
 summary='TF-16 lance la 2e frappe (31 SBD de l''Enterprise, mix VB-6/VS-6/VB-3)' WHERE event_id='EV-0606-1045-STRIKE2';
UPDATE events SET event_type='launch_start',
 summary='TF-16 lance la 3e frappe (24 SBD du Hornet)' WHERE event_id='EV-0606-1330-STRIKE3';

-- ...et les ATTAQUES deviennent des événements propres, aux bonnes heures
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0606-0950-S1ATK','1942-06-06T09:50:00-12:00',15,'attack','USN','1re frappe: coups sur Mogami et Mikuma','J6-poursuite'),
 ('EV-0606-1200-S2ATK','1942-06-06T12:00:00-12:00',15,'attack','USN','2e frappe: Mikuma dévasté; Mogami et un DD touchés','J6-poursuite'),
 ('EV-0606-1445-S3ATK','1942-06-06T14:45:00-12:00',15,'attack','USN','3e frappe: le Mikuma est achevé (coule dans la soirée); le Mogami s''échappe vers Truk','J6-poursuite');

-- Les cibles (pulsations de combat) migrent des départs vers les attaques
UPDATE event_participants SET event_id='EV-0606-0950-S1ATK' WHERE event_id='EV-0606-0800-STRIKE1';
UPDATE event_participants SET event_id='EV-0606-1200-S2ATK' WHERE event_id='EV-0606-1045-STRIKE2';
UPDATE event_participants SET event_id='EV-0606-1445-S3ATK' WHERE event_id='EV-0606-1330-STRIKE3';
INSERT INTO event_participants VALUES
 ('EV-0606-1200-S2ATK','ships','SH-MIKUMA','target'),
 ('EV-0606-1445-S3ATK','ships','SH-MIKUMA','target');

-- ============================================================
-- PHASE 7e : convention de causalité des segments
-- RÈGLE (désormais appliquée partout) : la cause d'un waypoint
-- justifie le segment SORTANT (du waypoint au suivant). Les virages
-- doivent donc être des waypoints à part entière.
-- Constat utilisateur: au waypoint 10:30 de TF-16, "cap 240" et
-- "repart NE" coexistaient car le virage (10:45) n'était pas un waypoint.
-- ============================================================

-- Le point de virage de 10:45 (début des récupérations)
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes) VALUES
 ('formations','TF-16','1942-06-04T10:45:00-12:00',31.01,-177.79,NULL,12,'estimated',25,'EV-0604-1045-TF16RECOV',
  'POINT DE VIRAGE: fin de la fermeture SO; début des cycles de récupération (courses au vent E-SE répétées, route nette NE)');

-- 15:30: le segment sortant (SE jusqu'au virage de 19:07) est gouverné
-- par le cycle lancement/récupérations de la frappe Hiryū
UPDATE positions SET cause_event_id='EV-0604-1530-E6LAUNCH',
  notes='Lancement de la frappe anti-Hiryū puis récupérations face au vent: dérive SE jusqu''au virage de 19:07. (Le bref rapprochement NO de ~14:55, EV-0604-1455-TF16NW, est sous la résolution des waypoints.)'
 WHERE entity_id='TF-16' AND ts='1942-06-04T15:30:00-12:00';

-- 00:01: cap consigné aligné sur la route sortante réelle (O-NO)
UPDATE positions SET course_deg=290 WHERE entity_id='TF-16' AND ts='1942-06-05T00:01:00-12:00';

-- Alignements détectés par l'audit N1 (cap consigné vs route sortante)
-- 12:30: le 110 était le cap instantané "au vent"; la route NETTE est NE
UPDATE positions SET course_deg=NULL,
  notes='En cycle de récupération: caps instantanés ~110 (au vent), ROUTE NETTE ~40-65 (NE)'
 WHERE entity_id='TF-16' AND ts='1942-06-04T12:30:00-12:00';
-- 15:30: le 300 était le rapprochement NO ponctuel; la route sortante est SE
UPDATE positions SET course_deg=130
 WHERE entity_id='TF-16' AND ts='1942-06-04T15:30:00-12:00';

-- Virage manquant: TF-16 rompt la poursuite le 6 au soir (l'événement existait)
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes) VALUES
 ('formations','TF-16','1942-06-06T19:07:00-12:00',29.35,-184.80,80,15,'estimated',35,'EV-0606-1907-RETIRE',
  'POINT DE VIRAGE: extrémité ouest de la poursuite; route NE vers le ravitaillement');

-- Virage manquant: TF-17 (escorte) redescend vers la zone de sauvetage le 5 au soir
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes) VALUES
 ('formations','TF-17','1942-06-05T20:00:00-12:00',30.95,-175.85,255,10,'estimated',30,'EV-0605-1200-SALVAGE',
  'POINT DE VIRAGE: extrémité est du retrait; retour O vers le groupe de sauvetage du Yorktown');

-- ============================================================
-- PHASE 7d : le "recul" de TF-16 en milieu de journée du 4 juin
-- Constat utilisateur (replay): TF-16 inverse sa route vers le NE
-- entre ~10:30 et 15:30 sans événement explicatif. Cause réelle:
-- récupérations successives des raids face au vent d'E-SE
-- (vent faible => longues courses au vent), donc dérive nette NE.
-- C'est ce qui maintient la frappe anti-Hiryū à courte distance.
-- ============================================================
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-1045-TF16RECOV','1942-06-04T10:45:00-12:00',15,'recovery_start','USN',
  'TF-16 interrompt sa progression SO: récupérations successives des raids du matin (SBD, chasse, rescapés VT, puis avions du Yorktown) face au vent d''E-SE — dérive nette vers le NE jusqu''à ~15:00','J4-contre-attaque');

INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('events','EV-0604-1045-TF16RECOV','ts','1942-06-04T10:45:00-12:00','SRC-ENTERPRISE-AR',1,'single_source',
  'Récupérations documentées dans l''action report; la dérive E pendant les cycles de pont explique la courte distance de frappe de 15:30 (~90 nm)');

-- Waypoint intermédiaire qui matérialise la dérive (cap "au vent" ~110)
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,cause_event_id,notes) VALUES
 ('formations','TF-16','1942-06-04T12:30:00-12:00',31.15,-177.45,110,12,'estimated',25,'EV-0604-1045-TF16RECOV',
  'En cycle de récupération: courses répétées face au vent E-SE, progression SO suspendue'),
-- Waypoint de minuit: fin de la jambe est, virage N puis O (plan de Spruance)
 ('formations','TF-16','1942-06-05T00:01:00-12:00',31.00,-176.30,350,15,'estimated',30,'EV-0605-0001-TF16N',
  'Point de virage nocturne: extrémité est de la jambe défensive, retour vers l''ouest');

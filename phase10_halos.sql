-- ============================================================
-- PHASE 10 : resserrage des incertitudes du groupe Yorktown/TF-17
-- (constat replay: halos surdimensionnés). Justification: le navire
-- abandonné est resté constamment accompagné (Hughes la nuit du 4-5,
-- puis groupe de sauvetage + écran de DD) => position tenue par
-- l'estime des escorteurs et les fixes des rapports d'action.
-- ============================================================
UPDATE positions SET position_error_nm=12,
  notes=COALESCE(notes,'')||' [err resserrée: TF-17 au complet sur zone]'
 WHERE entity_id='SH-CV5' AND ts IN ('1942-06-04T12:11:00-12:00','1942-06-04T14:43:00-12:00');
UPDATE positions SET position_error_nm=8,
  notes=COALESCE(notes,'')||' [err resserrée: à couple du Hammann, fixes multiples du groupe]'
 WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00';
UPDATE positions SET position_error_nm=15 WHERE entity_id='TF-17' AND ts='1942-06-05T12:00:00-12:00';
UPDATE positions SET position_error_nm=15 WHERE entity_id='TF-17' AND ts='1942-06-05T20:00:00-12:00';
UPDATE positions SET position_error_nm=10,
  notes=COALESCE(notes,'')||' [err resserrée: écran autour du point de sauvetage connu]'
 WHERE entity_id='TF-17' AND ts='1942-06-06T13:00:00-12:00';

INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('positions','SH-CV5','position_error_5_6juin','8-12 nm','SRC-YORKTOWN-AR',1,'estimated',
  'Resserrage justifié: navire jamais isolé (Hughes, puis groupe de sauvetage); position de naufrage connue à ~5 nm; les ±20-30 initiaux étaient un défaut générique de la Phase 4, pas une incertitude réelle.');

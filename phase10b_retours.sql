-- ============================================================
-- PHASE 10b : trajets RETOUR des missions de frappe (constat replay:
-- les raids disparaissaient au point d'attaque). Le dénombrement
-- affiche automatiquement les survivants (engagés - perdus).
-- VT-8 n'a volontairement PAS de retour: 15/15 abattus (1 survivant à l'eau).
-- Points d'arrivée = position de la plateforme d'origine à l'heure de
-- récupération (interpolée sur sa piste). Heures de récupération
-- estimées là où les sources ne les donnent pas (notées "estimé").
-- ============================================================

-- Récupérations manquantes (estimations, à recouper)
UPDATE missions SET recovery_ts='1942-06-04T08:30:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id IN ('MS-0604-VT8DET','MS-0604-B26');
UPDATE missions SET recovery_ts='1942-06-04T09:30:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0604-VMSB-SBD';
UPDATE missions SET recovery_ts='1942-06-04T10:00:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0604-SB2U';
UPDATE missions SET recovery_ts='1942-06-04T10:40:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0604-B17AM';
UPDATE missions SET recovery_ts='1942-06-04T11:00:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0604-VT6';
UPDATE missions SET recovery_ts='1942-06-04T05:30:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0604-PBYNIGHT';
UPDATE missions SET recovery_ts='1942-06-06T11:30:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0606-STRIKE1';
UPDATE missions SET recovery_ts='1942-06-06T13:30:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0606-STRIKE2';
UPDATE missions SET recovery_ts='1942-06-06T16:15:00-12:00', notes=COALESCE(notes,'')||' [recovery estimée]' WHERE mission_id='MS-0606-STRIKE3';

INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES
 -- Riposte du Hiryū (les retours que le replay réclamait)
 ('MS-0604-HIRYU1',2,'1942-06-04T12:20:00-12:00','1942-06-04T13:30:00-12:00',31.65,-176.85,30.92,-178.86,245,130,3000,'estimated','retour des 8 survivants vers le Hiryū'),
 ('MS-0604-HIRYU2',2,'1942-06-04T14:45:00-12:00','1942-06-04T15:40:00-12:00',31.60,-176.90,31.31,-178.97,255,115,1500,'estimated','retour des 9 survivants (5 B5N + 4 A6M); Hashimoto rapporte un "2e CV touché"'),
 -- Frappes US du matin
 ('MS-0604-CV6AM',5,'1942-06-04T10:32:00-12:00','1942-06-04T12:05:00-12:00',30.55,-179.15,31.12,-177.53,65,110,2500,'estimated','retour vers TF-16; traînards et pannes sèches (amerrissages) inclus dans les pertes'),
 ('MS-0604-VT6',2,'1942-06-04T10:00:00-12:00','1942-06-04T11:00:00-12:00',30.47,-179.05,31.03,-177.74,60,95,300,'estimated','retour des 4 rescapés'),
 ('MS-0604-CV5AM',3,'1942-06-04T10:40:00-12:00','1942-06-04T12:00:00-12:00',30.58,-179.05,31.11,-177.55,65,115,2500,'estimated','retour; VB-3 dérouté sur l''Enterprise (Yorktown sous attaque)'),
 -- Frappes parties de Midway
 ('MS-0604-VT8DET',2,'1942-06-04T07:15:00-12:00','1942-06-04T08:30:00-12:00',30.62,-179.20,28.21,-177.37,145,135,500,'estimated','retour du seul TBF survivant (Ens. Earnest), gravement touché'),
 ('MS-0604-B26',2,'1942-06-04T07:15:00-12:00','1942-06-04T08:30:00-12:00',30.62,-179.20,28.21,-177.37,145,145,300,'estimated','retour des 2 B-26 survivants'),
 ('MS-0604-VMSB-SBD',2,'1942-06-04T08:05:00-12:00','1942-06-04T09:30:00-12:00',30.68,-179.27,28.21,-177.37,145,105,2000,'estimated','retour des 8 survivants'),
 ('MS-0604-SB2U',2,'1942-06-04T08:30:00-12:00','1942-06-04T10:00:00-12:00',30.55,-179.05,28.21,-177.37,145,90,2000,'estimated','retour des 8 survivants'),
 ('MS-0604-B17AM',2,'1942-06-04T08:20:00-12:00','1942-06-04T10:40:00-12:00',30.60,-179.20,28.21,-177.37,145,120,5500,'estimated','retour (aucune perte)'),
 ('MS-0603-B17',2,'1942-06-03T16:40:00-12:00','1942-06-03T18:50:00-12:00',26.80,-184.00,28.21,-177.37,75,160,4000,'estimated','retour vers Midway'),
 ('MS-0604-PBYNIGHT',2,'1942-06-04T02:00:00-12:00','1942-06-04T05:30:00-12:00',27.20,-182.80,28.21,-177.37,75,95,300,'estimated','retour de nuit'),
 -- Frappe du soir sur le Hiryū
 ('MS-0604-E6PM',2,'1942-06-04T17:15:00-12:00','1942-06-04T18:30:00-12:00',31.67,-179.17,31.13,-177.05,105,110,2500,'estimated','retour des 21 SBD vers TF-16 (récupération au crépuscule)'),
 -- Poursuite du 6 juin
 ('MS-0606-STRIKE1',2,'1942-06-06T10:00:00-12:00','1942-06-06T11:30:00-12:00',29.20,-185.20,29.46,-183.92,75,110,2500,'estimated','retour vers TF-16'),
 ('MS-0606-STRIKE2',2,'1942-06-06T12:10:00-12:00','1942-06-06T13:30:00-12:00',29.25,-185.50,29.43,-184.25,78,110,2500,'estimated','retour vers TF-16'),
 ('MS-0606-STRIKE3',2,'1942-06-06T14:55:00-12:00','1942-06-06T16:15:00-12:00',29.35,-186.20,29.39,-184.59,87,110,2500,'estimated','retour vers TF-16');

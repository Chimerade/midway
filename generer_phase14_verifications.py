#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère phase14_verifications.sql : corrections issues de la vérification
sur sources officielles (lot 1, 2026-10-03). Toutes les heures en zone +12
(Midway). Les rapports de TF-16/TF-17 et de leurs bâtiments sont en zone +10
(CINCPAC : « times given by them are Zone plus 10 ») : on retranche 2 h.

Sources consultées (transcriptions HyperWar/ibiblio des documents officiels) :
  - CINCPAC, Battle of Midway, serial 01849 (zone +12)
  - Commander Destroyer Squadron Six, action report (zone +10)
  - Commander Task Force 16, action report (zone +10)
  - Bureau of Ships, USS Yorktown (CV-5) Loss in Action (zone +10)
  - ONI Combat Narrative « The Battle of Midway » (1943, zone +12)
  - USS Yorktown et USS Hornet, action reports (zone +10)
  - NHHC H-Gram 006 (2017) pour le cap 265° du groupe du Hornet

Positions dérivées (calculées ici pour rester traçables) :
  - Yorktown à 12:10 = TF-16 journalisée (phase 13) + 12 nm au 315°
    (DesRon 6 : « bearing 315° (T), distance about 12 miles »).
  - Vol du Hornet (CV8AM) au 265°, demi-tour de VS-8 à 09:40.
  - Éventail VS-5 : 10 lignes de 10° sur 280°-020°, 200 nm, lancé à 11:30.
Usage : python3 generer_phase14_verifications.py > phase14_verifications.sql
"""
import math

MIDWAY = (28.21, -177.37)


def dest(lat, lon, brg, d):
    la = lat + d * math.cos(math.radians(brg)) / 60
    lo = lon + d * math.sin(math.radians(brg)) / (60 * math.cos(math.radians((lat + la) / 2)))
    return la, lo


def route(a, b):
    """(distance nm, relèvement °) — même métrique que l'audit et l'inférence."""
    dlat = (b[0] - a[0]) * 60
    dlon = (b[1] - a[1]) * 60 * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(dlat, dlon), (math.degrees(math.atan2(dlon, dlat)) + 360) % 360


def hm(h, m):
    return h * 60 + m


def ts(minutes, day=4):
    day += minutes // 1440
    minutes %= 1440
    return f"1942-06-{day:02d}T{minutes // 60:02d}:{minutes % 60:02d}:00-12:00"


def interp(track, t):
    for (ta, *pa), (tb, *pb) in zip(track, track[1:]):
        if ta <= t <= tb:
            f = (t - ta) / (tb - ta)
            return pa[0] + f * (pb[0] - pa[0]), pa[1] + f * (pb[1] - pa[1])
    raise ValueError(t)


def r2(p):
    return round(p[0], 2), round(p[1], 2)


def q(s):
    return "'" + s.replace("'", "''") + "'"


# Piste TF-16 journalisée du 4 juin (valeurs de phase13_rebaseline_tf.sql)
TF16 = [(hm(7, 6), 31.366, -176.343), (hm(10, 30), 30.597, -176.581),
        (hm(10, 45), 30.587, -176.555), (hm(12, 30), 30.518, -176.373),
        (hm(15, 30), 30.399, -176.060), (hm(19, 7), 30.252, -175.795)]

# --- Yorktown / TF-17 -------------------------------------------------------
TF17_0838 = (31.218, -176.278)                      # lancement du groupe Yorktown (phase 13)
TF17_0906 = r2(dest(*TF17_0838, 146, 25 * 28 / 60))  # fin du lancement, cap 146 à 25 nds
YK_ATT = r2(dest(*interp(TF16, hm(12, 10)), 315, 12))  # DesRon 6 : 315°, ~12 milles
YK_1443 = r2(dest(*YK_ATT, 90, 7.5))                # repart 14:02 cap 090, 19-20 nds à 14:40
YK_1430 = r2(interp([(hm(14, 2), *YK_ATT), (hm(14, 43), *YK_1443)], hm(14, 30)))
TF17_0605 = (31.0, -176.1)                          # waypoint existant du 5 juin 12:00
SINK = (30.60, -176.567)                            # CINCPAC : « about 30-36 N, 176-34 W »

d_0906, c_0906 = route(TF17_0906, YK_ATT)
_, c_retrait = route(YK_1443, TF17_0605)

# --- Éventail VS-5 ------------------------------------------------------------
VS5_T0 = hm(11, 40)                                 # fin du lancement (début 11:30)
VS5_L = r2(interp([(hm(9, 6), *TF17_0906), (hm(12, 11), *YK_ATT)], hm(11, 30)))
V_OUT, V_CROSS, V_BACK = 115, 105, 95               # retour face aux alizés d'est
vs5_legs, vs5_end = [], 0
for k in range(10):
    b_out, b_cross = 290 + 10 * k, 280 + 10 * k
    p_out = dest(*VS5_L, b_out % 360, 200)
    p_cross = dest(*VS5_L, b_cross % 360, 200)
    t1 = VS5_T0 + round(200 / V_OUT * 60)
    d_x, c_x = route(p_out, p_cross)
    t2 = t1 + round(d_x / V_CROSS * 60)
    t3 = t2 + 120
    for _ in range(4):                              # récupération sur TF-16 (Enterprise/Hornet)
        home = interp(TF16, t3)
        d_b, c_b = route(p_cross, home)
        t3 = t2 + round(d_b / V_BACK * 60)
    vs5_end = max(vs5_end, t3)
    line = f"Ligne {b_out % 360:03d}°"
    vs5_legs += [
        (3 * k + 1, VS5_T0, t1, VS5_L, p_out, b_out % 360, V_OUT, 1500, f"{line} — 200 nm"),
        (3 * k + 2, t1, t2, p_out, p_cross, c_x, V_CROSS, 1500, f"{line} — crochet vers {b_cross % 360:03d}° ({d_x:.0f} nm)"),
        (3 * k + 3, t2, t3, p_cross, home, c_b, V_BACK, 1000,
         "retour vers TF-16 (Yorktown hors de combat): Adams repère le Hiryū sur ce trajet" if k == 0
         else "retour vers TF-16 (Yorktown hors de combat)"),
    ]

# --- Vol du Hornet (CV8AM) -----------------------------------------------------
CV8_T0, CV8_TURN, CV8_HOME, CV8_MID = hm(8, 6), hm(9, 40), hm(11, 20), hm(11, 30)
CV8_S = interp(TF16, CV8_T0)
CV8_D = 120 * (CV8_TURN - CV8_T0) / 60
CV8_T = dest(*CV8_S, 265, CV8_D)
CV8_H = interp(TF16, CV8_HOME)
d_h, c_h = route(CV8_T, CV8_H)
d_m, c_m = route(CV8_T, MIDWAY)
cv8_legs = [
    (1, CV8_T0, CV8_TURN, CV8_S, CV8_T, 265, 120, 6000,
     "Cap 265° (radar CXAM du Hornet, pilotes; NHHC H-Gram 006) et non 239° du rapport: passe au nord de la KB sans la voir"),
    (2, CV8_TURN, CV8_HOME, CV8_T, CV8_H, c_h, round(d_h / (CV8_HOME - CV8_TURN) * 60), 3000,
     "VS-8 fait demi-tour à 09:40; Ring, resté seul, suit; récupérés de justesse par le Hornet"),
    (3, CV8_TURN, CV8_MID, CV8_T, MIDWAY, c_m, round(d_m / (CV8_MID - CV8_TURN) * 60), 3000,
     "VB-8 se déroute sur Midway faute d'essence; 2 SBD amerrissent dans le lagon"),
]


def leg_sql(mid, legs):
    rows = []
    for seq, t0, t1, a, b, crs, spd, alt, note in legs:
        rows.append(f" ({q(mid)},{seq},{q(ts(t0))},{q(ts(t1))},{a[0]:.3f},{a[1]:.3f},{b[0]:.3f},{b[1]:.3f},"
                    f"{round(crs)},{spd},{alt},'estimated',{q(note)})")
    return ("INSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,"
            "course_deg,speed_kn,altitude_m,method,notes) VALUES\n" + ",\n".join(rows) + ";")


SQL = f"""-- ============================================================
-- PHASE 14 : vérifications sur sources officielles (lot 1, 2026-10-03)
-- Générée par generer_phase14_verifications.py — ne pas éditer à la main.
-- Heures en zone +12 ; rapports de TF-16/TF-17 en zone +10 convertis (-2 h).
-- ============================================================

-- ------------------------------------------------------------
-- 0. Sources primaires consultées
-- ------------------------------------------------------------
INSERT INTO sources (source_id,type,author,title,year,grade,time_reference,url,notes) VALUES
 ('SRC-DESRON6-AR','primary_official','Commander Destroyer Squadron Six','Battle of Midway — action report (Balch, Benham)',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-DesRon6.html',
  'Seul fix relatif chiffré de TF-17 au moment de l''attaque Kobayashi: fumée et DCA « bearing 315° (T), distance about 12 miles » depuis TF-16'),
 ('SRC-CTF16-AR','primary_official','Commander Task Force 16 (Spruance)','Battle of Midway — TF 16 action report',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-Carriers.html',
  '« All times given are zone plus ten »; à la 1re attaque, le Yorktown est « nearly out of sight of us to the northwestward »'),
 ('SRC-BUSHIPS-WDR','primary_official','Bureau of Ships','U.S.S. Yorktown (CV-5) — Loss in Action, Midway, June 4-7, 1942 (War Damage Report)',1942,'A','GMT-10',
  'https://www.ibiblio.org/hyperwar/USN/rep/WDR/U.S.S.%20YORKTOWN%20(CV-5),%20BOMB%20AND%20TORPEDO%20DAMAGE%20-%20Midway,%20June%204%20to%207,%201942%20(LOST%20IN%20ACTION).pdf',
  'Chronologie des avaries à la minute (zone +10): bombes 1414, stoppé 1440, 20 nds dispo 1550, torpilles 1645, abandon 1702, survivants recueillis 1918, naufrage 0701'),
 ('SRC-ONI-CN-1943','primary_official','Office of Naval Intelligence','The Battle of Midway, June 3-6, 1942 (Combat Narrative)',1943,'A','GMT-12',
  'https://www.ibiblio.org/hyperwar/USN/USN-CN-Midway/index.html',
  'Récit officiel contemporain établi d''après les rapports d''action');
UPDATE sources SET url='https://www.ibiblio.org/hyperwar/USN/rep/Midway/Midway-CinCPac.html'
 WHERE source_id='SRC-CINCPAC-01849' AND url IS NULL;

-- ------------------------------------------------------------
-- 1. Nouveaux événements (chronologie des actions vérifiées)
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,phase) VALUES
 ('EV-0604-0940-CV8TURN','1942-06-04T09:40:00-12:00',10,'course_change','USN',
  'Flight to nowhere: VS-8 fait demi-tour vers le Hornet, Ring poursuit seul vers l''ouest puis rentre; VB-8 se déroute sur Midway (2 SBD amerris dans le lagon); les 10 F4F de VF-8 amerrissent à court d''essence (8 pilotes récupérés)','J4-matin'),
 ('EV-0604-1130-VS5LAUNCH','1942-06-04T11:30:00-12:00',20,'launch_start','USN',
  'Le Yorktown lance 10 SBD de VS-5 (1 bombe de 1 000 lb chacun) en recherche sur 280°-020° à 200 nm pour trouver le 4e porte-avions','J4-hiryu'),
 ('EV-0604-1402-YKREPART','1942-06-04T14:02:00-12:00',10,'course_change','USN',
  'Feux éteints et conduits réparés: le Yorktown repart cap 090 et remonte à 19-20 nds; Pensacola, Vincennes, Balch et Benham, détachés de TF-16, ont rallié son écran','J4-hiryu'),
 ('EV-0604-1718-YKRESCUE','1942-06-04T17:18:00-12:00',15,'other','USN',
  'Fin du recueil des survivants du Yorktown: TF-17 se retire vers l''est, le Hughes reste seul auprès du porte-avions abandonné','J4-hiryu');
INSERT INTO event_participants (event_id,entity_table,entity_id,role) VALUES
 ('EV-0604-0940-CV8TURN','squadrons','SQ-VS8','actor'),('EV-0604-0940-CV8TURN','squadrons','SQ-VB8','actor'),
 ('EV-0604-0940-CV8TURN','squadrons','SQ-VF8','actor'),
 ('EV-0604-1130-VS5LAUNCH','ships','SH-CV5','actor'),('EV-0604-1130-VS5LAUNCH','squadrons','SQ-VS5','actor'),
 ('EV-0604-1402-YKREPART','ships','SH-CV5','actor'),
 ('EV-0604-1718-YKRESCUE','formations','TF-17','actor'),('EV-0604-1718-YKRESCUE','ships','SH-HUGHES','actor');

-- ------------------------------------------------------------
-- 2. Contact d'Adams : 14:30, pas 14:45 (CINCPAC « at 1430 », ONI « 1430 »,
--    Yorktown « about 1630 » en zone +10). L'identifiant encode l'heure : on renomme.
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,lat,lon,position_error_nm,phase,notes)
 SELECT 'EV-0604-1430-ADAMS','1942-06-04T14:30:00-12:00',10,event_type,side,
  'SBD de VS-5 (Adams, éventail lancé par le Yorktown 3 h plus tôt) localise le Hiryū: "1 CV, 2 BB, 3 CA, 4 DD, 31°15''N 179°05''W"',
  lat,lon,position_error_nm,phase,notes FROM events WHERE event_id='EV-0604-1445-ADAMS';
UPDATE event_participants SET event_id='EV-0604-1430-ADAMS' WHERE event_id='EV-0604-1445-ADAMS';
UPDATE claims SET entity_id='EV-0604-1430-ADAMS', value='1942-06-04T14:30:00-12:00',
  resolution_note='Le rapport Yorktown confirme mot pour mot composition et position du contact Adams; heure: « about 1630 » (zone +10) = 14:30'
 WHERE entity_table='events' AND entity_id='EV-0604-1445-ADAMS';
INSERT INTO contact_reports (report_id,reporter_table,reporter_id,ts_observed,ts_sent,ts_received,recipient_id,
                             reported_lat,reported_lon,reported_composition,actual_event_id,position_error_actual_nm,notes)
 SELECT 'CR-0604-1430-ADAMS',reporter_table,reporter_id,'1942-06-04T14:30:00-12:00','1942-06-04T14:30:00-12:00','1942-06-04T14:35:00-12:00',
  recipient_id,reported_lat,reported_lon,reported_composition,'EV-0604-1430-ADAMS',position_error_actual_nm,notes
 FROM contact_reports WHERE report_id='CR-0604-1445-ADAMS';
DELETE FROM contact_reports WHERE report_id='CR-0604-1445-ADAMS';
DELETE FROM events WHERE event_id='EV-0604-1445-ADAMS';
UPDATE events SET summary=REPLACE(summary,'(rapport Adams 14:45)','(rapport Adams 14:30)') WHERE event_id='EV-0604-1455-TF16NW';
UPDATE claims SET resolution_note=REPLACE(resolution_note,'rapport Adams (14:45-14:50)','rapport Adams (14:30-14:35)')
 WHERE resolution_note LIKE '%rapport Adams (14:45-14:50)%';
UPDATE decisions SET consequences=REPLACE(consequences,'le Hiryū à 14:45','le Hiryū à 14:30')
 WHERE consequences LIKE '%le Hiryū à 14:45%';
UPDATE squadron_status SET notes=REPLACE(notes,'le Hiryū à 14:45','le Hiryū à 14:30')
 WHERE squadron_id='SQ-VS5' AND notes LIKE '%le Hiryū à 14:45%';

-- ------------------------------------------------------------
-- 3. Recherche VS-5 : lancée à 11:30 (13:30 était l'heure du bord non convertie)
-- ------------------------------------------------------------
UPDATE missions SET launch_start_ts='1942-06-04T11:30:00-12:00', launch_end_ts={q(ts(VS5_T0))},
  recovery_ts={q(ts(vs5_end))}, outcome='14:30: Adams localise le Hiryū',
  notes='10 SBD en éventail 200 nm sur 280°-020° (la réserve de Fletcher paie); récupérés par TF-16, le Yorktown étant hors de combat'
 WHERE mission_id='MS-0604-VS5SEARCH';
{leg_sql('MS-0604-VS5SEARCH', vs5_legs)}

-- ------------------------------------------------------------
-- 4. Vol du Hornet (« flight to nowhere ») : cap 265°, pertes réelles
-- ------------------------------------------------------------
UPDATE missions SET notes='34 SBD + 10 F4F; cap 265° retenu contre 239° du rapport officiel (voir claims)'
 WHERE mission_id='MS-0604-CV8AM';
UPDATE mission_squadrons SET aircraft_lost=2,
  notes='13 SBD vers Midway faute d''essence: 2 amerris dans le lagon, 11 ravitaillés puis rentrés sur le Hornet à 15:27'
 WHERE mission_id='MS-0604-CV8AM' AND squadron_id='SQ-VB8';
UPDATE mission_squadrons SET notes='Les 10 F4F amerrissent à court d''essence; 8 pilotes récupérés'
 WHERE mission_id='MS-0604-CV8AM' AND squadron_id='SQ-VF8';
{leg_sql('MS-0604-CV8AM', cv8_legs)}

-- ------------------------------------------------------------
-- 5. Yorktown et TF-17 le 4 juin : un seul et même point jusqu'à la fin du sauvetage.
--    Ancienne position du Yorktown (31.65N 176.85W) attribuée au rapport Yorktown,
--    qui ne donne aucune position pour les attaques : 71 nm au NNO de TF-16,
--    incompatible avec CTF-16 et DesRon 6 (12 milles au NO).
-- ------------------------------------------------------------
UPDATE positions SET lat={YK_ATT[0]}, lon={YK_ATT[1]}, speed_kn=0, position_error_nm=15, source_id='SRC-DESRON6-AR',
  notes='Stoppé après les 3 bombes. Fix relatif: 12 milles au 315° de TF-16 (DesRon 6), « nearly out of sight to the northwestward » (CTF-16)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-04T12:11:00-12:00';
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,cause_event_id,notes) VALUES
 ('ships','SH-CV5','1942-06-04T14:02:00-12:00',{YK_ATT[0]},{YK_ATT[1]},90,19,'estimated',15,'SRC-CINCPAC-01849','EV-0604-1402-YKREPART',
  'Repart cap 090 (CINCPAC); la position chiffrée du rapport (33-51 N) est écartée, voir claims');
UPDATE positions SET lat={YK_1443[0]}, lon={YK_1443[1]}, speed_kn=0, position_error_nm=15,
  notes='2 torpilles à 14:45, sans énergie, gîte 23°; abandon à 15:00. ~7 nm à l''est du point d''attaque (cap 090 depuis 14:02)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-04T14:43:00-12:00';
INSERT INTO positions (entity_table,entity_id,ts,lat,lon,course_deg,speed_kn,method,position_error_nm,source_id,cause_event_id,notes) VALUES
 ('formations','TF-17','1942-06-04T09:06:00-12:00',{TF17_0906[0]},{TF17_0906[1]},{round(c_0906)},{round(d_0906 / (185 / 60))},'estimated',20,NULL,'EV-0604-0838-TF17LAUNCH',
  'Fin du lancement (cap 146 face au vent); route nette vers le point d''attaque de 12:11'),
 ('formations','TF-17','1942-06-04T12:11:00-12:00',{YK_ATT[0]},{YK_ATT[1]},90,0,'estimated',15,'SRC-DESRON6-AR','EV-0604-1205-KOBAYASHI',
  'Écran en cercle autour du Yorktown stoppé (12 milles au 315° de TF-16)'),
 ('formations','TF-17','1942-06-04T14:02:00-12:00',{YK_ATT[0]},{YK_ATT[1]},90,19,'estimated',15,'SRC-CINCPAC-01849','EV-0604-1402-YKREPART',
  'Le Yorktown repart cap 090 avec son écran renforcé par TF-16'),
 ('formations','TF-17','1942-06-04T14:43:00-12:00',{YK_1443[0]},{YK_1443[1]},NULL,0,'estimated',15,NULL,'EV-0604-1430-TOMOATK',
  'Écran autour du Yorktown torpillé; recueil des survivants jusqu''à 17:18');
UPDATE positions SET ts='1942-06-04T17:18:00-12:00', lat={YK_1443[0]}, lon={YK_1443[1]}, course_deg={round(c_retrait)},
  cause_event_id='EV-0604-1718-YKRESCUE',
  notes='Fin du recueil des survivants (BuShips: 1918 zone +10); Fletcher sur l''Astoria. Remplace le point de 16:00 de la phase 13 (30.867N 176.0W), 25 nm à l''ENE alors que l''écran recueillait encore les naufragés'
 WHERE entity_id='TF-17' AND ts='1942-06-04T16:00:00-12:00';

-- Frappes du Hiryū : points d'attaque et départs du retour sur le Yorktown recalé
UPDATE mission_legs SET end_lat={YK_ATT[0]}, end_lon={YK_ATT[1]} WHERE mission_id='MS-0604-HIRYU1' AND seq=1;
UPDATE mission_legs SET start_lat={YK_ATT[0]}, start_lon={YK_ATT[1]} WHERE mission_id='MS-0604-HIRYU1' AND seq=2;
UPDATE mission_legs SET end_lat={YK_1430[0]}, end_lon={YK_1430[1]} WHERE mission_id='MS-0604-HIRYU2' AND seq=1;
UPDATE mission_legs SET start_lat={YK_1443[0]}, start_lon={YK_1443[1]} WHERE mission_id='MS-0604-HIRYU2' AND seq=2;
-- Frappe du Yorktown : départ au point de fin de lancement
UPDATE mission_legs SET start_lat={TF17_0906[0]}, start_lon={TF17_0906[1]} WHERE mission_id='MS-0604-CV5AM' AND seq=1;

-- ------------------------------------------------------------
-- 6. Naufrage du Yorktown : 05:01 à 30°36'N 176°34'W (CINCPAC, zone +12).
--    07:01 était l'heure du bord (zone +10) ; on renomme l'événement.
-- ------------------------------------------------------------
INSERT INTO events (event_id,ts,time_uncertainty_min,event_type,side,summary,lat,lon,position_error_nm,phase,notes)
 SELECT 'EV-0607-0501-YKSINK','1942-06-07T05:01:00-12:00',time_uncertainty_min,event_type,side,
  'Le Yorktown chavire et coule à l''aube par 30°36''N 176°34''W',lat,lon,position_error_nm,phase,notes
 FROM events WHERE event_id='EV-0607-0701-YKSINK';
UPDATE positions SET ts='1942-06-07T05:01:00-12:00', lat={SINK[0]}, lon={SINK[1]}, cause_event_id='EV-0607-0501-YKSINK',
  source_id='SRC-CINCPAC-01849',
  notes='CINCPAC: « at 0501, 7 June, in about 30-36 N, 176-34 W, Yorktown sank ». Le rapport du bord donne 0701 (zone +10) et 30°46''N 167°24''W (longitude impossible)'
 WHERE entity_id='SH-CV5' AND ts='1942-06-07T07:01:00-12:00';
UPDATE claims SET entity_id='EV-0607-0501-YKSINK', value='1942-06-07T05:01:00-12:00', original_value='0501',
  status='verified', resolution_note='CINCPAC (zone +12) 0501 = BuShips et rapport du bord 0701 (zone +10)'
 WHERE entity_table='events' AND entity_id='EV-0607-0701-YKSINK';
DELETE FROM events WHERE event_id='EV-0607-0701-YKSINK';
UPDATE claims SET value='{SINK[0]},{SINK[1]}', original_value='about 30-36 N, 176-34 W', is_accepted=1, status='conflicting',
  resolution_note='Retenu: source A en zone +12, à 9 nm du point d''abandon reconstruit. La valeur antérieure (30.77) lisait 30-46, latitude du rapport du bord'
 WHERE entity_table='ships' AND entity_id='SH-CV5' AND field='sinking_position' AND source_id='SRC-CINCPAC-01849';
UPDATE claims SET is_accepted=0
 WHERE entity_table='positions' AND entity_id='SH-CV5' AND field='sinking_position' AND source_id='SRC-YORKTOWN-AR';
-- Le Hammann coule bord à bord avec le Yorktown (13:40 le 6) : même point que le Yorktown à 13:36
UPDATE positions SET lat=(SELECT lat FROM positions WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00'),
  lon=(SELECT lon FROM positions WHERE entity_id='SH-CV5' AND ts='1942-06-06T13:36:00-12:00'),
  notes='Coule le long du Yorktown (BuShips: « HAMMANN which was alongside »)'
 WHERE entity_id='SH-HAMMANN' AND ts='1942-06-06T13:40:00-12:00';

-- ------------------------------------------------------------
-- 7. Claims (valeur d'origine, source, arbitrage)
-- ------------------------------------------------------------
INSERT INTO claims (entity_table,entity_id,field,value,original_value,source_id,page_ref,is_accepted,status,resolution_note) VALUES
 ('positions','SH-CV5','position_0604_1211','{YK_ATT[0]},{YK_ATT[1]}','Heavy smoke (oil fire) and A.A. bursts, bearing 315° (T), distance about 12 miles','SRC-DESRON6-AR','détachement de 1434 (zone +10)',1,'conflicting',
  'Fix relatif appliqué à TF-16 journalisée (phase 13) à 12:10. Corroboré par CTF-16 (« to the northwestward ») et par le naufrage CINCPAC à 9 nm'),
 ('positions','SH-CV5','position_0604_1211','au NO de TF-16, presque hors de vue','When the first attack was made on the Yorktown, she was nearly out of sight of us to the northwestward','SRC-CTF16-AR',NULL,0,'conflicting','Concorde qualitativement avec DesRon 6'),
 ('positions','SH-CV5','position_0604_1211','~150 milles NE de Midway','YORKTOWN was operating 150 miles northeast of Midway as a part of a task force','SRC-BUSHIPS-WDR','Section II §3',0,'conflicting','Compatible: le point retenu est à ~158 nm au 012° de Midway'),
 ('positions','SH-CV5','position_0604_1402','33.85,-176.0','Latitude 33-51 N, Longitude 176 W, course 090°','SRC-CINCPAC-01849','attaque du Yorktown',0,'conflicting',
  'Écarté (règle 2, cohérence physique): 340 nm au N de Midway, contredit BuShips (~150 milles), DesRon 6 et CTF-16. Probable coquille'),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:30:00-12:00','about 1330 (zone +10)','SRC-YORKTOWN-AR','section AIR',1,'conflicting',
  '11:30 retenu (rapport du bord et ONI concordent) contre 11:50 (CINCPAC). L''ancienne valeur 13:30 était l''heure du bord non convertie'),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:30:00-12:00','At 1130','SRC-ONI-CN-1943','attaque du Yorktown',0,'conflicting',NULL),
 ('missions','MS-0604-VS5SEARCH','launch_start_ts','1942-06-04T11:50:00-12:00','at 1150','SRC-CINCPAC-01849',NULL,0,'conflicting',NULL),
 ('missions','MS-0604-VS5SEARCH','secteur','280-020 / 200 nm','search the area from bearing 280° T. to 020° for a distance of 200 miles','SRC-YORKTOWN-AR','section AIR',1,'conflicting','ONI concorde; CINCPAC écrit 280-030'),
 ('events','EV-0604-1430-ADAMS','ts','1942-06-04T14:30:00-12:00','at 1430','SRC-CINCPAC-01849',NULL,1,'verified','CINCPAC, ONI (1430) et rapport du bord (about 1630, zone +10) concordent'),
 ('events','EV-0604-1430-ADAMS','ts','1942-06-04T14:30:00-12:00','Three hours later (1430)','SRC-ONI-CN-1943','attaque du Yorktown',0,'verified',NULL),
 ('missions','MS-0604-CV8AM','course_out','239','The objective, enemy carriers, was calculated to be 155 miles distant, bearing 239° T.','SRC-HORNET-AR',NULL,0,'conflicting',
  'Cap de l''objectif calculé, pas la route volée; le rapport et sa carte sont tenus pour un camouflage (NHHC)'),
 ('missions','MS-0604-CV8AM','course_out','265','as far as the CXAM radar could track the air group, it had flown outbound on a course of 265 degrees','SRC-NHHC','H-Gram 006',1,'conflicting',
  'Retenu malgré le grade (règle 2): au 239°, le groupe aurait trouvé la KB comme VT-8, alors que toutes les sources A attestent l''absence de contact'),
 ('events','EV-0604-0940-CV8TURN','ts','1942-06-04T09:40:00-12:00','At 0940, the skipper of VS-8 unilaterally turned back toward Hornet','SRC-NHHC','H-Gram 006',1,'single_source',NULL),
 ('mission_squadrons','MS-0604-CV8AM/SQ-VB8','aircraft_lost','2','two of these ran out of gas and landed in the Lagoon at Midway','SRC-HORNET-AR',NULL,1,'verified',
  'CINCPAC (« All but 2 of the dive bombers ») et ONI (« 2 landed in the lagoon ») concordent; NHHC en compte 3 (grade C), non retenu'),
 ('mission_squadrons','MS-0604-CV8AM/SQ-VF8','pilots_rescued','8','All 10 of the fighters were forced down for lack of gas and lost at sea, though 8 of the pilots have been recovered','SRC-CINCPAC-01849',NULL,1,'verified',
  'ONI concorde (8 pilotes); le rapport du Hornet, plus précoce, en compte 5'),
 ('events','EV-0604-1402-YKREPART','ts','1942-06-04T14:02:00-12:00','At 1402 ... Yorktown was able to go ahead','SRC-CINCPAC-01849',NULL,1,'verified','BuShips: 20 nds disponibles à 1550 (zone +10) = 13:50'),
 ('events','EV-0604-1718-YKRESCUE','ts','1942-06-04T17:18:00-12:00','By 1918 all survivors were rescued (zone +10)','SRC-BUSHIPS-WDR','Section II §12',1,'single_source',NULL),
 ('events','EV-0607-0501-YKSINK','ts','1942-06-07T05:01:00-12:00','At 0701 YORKTOWN turned over on her port side and sank (zone +10)','SRC-BUSHIPS-WDR','Section II §16',0,'verified',NULL);
"""

print(SQL)

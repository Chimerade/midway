#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Moteur d'inférence des positions par contraintes physiques.
Confronte chaque piste aux contraintes disponibles et JOURNALISE tout
dans position_inferences (+ mise à jour des erreurs réelles des
contacts rapportés). N'ajuste un waypoint que si:
  - le résidu relatif dépasse le seuil,
  - le waypoint est de méthode 'estimated' (jamais une ancre),
  - la contrainte est mieux sourcée que le waypoint.
Usage : python3 inferer_positions.py [base] [--apply]
"""
import sqlite3, math, sys, os
from datetime import datetime, timezone

DB = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__) or '.', 'midway.sqlite')
APPLY = '--apply' in sys.argv
RUN = datetime.now(timezone.utc).isoformat(timespec='seconds')

con = sqlite3.connect(DB)
con.row_factory = sqlite3.Row
cur = con.cursor()

def t(s): return datetime.fromisoformat(s)
def unwrap(lon): return lon - 360 if lon > 0 else lon
def dist_nm(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return math.hypot(dlat, dlon)
def bearing(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return (math.degrees(math.atan2(dlon, dlat)) + 360) % 360

def track(eid):
    return cur.execute("SELECT * FROM positions WHERE entity_id=? ORDER BY ts", (eid,)).fetchall()
def interp(eid, when):
    rows = track(eid)
    if not rows: return None
    if when <= t(rows[0]['ts']): return rows[0]['lat'], rows[0]['lon'], rows[0]['position_error_nm'] or 25
    for a, b in zip(rows, rows[1:]):
        ta, tb = t(a['ts']), t(b['ts'])
        if ta <= when <= tb:
            f = (when - ta).total_seconds() / max(1, (tb - ta).total_seconds())
            return (a['lat'] + f * (b['lat'] - a['lat']),
                    unwrap(a['lon']) + f * (unwrap(b['lon']) - unwrap(a['lon'])),
                    max(a['position_error_nm'] or 25, b['position_error_nm'] or 25))
    last = rows[-1]
    return (last['lat'], unwrap(last['lon']), last['position_error_nm'] or 25) \
        if (when - t(last['ts'])).total_seconds() < 6 * 3600 else None

def log(ctype, ent_t, ent_id, ts, inputs, expected, observed, residual, action, justification, sources, shift=0):
    cur.execute("""INSERT INTO position_inferences
      (run_ts,constraint_type,entity_table,entity_id,ts,inputs,expected,observed,
       residual_nm,action,shift_nm,justification,source_ids)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
      (RUN, ctype, ent_t, ent_id, ts, inputs, expected, observed, residual, action, shift, justification, sources))

n_ok = n_flag = n_adj = 0
def count(action):
    global n_ok, n_flag, n_adj
    if action == 'ok': n_ok += 1
    elif action == 'flagged': n_flag += 1
    else: n_adj += 1

# ============================================================
# 1. ANCRES ÉPAVES : dérive entre dernière position en route et épave
# ============================================================
# Chaque navire frappé est borné par SA PROPRE piste de dérive (pas celle
# de sa formation — leçon du 1er run: la formation retraite, l'épave dérive)
WRECK_DRIFT = [  # (piste du navire, épave, vitesse max dérive/remorquage kn)
    ('SH-KAGA', 'SH-KAGA', 2),  ('SH-SORYU', 'SH-SORYU', 2),
    ('SH-AKAGI', 'SH-AKAGI', 2), ('SH-HIRYU', 'SH-HIRYU', 6),
    ('SH-CV5', 'SH-CV5', 4), ('CRUDIV7', 'SH-MIKUMA', 12),
]
for track_id, wreck_id, vmax in WRECK_DRIFT:
    w = cur.execute("SELECT * FROM positions WHERE entity_id=? ORDER BY ts DESC LIMIT 1", (wreck_id,)).fetchone()
    rows = [r for r in track(track_id) if t(r['ts']) < t(w['ts'])]
    if not rows or not w: continue
    last = rows[-1]
    d = dist_nm(last['lat'], last['lon'], w['lat'], w['lon'])
    h = (t(w['ts']) - t(last['ts'])).total_seconds() / 3600
    ok = d <= vmax * h + (w['position_error_nm'] or 10) + (last['position_error_nm'] or 25)
    action = 'ok' if ok else 'flagged'; count(action)
    log('wreck_anchor', 'positions', track_id, last['ts'],
        f"épave {wreck_id}@{w['ts']}", f"dérive <= {vmax}kn × {h:.1f}h = {vmax*h:.0f} nm (+erreurs)",
        f"{d:.0f} nm", round(d - vmax * h, 1), action,
        f"La position d'épave de {wreck_id} (source TROM/CINCPAC, la meilleure ancre disponible) "
        f"borne la piste en amont: dérive/remorquage de {d:.0f} nm en {h:.1f} h "
        f"{'compatible' if ok else 'INCOMPATIBLE'} avec {vmax} nds max.",
        'SRC-COMBINEDFLEET,SRC-CINCPAC-01849')

# ============================================================
# 2. TEMPS DE VOL ALLER (chaque segment de raid vs type le plus lent)
# ============================================================
legs = cur.execute("""
  SELECT l.*, m.side, m.mission_id mid,
    (SELECT MIN(a.cruise_speed_kn) FROM mission_squadrons ms
      JOIN squadrons s ON s.squadron_id=ms.squadron_id
      JOIN aircraft_types a ON a.type_id=s.type_id WHERE ms.mission_id=m.mission_id) vslow
  FROM mission_legs l JOIN missions m ON m.mission_id=l.mission_id
  WHERE l.start_ts IS NOT NULL AND l.end_ts IS NOT NULL""").fetchall()
for l in legs:
    if not l['vslow']: continue
    h = (t(l['end_ts']) - t(l['start_ts'])).total_seconds() / 3600
    d = dist_nm(l['start_lat'], l['start_lon'], l['end_lat'], l['end_lon'])
    dmax = l['vslow'] * 1.35 * h
    ok = d <= dmax
    action = 'ok' if ok else 'flagged'; count(action)
    log('flight_time_out', 'mission_legs', l['mid'], l['start_ts'],
        f"leg {l['seq']}; type le plus lent {l['vslow']:.0f} kn",
        f"<= {dmax:.0f} nm en {h*60:.0f} min", f"{d:.0f} nm",
        round(d - dmax, 1), action,
        f"Le segment {l['seq']} de {l['mid']} parcourt {d:.0f} nm en {h*60:.0f} min "
        f"({d/h:.0f} kn sol) — {'compatible' if ok else 'IMPOSSIBLE'} pour le type le plus lent "
        f"de la mission ({l['vslow']:.0f} kn croisière, marge ×1.35 vent/régime). "
        f"Un déplacement net inférieur est admis (recherche, regroupement).",
        'aircraft_types (fiches techniques)')

# ============================================================
# 3. TEMPS DE VOL RETOUR (attaque -> récupération sur la piste d'origine)
# ============================================================
ORIGIN = {'SH-CV6': 'TF-16', 'SH-HORNET': 'TF-16', 'SH-CV5': 'TF-17', 'SH-HIRYU': 'SH-HIRYU'}
for m in cur.execute("""SELECT m.*, (SELECT MIN(a.cruise_speed_kn) FROM mission_squadrons ms
        JOIN squadrons s ON s.squadron_id=ms.squadron_id
        JOIN aircraft_types a ON a.type_id=s.type_id WHERE ms.mission_id=m.mission_id) vslow
        FROM missions m WHERE m.attack_ts IS NOT NULL AND m.recovery_ts IS NOT NULL""").fetchall():
    tr = ORIGIN.get(m['origin_ship_id'])
    if not tr or not m['vslow']: continue
    lastleg = cur.execute("SELECT * FROM mission_legs WHERE mission_id=? ORDER BY seq DESC LIMIT 1", (m['mission_id'],)).fetchone()
    if not lastleg: continue
    home = interp(tr, t(m['recovery_ts']))
    if not home: continue
    d = dist_nm(lastleg['end_lat'], lastleg['end_lon'], home[0], home[1])
    h = (t(m['recovery_ts']) - t(m['attack_ts'])).total_seconds() / 3600
    if h <= 0: continue
    dmax = m['vslow'] * 1.35 * h + home[2]
    ok = d <= dmax
    action = 'ok' if ok else 'flagged'; count(action)
    log('flight_time_return', 'missions', m['mission_id'], m['recovery_ts'],
        f"point d'attaque (leg final) -> piste {tr} à la récupération",
        f"<= {dmax:.0f} nm en {h*60:.0f} min", f"{d:.0f} nm", round(d - dmax, 1), action,
        f"Retour de {m['mission_id']}: {d:.0f} nm entre le point d'attaque et {tr} au moment de la "
        f"récupération ({m['recovery_ts'][11:16]}), en {h*60:.0f} min — "
        f"{'cohérent' if ok else 'INCOHÉRENT'} (croisière {m['vslow']:.0f} kn, blessés/regroupement admis). "
        f"Cette contrainte BORNE LA POSITION du porte-avions à l'heure de récupération.",
        'missions (heures sourcées) + aircraft_types')

# ============================================================
# 4. CONTACTS RAPPORTÉS : résidu position rapportée vs piste réelle
#    -> remplit position_error_actual_nm + décompose relèvement/distance
# ============================================================
CONTACT_TARGET = {'CR-0604-0552-PBY': ('KIDO-BUTAI', 'Midway -> KB'),
                  'CR-TONE4-0728': ('TF-16', 'Tone n°4 -> TF US'),
                  'CR-TONE4-0820': ('TF-16', 'Tone n°4 (suivi)'),
                  'CR-0604-1445-ADAMS': ('SH-HIRYU', 'VS-5 (Adams) -> Hiryū')}
MIDWAY = (28.21, -177.37)
for r in cur.execute("SELECT * FROM contact_reports WHERE reported_lat IS NOT NULL").fetchall():
    target, lbl = CONTACT_TARGET.get(r['report_id'], (None, None))
    if not target: continue
    actual = interp(target, t(r['ts_observed']))
    if not actual: continue
    d = dist_nm(r['reported_lat'], r['reported_lon'], actual[0], actual[1])
    brg_rep = bearing(*MIDWAY, r['reported_lat'], r['reported_lon'])
    brg_act = bearing(*MIDWAY, actual[0], actual[1])
    rng_rep = dist_nm(*MIDWAY, r['reported_lat'], r['reported_lon'])
    rng_act = dist_nm(*MIDWAY, actual[0], actual[1])
    cur.execute("UPDATE contact_reports SET position_error_actual_nm=? WHERE report_id=?", (round(d, 1), r['report_id']))
    action = 'adjusted'; count(action)  # ajustement = la métadonnée d'erreur, jamais la piste
    log('contact_residual', 'contact_reports', r['report_id'], r['ts_observed'],
        f"piste {target} interpolée à {r['ts_observed'][11:16]}",
        f"rapporté: relèvement {brg_rep:.0f}° / {rng_rep:.0f} nm de Midway",
        f"réel: {brg_act:.0f}° / {rng_act:.0f} nm", round(d, 1), action,
        f"{lbl}: erreur totale {d:.0f} nm, décomposée en {abs(brg_rep-brg_act):.0f}° de relèvement "
        f"et {abs(rng_rep-rng_act):.0f} nm de distance. L'erreur est attribuée AU RAPPORT (estime de "
        f"l'observateur), pas à la piste: la piste {target} est mieux contrainte (épaves, temps de vol). "
        f"Champ position_error_actual_nm mis à jour.", 'contact_reports + piste reconstruite',
        shift=0)

# ============================================================
# 5. VITESSES NAVALES (journalisation systématique des segments)
# ============================================================
MAXSPD = {'KIDO-BUTAI': 28, 'TF-16': 33, 'TF-17': 33, 'CRUDIV7': 12, 'SH-HIRYU': 34.3, 'SH-CV5': 30,
          'TRANSPORT-GROUP': 14}
for ent, vmax in MAXSPD.items():
    rows = track(ent)
    for a, b in zip(rows, rows[1:]):
        h = (t(b['ts']) - t(a['ts'])).total_seconds() / 3600
        if h <= 0: continue
        v = dist_nm(a['lat'], a['lon'], b['lat'], b['lon']) / h
        ok = v <= vmax * 1.1
        action = 'ok' if ok else 'flagged'; count(action)
        if not ok or v > vmax * 0.85:  # ne journalise que les segments tendus ou fautifs
            log('ship_speed', 'positions', ent, b['ts'],
                f"segment {a['ts'][5:16]} -> {b['ts'][5:16]}; cause: {b['cause_event_id'] or 'NON RATTACHÉE'}",
                f"<= {vmax} kn", f"{v:.0f} kn", round((v - vmax) * h, 1), action,
                f"{ent}: vitesse-déplacement {v:.0f} kn sur le segment (max {vmax} kn). "
                f"{'Cohérent mais tendu: peu de marge pour le zigzag.' if ok else 'IMPOSSIBLE: à corriger.'}",
                'ships.max_speed_kn')

con.commit()

# ============================================================
# RAPPORT
# ============================================================
print(f"=== INFÉRENCE ({RUN}) — {n_ok} ok / {n_flag} flagged / {n_adj} métadonnées ajustées ===\n")
for r in cur.execute("SELECT * FROM position_inferences WHERE run_ts=? ORDER BY constraint_type, residual_nm DESC", (RUN,)):
    tag = {'ok': '✓', 'flagged': '✗', 'adjusted': '→'}[r['action']]
    print(f"[{tag}] {r['constraint_type']:<18} {r['entity_id'] or '':<22} résidu {r['residual_nm'] or 0:>7.1f}  {r['justification'][:110]}")
con.close()
sys.exit(1 if n_flag else 0)

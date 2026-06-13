#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Audit de cohérence de midway.sqlite — banc de test du §10 de la méthodologie.
Usage : python3 audit_coherence.py [chemin_base]
Sortie : liste de constats [FAIL] / [WARN] / [INFO] + score.
"""
import sqlite3, math, sys, os, re
from datetime import datetime
from collections import defaultdict

DB = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__) or '.', 'midway.sqlite')
con = sqlite3.connect(f'file:{DB}?mode=ro&immutable=1', uri=True)
con.row_factory = sqlite3.Row

findings = []
def add(sev, code, msg): findings.append((sev, code, msg))

def t(s): return datetime.fromisoformat(s)
def unwrap(lon): return lon - 360 if lon > 0 else lon
def dist_nm(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return math.hypot(dlat, dlon)

# ============================================================
# A. Structure
# ============================================================
if con.execute("PRAGMA integrity_check").fetchone()[0] != 'ok':
    add('FAIL', 'A1', 'integrity_check non OK')
fk = con.execute("PRAGMA foreign_key_check").fetchall()
if fk: add('FAIL', 'A2', f'{len(fk)} violations de clé étrangère')

# ============================================================
# B. Ordre temporel des missions (launch <= attack <= recovery)
# ============================================================
for m in con.execute("SELECT * FROM missions"):
    seq = [('launch_start', m['launch_start_ts']), ('launch_end', m['launch_end_ts']),
           ('attack', m['attack_ts']), ('recovery', m['recovery_ts'])]
    seq = [(k, v) for k, v in seq if v]
    for (k1, v1), (k2, v2) in zip(seq, seq[1:]):
        if t(v1) > t(v2):
            add('FAIL', 'B1', f"{m['mission_id']}: {k1} ({v1}) > {k2} ({v2})")

# ============================================================
# C. Communications : réception >= émission ; observation <= émission
# ============================================================
for r in con.execute("SELECT * FROM contact_reports"):
    if r['ts_sent'] and r['ts_received'] and t(r['ts_sent']) > t(r['ts_received']):
        add('FAIL', 'C1', f"{r['report_id']}: émis après réception")
    if r['ts_observed'] and r['ts_sent'] and t(r['ts_observed']) > t(r['ts_sent']):
        add('FAIL', 'C2', f"{r['report_id']}: observé après émission")
    if r['reported_lat'] is None:
        add('WARN', 'C3', f"{r['report_id']}: position rapportée absente (inaffichable en mode perçu)")
for r in con.execute("SELECT * FROM messages WHERE ts_sent IS NOT NULL AND ts_received IS NOT NULL"):
    if t(r['ts_sent']) > t(r['ts_received']):
        add('FAIL', 'C1', f"{r['message_id']}: émis après réception")

# ============================================================
# D. Physique des raids : vitesse sol et rayon d'action
# ============================================================
cruise = {r['type_id']: r['cruise_speed_kn'] for r in con.execute("SELECT type_id, cruise_speed_kn FROM aircraft_types")}
radius = {r['type_id']: r['combat_radius_nm'] for r in con.execute("SELECT type_id, combat_radius_nm FROM aircraft_types")}
mission_types = defaultdict(list)
for r in con.execute("SELECT ms.mission_id, s.type_id FROM mission_squadrons ms JOIN squadrons s ON s.squadron_id=ms.squadron_id"):
    if r['type_id']: mission_types[r['mission_id']].append(r['type_id'])
legs_by_mission = defaultdict(list)
for l in con.execute("SELECT * FROM mission_legs WHERE start_ts IS NOT NULL AND end_ts IS NOT NULL"):
    legs_by_mission[l['mission_id']].append(l)
    h = (t(l['end_ts']) - t(l['start_ts'])).total_seconds() / 3600
    if h <= 0:
        add('FAIL', 'D0', f"{l['mission_id']} leg{l['seq']}: durée nulle ou négative"); continue
    d = dist_nm(l['start_lat'], l['start_lon'], l['end_lat'], l['end_lon'])
    types = mission_types.get(l['mission_id'], [])
    if types:
        vmax = min(cruise[tp] for tp in types if cruise.get(tp)) * 1.35  # marge vent/régime
        if d / h > vmax:
            add('FAIL', 'D1', f"{l['mission_id']} leg{l['seq']}: {d/h:.0f} kn sol > {vmax:.0f} (type le plus lent ×1.35)")
search_missions = {r[0] for r in con.execute("SELECT mission_id FROM missions WHERE mission_type='search'")}
for mid, legs in legs_by_mission.items():
    if mid in search_missions:
        continue  # profil recherche: pas de charge offensive, rayon != rayon de combat;
                  # et les éventails additionnent les lignes d'appareils différents
    types = mission_types.get(mid, [])
    if types:
        rmin = min(radius[tp] for tp in types if radius.get(tp))
        total = sum(dist_nm(l['start_lat'], l['start_lon'], l['end_lat'], l['end_lon']) for l in legs)
        if total > rmin * 2.2:
            add('WARN', 'D2', f"{mid}: trajets {total:.0f} nm > 2.2×rayon de combat du type le plus lent ({rmin} nm)")

# ============================================================
# E. Physique des pistes navales : vitesse-déplacement <= vitesse max
# ============================================================
MAXSPD = {'KIDO-BUTAI': 28, 'TF-16': 33, 'TF-17': 33, 'CRUDIV7': 35,
          'SH-HIRYU': 34.3, 'SH-CV5': 30}
for ent, vmax in MAXSPD.items():
    rows = con.execute("SELECT ts, lat, lon FROM positions WHERE entity_id=? ORDER BY ts", (ent,)).fetchall()
    for a, b in zip(rows, rows[1:]):
        h = (t(b['ts']) - t(a['ts'])).total_seconds() / 3600
        if h > 0:
            v = dist_nm(a['lat'], a['lon'], b['lat'], b['lon']) / h
            if v > vmax * 1.1:
                add('FAIL', 'E1', f"{ent}: {v:.0f} kn entre {a['ts'][5:16]} et {b['ts'][5:16]} (max {vmax})")

# ============================================================
# F. Engagements SIMULTANÉS des escadrilles vs effectif
# (les rotations successives sont légitimes; seul le chevauchement
#  temporel d'engagements > effectif est une incohérence)
# ============================================================
strength = {r['squadron_id']: r['strength_0406'] for r in con.execute("SELECT squadron_id, strength_0406 FROM squadrons")}
sq_intervals = defaultdict(list)
for r in con.execute("""SELECT ms.squadron_id, ms.aircraft_committed,
                               m.launch_start_ts, COALESCE(m.recovery_ts, m.attack_ts, m.launch_end_ts, m.launch_start_ts) fin
                        FROM mission_squadrons ms JOIN missions m ON m.mission_id=ms.mission_id
                        WHERE m.launch_start_ts IS NOT NULL AND ms.aircraft_committed IS NOT NULL"""):
    sq_intervals[r['squadron_id']].append((t(r['launch_start_ts']), t(r['fin']), r['aircraft_committed']))
for sq, ivs in sq_intervals.items():
    if not strength.get(sq): continue
    bounds = sorted({x for a, b, _ in ivs for x in (a, b)})
    for x in bounds:
        conc = sum(c for a, b, c in ivs if a <= x < b)
        if conc > strength[sq]:
            add('WARN', 'F1', f"{sq}: {conc} appareils engagés simultanément à {x.isoformat()[5:16]} > effectif {strength[sq]}")
            break

# ============================================================
# G. Départ des raids proche de la plateforme d'origine
# ============================================================
ORIGIN_TRACK = {'SH-CV6': 'TF-16', 'SH-HORNET': 'TF-16', 'SH-CV5': 'TF-17',
                'SH-HIRYU': 'SH-HIRYU', 'SH-MIDWAY': 'SH-MIDWAY'}
def pos_at(ent, ts, tol_h=3):
    rows = con.execute("SELECT ts, lat, lon FROM positions WHERE entity_id=? ORDER BY ts", (ent,)).fetchall()
    best, bdt = None, tol_h * 3600
    for r in rows:
        dt = abs((t(r['ts']) - ts).total_seconds())
        if dt < bdt: best, bdt = r, dt
    return best
for m in con.execute("SELECT mission_id, origin_ship_id FROM missions WHERE origin_ship_id IS NOT NULL"):
    legs = sorted(legs_by_mission.get(m['mission_id'], []), key=lambda l: l['seq'])
    if not legs: continue
    l1 = legs[0]
    track = ORIGIN_TRACK.get(m['origin_ship_id'])
    if not track: continue
    p = pos_at(track, t(l1['start_ts']))
    if p:
        d = dist_nm(l1['start_lat'], l1['start_lon'], p['lat'], p['lon'])
        if d > 60:
            add('WARN', 'G1', f"{m['mission_id']}: 1er segment démarre à {d:.0f} nm de la piste de {track} (split en route? sinon incohérence)")

# ============================================================
# H. Couverture temporelle des pistes (trous pour la carte)
# ============================================================
tmin_all = t('1942-06-03T00:00:00-12:00'); tmax_all = t('1942-06-07T08:00:00-12:00')
ACTIVE_UNTIL = {  # fin d'existence attendue de l'entité
    'KIDO-BUTAI': '1942-06-05T09:12:00-12:00', 'TF-16': '1942-06-07T08:00:00-12:00',
    'TF-17': '1942-06-06T14:00:00-12:00', 'CRUDIV7': '1942-06-06T19:30:00-12:00',
    'SH-HIRYU': '1942-06-05T09:12:00-12:00', 'SH-CV5': '1942-06-07T07:01:00-12:00'}
for ent, until in ACTIVE_UNTIL.items():
    rows = con.execute("SELECT MIN(ts) a, MAX(ts) b, COUNT(*) n FROM positions WHERE entity_id=?", (ent,)).fetchone()
    if not rows['n']:
        add('WARN', 'H1', f"{ent}: aucune position"); continue
    gap_end = (t(until) - t(rows['b'])).total_seconds() / 3600
    if gap_end > 6:
        add('WARN', 'H2', f"{ent}: dernière position {rows['b'][5:16]} mais actif jusqu'à {until[5:16]} ({gap_end:.0f} h sans piste)")

# Missions avec attaque mais sans aucun segment (inaffichables)
for m in con.execute("""SELECT mission_id FROM missions WHERE attack_ts IS NOT NULL
                        AND mission_id NOT IN (SELECT DISTINCT mission_id FROM mission_legs)"""):
    add('WARN', 'H3', f"{m['mission_id']}: mission avec attaque mais sans segment de trajet")

# ============================================================
# I. Tables structurantes encore vides (backlog de phases)
# ============================================================
for tbl, phase in [('squadron_status', 'Phase 5'), ('weather_obs', 'Phase 2/5'),
                   ('damage_states', 'Phase 3/5'), ('knowledge_states', 'Phase 6')]:
    n = con.execute(f"SELECT COUNT(*) FROM {tbl}").fetchone()[0]
    if n == 0: add('INFO', 'I1', f"table {tbl} vide ({phase})")

# ============================================================
# J. Nommage : l'heure encodée dans event_id doit matcher ts (±15 min)
# ============================================================
for e in con.execute("SELECT event_id, ts FROM events"):
    m = re.match(r'EV-(\d{4})-(\d{4})-', e['event_id'])
    if m:
        hh, mm = int(m.group(2)[:2]), int(m.group(2)[2:])
        ts = t(e['ts'])
        delta = abs((ts.hour * 60 + ts.minute) - (hh * 60 + mm))
        if 15 < delta < 1380:
            add('WARN', 'J1', f"{e['event_id']}: id encode {m.group(2)} mais ts = {e['ts'][11:16]}")

# ============================================================
# K. Sourçage : champs critiques sans claim
# ============================================================
claimed = {(r['entity_table'], r['entity_id'], r['field'])
           for r in con.execute("SELECT entity_table, entity_id, field FROM claims")}
n_sq = con.execute("SELECT COUNT(*) FROM squadrons WHERE strength_0406 IS NOT NULL").fetchone()[0]
n_sq_claimed = len([1 for r in con.execute("SELECT squadron_id FROM squadrons WHERE strength_0406 IS NOT NULL")
                    if ('squadrons', r['squadron_id'], 'strength_0406') in claimed])
add('INFO', 'K1', f"effectifs d'escadrilles sourcés: {n_sq_claimed}/{n_sq}")
n_ev = con.execute("SELECT COUNT(*) FROM events").fetchone()[0]
n_ev_claimed = len({eid for (tb, eid, f) in claimed if tb == 'events'})
add('INFO', 'K2', f"événements avec au moins une claim: {n_ev_claimed}/{n_ev}")

# ============================================================
# M. Causalité des mouvements + inférences (Phase 7)
# ============================================================
cols = [r[1] for r in con.execute("PRAGMA table_info(positions)")]
if 'cause_event_id' in cols:
    for r in con.execute("""SELECT entity_id, ts FROM positions
                            WHERE cause_event_id IS NULL AND entity_id != 'SH-MIDWAY'"""):
        add('WARN', 'M1', f"waypoint sans événement-cause: {r['entity_id']} @ {r['ts'][5:16]}")
    for r in con.execute("SELECT report_id FROM contact_reports WHERE actual_event_id IS NULL"):
        add('FAIL', 'M2', f"{r['report_id']}: contact rapporté sans événement associé (doit figurer dans la chronologie)")
    try:
        ni = con.execute("SELECT action, COUNT(*) FROM position_inferences GROUP BY action").fetchall()
        if ni: add('INFO', 'M3', "inférences: " + ", ".join(f"{a}={n}" for a, n in ni))
        else: add('INFO', 'M3', "aucune inférence enregistrée — lancer inferer_positions.py")
        nf_ = con.execute("SELECT COUNT(*) FROM position_inferences WHERE action='flagged'").fetchone()[0]
        if nf_: add('FAIL', 'M4', f"{nf_} contraintes physiques violées (voir position_inferences)")
    except sqlite3.OperationalError:
        add('WARN', 'M3', "table position_inferences absente — appliquer phase7_causes.sql")
    try:
        rf = con.execute("SELECT verdict, COUNT(*) FROM replay_findings GROUP BY verdict").fetchall()
        if rf:
            add('INFO', 'M5', "replay F1: " + ", ".join(f"{v}={n}" for v, n in rf))
            ni = con.execute("SELECT COUNT(*) FROM replay_findings WHERE verdict='incoherent'").fetchone()[0]
            if ni: add('FAIL', 'M6', f"{ni} opérations historiques impossibles dans le modèle (voir replay_findings)")
        else:
            add('INFO', 'M5', "replay F1 non exécuté — lancer simulateur_f1.py")
    except sqlite3.OperationalError:
        add('INFO', 'M5', "replay F1 non exécuté — lancer simulateur_f1.py")

# ============================================================
# O. Synchronisation missions <-> chronologie : tout départ de
#    mission doit avoir un événement à ±30 min (sinon la carte
#    montre un mouvement que le fil n'explique pas)
# ============================================================
ev_times = [t(r[0]) for r in con.execute("SELECT ts FROM events")]
for m in con.execute("SELECT mission_id, launch_start_ts FROM missions WHERE launch_start_ts IS NOT NULL"):
    if not any(abs((t(m['launch_start_ts']) - e).total_seconds()) <= 1800 for e in ev_times):
        add('WARN', 'O1', f"{m['mission_id']}: départ {m['launch_start_ts'][5:16]} sans événement à ±30 min dans la chronologie")

# ============================================================
# N. Convention des caps : le cap consigné à un waypoint doit
#    correspondre (±45°) à la route effective du segment SORTANT
# ============================================================
def route_deg(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return (math.degrees(math.atan2(dlon, dlat)) + 360) % 360
for ent in [r[0] for r in con.execute("SELECT DISTINCT entity_id FROM positions WHERE entity_table='formations'")]:
    rows = con.execute("SELECT ts, lat, lon, course_deg FROM positions WHERE entity_id=? ORDER BY ts", (ent,)).fetchall()
    for a, b in zip(rows, rows[1:]):
        if a['course_deg'] is None: continue
        if dist_nm(a['lat'], a['lon'], b['lat'], b['lon']) < 8: continue  # quasi-stationnaire
        r = route_deg(a['lat'], a['lon'], b['lat'], b['lon'])
        diff = abs((r - a['course_deg'] + 180) % 360 - 180)
        if diff > 45:
            add('WARN', 'N1', f"{ent} @ {a['ts'][5:16]}: cap consigné {a['course_deg']:.0f}° mais route sortante {r:.0f}° (écart {diff:.0f}°) — virage manquant ou cap à corriger")

# ============================================================
# G. Cohérence cinématique des événements : à event.ts, l'acteur/
#    observateur doit être à portée de sa cible. Confronte la
#    sémantique (event_participants) à la cinématique réellement
#    dessinée (positions pour navires/formations, mission_legs pour
#    avions — miroir exact du renderer). Évite les « frappes/détections
#    sans avion sur l'objectif ».
# ============================================================
def _pos_track(eid, when):
    rows = con.execute("SELECT ts,lat,lon FROM positions WHERE entity_id=? ORDER BY ts", (eid,)).fetchall()
    if not rows: return None
    if when <= t(rows[0]['ts']): return (rows[0]['lat'], rows[0]['lon'])
    for a, b in zip(rows, rows[1:]):
        ta, tb = t(a['ts']), t(b['ts'])
        if ta <= when <= tb:
            f = (when - ta).total_seconds() / max(1, (tb - ta).total_seconds())
            return (a['lat'] + f*(b['lat']-a['lat']), unwrap(a['lon']) + f*(unwrap(b['lon'])-unwrap(a['lon'])))
    last = rows[-1]
    return (last['lat'], unwrap(last['lon'])) if (when - t(last['ts'])).total_seconds() < 6*3600 else None

def _sqn_pos(sqid, when):
    out = []
    for l in con.execute("""SELECT l.start_ts,l.end_ts,l.start_lat,l.start_lon,l.end_lat,l.end_lon
                            FROM mission_legs l JOIN mission_squadrons ms ON ms.mission_id=l.mission_id
                            WHERE ms.squadron_id=? AND l.start_ts IS NOT NULL AND l.end_ts IS NOT NULL""", (sqid,)):
        ta, tb = t(l['start_ts']), t(l['end_ts'])
        if not (ta <= when <= tb): continue
        f = (when - ta).total_seconds() / max(1, (tb - ta).total_seconds())
        out.append((l['start_lat'] + f*(l['end_lat']-l['start_lat']),
                    unwrap(l['start_lon']) + f*(unwrap(l['end_lon'])-unwrap(l['start_lon']))))
    return out

def _entity_pos(etable, eid, when):
    if etable in ('ships', 'formations'):
        p = _pos_track(eid, when); return [p] if p else []
    if etable == 'squadrons':
        return _sqn_pos(eid, when)
    return []

G_RULES = {  # event_type : (tolérance_nm, sévérité, libellé de la relation)
    'attack': (10, 'FAIL', 'acteur sur cible'), 'hit': (10, 'FAIL', 'acteur sur cible'),
    'sinking': (10, 'FAIL', 'acteur sur cible'), 'scuttling': (10, 'FAIL', 'acteur sur cible'),
    'sighting': (40, 'WARN', 'observateur à portée'), 'spot': (40, 'WARN', 'observateur à portée'),
    'recovery_start': (5, 'WARN', 'avion sur navire'), 'recovery_end': (5, 'WARN', 'avion sur navire'),
}
g_unverif = 0
for e in con.execute("SELECT event_id, ts, event_type FROM events WHERE event_type IN (%s)"
                     % ','.join('?'*len(G_RULES)), tuple(G_RULES)):
    when = t(e['ts']); tol, sev, rel = G_RULES[e['event_type']]
    parts = con.execute("SELECT role,entity_table,entity_id FROM event_participants WHERE event_id=?",
                        (e['event_id'],)).fetchall()
    movers = [p for p in parts if p['role'] in ('actor', 'observer')]
    targets = [p for p in parts if p['role'] == 'target']
    if not movers or not targets:
        g_unverif += 1; continue
    best = None; air_unpositioned = False
    for m in movers:
        mps = _entity_pos(m['entity_table'], m['entity_id'], when)
        if not mps and m['entity_table'] == 'squadrons': air_unpositioned = True
        for tg in targets:
            for tp in _entity_pos(tg['entity_table'], tg['entity_id'], when):
                for mp in mps:
                    d = dist_nm(mp[0], mp[1], tp[0], tp[1])
                    if best is None or d < best[0]: best = (d, m['entity_id'], tg['entity_id'])
    if best is None:
        if air_unpositioned and e['event_type'] in ('attack', 'hit', 'sinking', 'scuttling'):
            add('WARN', 'G2', f"{e['event_id']} ({e['ts'][11:16]}): acteur aérien non dessiné à l'instant de la frappe (trou entre legs ?)")
        else:
            g_unverif += 1
        continue
    d, mid, tid = best
    if d > tol:
        add(sev, 'G1', f"{e['event_id']} ({e['ts'][11:16]}): {mid}→{tid} {d:.0f} nm > {tol} nm ({rel})")
if g_unverif:
    add('INFO', 'G0', f"{g_unverif} événements spatiaux non vérifiables (rôle actor/observer ou target manquant — complétude event_participants)")

# ============================================================
# Rapport
# ============================================================
order = {'FAIL': 0, 'WARN': 1, 'INFO': 2}
findings.sort(key=lambda x: (order[x[0]], x[1]))
nf = sum(1 for s, _, _ in findings if s == 'FAIL')
nw = sum(1 for s, _, _ in findings if s == 'WARN')
print(f"=== AUDIT {os.path.basename(DB)} — {nf} FAIL / {nw} WARN / {len(findings)-nf-nw} INFO ===\n")
for sev, code, msg in findings:
    print(f"[{sev}] {code}  {msg}")
sys.exit(1 if nf else 0)

#!/usr/bin/env python3
"""Diagnostic LECTURE SEULE — cohérence cinématique des événements.

Confronte les deux représentations spatiales à l'instant `event.ts` :
  - sémantique : events + event_participants (rôles actor/observer/target)
  - cinématique : positions (navires/formations) + mission_legs (avions)

Pour chaque événement spatial, calcule la distance réelle entre l'acteur/observateur
et la cible, et la compare à une tolérance par type. N'écrit RIEN.

Usage : python3 diag_cinematique.py [base.sqlite]
"""
import sqlite3, sys, math
from datetime import datetime

DB = sys.argv[1] if len(sys.argv) > 1 else 'midway.sqlite'
con = sqlite3.connect(DB); con.row_factory = sqlite3.Row

def t(s): return datetime.fromisoformat(s)
def unwrap(lon): return lon - 360 if lon > 0 else lon
def dist_nm(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return math.hypot(dlat, dlon)

# --- Résolveur de position à T -------------------------------------------------
def interp_track(eid, when):
    """Position interpolée d'un navire/formation depuis la table positions."""
    rows = con.execute("SELECT ts,lat,lon FROM positions WHERE entity_id=? ORDER BY ts", (eid,)).fetchall()
    if not rows: return None
    if when <= t(rows[0]['ts']): return (rows[0]['lat'], rows[0]['lon'])
    for a, b in zip(rows, rows[1:]):
        ta, tb = t(a['ts']), t(b['ts'])
        if ta <= when <= tb:
            f = (when - ta).total_seconds() / max(1, (tb - ta).total_seconds())
            return (a['lat'] + f * (b['lat'] - a['lat']),
                    unwrap(a['lon']) + f * (unwrap(b['lon']) - unwrap(a['lon'])))
    last = rows[-1]
    if (when - t(last['ts'])).total_seconds() < 6 * 3600:
        return (last['lat'], unwrap(last['lon']))
    return None

def squadron_positions(sqid, when):
    """Positions de TOUTES les lignes actives d'une escadrille à T (éventails inclus).
    squadron -> mission_squadrons -> mission_legs actifs à `when`. Miroir du renderer."""
    legs = con.execute("""
        SELECT l.start_ts,l.end_ts,l.start_lat,l.start_lon,l.end_lat,l.end_lon
        FROM mission_legs l
        JOIN mission_squadrons ms ON ms.mission_id = l.mission_id
        WHERE ms.squadron_id = ? AND l.start_ts IS NOT NULL AND l.end_ts IS NOT NULL""", (sqid,)).fetchall()
    out = []
    for l in legs:
        ta, tb = t(l['start_ts']), t(l['end_ts'])
        if not (ta <= when <= tb): continue
        f = (when - ta).total_seconds() / max(1, (tb - ta).total_seconds())
        out.append((l['start_lat'] + f * (l['end_lat'] - l['start_lat']),
                    unwrap(l['start_lon']) + f * (unwrap(l['end_lon']) - unwrap(l['start_lon']))))
    return out

def positions_of(entity_table, eid, when):
    """Renvoie une liste de positions candidates (>=0) pour une entité à T."""
    if entity_table in ('ships', 'formations'):
        p = interp_track(eid, when)
        return [p] if p else []
    if entity_table == 'squadrons':
        return squadron_positions(eid, when)
    return []  # persons : pas de cinématique propre

# --- Tolérances et sévérité par type d'événement -------------------------------
#   (type) -> (tolérance_nm, sévérité, libellé de la relation)
RULES = {
    'attack':   (10, 'FAIL', 'acteur sur cible'),
    'hit':      (10, 'FAIL', 'acteur sur cible'),
    'sinking':  (10, 'FAIL', 'acteur sur cible'),
    'scuttling':(10, 'FAIL', 'acteur sur cible'),
    'sighting': (40, 'WARN', 'observateur à portée visuelle'),
    'spot':     (40, 'WARN', 'observateur à portée visuelle'),
    'recovery_start': (5, 'WARN', 'avion sur navire'),
    'recovery_end':   (5, 'WARN', 'avion sur navire'),
}

# --- Boucle de contrôle --------------------------------------------------------
rows = con.execute("""SELECT e.event_id, e.ts, e.event_type, e.summary
                      FROM events e WHERE e.event_type IN (%s) ORDER BY e.ts"""
                   % ','.join('?'*len(RULES)), tuple(RULES)).fetchall()

results = []   # (severite, dist, ev, detail)
skipped = []   # (ev, raison)
for e in rows:
    when = t(e['ts'])
    tol, sev, rel = RULES[e['event_type']]
    parts = con.execute("SELECT role,entity_table,entity_id FROM event_participants WHERE event_id=?",
                        (e['event_id'],)).fetchall()
    movers = [p for p in parts if p['role'] in ('actor', 'observer')]
    targets = [p for p in parts if p['role'] == 'target']
    if not movers:
        skipped.append((e, "pas d'acteur/observateur")); continue
    if not targets:
        skipped.append((e, "pas de cible")); continue
    # meilleur (= plus proche) couple acteur/cible : on veut "au moins un avion touche la cible"
    best = None
    for m in movers:
        mps = positions_of(m['entity_table'], m['entity_id'], when)
        if not mps: continue
        for tg in targets:
            tps = positions_of(tg['entity_table'], tg['entity_id'], when)
            if not tps: continue
            for mp in mps:
                for tp in tps:
                    d = dist_nm(mp[0], mp[1], tp[0], tp[1])
                    if best is None or d < best[0]:
                        best = (d, m['entity_id'], tg['entity_id'])
    if best is None:
        skipped.append((e, "position introuvable (pas de leg/track actif à T)")); continue
    d, mid, tid = best
    flag = sev if d > tol else 'OK'
    results.append((flag, d, tol, e, mid, tid, rel))

# --- Rapport -------------------------------------------------------------------
order = {'FAIL': 0, 'WARN': 1, 'OK': 2}
results.sort(key=lambda r: (order[r[0]], -r[1]))
nf = sum(1 for r in results if r[0] == 'FAIL')
nw = sum(1 for r in results if r[0] == 'WARN')
nok = sum(1 for r in results if r[0] == 'OK')
print(f"=== DIAG CINÉMATIQUE {DB} — {nf} FAIL / {nw} WARN / {nok} OK / {len(skipped)} non vérifiables ===\n")
for flag, d, tol, e, mid, tid, rel in results:
    if flag == 'OK': continue
    print(f"[{flag}] {e['ts'][11:16]} {e['event_id']:22s} {e['event_type']:9s} "
          f"{mid}→{tid} : {d:5.1f} nm (tol {tol}, {rel})")
    print(f"        « {e['summary'][:78]} »")
print("\n--- OK (cohérents) ---")
for flag, d, tol, e, mid, tid, rel in results:
    if flag != 'OK': continue
    print(f"[ OK ] {e['ts'][11:16]} {e['event_id']:22s} {mid}→{tid} : {d:5.1f} nm (tol {tol})")
if skipped:
    print("\n--- non vérifiables (manque acteur/cible ou cinématique) ---")
    for e, why in skipped:
        print(f"[ -- ] {e['ts'][11:16]} {e['event_id']:22s} {e['event_type']:9s} : {why}")

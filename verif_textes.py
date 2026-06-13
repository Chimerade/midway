#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vérificateur textes vs réalité — chasse les incohérences du type "le texte
dit ~700 nm mais la géométrie dit 450" (cas Reid).
Extrait les valeurs chiffrées des champs textuels (summary, notes, outcome)
et les confronte aux données structurées (positions, legs, effectifs engagés).
Sortie : liste à adjuger manuellement (le script SIGNALE, l'humain tranche).
Usage : python3 verif_textes.py [base]
"""
import sqlite3, re, math, sys, os
from datetime import datetime

DB = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__) or '.', 'midway.sqlite')
con = sqlite3.connect(f'file:{DB}?mode=ro&immutable=1', uri=True)
con.row_factory = sqlite3.Row

MID = (28.21, -177.37)
def unwrap(l): return l - 360 if l > 0 else l
def dist(la1, lo1, la2, lo2):
    dlat = (la2 - la1) * 60
    dlon = (unwrap(lo2) - unwrap(lo1)) * 60 * math.cos(math.radians((la1 + la2) / 2))
    return math.hypot(dlat, dlon)
def t(s): return datetime.fromisoformat(s)

issues, oks = [], 0
def check(kind, ref, mentioned, computed, tol_rel, ctx):
    global oks
    if computed is None: return
    rel = abs(mentioned - computed) / max(computed, 1)
    if rel > tol_rel:
        issues.append((kind, ref, mentioned, computed, ctx))
    else:
        oks += 1

# ------------------------------------------------------------------
# 1. Segments de raid: "X nm" dans la note vs longueur géométrique
# ------------------------------------------------------------------
for l in con.execute("SELECT * FROM mission_legs WHERE notes IS NOT NULL"):
    if 'déplacement net' in l['notes'] or 'distance volée' in l['notes']:
        continue  # note auto-documentée: déplacement != distance parcourue
    vals = [int(m.group(1)) for m in re.finditer(r'(\d{2,4})\s*nm', l['notes'])]
    if vals:
        d = dist(l['start_lat'], l['start_lon'], l['end_lat'], l['end_lon'])
        # cohérent si AU MOINS UNE valeur citée correspond à la longueur du segment
        # (les autres nombres peuvent décrire autre chose: point d'interception, etc.)
        if any(abs(v - d) / max(d, 1) <= 0.18 for v in vals):
            oks += 1
        else:
            issues.append(('LEG-DIST', f"{l['mission_id']} leg{l['seq']}", vals, d,
                           f"note «{l['notes'][:60]}» — aucune valeur citée ne correspond à la longueur {d:.0f} nm"))

# ------------------------------------------------------------------
# 2. Notes de positions: "X nm ... de Midway" vs distance réelle
# ------------------------------------------------------------------
for p in con.execute("SELECT * FROM positions WHERE notes IS NOT NULL"):
    mm = re.search(r'~?(\d{2,4})\s*nm[^.;]{0,25}de Midway', p['notes'])
    if mm:
        d = dist(p['lat'], p['lon'], *MID)
        check('POS-DIST', f"{p['entity_id']} @ {p['ts'][5:16]}", int(mm.group(1)), d, 0.15,
              f"note «{p['notes'][:60]}» vs distance Midway {d:.0f} nm")

# ------------------------------------------------------------------
# 3. Événements: "X nm" + position propre OU "de Midway"/"de la cible"
# ------------------------------------------------------------------
for e in con.execute("SELECT * FROM events WHERE summary LIKE '%nm%'"):
    mm = re.search(r'~?(\d{2,4})\s*nm[^.;]{0,30}de Midway', e['summary'])
    if mm and e['lat'] is not None:
        d = dist(e['lat'], e['lon'], *MID)
        check('EV-DIST', e['event_id'], int(mm.group(1)), d, 0.15,
              f"«{e['summary'][:70]}» vs position de l'événement: {d:.0f} nm de Midway")

# ------------------------------------------------------------------
# 4. Contacts rapportés: "distance X" / "X nm de Midway" dans le texte
#    vs distance(point rapporté, Midway) — vérification d'aller-retour
# ------------------------------------------------------------------
for c in con.execute("SELECT * FROM contact_reports WHERE reported_lat IS NOT NULL"):
    txt = (c['reported_composition'] or '') + ' ' + (c['notes'] or '')
    mm = re.search(r'distance\s+(\d{2,4})|(\d{2,4})\s*nm de Midway', txt)
    if mm:
        d = dist(c['reported_lat'], c['reported_lon'], *MID)
        val = int(mm.group(1) or mm.group(2))
        check('CR-ROUNDTRIP', c['report_id'], val, d, 0.12,
              f"texte du rapport vs point rapporté stocké ({d:.0f} nm de Midway)")

# ------------------------------------------------------------------
# 5. Erreurs d'estime CITÉES dans les textes vs résidus MESURÉS (inférence)
# ------------------------------------------------------------------
for c in con.execute("SELECT * FROM contact_reports WHERE position_error_actual_nm IS NOT NULL"):
    txt = (c['notes'] or '')
    mm = re.search(r'~?(\d{2})-?(\d{2})?\s*nm', txt)
    if mm and ('erreur' in txt or 'erronée' in txt):
        lo = int(mm.group(1)); hi = int(mm.group(2) or mm.group(1))
        if not (lo * 0.7 <= c['position_error_actual_nm'] <= hi * 1.3):
            issues.append(('ERR-MESURE', c['report_id'], f"{lo}-{hi}", c['position_error_actual_nm'],
                           f"le texte cite une erreur ~{lo}-{hi} nm; le moteur d'inférence a mesuré {c['position_error_actual_nm']:.0f} nm"))
        else: oks += 1
for e in con.execute("SELECT e.*, c.position_error_actual_nm err FROM events e JOIN contact_reports c ON c.actual_event_id=e.event_id WHERE e.summary LIKE '%erronée%' AND c.position_error_actual_nm IS NOT NULL"):
    mm = re.search(r'~?(\d{2})-(\d{2})\s*nm', e['summary'])
    if mm:
        lo, hi = int(mm.group(1)), int(mm.group(2))
        if not (lo * 0.7 <= e['err'] <= hi * 1.3):
            issues.append(('ERR-MESURE', e['event_id'], f"{lo}-{hi}", e['err'],
                           f"résumé «...erronée de ~{lo}-{hi} nm» vs résidu mesuré {e['err']:.0f} nm"))
        else: oks += 1

# ------------------------------------------------------------------
# 6. Heures citées dans les résumés vs ts de l'événement (fenêtre ±120 min)
# ------------------------------------------------------------------
for e in con.execute("SELECT * FROM events"):
    ets = t(e['ts']); base = ets.hour * 60 + ets.minute
    for mm in re.finditer(r'(?<![\d:])([01]?\d|2[0-3]):([0-5]\d)(?!\d)', e['summary']):
        # bornes de plage explicites: "jusqu'à HH:MM", "avant/après", "HH:MM-HH:MM"
        prefix = e['summary'][max(0, mm.start() - 14):mm.start()]
        if re.search(r"(jusqu'à\s*~?|avant\s|après\s|-->?\s*|[\d:]-)$", prefix):
            oks += 1; continue
        cited = int(mm.group(1)) * 60 + int(mm.group(2))
        delta = min(abs(cited - base), 1440 - abs(cited - base))
        if delta > 120:
            issues.append(('EV-HEURE', e['event_id'], mm.group(0), f"{ets.hour:02d}:{ets.minute:02d}",
                           f"résumé cite {mm.group(0)} mais ts = {e['ts'][11:16]} (Δ{delta:.0f} min) — citation d'un autre moment? vérifier"))
        else: oks += 1

# ------------------------------------------------------------------
# 7. Effectifs cités dans les textes de mission vs somme engagée
# ------------------------------------------------------------------
# un nombre cité peut désigner le TOTAL ou un SOUS-ENSEMBLE par rôle (ex: "34 SBD"
# = bombardiers seuls, "18 D3A + 6 A6M" = par type). On compare aux deux.
for msn in con.execute("SELECT mission_id, outcome, notes, target_desc FROM missions"):
    sums = {r['role']: r['n'] for r in con.execute("""
        SELECT a.role, SUM(ms.aircraft_committed) n
        FROM mission_squadrons ms JOIN squadrons s ON s.squadron_id=ms.squadron_id
        LEFT JOIN aircraft_types a ON a.type_id=s.type_id
        WHERE ms.mission_id=? GROUP BY a.role""", (msn['mission_id'],))}
    tot = sum(v for v in sums.values() if v)
    if not tot: continue
    candidats = set(v for v in sums.values() if v) | {tot}
    txt = ' '.join(x for x in (msn['outcome'], msn['notes'], msn['target_desc']) if x)
    for mm in re.finditer(r'(?<![~(\d])(\d{1,3})\s+(appareils|SBD|TBD|VSB|PBY|B-17|D3A|B5N|A6M|F4F)', txt):
        v = int(mm.group(1))
        if any(abs(v - c) <= max(2, 0.12 * c) for c in candidats):
            oks += 1
        else:
            issues.append(('MSN-EFFECTIF', msn['mission_id'], mm.group(0), f"total {tot}, par rôle {sums}",
                           f"texte «{mm.group(0)}» ne correspond ni au total ni à un sous-ensemble par rôle"))

# ------------------------------------------------------------------
# 8. Cohérence convoi: vitesse impliquée entre points successifs vs notes "X nds"
# ------------------------------------------------------------------
rows = con.execute("SELECT ts, lat, lon, speed_kn FROM positions WHERE entity_id='TRANSPORT-GROUP' ORDER BY ts").fetchall()
for a, b in zip(rows, rows[1:]):
    h = (t(b['ts']) - t(a['ts'])).total_seconds() / 3600
    v = dist(a['lat'], a['lon'], b['lat'], b['lon']) / h if h else 0
    if a['speed_kn'] and abs(v - a['speed_kn']) > 5:
        issues.append(('VITESSE', f"TRANSPORT-GROUP @ {a['ts'][5:16]}", a['speed_kn'], round(v, 1),
                       f"vitesse consignée {a['speed_kn']} nds vs vitesse-déplacement {v:.1f} nds"))
    else: oks += 1

# ------------------------------------------------------------------
print(f"=== VÉRIF TEXTES vs RÉALITÉ — {len(issues)} à adjuger / {oks} cohérents ===\n")
for kind, ref, mentioned, computed, ctx in issues:
    print(f"[{kind:<13}] {ref:<28} texte: {mentioned} | calculé: {computed if isinstance(computed,str) else round(computed,1)}")
    print(f"               {ctx}\n")
sys.exit(0)

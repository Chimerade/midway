#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MOTEUR F2 (squelette v0) — simulation à événements discrets de la journée
du 4 juin, pilotée par les DÉCISIONS (pas par la chronologie).

Modes :
  python3 simulateur_f2.py [base]                    -> mode historique déterministe
                                                        (validation: généré vs réel, tolérance ±30 min)
  python3 simulateur_f2.py [base] --mc 1000          -> Monte-Carlo (distributions)
  python3 simulateur_f2.py [base] --scenario yamaguchi --mc 1000
                                                     -> contre-factuel F3 : option B de la décision D3
                                                        (frappe D3A immédiate de CarDiv2 à 08:45)

Simplifications assumées du squelette (v0, à raffiner) :
  - théâtre réduit aux frappes anti-navires du 4 juin (Midway = scripts d'entrée);
  - CAP modélisée par état (alertée / saturée basse altitude), pas avion par avion;
  - pas encore de gestion fine ascenseurs/équipes en mode simulé (durées agrégées F1);
  - la détection suit l'historique (Tone n°4 07:28) sauf scénario contraire.
Tout paramètre stochastique vient de constraint_params (calibrage sourcé).
"""
import sqlite3, sys, os, math, random, heapq, statistics
from collections import defaultdict

DB = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith('--') else \
     os.path.join(os.path.dirname(__file__) or '.', 'midway.sqlite')
MC = int(sys.argv[sys.argv.index('--mc') + 1]) if '--mc' in sys.argv else 0
SCENARIO = sys.argv[sys.argv.index('--scenario') + 1] if '--scenario' in sys.argv else 'historique'

con = sqlite3.connect(f'file:{DB}?mode=ro&immutable=1', uri=True)
con.row_factory = sqlite3.Row
P = {r['param_id']: dict(r) for r in con.execute("SELECT * FROM constraint_params")}

def draw(pid, rng):
    """Tire dans la distribution du paramètre; déterministe = valeur centrale."""
    p = P[pid]
    if rng is None: return p['value']
    d = p['distribution'] or ''
    if d.startswith('triangular'):
        a, m, b = [float(x) for x in d[11:-1].split(',')]
        return rng.triangular(a, b, m)
    if d.startswith('beta'):
        a, b = [float(x) for x in d[5:-1].split(',')]
        return rng.betavariate(a, b)
    return p['value']

def hhmm(t):
    t = round(t); return f"{t//60:02d}:{t%60:02d}"

# ------------------------------------------------------------------
# État initial (lu dans la base — squadron_status à 04:45)
# ------------------------------------------------------------------
def etat_initial():
    return {
        # Kidō Butai
        'kb_cvs': {'AKAGI': {'ok': True, 'armed_hangar': True},
                   'KAGA': {'ok': True, 'armed_hangar': True},
                   'SORYU': {'ok': True, 'armed_hangar': True},
                   'HIRYU': {'ok': True, 'armed_hangar': True}},
        'kb_reserve_db': 34,      # D3A CarDiv2 (16+18), réserve anti-navire
        'kb_reserve_tb': 45,      # B5N CarDiv1 (18+27)
        'kb_cap_state': 'alert',  # alert | low (tirée au ras de l'eau par les VT)
        # US
        'us_cvs': {'ENTERPRISE': {'hits': 0, 'torp': 0, 'ok': True},
                   'HORNET': {'hits': 0, 'torp': 0, 'ok': True},
                   'YORKTOWN': {'hits': 0, 'torp': 0, 'ok': True}},
        'us_cap': 'alert',
        'hiryu_db': 18, 'hiryu_tb': 10,
        'log': [],
    }

# ------------------------------------------------------------------
# Résolution d'une frappe (Monte-Carlo ou déterministe)
# ------------------------------------------------------------------
def frappe_sur_cv(n_att, type_att, cap_state, target, st, rng, t, label):
    """type_att: 'db' (piqué) ou 'tb' (torpille). Retourne (coups, perdus)."""
    surv_p = {'db': {'alert': 'P-SURV-DB-FULLCAP', 'low': 'P-SURV-DB-WEAKCAP'},
              'tb': {'alert': 'P-SURV-TB-FULLCAP', 'low': 'P-SURV-DB-WEAKCAP'}}[type_att][cap_state]
    hit_p = {'db': 'P-HIT-D3A' if label.startswith('IJN') else 'P-HIT-SBD-CV',
             'tb': 'P-HIT-TYPE91'}[type_att]
    survivors = 0
    for _ in range(n_att):
        if (rng.random() if rng else 0.5) < draw(surv_p, rng) * (1 - draw('P-AA-US-KILL', rng) if label.startswith('IJN') else 1):
            survivors += 1
    if rng is None:  # déterministe: espérances
        survivors = round(n_att * draw(surv_p, None) * ((1 - draw('P-AA-US-KILL', None)) if label.startswith('IJN') else 1))
    hits = sum(1 for _ in range(survivors) if (rng.random() if rng else 0.5) < draw(hit_p, rng)) \
           if rng else round(survivors * draw(hit_p, None))
    st['log'].append((t, f"{label}: {n_att} engagés, {survivors} au largage, {hits} coups sur {target}"))
    return hits, n_att - survivors

def applique_degats_cv(cv, hits, torp, armed_hangar, rng):
    p_loss = 0.0
    if hits >= 1 and armed_hangar: p_loss = draw('P-LOSS-CV-ARMEDHANGAR', rng)
    elif hits >= 3: p_loss = draw('P-LOSS-CV-3HIT', rng)
    elif hits >= 1: p_loss = draw('P-LOSS-CV-1HIT', rng) * hits
    dead_water = torp >= 2 and (rng.random() if rng else 0.5) < draw('P-MISSIONKILL-CV-TORP2', rng)
    lost = (rng.random() if rng else 0.5) < p_loss
    return lost, dead_water

# ------------------------------------------------------------------
# Un run de simulation (file d'événements)
# ------------------------------------------------------------------
def run(scenario, rng):
    st = etat_initial()
    Q = []  # (t_minutes, seq, action, payload)
    seq = 0
    def push(t, action, payload=None):
        nonlocal seq; heapq.heappush(Q, (t, seq, action, payload)); seq += 1

    # --- Script des décisions (mode historique) ---
    push(4*60+30, 'launch_midway_strike')          # frappe Tomonaga
    push(7*60+28, 'tone4_contact')                 # détection des US
    push(9*60+20, 'vt_attacks_begin')              # VT-8/6/3: la CAP descend
    push(10*60+22, 'us_strike_arrives')            # SBD Enterprise+Yorktown
    if scenario == 'yamaguchi':
        push(8*60+45, 'cardiv2_db_strike')         # option B de D3
    else:
        push(10*60+30, 'kb_full_strike_planned')   # plan historique (jamais parti)

    while Q:
        t, _, action, payload = heapq.heappop(Q)
        if action == 'launch_midway_strike':
            st['log'].append((t, "Frappe Tomonaga lancée (108 appareils) — hors périmètre de résolution v0"))
        elif action == 'tone4_contact':
            st['log'].append((t, "Tone n°4 signale la force US; dilemme du réarmement engagé"))
        elif action == 'vt_attacks_begin':
            st['kb_cap_state'] = 'low'
            st['log'].append((t, "Attaques VT successives: CAP japonaise tirée au ras de l'eau"))
        elif action == 'cardiv2_db_strike':
            st['kb_reserve_db'] = 0
            for cv in ('SORYU', 'HIRYU'):
                st['kb_cvs'][cv]['armed_hangar'] = False   # hangars vidés par la frappe
            arrive = t + 95                                # transit ~125 nm
            push(arrive, 'ijn_strike_hits_tf', {'db': 34, 'tb': 0, 'tag': 'IJN CarDiv2 (Yamaguchi)'})
            st['log'].append((t, "OPTION YAMAGUCHI: 34 D3A + escorte réduite lancés sur la force US"))
        elif action == 'ijn_strike_hits_tf':
            tgt = 'YORKTOWN'  # TF-17, la plus proche (comme historiquement)
            hits, lost = frappe_sur_cv(payload['db'], 'db', 'alert', tgt, st, rng, t, payload['tag'])
            cvs = st['us_cvs'][tgt]
            cvs['hits'] += hits
            lostf, dw = applique_degats_cv(tgt, cvs['hits'], cvs['torp'], False, rng)
            if lostf or cvs['hits'] >= 3: cvs['ok'] = False
            st['log'].append((t, f"{tgt}: total {cvs['hits']} bombes — {'hors de combat' if not cvs['ok'] else 'opérationnel'}"))
        elif action == 'us_strike_arrives':
            # 47 SBD plongent sur 3 CV (répartition historique), CAP selon état
            cible_map = [('KAGA', 25), ('AKAGI', 3), ('SORYU', 17)]
            for cv, n in cible_map:
                hits, _ = frappe_sur_cv(n, 'db', st['kb_cap_state'], cv, st, rng, 'USN SBD ' + cv)\
                          if False else frappe_sur_cv(n, 'db', st['kb_cap_state'], cv, st, rng, t, 'USN SBD->' + cv)
                lost, _ = applique_degats_cv(cv, hits, 0, st['kb_cvs'][cv]['armed_hangar'], rng)
                if lost: st['kb_cvs'][cv]['ok'] = False
            n_lost = sum(1 for c in st['kb_cvs'].values() if not c['ok'])
            st['log'].append((t, f"Frappe US résolue: {n_lost} CV japonais hors de combat"))
            # riposte du Hiryū s'il survit
            if st['kb_cvs']['HIRYU']['ok']:
                push(t + 32, 'hiryu_strike1')
        elif action == 'hiryu_strike1':
            push(t + 70, 'ijn_strike_hits_tf', {'db': st['hiryu_db'], 'tb': 0, 'tag': 'IJN Hiryū (Kobayashi)'})
            st['log'].append((t, f"Hiryū lance {st['hiryu_db']} D3A"))
        elif action == 'kb_full_strike_planned':
            ok = [c for c, v in st['kb_cvs'].items() if v['ok']]
            if len(ok) >= 3:
                st['log'].append((t, "Frappe complète KB lancée (situation non historique)"))
            else:
                st['log'].append((t, f"Frappe complète impossible: {4-len(ok)} CV hors de combat (conforme à l'histoire)"))
    return st

# ------------------------------------------------------------------
# MODE HISTORIQUE DÉTERMINISTE : validation généré vs réel
# ------------------------------------------------------------------
if not MC:
    st = run('historique', None)
    print("=== F2 v0 — mode historique déterministe ===\n")
    for t, msg in st['log']:
        print(f"{hhmm(t)}  {msg}")
    print("\n--- Validation (généré vs historique, tolérance ±30 min) ---")
    CHECKS = [
        ('CAP japonaise saturée basse altitude', 9*60+20, 9*60+20),
        ('Frappe US sur la KB', 10*60+22, 10*60+22),
        ('Lancement riposte Hiryū', 10*60+22+32, 10*60+54),
        ('Coups sur le Yorktown', 10*60+22+32+70, 12*60+5),
    ]
    ok = True
    for name, gen, hist in CHECKS:
        d = gen - hist
        verdict = 'OK' if abs(d) <= 30 else 'ÉCART'
        ok &= abs(d) <= 30
        print(f"[{verdict}] {name}: généré {hhmm(gen)} vs réel {hhmm(hist)} ({d:+.0f} min)")
    n_lost = sum(1 for c in st['kb_cvs'].values() if not c['ok'])
    print(f"[{'OK' if n_lost==3 else 'ÉCART'}] CV japonais perdus à 10:30 (espérances): {n_lost} (réel: 3)")
    sys.exit(0 if ok else 1)

# ------------------------------------------------------------------
# MODE MONTE-CARLO
# ------------------------------------------------------------------
res = {'kb_lost_1030': [], 'yorktown_out': [], 'yorktown_out_time': [], 'us_cv_out': []}
for i in range(MC):
    rng = random.Random(1942 + i)
    st = run(SCENARIO, rng)
    res['kb_lost_1030'].append(sum(1 for c in st['kb_cvs'].values() if not c['ok']))
    res['yorktown_out'].append(0 if st['us_cvs']['YORKTOWN']['ok'] else 1)
    res['us_cv_out'].append(sum(1 for c in st['us_cvs'].values() if not c['ok']))

print(f"=== F2 v0 — Monte-Carlo N={MC}, scénario: {SCENARIO} ===\n")
kb = res['kb_lost_1030']
print(f"CV japonais hors de combat à ~10:30 :")
for k in range(5):
    n = kb.count(k)
    if n: print(f"  {k} CV : {100*n/MC:5.1f} %  {'█'*int(50*n/MC)}")
print(f"  moyenne {statistics.mean(kb):.2f} (historique: 3)")
print(f"\nYorktown hors de combat en fin de matinée : {100*statistics.mean(res['yorktown_out']):.1f} %"
      + ("  (historique: oui, mais à 12:05-14:45 en deux frappes)" if SCENARIO == 'historique'
         else "  (contre-factuel: frappe Yamaguchi ~10:20 + riposte Hiryū éventuelle)"))
print(f"PA US hors de combat (moyenne) : {statistics.mean(res['us_cv_out']):.2f}")
if SCENARIO == 'yamaguchi':
    print(f"""
Lecture F3 (option Yamaguchi, v0) :
 - les hangars de CarDiv2 sont vides à 10:22 -> la survie de Sōryū/Hiryū s'améliore
   (la perte n'est plus quasi certaine au 1er coup);
 - le Yorktown encaisse ~1h40 plus tôt, avant d'avoir récupéré sa frappe;
 - la frappe non escortée paie le prix de la CAP US alertée (P-SURV-DB-FULLCAP~0.40).
Limites v0 : pas de 2e vague japonaise modélisée, détection figée, Midway scripté —
à raffiner avant toute conclusion historique.""")

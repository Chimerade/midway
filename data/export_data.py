#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Exporte midway.sqlite en JSON pour le site React.
Usage: python3 export_data.py [chemin_base] [dossier_sortie]"""
import sqlite3, json, sys, os, hashlib, re
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
DB  = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'midway.sqlite')
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'web', 'public', 'data')
os.makedirs(OUT, exist_ok=True)

EPOCH = datetime.fromisoformat('1942-06-03T00:00:00-12:00')
def tmin(ts):
    return round((datetime.fromisoformat(ts) - EPOCH).total_seconds() / 60)

con = sqlite3.connect(f'file:{DB}?mode=ro&immutable=1', uri=True)
con.row_factory = sqlite3.Row

# --- Composition des formations (étiquettes lisibles) ---
def formation_sub(fid):
    fids, frontier = {fid}, [fid]
    while frontier:
        kids = [r['formation_id'] for r in con.execute(
            f"SELECT formation_id FROM formations WHERE parent_formation_id IN ({','.join('?'*len(frontier))})", frontier)]
        frontier = [k for k in kids if k not in fids]; fids.update(frontier)
    ph = ','.join('?' * len(fids)); fl = list(fids)
    cdr = con.execute("""SELECT p.name FROM formations f LEFT JOIN persons p
                         ON p.person_id=f.commander_id WHERE f.formation_id=?""", (fid,)).fetchone()
    cvs = [r['name'].replace('USS ', '') for r in con.execute(
        f"SELECT name FROM ships WHERE formation_id IN ({ph}) AND ship_type IN ('CV','CVL') ORDER BY name", fl)]
    counts = con.execute(f"""SELECT ship_type, COUNT(*) n FROM ships
                            WHERE formation_id IN ({ph}) AND ship_type NOT IN ('CV','CVL','base')
                            GROUP BY ship_type ORDER BY ship_type""", fl).fetchall()
    esc = ' '.join(f"{r['n']}{r['ship_type']}" for r in counts)
    parts = []
    if cvs: parts.append('PA: ' + ' · '.join(cvs))
    if esc: parts.append(('escorte: ' if cvs else '') + esc)
    if cdr and cdr['name']: parts.append(cdr['name'].split(' ')[0])
    return ' — '.join(parts)

# --- Pistes ---
TRACKED = [
    ('formations','KIDO-BUTAI','Kidō Butai','IJN', None),
    ('formations','TF-16','Task Force 16','USN', None),
    ('formations','TF-17','Task Force 17','USN', None),
    ('formations','CRUDIV7','CruDiv 7','IJN', None),
    ('formations','TRANSPORT-GROUP',"Convoi d'invasion",'IJN', None),
    ('ships','SH-HIRYU','Hiryū','IJN','PA isolé — seul CV opérationnel après 10h26'),
    ('ships','SH-CV5','Yorktown','USN','PA détaché de TF-17 après les coups de 12h11'),
    ('ships','SH-KAGA','Kaga','IJN','stoppé en flammes après 10h26'),
    ('ships','SH-SORYU','Sōryū','IJN','stoppé en flammes après 10h28'),
    ('ships','SH-AKAGI','Akagi','IJN','en flammes, abandonné, dérive'),
]
entities = []
for table, eid, label, side, sub in TRACKED:
    rows = con.execute(
        """SELECT p.ts, p.lat, p.lon, p.position_error_nm, p.method, p.course_deg, p.notes,
                  p.cause_event_id, e.event_type cause_type, e.summary cause_summary
           FROM positions p LEFT JOIN events e ON e.event_id=p.cause_event_id
           WHERE p.entity_table=? AND p.entity_id=? ORDER BY p.ts""", (table, eid)).fetchall()
    if rows:
        entities.append({
            'id': eid, 'label': label, 'side': side,
            'sub': sub if sub else (formation_sub(eid) if table == 'formations' else ''),
            'track': [{'t': tmin(r['ts']), 'lat': r['lat'], 'lon': r['lon'],
                       'err': r['position_error_nm'] or 25, 'm': r['method'],
                       'crs': r['course_deg'], 'ts': r['ts'][5:16],
                       'cause': (f"[{r['cause_type']}] {r['cause_summary']}" if r['cause_event_id'] else None),
                       'note': r['notes']} for r in rows]})

# --- Épaves ---
wrecks = []
for sid, name in [('SH-KAGA','Kaga'),('SH-SORYU','Sōryū'),('SH-AKAGI','Akagi'),
                  ('SH-HIRYU','Hiryū'),('SH-CV5','Yorktown'),('SH-HAMMANN','Hammann'),('SH-MIKUMA','Mikuma')]:
    r = con.execute("SELECT ts, lat, lon FROM positions WHERE entity_id=? ORDER BY ts DESC LIMIT 1", (sid,)).fetchone()
    if r: wrecks.append({'t': tmin(r['ts']), 'lat': r['lat'], 'lon': r['lon'], 'name': name,
                         'h': r['ts'][8:10] + ' juin ' + r['ts'][11:16], 'ent': sid})

# --- Navires en feu/stoppés: intervalles depuis la séquence d'avaries
#     (ouvert sur flight_ops='impossible', refermé sur 'degraded'/'normal',
#      clôture finale au naufrage) ---
fires = []
for sid in ('SH-KAGA','SH-SORYU','SH-AKAGI','SH-HIRYU','SH-CV5','SH-MIKUMA'):
    wk = next((w for w in wrecks if w['ent'] == sid), None)
    if not wk: continue
    open_t = None
    for d in con.execute("SELECT ts, flight_ops FROM damage_states WHERE ship_id=? ORDER BY ts", (sid,)):
        if d['flight_ops'] == 'impossible' and open_t is None:
            open_t = tmin(d['ts'])
        elif d['flight_ops'] in ('degraded', 'normal') and open_t is not None:
            fires.append({'ent': sid, 't0': open_t, 't1': tmin(d['ts'])})
            open_t = None
    if open_t is not None:
        fires.append({'ent': sid, 't0': open_t, 't1': wk['t']})

# --- Repérages (qui voit qui): événements sighting/report avec cible ---
spots = []
for r in con.execute("""
    SELECT e.ts, e.summary, ep.entity_id ent
    FROM events e JOIN event_participants ep ON ep.event_id=e.event_id AND ep.role='target'
    WHERE e.event_type IN ('sighting','report') ORDER BY e.ts"""):
    spots.append({'t': tmin(r['ts']), 'ent': r['ent'], 's': r['summary'][:55]})

# --- Combats (attaques/coups localisés sur leur cible) ---
combats, seen = [], set()
for r in con.execute("""
    SELECT e.event_id, e.ts, e.time_uncertainty_min u, ep.entity_id ent, e.summary
    FROM events e JOIN event_participants ep ON ep.event_id=e.event_id AND ep.role='target'
    WHERE e.event_type IN ('attack','hit','collision') ORDER BY e.ts"""):
    key = (r['event_id'], r['ent'])
    if key in seen: continue
    seen.add(key)
    t0 = tmin(r['ts'])
    combats.append({'t0': t0 - 2, 't1': t0 + max(14, (r['u'] or 0)), 'ent': r['ent'],
                    's': r['summary'][:60]})

# --- Raids (avec effectifs engagés/perdus pour le dénombrement au zoom) ---
minfo = {r['mission_id']: r for r in con.execute("""
    SELECT m.mission_id, m.attack_ts, m.launch_start_ts,
           COALESCE(SUM(ms.aircraft_committed),0) n0,
           COALESCE(SUM(ms.aircraft_lost),0) lost
    FROM missions m LEFT JOIN mission_squadrons ms ON ms.mission_id=m.mission_id
    GROUP BY m.mission_id""")}
first_leg = {}
for r in con.execute("SELECT mission_id, MIN(seq) s FROM mission_legs GROUP BY mission_id"):
    first_leg[r['mission_id']] = r['s']
raids = []
for r in con.execute("""
    SELECT l.mission_id, l.seq, l.start_ts, l.end_ts, l.start_lat, l.start_lon,
           l.end_lat, l.end_lon, m.side
    FROM mission_legs l JOIN missions m ON m.mission_id=l.mission_id
    WHERE l.start_ts IS NOT NULL AND l.end_ts IS NOT NULL ORDER BY l.mission_id, l.seq"""):
    mi = minfo.get(r['mission_id'])
    # phase de décollage: entre launch_start de la mission et le départ du 1er segment
    tl = None
    if mi and mi['launch_start_ts'] and r['seq'] == first_leg.get(r['mission_id']):
        tl_v = tmin(mi['launch_start_ts'])
        if tl_v < tmin(r['start_ts']): tl = tl_v
    raids.append({'mid': r['mission_id'], 'seq': r['seq'], 'side': 'IJN' if r['side']=='IJN' else 'USN',
                  't0': tmin(r['start_ts']), 't1': tmin(r['end_ts']),
                  'a': [r['start_lat'], r['start_lon']], 'b': [r['end_lat'], r['end_lon']],
                  'n0': mi['n0'] if mi else 0, 'lost': mi['lost'] if mi else 0,
                  'ta': tmin(mi['attack_ts']) if mi and mi['attack_ts'] else None, 'tl': tl})
# lignes parallèles d'une même mission (éventails): l'effectif mission se RÉPARTIT
for r in raids:
    r['par'] = sum(1 for o in raids if o['mid'] == r['mid']
                   and o['t0'] < r['t1'] and o['t1'] > r['t0'])

# --- Événements / contacts ---
events = [{'t': tmin(r['ts']), 'type': r['event_type'], 'side': r['side'] or '',
           's': r['summary'], 'u': r['time_uncertainty_min'] or 0}
          for r in con.execute("SELECT ts, event_type, side, summary, time_uncertainty_min FROM events ORDER BY ts")]
contacts = [{'t': tmin(r['ts_sent']), 'lat': r['reported_lat'], 'lon': r['reported_lon'],
             's': r['reported_composition']}
            for r in con.execute("SELECT ts_sent, reported_lat, reported_lon, reported_composition "
                                 "FROM contact_reports WHERE reported_lat IS NOT NULL")]

# --- Tampon de version ---
db_path = DB[5:].split('?')[0] if DB.startswith('file:') else DB
build = {
    'gen': datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC'),
    'db_hash': hashlib.sha1(open(db_path, 'rb').read()).hexdigest()[:8],
    'n_ev': len(events),
    'n_pos': con.execute("SELECT COUNT(*) FROM positions").fetchone()[0],
    'n_inf': (con.execute("SELECT COUNT(*) FROM position_inferences").fetchone()[0]
              if con.execute("SELECT COUNT(*) FROM sqlite_master WHERE name='position_inferences'").fetchone()[0] else 0),
}
data = {'entities': entities, 'wrecks': wrecks, 'fires': fires, 'combats': combats,
        'spots': spots, 'raids': raids, 'events': events, 'contacts': contacts,
        'tmax': max(e['t'] for e in events) + 120,
        'tmin': min([e['t'] for e in events] + [p['t'] for en in entities for p in en['track']]) - 30,
        'build': build}

# Écriture des fichiers JSON
def write(name, obj):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False)

write('replay.json', data)
write('chronologie.json', events)          # `events` vient de generer_carte.py:152-154
write('meta.json', build)                  # `build` vient de generer_carte.py:162-169

con.close()

# Méthodologie : extraire le contenu du <body> (sans <nav>/<script>) en asset HTML,
# pour chaque langue disponible -> methodologie.<lang>.html
def export_methodologie(src_name, out_name):
    path = os.path.join(ROOT, src_name)
    src = open(path, encoding='utf-8').read()
    m = re.search(r'<body[^>]*>(.*)</body>', src, re.S)
    if not m:
        raise SystemExit(f"export_data: impossible d'extraire le <body> de {src_name}")
    body = re.sub(r'<nav>.*?</nav>', '', m.group(1), flags=re.S)
    body = re.sub(r'<script.*?</script>', '', body, flags=re.S)
    with open(os.path.join(OUT, out_name), 'w', encoding='utf-8') as f:
        f.write(body.strip())

export_methodologie('methodologie_midway.html', 'methodologie.fr.html')
export_methodologie('methodologie_midway.en.html', 'methodologie.en.html')

print(f"OK: {OUT} (entites={len(entities)}, events={len(events)})")

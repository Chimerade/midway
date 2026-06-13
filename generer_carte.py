#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère carte_midway.html (replay F1) à partir de midway.sqlite.
Usage : python3 generer_carte.py [chemin_base] [chemin_sortie]
À relancer après chaque mise à jour de la base (le tampon de build fait foi).
"""
import sqlite3, json, sys, os, hashlib
from datetime import datetime, timezone

DB  = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__) or '.', 'midway.sqlite')
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__) or '.', 'carte_midway.html')

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
        'tmax': max(e['t'] for e in events) + 120, 'build': build}
con.close()

HTML = r'''<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8">
<title>Midway 1942 — Replay</title>
<style>
 :root{--bg:#fff;--panel:#f4f6f9;--bord:#d4dce5;--txt:#1c2733;--txt2:#5a6b80;--accent:#b07900;}
 body.dark{--bg:#0b1220;--panel:#101a2e;--bord:#223348;--txt:#cfd8e3;--txt2:#8fa3bd;--accent:#ffd479;}
 body{margin:0;font-family:Verdana,sans-serif;background:var(--bg);color:var(--txt);display:flex;flex-direction:column;height:100vh;overflow:hidden}
 #bar{padding:8px 14px;background:var(--panel);border-bottom:1px solid var(--bord);display:flex;gap:12px;align-items:center;flex-wrap:wrap}
 #bar b{font-size:13px}
 #clock{font-size:17px;color:var(--accent);font-family:Consolas,monospace;min-width:225px}
 input[type=range]{accent-color:#1f6fce}
 #slider{flex:1;min-width:160px}
 button{background:var(--bg);color:var(--txt);border:1px solid var(--bord);border-radius:4px;padding:4px 11px;cursor:pointer;font-size:13px}
 button:hover{border-color:#1f6fce}
 label{font-size:11px;user-select:none;cursor:pointer}
 #main{display:flex;flex:1;min-height:0}
 #map{flex:1;position:relative}
 canvas{position:absolute;inset:0;width:100%;height:100%}
 #feed{width:330px;background:var(--panel);border-left:1px solid var(--bord);overflow-y:auto;padding:10px;font-size:11px;line-height:1.45}
 .ev{padding:5px 7px;margin-bottom:5px;border-left:3px solid var(--bord);background:var(--bg);border-radius:0 4px 4px 0;opacity:.5;cursor:pointer}
 .ev:hover{opacity:.85;outline:1px solid #1f6fce}
 .ev.cur{opacity:1;background:var(--panel);border:1px solid var(--bord);border-left-width:3px}
 .ev.past{opacity:.35}
 .ev .t{color:var(--accent);font-family:Consolas,monospace}
 .ev.IJN{border-left-color:#d23b3b}.ev.USN{border-left-color:#1f6fce}
 #legend{position:absolute;bottom:10px;left:10px;background:var(--panel);opacity:.95;padding:8px 12px;border-radius:6px;font-size:10px;line-height:1.7;border:1px solid var(--bord)}
 #wpinfo{display:none;position:absolute;top:10px;left:10px;max-width:440px;background:var(--panel);border:1px solid var(--bord);border-radius:6px;padding:9px 12px;font-size:11px;line-height:1.5;z-index:5}
 #build{margin-left:auto;font-size:10px;color:var(--txt2);font-family:Consolas,monospace}
 .sw{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px;vertical-align:-1px}
</style></head><body>
<div id="bar">
 <b>MIDWAY 1942 — REPLAY</b>
 <div id="clock"></div>
 <button id="play">▶ Lecture</button>
 <span style="font-size:11px">vitesse</span>
 <input type="range" id="speed" min="1" max="3.56" value="2.778" step="0.01" style="width:120px" title="vitesse de lecture (continue, de ×10 à ×3600)">
 <span id="speedlbl" style="font-size:11px;font-family:Consolas,monospace;min-width:50px"></span>
 <input type="range" id="slider" min="0" max="1" value="0" step="1">
 <span style="font-size:11px">zoom</span>
 <button id="zoomout">−</button>
 <input type="range" id="zoom" min="0.4" max="10" value="1" step="0.1" style="width:110px">
 <button id="zoomin">+</button>
 <button id="themebtn">🌙 sombre</button>
 <label><input type="checkbox" id="cbHalo" checked> halos</label>
 <label><input type="checkbox" id="cbTrail" checked> traînées</label>
 <label><input type="checkbox" id="cbRaid" checked> raids</label>
 <label><input type="checkbox" id="cbPercu"> monde perçu</label>
 <span id="build"></span>
</div>
<div id="main">
 <div id="map"><canvas id="cv"></canvas>
  <div id="wpinfo"></div>
  <button id="legbtn" style="display:none;position:absolute;bottom:10px;left:10px;z-index:6">ℹ légende</button>
  <div id="legend">
   <span id="legclose" style="float:right;cursor:pointer;font-weight:bold;padding:0 4px" title="fermer">✕</span>
   <span class="sw" style="background:#1f6fce"></span>US Navy &nbsp;
   <span class="sw" style="background:#d23b3b"></span>Marine impériale<br>
   <b>Task Force (TF)</b> = groupe opérationnel US autour de porte-avions;<br>
   <b>Kidō Butai</b> = force de frappe des PA japonais (composition sous le nom)<br>
   ▲ navire/groupe en route (pointe = direction) · 🔥 en feu/stoppé · ✕ coulé<br>
   ◉ pulsation orange = combat en cours · 👁 pulsation jaune = unité repérée par l'ennemi<br>
   ✛ raid en vol (effectif affiché au zoom; <b>1 point = 1 avion</b> au zoom ≥ ×2,2)<br>
   pertes appliquées au point d'attaque (approx.: inclut les amerrissages au retour)<br>
   ◆ waypoint — <b>cliquer</b> : justification du cap<br>
   ◌ halo = erreur de position (nm); il <b>grossit</b> quand la piste est périmée (+5 nm/h)<br>
   Zoom: molette ou curseur · Anneaux 100/200/300 nm · pointillé = antiméridien
  </div>
 </div>
 <div id="feed"></div>
</div>
<script>
const D = __DATA__;
const LAT0=28.21, LON0=-177.37, RAD=Math.PI/180;
const cv=document.getElementById('cv'), ctx=cv.getContext('2d');
let T=270, playing=false, scale=1.0, panX=0, panY=-120;
const slider=document.getElementById('slider'); slider.max=D.tmax;
const zoomCtl=document.getElementById('zoom');
const colors={USN:'#1f6fce',IJN:'#d23b3b'};
const THEMES={
 light:{bg:'#ffffff',grid:'#e6ecf2',gridLbl:'#9aa7b5',ring:'#d7e1ea',idl:'#b8c6d8',
        label:'#16212e',sub:'#5a6b80',wreck:'#7d8893',midway:'#b07900',contact:'#b07900',stale:.5},
 dark:{bg:'#0b1220',grid:'#16243d',gridLbl:'#2c4060',ring:'#27406b',idl:'#31496e',
       label:'#f0f4f8',sub:'#8fa3bd',wreck:'#888',midway:'#ffd479',contact:'#ffd479',stale:.5}};
let theme='light';

function unwrap(lon){ return lon>0 ? lon-360 : lon; }
function pxnm(){ return Math.min(cv.width,cv.height)/900; }
function proj(lat,lon){
  const x=(unwrap(lon)-LON0)*60*Math.cos(LAT0*RAD), y=(lat-LAT0)*60;
  return [cv.width/2 + (x+panX)*scale*pxnm(), cv.height/2 - (y+panY)*scale*pxnm()];
}
function fmt(t){
  t=Math.floor(t);
  const d=3+Math.floor(t/1440), h=Math.floor((t%1440)/60), m=t%60;
  return `${d} juin 1942 — ${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')} (GMT−12)`;
}
function cardinal(b){return ['N','NE','E','SE','S','SO','O','NO'][Math.round(((b%360)+360)%360/45)%8];}
function routeTo(a,b){
  const dlat=(b.lat-a.lat)*60, dlon=(unwrap(b.lon)-unwrap(a.lon))*60*Math.cos(LAT0*RAD);
  return (Math.atan2(dlon,dlat)*180/Math.PI+360)%360;
}
function distNm(a,b){
  const dlat=(b.lat-a.lat)*60, dlon=(unwrap(b.lon)-unwrap(a.lon))*60*Math.cos(LAT0*RAD);
  return Math.hypot(dlat,dlon);
}
function interp(track,t){
  if(t<track[0].t) return null;
  for(let i=0;i<track.length-1;i++){
    const a=track[i], b=track[i+1];
    if(t>=a.t && t<=b.t){
      const f=(t-a.t)/Math.max(1,b.t-a.t);
      return {lat:a.lat+f*(b.lat-a.lat), lon:unwrap(a.lon)+f*(unwrap(b.lon)-unwrap(a.lon)),
              err:a.err+f*(b.err-a.err), route:routeTo(a,b)};
    }
  }
  const last=track[track.length-1];
  if(t-last.t<360){
    const prev=track.length>1?track[track.length-2]:null;
    // piste périmée: l'incertitude CROÎT avec le temps écoulé (~5 nm/h, plafond 90)
    const grown=Math.min(90, last.err + (t-last.t)/60*5);
    return {lat:last.lat,lon:unwrap(last.lon),err:grown,stale:true,
            route:prev?routeTo(prev,last):null};
  }
  return null;
}
const entById={}; D.entities.forEach(e=>entById[e.id]=e);
function posOf(entId,t){ // position d'une entité (piste, Midway, ou épave)
  if(entId==='SH-MIDWAY') return {lat:28.21,lon:-177.37};
  if(entById[entId]) return interp(entById[entId].track,t);
  const w=D.wrecks.find(w=>w.ent===entId); return w?{lat:w.lat,lon:w.lon}:null;
}
function isSunk(entId,t){ const w=D.wrecks.find(w=>w.ent===entId); return w&&t>=w.t; }

let clickables=[], selWp=null;
function draw(){
  clickables=[];
  const P=THEMES[theme];
  cv.width=cv.parentElement.clientWidth; cv.height=cv.parentElement.clientHeight;
  ctx.fillStyle=P.bg; ctx.fillRect(0,0,cv.width,cv.height);
  // grille
  ctx.strokeStyle=P.grid; ctx.lineWidth=1; ctx.fillStyle=P.gridLbl; ctx.font='9px Verdana';
  for(let la=26;la<=34;la++){ const [x1,y1]=proj(la,-188), [x2,y2]=proj(la,-170);
    ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke(); ctx.fillText(la+'°N',8,y1-3);}
  for(let lo=-188;lo<=-170;lo+=2){ const [x1,y1]=proj(26,lo), [x2,y2]=proj(34,lo);
    ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();
    const lbl=lo<-180?(360+lo)+'°E':(-lo)+'°W'; ctx.fillText(lbl,x1+3,cv.height-8);}
  ctx.setLineDash([4,4]); ctx.strokeStyle=P.idl;
  const [ax1,ay1]=proj(25.5,-180), [ax2,ay2]=proj(34.5,-180);
  ctx.beginPath();ctx.moveTo(ax1,ay1);ctx.lineTo(ax2,ay2);ctx.stroke(); ctx.setLineDash([]);
  // Midway + anneaux
  const [mx,my]=proj(LAT0,LON0);
  ctx.strokeStyle=P.ring;
  [100,200,300].forEach(r=>{ctx.beginPath();ctx.arc(mx,my,r*scale*pxnm(),0,7);ctx.stroke();});
  ctx.fillStyle=P.midway; ctx.beginPath();ctx.arc(mx,my,4,0,7);ctx.fill();
  ctx.fillText('MIDWAY',mx+7,my+4);
  // épaves
  ctx.font='12px Verdana';
  D.wrecks.forEach(w=>{ if(T>=w.t){ const[x,y]=proj(w.lat,w.lon);
    ctx.fillStyle=P.wreck; ctx.fillText('✕',x-4,y+4); ctx.font='9px Verdana';
    ctx.fillText(`${w.name} — coulé ${w.h.split(' ')[2]}`,x+8,y+3); ctx.font='12px Verdana';}});
  // pistes
  D.entities.forEach(e=>{
    const c=colors[e.side];
    if(document.getElementById('cbTrail').checked){
      ctx.strokeStyle=c; ctx.globalAlpha=.3; ctx.lineWidth=1.5; ctx.beginPath(); let started=false;
      for(const p of e.track){ if(p.t>T)break; const[x,y]=proj(p.lat,p.lon);
        started?ctx.lineTo(x,y):ctx.moveTo(x,y); started=true;}
      const cur=interp(e.track,T);
      if(cur&&started){const[x,y]=proj(cur.lat,cur.lon);ctx.lineTo(x,y);}
      ctx.stroke(); ctx.globalAlpha=1;
    }
    e.track.forEach((pt,pi)=>{ if(pt.t<=T){ const[wx,wy]=proj(pt.lat,pt.lon);
      ctx.fillStyle=pt.cause?c:'#999';
      ctx.save();ctx.translate(wx,wy);ctx.rotate(Math.PI/4);ctx.fillRect(-3,-3,6,6);ctx.restore();
      clickables.push({x:wx,y:wy,ent:e.label,pt:pt,trk:e.track,idx:pi});}});
    if(isSunk(e.id,T)) return;            // coulé: seul le ✕ subsiste
    const p=interp(e.track,T); if(!p)return;
    const[x,y]=proj(p.lat,p.lon);
    if(document.getElementById('cbHalo').checked){
      const hr=p.err*scale*pxnm();
      ctx.fillStyle=c; ctx.globalAlpha=.07;
      ctx.beginPath();ctx.arc(x,y,hr,0,7);ctx.fill();ctx.globalAlpha=.35;
      ctx.strokeStyle=c; ctx.setLineDash([5,5]);
      ctx.beginPath();ctx.arc(x,y,hr,0,7);ctx.stroke();
      ctx.setLineDash([]); ctx.globalAlpha=1;
      if(scale>=1.8){ // étiquette de l'incertitude sur le bord du halo
        ctx.fillStyle=P.sub; ctx.font='9px Verdana';
        ctx.fillText(`±${Math.round(p.err)} nm${p.stale?' (périmée)':''}`,x+hr*0.71+3,y-hr*0.71-3);
        ctx.font='12px Verdana';}}
    const fire=D.fires.find(f=>f.ent===e.id&&T>=f.t0&&T<f.t1);
    if(fire){ // en feu: flamme vacillante, pas de flèche (stoppé/dérive)
      const fl=.6+.4*Math.sin(Date.now()/110+x);
      ctx.globalAlpha=fl; ctx.font='14px Verdana'; ctx.fillText('🔥',x-7,y+5); ctx.globalAlpha=1;
    } else if(p.route!=null){ // en route: flèche orientée
      ctx.fillStyle=c; ctx.save();ctx.translate(x,y);ctx.rotate(p.route*RAD);
      ctx.beginPath();ctx.moveTo(0,-9);ctx.lineTo(5.5,7);ctx.lineTo(0,3.5);ctx.lineTo(-5.5,7);
      ctx.closePath();ctx.fill();ctx.restore();
      if(p.stale){ctx.strokeStyle=c;ctx.beginPath();ctx.arc(x,y,11,0,7);ctx.stroke();}
    } else { ctx.fillStyle=c; ctx.beginPath();ctx.arc(x,y,5,0,7);ctx.fill(); }
    ctx.fillStyle=P.label; ctx.font='bold 11px Verdana';
    ctx.fillText(e.label+(fire?' (en feu)':''),x+10,y+1);
    if(e.sub){ctx.fillStyle=P.sub; ctx.font='9px Verdana'; ctx.fillText(e.sub,x+10,y+13);}
    ctx.font='12px Verdana';
  });
  // waypoint sélectionné: surligner ses segments entrant/sortant
  if(selWp){
    const [sx,sy]=proj(selWp.pt.lat,selWp.pt.lon);
    ctx.strokeStyle='#ff7a00'; ctx.lineWidth=2;
    ctx.beginPath();ctx.arc(sx,sy,9,0,7);ctx.stroke();
    if(selWp.idx>0){ // segment entrant (fin, pointillé)
      const a=selWp.trk[selWp.idx-1], [ax,ay]=proj(a.lat,a.lon);
      ctx.setLineDash([4,4]); ctx.lineWidth=1.5;
      ctx.beginPath();ctx.moveTo(ax,ay);ctx.lineTo(sx,sy);ctx.stroke(); ctx.setLineDash([]);
    }
    if(selWp.idx<selWp.trk.length-1){ // segment sortant (épais + flèche)
      const b=selWp.trk[selWp.idx+1], [bx2,by2]=proj(b.lat,b.lon);
      ctx.lineWidth=3;
      ctx.beginPath();ctx.moveTo(sx,sy);ctx.lineTo(bx2,by2);ctx.stroke();
      const ang=Math.atan2(by2-sy,bx2-sx), mxp=(sx+bx2)/2, myp=(sy+by2)/2;
      ctx.fillStyle='#ff7a00';
      ctx.save();ctx.translate(mxp,myp);ctx.rotate(ang);
      ctx.beginPath();ctx.moveTo(8,0);ctx.lineTo(-5,-5);ctx.lineTo(-5,5);ctx.closePath();ctx.fill();ctx.restore();
    }
    ctx.lineWidth=1;
  }
  // repérages: "qui voit qui" — œil pulsant sur l'entité repérée
  D.spots.forEach(sp=>{ if(T>=sp.t-2&&T<=sp.t+12){
    const p=posOf(sp.ent,T); if(!p)return; const[x,y]=proj(p.lat,p.lon);
    const ph=(Date.now()/500)%1;
    ctx.strokeStyle='#e6a700'; ctx.globalAlpha=(1-ph)*.8; ctx.lineWidth=2;
    ctx.beginPath();ctx.arc(x,y,6+ph*18,0,7);ctx.stroke();
    ctx.globalAlpha=1; ctx.lineWidth=1;
    ctx.font='12px Verdana'; ctx.fillText('👁',x-6,y-14);
    if(scale>=1.3){ctx.fillStyle='#b07900';ctx.font='9px Verdana';
      ctx.fillText('repéré: '+sp.s+'…',x+14,y-16);ctx.font='12px Verdana';}}});
  // combats: pulsations sur la cible
  D.combats.forEach(cb=>{ if(T>=cb.t0&&T<=cb.t1){
    const p=posOf(cb.ent,T); if(!p)return; const[x,y]=proj(p.lat,p.lon);
    const ph=(Date.now()/650)%1;
    [ph,(ph+0.5)%1].forEach(q=>{
      ctx.strokeStyle='#ff7a00'; ctx.globalAlpha=(1-q)*.85; ctx.lineWidth=2.5;
      ctx.beginPath();ctx.arc(x,y,7+q*26,0,7);ctx.stroke();});
    ctx.globalAlpha=1; ctx.lineWidth=1;
    ctx.fillStyle='#ff7a00'; ctx.font='bold 12px Verdana'; ctx.fillText('✸',x-5,y-12);
    ctx.font='12px Verdana';}});
  // raids — dénombrables au zoom: 1 point = 1 avion, attrition au point d'attaque
  if(document.getElementById('cbRaid').checked){
    D.raids.forEach(r=>{
      const launching=r.tl!=null && T>=r.tl && T<r.t0;
      if(launching || (T>=r.t0&&T<=r.t1)){
      const f=launching?0:(T-r.t0)/(r.t1-r.t0);
      const lat=r.a[0]+f*(r.b[0]-r.a[0]), lon=unwrap(r.a[1])+f*(unwrap(r.b[1])-unwrap(r.a[1]));
      const[x,y]=proj(lat,lon); const c=colors[r.side];
      ctx.strokeStyle=c; ctx.globalAlpha=.4;
      const[xa,ya]=proj(r.a[0],r.a[1]); ctx.setLineDash([2,3]);
      ctx.beginPath();ctx.moveTo(xa,ya);ctx.lineTo(x,y);ctx.stroke();ctx.setLineDash([]);ctx.globalAlpha=1;
      const after=r.ta!=null && T>=r.ta;
      let n=after ? Math.max(0,r.n0-r.lost) : r.n0;
      if(launching) n=Math.max(1,Math.round(r.n0*(T-r.tl)/Math.max(1,r.t0-r.tl))); // décollages en cours
      const par=r.par||1;
      if(par>1) n=Math.max(1,Math.round(n/par)); // éventail: l'effectif se répartit entre les lignes
      if(scale>=2.2 && r.n0>0){
        // formation en coin (V), 1 point/avion (paquets de 2 au-delà de 60)
        const pack=r.n0>60?2:1, shown=Math.ceil(n/pack);
        const[xb,yb]=proj(r.b[0],r.b[1]);
        const ang=Math.atan2(yb-y,xb-x);
        ctx.save();ctx.translate(x,y);ctx.rotate(ang+Math.PI/2);
        ctx.fillStyle=c;
        for(let i=0;i<shown;i++){
          const row=Math.floor((-1+Math.sqrt(1+8*i))/2), k=i-row*(row+1)/2;
          const px=(k-row/2)*7, py=row*6;
          ctx.beginPath();ctx.arc(px,py,2,0,7);ctx.fill();
        }
        // avions perdus: points gris qui s'estompent pendant 20 min après l'attaque
        if(after && r.lost>0 && T<=r.ta+20){
          ctx.globalAlpha=Math.max(0,1-(T-r.ta)/20)*.8; ctx.fillStyle='#888';
          const lostShown=Math.ceil(r.lost/pack);
          for(let i=0;i<lostShown;i++){
            const row=Math.floor((-1+Math.sqrt(1+8*(i+shown)))/2), k=(i+shown)-row*(row+1)/2;
            ctx.beginPath();ctx.arc((k-row/2)*7,row*6+9+(T-r.ta)*0.8,2,0,7);ctx.fill();
          }
          ctx.globalAlpha=1;
        }
        ctx.restore();
        ctx.fillStyle=P.label; ctx.font='bold 9px Verdana';
        ctx.fillText(`${par>1?'≈':''}${n}${pack>1?' (1 pt = 2)':''} av.${par>1?'/ligne':''}${launching?' — décollage…':''}`,x+10,y+4);
      } else {
        ctx.fillStyle=c; ctx.font='13px Verdana'; ctx.fillText('✛',x-5,y+5);
        if(scale>=1.3 && r.n0>0){ctx.font='bold 9px Verdana';ctx.fillStyle=P.label;
          ctx.fillText(`${par>1?'≈':''}${n} av.${par>1?'/ligne':''}${launching?' — décollage…':''}`,x+9,y+10);}
      }
      ctx.font='9px Verdana'; ctx.fillStyle=P.sub;
      ctx.fillText(r.mid.replace(/MS-060[346]-/,''),x+8,y-6);
      ctx.font='12px Verdana';}});
  }

  // monde perçu
  if(document.getElementById('cbPercu').checked){
    D.contacts.forEach(c=>{ if(T>=c.t&&T<=c.t+180){ const[x,y]=proj(c.lat,c.lon);
      ctx.strokeStyle=P.contact;ctx.setLineDash([3,3]);
      ctx.beginPath();ctx.arc(x,y,12,0,7);ctx.stroke();ctx.setLineDash([]);
      ctx.fillStyle=P.contact;ctx.font='9px Verdana';
      ctx.fillText('contact rapporté: '+c.s.slice(0,40)+'…',x+15,y);ctx.font='12px Verdana';}});
  }
  // boussole
  const bx=cv.width-52, by=52, br=30;
  ctx.strokeStyle=P.ring; ctx.fillStyle=P.bg;
  ctx.beginPath();ctx.arc(bx,by,br,0,7);ctx.fill();ctx.stroke();
  for(let a=0;a<360;a+=45){const r1=a%90?br-5:br-8, rad=(a-90)*RAD;
    ctx.beginPath();ctx.moveTo(bx+Math.cos(rad)*r1,by+Math.sin(rad)*r1);
    ctx.lineTo(bx+Math.cos(rad)*br,by+Math.sin(rad)*br);ctx.stroke();}
  ctx.fillStyle='#d23b3b';ctx.beginPath();
  ctx.moveTo(bx,by-br+6);ctx.lineTo(bx-5,by);ctx.lineTo(bx+5,by);ctx.closePath();ctx.fill();
  ctx.fillStyle=P.label;ctx.font='bold 10px Verdana';ctx.textAlign='center';
  ctx.fillText('N',bx,by-br+16);ctx.font='9px Verdana';
  ctx.fillText('E',bx+br-12,by+3);ctx.fillText('S',bx,by+br-8);ctx.fillText('O',bx-br+12,by+3);
  ctx.textAlign='left';
  document.getElementById('clock').textContent=fmt(T);
  slider.value=Math.round(T);
}
const feed=document.getElementById('feed');
let userScrollUntil=0, progScroll=false;
function buildFeed(){ // construit le fil UNE fois; clic = sauter à l'instant de l'événement
  feed.innerHTML=D.events.map((e,i)=>
   `<div class="ev ${e.side}" id="ev${i}" data-t="${e.t}" title="cliquer: aller à cet instant">
     <span class="t">${fmt(e.t).split('— ')[1].split(' ')[0]} J${3+Math.floor(e.t/1440)}</span>
     ${e.u?`±${e.u}'`:''} — ${e.s}</div>`).join('');
  feed.querySelectorAll('.ev').forEach(div=>{
    div.onclick=()=>{ T=parseFloat(div.dataset.t); updateFeed(true); };
  });
  feed.addEventListener('scroll',()=>{ if(!progScroll) userScrollUntil=Date.now()+5000; });
}
let lastCur=-1;
function updateFeed(force){
  // événement courant = dernier événement passé (ou tout proche)
  let cur=-1;
  for(let i=0;i<D.events.length;i++){ if(D.events[i].t<=T+1) cur=i; else break; }
  if(cur===lastCur && !force) return;
  lastCur=cur;
  D.events.forEach((e,i)=>{
    const div=document.getElementById('ev'+i);
    div.classList.toggle('cur', i===cur || Math.abs(e.t-T)<=15);
    div.classList.toggle('past', e.t<T-60 && i!==cur);
  });
  // suivi auto: pendant la lecture (sauf si l'utilisateur vient de scroller), ou après un saut
  if(cur>=0 && (force || (playing && Date.now()>userScrollUntil))){
    progScroll=true;
    document.getElementById('ev'+cur).scrollIntoView({block:'center',behavior:force?'auto':'smooth'});
    setTimeout(()=>progScroll=false,400);
  }
}
let lastFrame=performance.now();
function speedFactor(){ return Math.pow(10, parseFloat(document.getElementById('speed').value)); }
function updateSpeedLbl(){
  const f=speedFactor();
  document.getElementById('speedlbl').textContent='×'+(f<100?f.toFixed(0):Math.round(f/10)*10);
}
function tick(){
  const now=performance.now(), dt=(now-lastFrame)/1000; lastFrame=now;
  if(playing){
    T=Math.min(D.tmax, T + speedFactor()*dt/60);   // facteur = secondes simulées / seconde réelle
    if(T>=D.tmax){playing=false;document.getElementById('play').textContent='▶ Lecture';}}
  draw();
  updateFeed(false);
  requestAnimationFrame(tick);
}
document.getElementById('speed').oninput=updateSpeedLbl;
updateSpeedLbl();
document.getElementById('build').textContent=
  `build ${D.build.gen} · base #${D.build.db_hash} · ${D.build.n_ev} évts · ${D.build.n_pos} pos · ${D.build.n_inf} inférences`;
document.title=`Midway 1942 — Replay (build ${D.build.gen}, base #${D.build.db_hash})`;
document.getElementById('play').onclick=()=>{playing=!playing;
  document.getElementById('play').textContent=playing?'⏸ Pause':'▶ Lecture';};
slider.oninput=()=>{T=parseInt(slider.value); updateFeed(true);};
zoomCtl.oninput=()=>{scale=parseFloat(zoomCtl.value);};
document.getElementById('zoomin').onclick=()=>{scale=Math.min(10,scale*1.25);zoomCtl.value=scale;};
document.getElementById('zoomout').onclick=()=>{scale=Math.max(.4,scale/1.25);zoomCtl.value=scale;};
document.getElementById('legclose').onclick=()=>{
  document.getElementById('legend').style.display='none';
  document.getElementById('legbtn').style.display='block';};
document.getElementById('legbtn').onclick=()=>{
  document.getElementById('legend').style.display='block';
  document.getElementById('legbtn').style.display='none';};
document.getElementById('themebtn').onclick=()=>{
  theme=theme==='light'?'dark':'light';
  document.body.classList.toggle('dark',theme==='dark');
  document.getElementById('themebtn').textContent=theme==='light'?'🌙 sombre':'☀ clair';};
cv.parentElement.addEventListener('wheel',e=>{e.preventDefault();
  scale=Math.max(.4,Math.min(10,scale*(e.deltaY<0?1.1:0.9)));zoomCtl.value=scale;},{passive:false});
let drag=null, dragDist=0;
cv.parentElement.addEventListener('mousedown',e=>{drag=[e.clientX,e.clientY];dragDist=0;});
window.addEventListener('mousemove',e=>{if(drag){
  dragDist+=Math.abs(e.clientX-drag[0])+Math.abs(e.clientY-drag[1]);
  panX+=(e.clientX-drag[0])/(scale*pxnm()); panY-=(e.clientY-drag[1])/(scale*pxnm());
  drag=[e.clientX,e.clientY];}});
window.addEventListener('mouseup',e=>{
  if(drag&&dragDist<5){
    const r=cv.getBoundingClientRect(), mx2=e.clientX-r.left, my2=e.clientY-r.top;
    let best=null,bd=14;
    clickables.forEach(c=>{const d=Math.hypot(c.x-mx2,c.y-my2); if(d<bd){bd=d;best=c;}});
    const box=document.getElementById('wpinfo');
    selWp=best||null;
    if(best){
      box.style.display='block';
      let html=`<b>${best.ent}</b> — waypoint ${best.pt.ts} · méthode <i>${best.pt.m}</i> · ±${best.pt.err} nm`;
      if(best.idx>0){
        const prev=best.trk[best.idx-1], rr=routeTo(prev,best.pt), d=distNm(prev,best.pt);
        html+=`<br><span style="color:var(--txt2)">◀ Arrive</span> par route ${rr.toFixed(0)}° (${cardinal(rr)})`+
              ` — ${d.toFixed(0)} nm depuis le waypoint ${prev.ts}`+
              `<br><span style="color:var(--txt2);padding-left:14px">${(prev.cause||'cause du segment précédent inconnue').slice(0,120)}</span>`;
      }
      if(best.idx<best.trk.length-1){
        const nxt=best.trk[best.idx+1], rr=routeTo(best.pt,nxt), d=distNm(best.pt,nxt), dt=nxt.t-best.pt.t;
        html+=`<br><span style="color:var(--accent)">▶ Repart</span> route <b>${rr.toFixed(0)}° (${cardinal(rr)})</b>`+
              ` — <b>${d.toFixed(0)} nm en ${dt>=90?(dt/60).toFixed(1)+' h':dt+' min'}</b> jusqu'au waypoint ${nxt.ts}`+
              `${d<15?' <span style="color:#ff7a00">(segment court — voir le surlignage orange sur la carte)</span>':''}`+
              `<br><span style="color:var(--accent);padding-left:14px">${(best.pt.cause||'⚠ cause non rattachée')}</span>`;
      } else {
        html+=`<br><span style="color:var(--accent)">■ Dernier point</span> — ${(best.pt.cause||'⚠ cause non rattachée')}`;
      }
      if(best.pt.note) html+=`<br><span style="color:var(--txt2)">${best.pt.note}</span>`;
      box.innerHTML=html;
    } else box.style.display='none';
  }
  drag=null;});
T=270; buildFeed(); updateFeed(true); tick();
</script></body></html>'''

html = HTML.replace('__DATA__', json.dumps(data, ensure_ascii=False))
with open(OUT, 'w', encoding='utf-8') as f:
    f.write(html)
print(f"OK: {OUT}")
print(f"  entités: {len(entities)} | épaves: {len(wrecks)} | feux: {len(fires)} | combats: {len(combats)} | raids: {len(raids)} | événements: {len(events)}")

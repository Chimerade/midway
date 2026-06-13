#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère phase8b_recherches.sql : les 7 lignes de recherche japonaises du
4 juin (schéma du rapport Nagumo / Shattered Sword: 300 nm + crochet 60 nm
à gauche) et l'éventail PBY de Midway (~700 nm, secteur OSO->NNE).
Relèvements retenus (à confirmer sur le schéma du rapport Nagumo, claims
single_source): Akagi 181°, Kaga 158°, Tone n°1 123°, Tone n°4 100°,
Chikuma n°1 77°, Chikuma n°5 54°, Haruna (E8N, ligne courte 150 nm) 142°.
La TF US se trouvait dans l'interstice Tone n°4 / Chikuma n°1.
"""
import math, os

LAT0, LON0 = 31.00, -179.60      # point de lancement KB 04:30
MID = (28.21, -177.37)

def dest(lat, lon, brg, d):
    la = lat + d * math.cos(math.radians(brg)) / 60
    lo = lon + d * math.sin(math.radians(brg)) / (60 * math.cos(math.radians((lat + la) / 2)))
    return round(la, 2), round(lo, 2)

def t(day, h, m):
    h, m = h + int(m) // 60, int(m) % 60      # normalise (ex: 04:60 -> 05:00)
    return f"1942-06-{day:02d}T{h:02d}:{m:02d}:00-12:00"

L = []
L.append("-- ============================================================")
L.append("-- PHASE 8b : lignes de recherche (générées par generer_phase8_recherches.py)")
L.append("-- ============================================================")
L.append("INSERT INTO squadrons (squadron_id,name,side,ship_id,type_id,strength_0406,experience,notes) VALUES")
L.append(" ('SQ-HARUNA-RECON','Hydravions du Haruna (E8N2)','IJN','SH-HARUNA','AC-E8N2',3,'average','Ligne de recherche courte (150 nm) du 4 juin');")

# ---- 7 lignes japonaises ----
LINES = [  # (nom, squadron, brg, dist, dep_min depuis 04:30, vitesse kn)
    ('AKAGI',    'SQ-AKAGI-KANKO',   181, 300, 0,  140),
    ('KAGA',     'SQ-KAGA-KANKO',    158, 300, 0,  140),
    ('TONE1',    'SQ-TONE-RECON',    123, 300, 0,  120),
    ('TONE4',    'SQ-TONE-RECON',    100, 300, 30, 120),   # lancé en retard
    ('CHIKUMA1', 'SQ-CHIKUMA-RECON',  77, 300, 0,  120),
    ('CHIKUMA5', 'SQ-CHIKUMA-RECON',  54, 300, 0,  120),
    ('HARUNA',   'SQ-HARUNA-RECON',  142, 150, 0,   90),
]
L.append("\nINSERT INTO missions VALUES")
rows = []
for name, sq, brg, dist, dep, v in LINES:
    dep_t = t(4, 4, 30 + dep)
    out_min = dist / v * 60
    dog_min = 60 / v * 60 if dist == 300 else 30 / v * 60
    back_min = (dist * 1.05) / v * 60
    end_t = t(4, 4 + int((30 + dep + out_min + dog_min + back_min) // 60), (30 + dep + out_min + dog_min + back_min) % 60)
    rows.append(f" ('MS-0604-SEARCH-{name}','IJN',NULL,'search','Ligne {name.lower()} — relèvement {brg}°, {dist} nm + crochet',"
                f"'{dep_t}','{dep_t}',NULL,'{end_t}',"
                f"'{ 'CONTACT: TF US trouvée 07:28' if name=='TONE4' else ('passée près de TF-17 sans la voir (nuages)' if name=='CHIKUMA5' else 'RAS') }',"
                f"'Relèvement à confirmer (schéma rapport Nagumo); la TF US était dans l''interstice Tone4/Chikuma1')")
L.append(",\n".join(rows) + ";")

L.append("\nINSERT INTO mission_squadrons VALUES")
L.append(",\n".join(f" ('MS-0604-SEARCH-{n}','{sq}',1,0,NULL,'1 appareil')" for n, sq, *_ in LINES) + ";")

L.append("\nINSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES")
rows = []
for name, sq, brg, dist, dep, v in LINES:
    t0 = 4 * 60 + 30 + dep                       # minutes depuis 00:00
    out = dist / v * 60
    p1 = dest(LAT0, LON0, brg, dist)
    dog = (60 if dist == 300 else 30)
    p2 = dest(*p1, brg - 90, dog)
    tt = lambda m: t(4, int(m // 60), m % 60)
    rows.append(f" ('MS-0604-SEARCH-{name}',1,'{tt(t0)}','{tt(t0+out)}',{LAT0},{LON0},{p1[0]},{p1[1]},{brg},{v},500,'estimated','aller {dist} nm')")
    rows.append(f" ('MS-0604-SEARCH-{name}',2,'{tt(t0+out)}','{tt(t0+out+dog/v*60)}',{p1[0]},{p1[1]},{p2[0]},{p2[1]},{(brg-90)%360},{v},500,'estimated','crochet {dog} nm à gauche')")
    # retour vers la KB (qui a bougé: point de récupération approx 30.7,-179.3)
    rows.append(f" ('MS-0604-SEARCH-{name}',3,'{tt(t0+out+dog/v*60)}','{tt(t0+out+dog/v*60+dist*1.05/v*60)}',{p2[0]},{p2[1]},30.70,-179.30,{(brg+180)%360},{v},500,'estimated','retour vers la force (position ~07:00-09:30)')")
L.append(",\n".join(rows) + ";")

# ---- éventail PBY ----
L.append("\nINSERT INTO missions VALUES")
L.append(" ('MS-0604-PBY-SEARCH','USN','SH-MIDWAY','search','Recherche en éventail OSO->NNE, ~700 nm',"
         "'1942-06-04T04:15:00-12:00','1942-06-04T04:45:00-12:00',NULL,NULL,"
         "'05:34: Ady trouve la KB; 05:52: rapport 2 CV (Chase)','22 PBY; 8 lignes représentatives tracées (grade C)');")
L.append("INSERT INTO mission_squadrons VALUES ('MS-0604-PBY-SEARCH','SQ-PBY-MIDWAY',22,0,NULL,'8 lignes représentatives sur ~16 secteurs réels');")
L.append("\nINSERT INTO mission_legs (mission_id,seq,start_ts,end_ts,start_lat,start_lon,end_lat,end_lon,course_deg,speed_kn,altitude_m,method,notes) VALUES")
rows = []
BRGS = (220, 245, 270, 295, 315, 330, 345, 10)
for i, brg in enumerate(BRGS, 1):
    p = dest(*MID, brg, 700)
    rows.append(f" ('MS-0604-PBY-SEARCH',{i},'1942-06-04T04:30:00-12:00','1942-06-04T11:30:00-12:00',{MID[0]},{MID[1]},{p[0]},{p[1]},{brg},100,300,'estimated','ligne {brg}° — aller 700 nm"
                + (" — secteur du contact d''Ady (05:34)" if brg == 315 else "") + "')")
for i, brg in enumerate(BRGS, 1):  # retours (certains équipages déroutés/prolongés: simplification)
    p = dest(*MID, brg, 700)
    rows.append(f" ('MS-0604-PBY-SEARCH',{i+8},'1942-06-04T11:30:00-12:00','1942-06-04T18:30:00-12:00',{p[0]},{p[1]},{MID[0]},{MID[1]},{(brg+180)%360},100,300,'estimated','ligne {brg}° — retour vers Midway (réalité variable: déroutements, suivis de contact)')")
L.append(",\n".join(rows) + ";")
L.append("UPDATE missions SET recovery_ts='1942-06-04T18:30:00-12:00' WHERE mission_id='MS-0604-PBY-SEARCH';")

L.append("""
INSERT INTO claims (entity_table,entity_id,field,value,source_id,is_accepted,status,resolution_note) VALUES
 ('missions','MS-0604-SEARCH-TONE4','bearing','100','SRC-SHATTERED-SWORD',1,'single_source','Relèvement de la ligne n°4 du Tone; à confirmer sur le schéma du rapport Nagumo (OPNAV P32-1002)'),
 ('missions','MS-0604-SEARCH-CHIKUMA5','bearing','54','SRC-SHATTERED-SWORD',1,'single_source','Ligne passée près de TF-17 sous plafond nuageux sans contact'),
 ('missions','MS-0604-PBY-SEARCH','plan','22 PBY, secteur OSO-NNE, 700 nm','SRC-CINCPAC-01849',1,'single_source','Schéma précis des 16 secteurs à reprendre du rapport CINCPAC');
""")

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'phase8b_recherches.sql')
open(out, 'w', encoding='utf-8').write("\n".join(L))
print("OK:", out)

import json, os, subprocess, sys, tempfile, sqlite3

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root (SQL files live here)
SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'export_data.py')

def build_db(path):
    files = ('schema_midway.sql','seed_exemples.sql','phase2_oob.sql','phase3_chronologie.sql',
        'phase4_positions.sql','phase4b_corrections.sql','phase5_processus.sql',
        'phase6_connaissance.sql','phase7_causes.sql','phase7b_derives.sql','phase7c_tf16.sql',
        'phase7d_tf16_recup.sql','phase7e_convention_caps.sql','phase7f_cibles.sql',
        'phase8_depouillement.sql','phase8b_recherches.sql','phase8c_j3_recherches.sql',
        'phase9_params_f2.sql','phase10_halos.sql','phase10b_retours.sql','phase10c_effectifs.sql',
        'phase10d_evenements_missions.sql','phase10e_reperages.sql','phase10f_b17.sql',
        'phase13_rebaseline_tf.sql')
    con = sqlite3.connect(path); con.execute("PRAGMA foreign_keys=ON")
    for f in files: con.executescript(open(os.path.join(ROOT, f)).read())
    con.commit(); con.close()

def main():
    tmp = tempfile.mkdtemp()
    db = os.path.join(tmp, 'midway.sqlite'); build_db(db)
    out = os.path.join(tmp, 'data')
    subprocess.run([sys.executable, SCRIPT, db, out], check=True)

    replay = json.load(open(os.path.join(out, 'replay.json')))
    for key in ('entities','wrecks','fires','combats','spots','raids','events','contacts','tmin','tmax','build'):
        assert key in replay, f"replay.json manque la cle {key}"
    assert len(replay['entities']) >= 1, "aucune entite exportee"
    assert replay['entities'][0]['track'], "entite sans track"
    assert 'db_hash' in replay['build'], "build sans db_hash"

    chrono = json.load(open(os.path.join(out, 'chronologie.json')))
    assert isinstance(chrono, list) and len(chrono) > 0, "chronologie vide"
    assert {'t','type','side','s'} <= set(chrono[0].keys()), "evenement chrono incomplet"

    meta = json.load(open(os.path.join(out, 'meta.json')))
    assert meta['db_hash'] == replay['build']['db_hash'], "db_hash incoherent entre meta et replay"

    # méthodologie bilingue: un asset par langue
    meth_fr = open(os.path.join(out, 'methodologie.fr.html'), encoding='utf-8').read()
    assert 'Principes directeurs' in meth_fr, "methodologie.fr.html: contenu attendu absent"
    assert '<nav>' not in meth_fr and '<script' not in meth_fr, "methodologie.fr.html: nav/script non strippes"
    meth_en = open(os.path.join(out, 'methodologie.en.html'), encoding='utf-8').read()
    assert meth_en.strip(), "methodologie.en.html vide"
    assert '<nav>' not in meth_en and '<script' not in meth_en, "methodologie.en.html: nav/script non strippes"
    print("OK")

if __name__ == '__main__':
    main()

#!/bin/bash
# Pipeline complet — à lancer après TOUTE modification (SQL ou scripts).
# Ordre: rebuild base -> inférence positions -> replay F1 -> audit -> carte HTML.
# La carte est générée EN DERNIER: son tampon #hash correspond donc toujours
# à la base finale. Échoue au premier problème (set -e).
set -e
cd "$(dirname "$0")"
TMP=$(mktemp -d)/midway.sqlite

python3 - "$TMP" <<'EOF'
import sqlite3, sys
files=('schema_midway.sql','seed_exemples.sql','phase2_oob.sql','phase3_chronologie.sql',
       'phase4_positions.sql','phase4b_corrections.sql','phase5_processus.sql',
       'phase6_connaissance.sql','phase7_causes.sql','phase7b_derives.sql',
       'phase7c_tf16.sql','phase7d_tf16_recup.sql','phase7e_convention_caps.sql','phase7f_cibles.sql',
       'phase8_depouillement.sql','phase8b_recherches.sql','phase8c_j3_recherches.sql','phase9_params_f2.sql','phase10_halos.sql','phase10b_retours.sql','phase10c_effectifs.sql','phase10d_evenements_missions.sql','phase10e_reperages.sql','phase10f_b17.sql')
con = sqlite3.connect(sys.argv[1])
con.execute("PRAGMA foreign_keys=ON")
for f in files: con.executescript(open(f).read())
con.commit(); con.close()
print(f"[1/5] base reconstruite ({len(files)} fichiers SQL)")
EOF

python3 inferer_positions.py "$TMP" --quiet >/dev/null && echo "[2/5] inférence positions OK"
python3 simulateur_f1.py "$TMP" --quiet           && echo "[3/5] replay F1 OK"
python3 audit_coherence.py "$TMP"                 && echo "[4/6] audit OK"
python3 verif_textes.py "$TMP" | head -3          && echo "[5/6] vérif textes vs réalité OK"
cp "$TMP" midway.sqlite
cp "$(dirname "$TMP")/rapport_f1.md" . 2>/dev/null || true
python3 generer_carte.py midway.sqlite carte_midway.html && echo "[5/5] carte régénérée"
echo "Terminé. Tampon de la carte = empreinte de la base finale."

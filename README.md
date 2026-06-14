# Midway 1942 — reconstruction sourcée et rejouable

Reconstruction chronologique, spatiale et **physique** de la bataille de Midway
(3–7 juin 1942), à partir d'une base de données où **chaque donnée est une
affirmation sourcée et gradée**. Le projet ne raconte pas la bataille : il la
**modélise** de façon vérifiable, puis la rejoue dans un modèle de contraintes
(ponts d'envol, équipes d'armement, durées des opérations) pour distinguer ce qui
était *possible* de ce qui relève du récit.

Trois briques :

1. **Une base de données** (`midway.sqlite`) construite à partir de fichiers SQL
   versionnés — l'unique source de vérité.
2. **Des outils Python** d'inférence, de simulation et d'audit.
3. **Un site web** (React/TypeScript) qui lit des données exportées de la base :
   carte/replay animé, chronologie, méthodologie.

---

## Démarrage rapide

Prérequis : **Python 3** et **Node.js** (pour le site).

```bash
# 1. Régénérer toute la chaîne (base → inférence → replay → audit → carte → export → site)
./tout_regenerer.sh

# 2. Lancer le site web en développement
cd web
npm install      # première fois seulement
npm run dev      # ouvre http://localhost:5173/
```

La carte « historique » mono-fichier reste disponible : ouvrez directement
`carte_midway.html` dans un navigateur (aucune dépendance).

---

## Le modèle de données

Tout repose sur le **sourçage**. Le schéma (`schema_midway.sql`, 26 tables +
3 vues) impose que toute valeur soit une `claim` rattachée à une `source` gradée
(A/B/C/D). Plusieurs claims peuvent porter sur le même champ ; une seule est
retenue (`is_accepted=1`), avec une note d'arbitrage si conflit.

Briques principales du modèle :

| Domaine | Tables clés |
|---|---|
| Sourçage | `sources`, `claims` |
| Ordre de bataille | `formations`, `ships`, `squadrons`, `persons`, `aircraft_types`, `ordnance_types` |
| Contraintes physiques | `carrier_constraints`, `process_templates`, `process_steps`, `constraint_params` |
| Chronologie & espace | `events`, `event_participants`, `positions`, `missions`, `mission_legs`, `mission_squadrons` |
| Renseignement & décision | `contact_reports`, `messages`, `decisions`, `knowledge_states` |
| États | `damage_states`, `squadron_status`, `weather_obs` |

**Conventions** (figées dans le schéma) :
- **Temps** : heure locale de Midway (**GMT−12**), ISO 8601
  `YYYY-MM-DDTHH:MM:SS-12:00`. L'heure d'origine de chaque source (souvent Tokyo,
  GMT+9) est conservée dans `claims.original_value`.
- **Espace** : latitude/longitude WGS84 en degrés décimaux.
- **Granularité aérienne** : l'escadrille (`squadron`).

La méthodologie complète (principes, protocole de vérification, modèle conceptuel,
phasage) est documentée dans **`methodologie_midway.html`** (12 sections).

---

## Le pipeline de régénération

`tout_regenerer.sh` reconstruit tout dans l'ordre, et échoue au premier problème
(`set -e`) :

1. **Reconstruction de la base** depuis les ~25 fichiers `.sql`
   (`schema_midway.sql`, `seed_exemples.sql`, puis `phase2`…`phase13`).
2. **Inférence des positions** (`inferer_positions.py`).
3. **Replay F1** (`simulateur_f1.py`).
4. **Audit de cohérence** (`audit_coherence.py`).
5. **Vérification textes vs réalité** (`verif_textes.py`).
6. **Carte historique** (`generer_carte.py` → `carte_midway.html`).
7. **Export JSON** (`data/export_data.py` → `web/public/data/`).
8. **Build du site React** (`web/dist/`).

La base, la carte et les JSON exportés sont versionnés (artefacts régénérables) ;
le tampon `db_hash` lie chaque sortie à l'empreinte de la base finale.

---

## Les outils Python

| Script | Rôle |
|---|---|
| `inferer_positions.py` | Confronte chaque piste aux contraintes physiques et journalise tout dans `position_inferences` ; n'ajuste qu'un waypoint `estimated` mieux sourcé. |
| `simulateur_f1.py` | **Moteur F1** — rejoue les opérations *historiques* dans le modèle physique ; chaque opération reçoit un verdict `coherent` / `tension` / `incoherent`. Produit `rapport_f1.md`. |
| `simulateur_f2.py` | **Moteur F2** (squelette) — simulation à événements discrets pilotée par les *décisions* plutôt que par la chronologie. |
| `audit_coherence.py` | Banc de test de cohérence de la base (constats `FAIL`/`WARN`/`INFO` + score). |
| `verif_textes.py` | Chasse les écarts entre les valeurs chiffrées des textes et la géométrie/les données structurées (le script signale, l'humain tranche). |
| `diag_cinematique.py` | Diagnostic lecture seule de la cohérence cinématique des événements. |
| `generer_carte.py` | Génère la carte/replay mono-fichier `carte_midway.html` depuis la base. |
| `generer_phase8_recherches.py` | Génère le SQL des routes de recherche aériennes du 4 juin. |
| `data/export_data.py` | Exporte la base en JSON pour le site React (`replay.json`, `chronologie.json`, `meta.json`, `methodologie.html`). |

`rapport_f1.md` (généré) illustre la démarche : pour chaque opération, l'écart
entre l'histoire et le modèle est mesuré et interprété (p. ex. l'effet des
interruptions sous attaque sur le réarmement des porte-avions japonais).

---

## Le site web (`web/`)

Application React + TypeScript (Vite, React Router), qui lit les JSON exportés —
aucune donnée n'est embarquée en dur dans le HTML.

| Page | Contenu |
|---|---|
| Accueil | Présentation et liens. |
| Carte | Replay animé sur canvas : pistes, halos d'incertitude, raids dénombrables, combats, repérages. Légende repliable et fil d'événements optionnel (clic = saut à l'instant). |
| Chronologie | Liste des événements (timeline). |
| Méthodologie | La méthodologie de modélisation. |

Commandes utiles (depuis `web/`) : `npm run dev` (développement),
`npm run build` (build statique dans `web/dist/`), `npm test` (Vitest),
`npm run lint`.

> La conception (spec) et le plan d'implémentation de la migration vers ce site
> sont conservés dans `docs/superpowers/`.

---

## État d'avancement

- **F1 (replay validé)** : opérationnel — les opérations historiques sont
  confrontées au modèle physique.
- **F2 (simulation par décisions)** : squelette, en cours.
- **F3 (contre-factuels)** : pistes identifiées dans `rapport_f1.md` (p. ex. la
  frappe non escortée proposée par Yamaguchi à 08:30).

---

## Licence

Aucune licence n'est encore définie. En l'absence de licence explicite, le code
reste « tous droits réservés » par défaut — ajoutez un fichier `LICENSE` (MIT,
CC-BY pour les données historiques, etc.) si vous souhaitez en autoriser la
réutilisation.

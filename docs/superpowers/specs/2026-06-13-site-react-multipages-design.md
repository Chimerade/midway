# Spec — Site React multi-pages Midway

**Date :** 2026-06-13
**Statut :** Validé (design)

## Objectif

Transformer le projet Midway, aujourd'hui un pipeline de génération de pages HTML
autoportantes, en un véritable site web React multi-pages avec menu de navigation.
La donnée doit être **lue depuis des fichiers JSON exportés de la base** plutôt
qu'embarquée en dur dans le HTML, afin de permettre des évolutions (nouvelles pages,
nouveaux contenus) sans tout reconstruire.

## Principes

- **Source de vérité inchangée :** les ~25 fichiers `.sql` et `midway.sqlite`
  restent la source de vérité. Aucune donnée n'est saisie côté front.
- **Découplage données / présentation :** la base est compilée en JSON granulaire ;
  React ne connaît que ces JSON. Plus aucune donnée inline dans du HTML.
- **Portage iso-fonctionnel du replay :** le moteur canvas existant est porté à
  l'identique (même rendu, mêmes contrôles) avant toute amélioration.
- **YAGNI :** pas d'API, pas d'édition en ligne, pas de refonte UI, pas de
  responsive mobile poussé pour cette V1.

## Décisions actées

| Sujet | Décision |
|---|---|
| Accès aux données | Export JSON statique (pas d'API, pas de sql.js) |
| Pages V1 | Accueil, Carte/Replay, Méthodologie, Chronologie |
| Langage | TypeScript (typer le contrat JSON ↔ canvas) |
| Portage canvas | Iso-fonctionnel d'abord |
| Outil de build | Vite |
| Routing | React Router |
| Styles | CSS + variables custom (réutilise le thème clair/sombre existant) |
| State | State React + contexte pour le thème (pas de librairie) |

## Architecture d'ensemble

Deux mondes séparés, reliés par un contrat JSON :

```
data/   (existant, quasi inchangé)          web/   (nouveau, app React/TS)
 ├─ *.sql ─→ midway.sqlite                    ├─ public/data/*.json  ← cible export
 ├─ scripts Python (inférence, simul…)        └─ src/
 └─ export_data.py  ───────[JSON]───────────────→  routes, composants, types
```

`export_data.py` (dérivé de `generer_carte.py`) compile la base en JSON.
React charge les JSON via `fetch`. La source de vérité reste le SQL.

## Couche d'export (Python)

Nouveau script `data/export_data.py`, reprenant les requêtes SQL de
`generer_carte.py:21-174`, mais écrivant des fichiers au lieu d'injecter du HTML.

| Fichier exporté | Contenu | Source |
|---|---|---|
| `web/public/data/replay.json` | entities, wrecks, fires, combats, spots, raids, events, contacts, tmin, tmax, build | requêtes existantes de `generer_carte.py` |
| `web/public/data/chronologie.json` | événements enrichis pour la page timeline | table `events` |
| `web/public/data/meta.json` | tampon de version partagé (db_hash, date de génération) | `generer_carte.py:160-169` |

Le template HTML + JS de `generer_carte.py` (lignes 177-608) quitte le Python
pour devenir du React. Le tampon `db_hash` est préservé dans `meta.json` afin de
conserver la traçabilité base ↔ site.

`generer_carte.py` peut être conservé tel quel pendant la migration (production de
l'ancien HTML de référence), puis retiré une fois l'équivalence validée.

## Structure de l'application React

```
web/src/
 ├─ main.tsx, App.tsx          # routeur + layout (menu)
 ├─ layout/  Nav, ThemeToggle  # menu + bascule clair/sombre (contexte)
 ├─ routes/
 │   ├─ Home.tsx               # accueil (nouveau)
 │   ├─ Carte.tsx              # héberge <ReplayMap>
 │   ├─ Methodologie.tsx       # prose convertie depuis methodologie_midway.html
 │   └─ Chronologie.tsx        # timeline depuis chronologie.json
 ├─ components/ReplayMap/
 │   ├─ ReplayMap.tsx          # canvas (useRef) + boucle tick/draw
 │   ├─ Controls.tsx           # lecture, vitesse, zoom, cases à cocher → state React
 │   └─ render.ts              # logique de dessin portée à l'identique
 ├─ types/replay.ts            # contrat TypeScript (entities, raids, events…)
 └─ data/useReplayData.ts      # fetch + parse des JSON
```

## Composant ReplayMap (portage iso-fonctionnel)

- Le `<canvas>` est référencé via `useRef`.
- La boucle `requestAnimationFrame` (`tick`/`draw`) vit dans **un seul `useEffect`**
  à dépendances vides, pour éviter le conflit avec le cycle de rendu React.
- Les contrôles, aujourd'hui lus via `getElementById('cbHalo')` etc., deviennent du
  **state React** transmis au moteur de dessin.
- `render.ts` conserve à l'identique la projection géographique, `interp`, les halos
  d'incertitude, les raids dénombrables et le fil d'événements. Le comportement
  visuel doit être équivalent à l'ancien `carte_midway.html`.

### Contrat de données (types/replay.ts)

Le JSON `replay.json` expose des clés condensées (`t`, `crs`, `n0`, `lost`, `par`,
`err`, `m`…). Ces formes doivent être typées explicitement en TypeScript pour
détecter au build toute rupture entre l'exporteur Python et le moteur canvas.
Le contrat est dérivé de la structure produite par `generer_carte.py:170-174`.

## Navigation & pages

React Router avec quatre routes :

- `/` — Accueil (présentation du projet, contexte de la bataille, liens)
- `/carte` — Replay animé (`<ReplayMap>`)
- `/methodologie` — prose convertie depuis `methodologie_midway.html` (sections 1-12)
- `/chronologie` — timeline navigable des événements

Menu commun dans le layout. Le thème clair/sombre actuel devient un contexte React
global (bascule disponible sur toutes les pages).

## Pipeline & déploiement

`tout_regenerer.sh` est adapté : l'étape « carte » (`generer_carte.py`) est
remplacée/complétée par `export_data.py` (génère les JSON dans
`web/public/data/`), puis `npm run build` (dans `web/`) produit le site statique.

Pendant toute la migration, l'ancien `carte_midway.html` reste la référence
fonctionnelle jusqu'à validation de l'équivalence du replay React.

Déploiement : site statique (les JSON sont des assets servis comme le reste).

## Hors périmètre (YAGNI)

- Pas d'API backend ni de base serveur.
- Pas d'édition / écriture des données depuis le site.
- Pas de `sql.js` / SQLite WASM en navigateur.
- Pas de refonte de l'UI du replay (iso-fonctionnel d'abord).
- Pas de responsive mobile poussé pour la V1.

## Critères de succès

1. Le site React se lance (`npm run dev`) et se build (`npm run build`) en statique.
2. Les quatre pages sont navigables via un menu commun.
3. La page Carte reproduit le comportement du `carte_midway.html` actuel
   (rendu et contrôles équivalents).
4. Aucune donnée n'est inline dans le HTML : tout provient des JSON exportés.
5. `export_data.py` régénère les JSON depuis la base ; le tampon `db_hash` est
   présent dans `meta.json`.
6. `tout_regenerer.sh` enchaîne rebuild base → export JSON → build React.

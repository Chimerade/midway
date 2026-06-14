# Site Midway 1942 (`web/`)

Application React + TypeScript (Vite, React Router) du projet
[Midway 1942](../README.md). Elle lit des fichiers JSON exportés de la base
SQLite (`public/data/`, produits par `../data/export_data.py`) — aucune donnée
n'est embarquée en dur dans le code.

## Commandes

```bash
npm install        # première fois
npm run dev        # serveur de développement (http://localhost:5173/)
npm run build      # build statique → dist/ (utilisé par ../tout_regenerer.sh)
npm test           # tests Vitest
npm run lint       # ESLint
```

Les données sont normalement régénérées par le pipeline racine
`../tout_regenerer.sh`. Pour ne (re)faire que l'export JSON :

```bash
python3 ../data/export_data.py ../midway.sqlite public/data
```

## Structure

```
src/
├── main.tsx, App.tsx        # routeur + montage
├── layout/                  # menu + coquille
├── theme/                   # contexte thème clair/sombre
├── routes/                  # Accueil, Carte, Chronologie, Méthodologie
├── components/ReplayMap/     # moteur canvas (render.ts), ReplayMap, Controls, Legend, Feed
├── data/                    # hooks de chargement des JSON
└── types/                   # contrat TypeScript des données
```

Le moteur de dessin (`components/ReplayMap/render.ts`) est un portage
iso-fonctionnel de la carte mono-fichier historique `../carte_midway.html`.

# Site React multi-pages Midway — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le pipeline HTML autoportant par un site React/TypeScript multi-pages (Accueil, Carte/Replay, Méthodologie, Chronologie) lisant des JSON exportés de la base SQLite.

**Architecture:** La base `midway.sqlite` reste la source de vérité. Un script Python `data/export_data.py` (dérivé de `generer_carte.py`) compile la base en fichiers JSON dans `web/public/data/`. Une SPA React/Vite charge ces JSON via `fetch`. Le moteur canvas du replay est porté à l'identique depuis le JS inline de `generer_carte.py`.

**Tech Stack:** Python 3 (export), Vite + React 18 + TypeScript, react-router-dom v7 (mode librairie/déclaratif), Vitest (tests front), CSS + variables custom (thème clair/sombre existant).

**Conventions de ce dépôt :** les scripts Python sont exécutés directement (`python3 script.py`), sans framework de test ; les tests Python de ce plan suivent ce style (script à `assert`, lancé via `python3`, sortie `OK`/exception). Le front, lui, utilise Vitest.

**Repère de chemins :** racine du dépôt = `/Users/thierry/Claude/Projects/midway` (ci-après la racine). Les chemins du plan sont relatifs à la racine.

---

## Structure des fichiers

**Créés :**
- `data/export_data.py` — compile la base en JSON (`replay.json`, `chronologie.json`, `meta.json`) + extrait `methodologie.html`
- `data/test_export_data.py` — test du script d'export (style assert)
- `web/` — application Vite React/TS (générée par scaffold)
- `web/src/types/replay.ts` — contrat TypeScript des données
- `web/src/data/useReplayData.ts` — hook de chargement des JSON
- `web/src/data/useReplayData.test.ts` — test Vitest du hook/parsing
- `web/src/theme/ThemeContext.tsx` — contexte thème clair/sombre
- `web/src/layout/Layout.tsx`, `web/src/layout/Nav.tsx` — coquille + menu
- `web/src/routes/Home.tsx`, `Carte.tsx`, `Methodologie.tsx`, `Chronologie.tsx`
- `web/src/components/ReplayMap/ReplayMap.tsx` — composant canvas
- `web/src/components/ReplayMap/Controls.tsx` — barre de contrôles
- `web/src/components/ReplayMap/render.ts` — moteur de dessin porté
- `web/src/components/ReplayMap/types.ts` — `RenderState` (état passé au moteur)

**Modifiés :**
- `tout_regenerer.sh` — ajoute l'étape export + build React

**Note :** `generer_carte.py` et `carte_midway.html` sont **conservés** comme référence pendant toute la migration. On ne les supprime pas dans ce plan.

---

## Task 1: Échafaudage de l'app React

**Files:**
- Create: `web/` (généré par Vite)

- [ ] **Step 1: Scaffold Vite React TS**

Run (depuis la racine) :
```bash
npm create vite@latest web -- --template react-ts
cd web && npm install
npm install react-router-dom
```
Expected: `web/` créé avec `package.json`, `src/App.tsx`, `vite.config.ts`. Installation sans erreur.

- [ ] **Step 2: Vérifier que le dev server démarre**

Run :
```bash
cd web && npm run dev -- --port 5173 &
sleep 4 && curl -s -o /dev/null -w "%{http_code}" http://localhost:5173/ ; kill %1
```
Expected: `200`.

- [ ] **Step 3: Nettoyer le boilerplate**

Remplacer `web/src/App.tsx` par un squelette minimal :
```tsx
export default function App() {
  return <div>Midway</div>;
}
```
Supprimer `web/src/App.css` et le contenu de `web/src/index.css` (le vider, on le remplira au thème). Retirer l'import de `App.css` dans `App.tsx` s'il existe.

- [ ] **Step 4: Commit**

```bash
git add web && git commit -m "feat: scaffold Vite React TS app in web/"
```

---

## Task 2: Script d'export JSON (data/export_data.py)

Reprend les requêtes de `generer_carte.py:18-174` mais écrit des fichiers JSON au lieu d'injecter du HTML. **Réutiliser telles quelles** les fonctions `tmin`, `formation_sub` et les boucles de construction de `entities`, `wrecks`, `fires`, `combats`, `spots`, `raids`, `events`, `contacts`, et le dict `build` (`generer_carte.py:160-169`).

**Files:**
- Create: `data/export_data.py`
- Test: `data/test_export_data.py`

- [ ] **Step 1: Écrire le test (échec attendu)**

`data/test_export_data.py` :
```python
import json, os, subprocess, sys, tempfile, sqlite3

ROOT = os.path.dirname(os.path.abspath(__file__))

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
    subprocess.run([sys.executable, os.path.join(ROOT, 'export_data.py'), db, out], check=True)

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

    assert os.path.exists(os.path.join(out, 'methodologie.html')), "methodologie.html absent"
    print("OK")

if __name__ == '__main__':
    main()
```

- [ ] **Step 2: Lancer le test (échec attendu)**

Run : `python3 data/test_export_data.py`
Expected: échec — `export_data.py` n'existe pas (FileNotFoundError / CalledProcessError).

- [ ] **Step 3: Écrire export_data.py**

`data/export_data.py` — copier la logique de `generer_carte.py:8-175` (imports, `tmin`, `formation_sub`, `TRACKED`, et toutes les boucles construisant `entities`, `wrecks`, `fires`, `combats`, `spots`, `raids`, `minfo`/`first_leg`, `events`, `contacts`, `build`, `data`). Remplacer la fin (génération HTML, lignes 177-614) par l'écriture de fichiers :

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Exporte midway.sqlite en JSON pour le site React.
Usage: python3 export_data.py [chemin_base] [dossier_sortie]"""
import sqlite3, json, sys, os, hashlib, re
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.abspath(__file__))
DB  = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'midway.sqlite')
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'web', 'public', 'data')
os.makedirs(OUT, exist_ok=True)

# ----- [COPIER ICI generer_carte.py:14-174 :]
#   EPOCH, tmin(), la connexion `con` (mode ro), formation_sub(),
#   TRACKED, la construction de entities/wrecks/fires/combats/spots/raids/
#   events/contacts, db_path, build, et le dict `data`.
#   (Ne PAS copier le bloc HTML lignes 177+.)
# -----

# Écriture des fichiers JSON
def write(name, obj):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False)

write('replay.json', data)
write('chronologie.json', events)          # `events` vient de generer_carte.py:152-154
write('meta.json', build)                  # `build` vient de generer_carte.py:162-169

# Méthodologie : extraire le contenu du <body> (sans <nav>/<script>) en asset HTML
src = open(os.path.join(ROOT, 'methodologie_midway.html'), encoding='utf-8').read()
body = re.search(r'<body[^>]*>(.*)</body>', src, re.S).group(1)
body = re.sub(r'<nav>.*?</nav>', '', body, flags=re.S)
body = re.sub(r'<script.*?</script>', '', body, flags=re.S)
with open(os.path.join(OUT, 'methodologie.html'), 'w', encoding='utf-8') as f:
    f.write(body.strip())

con.close()
print(f"OK: {OUT} (entites={len(entities)}, events={len(events)})")
```

Note : `data` (generer_carte.py:170-174) contient déjà `entities, wrecks, fires, combats, spots, raids, events, contacts, tmax, tmin, build`. La clé `build` y est imbriquée ; `meta.json` reçoit le même dict `build`.

- [ ] **Step 4: Lancer le test (succès attendu)**

Run : `python3 data/test_export_data.py`
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add data/export_data.py data/test_export_data.py
git commit -m "feat: add export_data.py producing JSON from sqlite"
```

---

## Task 3: Générer les JSON dans web/ et brancher le pipeline

**Files:**
- Modify: `tout_regenerer.sh`

- [ ] **Step 1: Générer les JSON une première fois**

Run : `python3 data/export_data.py midway.sqlite web/public/data`
Expected: `OK: …/web/public/data (entites=…, events=…)` et les fichiers `replay.json`, `chronologie.json`, `meta.json`, `methodologie.html` présents dans `web/public/data/`.

- [ ] **Step 2: Vérifier le contenu généré**

Run :
```bash
ls -la web/public/data/ && python3 -c "import json; d=json.load(open('web/public/data/replay.json')); print('entities', len(d['entities']), 'events', len(d['events']), 'hash', d['build']['db_hash'])"
```
Expected: 4 fichiers listés ; compte d'entités/événements non nul et un hash de 8 caractères.

- [ ] **Step 3: Ajouter l'étape export au pipeline**

Dans `tout_regenerer.sh`, après la ligne `python3 generer_carte.py midway.sqlite carte_midway.html && echo "[5/5] carte régénérée"`, ajouter :
```bash
python3 export_data.py midway.sqlite web/public/data && echo "[6/6] JSON exportés vers web/"
```
(On garde `generer_carte.py` : l'ancienne carte reste la référence pendant la migration.)

- [ ] **Step 4: Vérifier le pipeline complet**

Run : `./tout_regenerer.sh`
Expected: toutes les étapes `OK`, dont `[6/6] JSON exportés vers web/`.

- [ ] **Step 5: Commit**

```bash
git add tout_regenerer.sh web/public/data
git commit -m "feat: export JSON in tout_regenerer.sh pipeline"
```

---

## Task 4: Contrat TypeScript + hook de chargement

**Files:**
- Create: `web/src/types/replay.ts`
- Create: `web/src/data/useReplayData.ts`
- Test: `web/src/data/useReplayData.test.ts`
- Modify: `web/package.json` (script de test), `web/vite.config.ts` (config vitest)

- [ ] **Step 1: Installer Vitest**

Run : `cd web && npm install -D vitest`
Puis ajouter dans `web/package.json`, section `"scripts"` : `"test": "vitest run"`.

- [ ] **Step 2: Écrire les types**

`web/src/types/replay.ts` — typer les clés condensées du JSON (dérivées de `generer_carte.py:64-174`) :
```ts
export interface TrackPoint {
  t: number; lat: number; lon: number; err: number; m: string;
  crs: number | null; ts: string; cause: string | null; note: string | null;
}
export interface Entity { id: string; label: string; side: 'IJN' | 'USN'; sub: string; track: TrackPoint[]; }
export interface Wreck { t: number; lat: number; lon: number; name: string; h: string; ent: string; }
export interface Fire { ent: string; t0: number; t1: number; }
export interface Combat { t0: number; t1: number; ent: string; s: string; }
export interface Spot { t: number; ent: string; s: string; }
export interface Raid {
  mid: string; seq: number; side: 'IJN' | 'USN'; t0: number; t1: number;
  a: [number, number]; b: [number, number]; n0: number; lost: number;
  ta: number | null; tl: number | null; par: number;
}
export interface GameEvent { t: number; type: string; side: string; s: string; u: number; }
export interface Contact { t: number; lat: number; lon: number; s: string; }
export interface Build { gen: string; db_hash: string; n_ev: number; n_pos: number; n_inf: number; }
export interface ReplayData {
  entities: Entity[]; wrecks: Wreck[]; fires: Fire[]; combats: Combat[];
  spots: Spot[]; raids: Raid[]; events: GameEvent[]; contacts: Contact[];
  tmin: number; tmax: number; build: Build;
}
```

- [ ] **Step 3: Écrire le test du hook (échec attendu)**

`web/src/data/useReplayData.test.ts` :
```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useReplayData } from './useReplayData';

const sample = {
  entities: [{ id: 'KB', label: 'Kido', side: 'IJN', sub: '', track: [{ t: 0, lat: 30, lon: -179, err: 25, m: 'est', crs: 135, ts: '06-04T04:30', cause: null, note: null }] }],
  wrecks: [], fires: [], combats: [], spots: [], raids: [], events: [], contacts: [],
  tmin: 0, tmax: 100, build: { gen: 'x', db_hash: 'abcd1234', n_ev: 0, n_pos: 0, n_inf: 0 },
};

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(sample) } as Response)));
});

describe('useReplayData', () => {
  it('charge et expose les données', async () => {
    const { result } = renderHook(() => useReplayData());
    await waitFor(() => expect(result.current.data).not.toBeNull());
    expect(result.current.data!.entities[0].label).toBe('Kido');
    expect(result.current.error).toBeNull();
  });
});
```

- [ ] **Step 4: Installer les deps de test et lancer (échec attendu)**

Run : `cd web && npm install -D @testing-library/react jsdom && npm test`
Modifier `web/vite.config.ts` pour importer `defineConfig` depuis `vitest/config` (et non `vite`) et ajouter la clé `test`, afin d'éviter les erreurs de types :
```ts
/// <reference types="vitest" />
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom' },
});
```
Expected: échec — `useReplayData` n'existe pas.

- [ ] **Step 5: Écrire le hook**

`web/src/data/useReplayData.ts` :
```ts
import { useEffect, useState } from 'react';
import type { ReplayData } from '../types/replay';

export function useReplayData() {
  const [data, setData] = useState<ReplayData | null>(null);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`${import.meta.env.BASE_URL}data/replay.json`)
      .then((r) => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
      .then((d: ReplayData) => { if (alive) setData(d); })
      .catch((e) => { if (alive) setError(String(e)); });
    return () => { alive = false; };
  }, []);
  return { data, error };
}
```

- [ ] **Step 6: Lancer le test (succès attendu)**

Run : `cd web && npm test`
Expected: 1 test passé.

- [ ] **Step 7: Commit**

```bash
git add web/src/types web/src/data web/package.json web/vite.config.ts web/package-lock.json
git commit -m "feat: typed replay data contract and loader hook"
```

---

## Task 5: Thème, layout et routing

**Files:**
- Create: `web/src/theme/ThemeContext.tsx`
- Create: `web/src/layout/Layout.tsx`, `web/src/layout/Nav.tsx`
- Create: `web/src/routes/Home.tsx`, `Carte.tsx`, `Methodologie.tsx`, `Chronologie.tsx`
- Modify: `web/src/App.tsx`, `web/src/main.tsx`, `web/src/index.css`

- [ ] **Step 1: Thème (contexte clair/sombre)**

`web/src/theme/ThemeContext.tsx` — reprend la bascule `body.dark` de `generer_carte.py:182` :
```tsx
import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';

type Theme = 'light' | 'dark';
const Ctx = createContext<{ theme: Theme; toggle: () => void }>({ theme: 'light', toggle: () => {} });

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');
  useEffect(() => { document.body.classList.toggle('dark', theme === 'dark'); }, [theme]);
  return <Ctx.Provider value={{ theme, toggle: () => setTheme((t) => (t === 'light' ? 'dark' : 'light')) }}>{children}</Ctx.Provider>;
}
export const useTheme = () => useContext(Ctx);
```

- [ ] **Step 2: CSS de base (variables de thème)**

`web/src/index.css` — copier les variables `:root` et `body.dark` de `generer_carte.py:181-182`, plus un style de nav minimal :
```css
:root{--bg:#fff;--panel:#f4f6f9;--bord:#d4dce5;--txt:#1c2733;--txt2:#5a6b80;--accent:#b07900;}
body.dark{--bg:#0b1220;--panel:#101a2e;--bord:#223348;--txt:#cfd8e3;--txt2:#8fa3bd;--accent:#ffd479;}
body{margin:0;font-family:Verdana,sans-serif;background:var(--bg);color:var(--txt);}
nav.mainnav{display:flex;gap:1.1rem;align-items:center;padding:.7rem 2rem;background:var(--panel);border-bottom:1px solid var(--bord);font-size:.85rem;}
nav.mainnav a{color:var(--txt2);text-decoration:none;}
nav.mainnav a.active{color:var(--accent);font-weight:bold;}
nav.mainnav .spacer{margin-left:auto;}
nav.mainnav button{background:var(--bg);color:var(--txt);border:1px solid var(--bord);border-radius:4px;padding:3px 10px;cursor:pointer;}
.page{padding:1.5rem 2rem;line-height:1.5;}
```

- [ ] **Step 3: Nav + Layout**

`web/src/layout/Nav.tsx` :
```tsx
import { NavLink } from 'react-router-dom';
import { useTheme } from '../theme/ThemeContext';

const link = ({ isActive }: { isActive: boolean }) => (isActive ? 'active' : '');

export default function Nav() {
  const { theme, toggle } = useTheme();
  return (
    <nav className="mainnav">
      <strong>MIDWAY 1942</strong>
      <NavLink to="/" end className={link}>Accueil</NavLink>
      <NavLink to="/carte" className={link}>Carte</NavLink>
      <NavLink to="/chronologie" className={link}>Chronologie</NavLink>
      <NavLink to="/methodologie" className={link}>Méthodologie</NavLink>
      <span className="spacer" />
      <button onClick={toggle}>{theme === 'light' ? '🌙 sombre' : '☀ clair'}</button>
    </nav>
  );
}
```

`web/src/layout/Layout.tsx` :
```tsx
import { Outlet } from 'react-router-dom';
import Nav from './Nav';

export default function Layout() {
  return (<><Nav /><Outlet /></>);
}
```

- [ ] **Step 4: Pages stub**

Créer les quatre fichiers avec un contenu minimal (ils seront étoffés ensuite) :

`web/src/routes/Home.tsx` :
```tsx
export default function Home() {
  return <div className="page"><h1>Bataille de Midway (3–7 juin 1942)</h1><p>Reconstitution et replay.</p></div>;
}
```
`web/src/routes/Carte.tsx` :
```tsx
export default function Carte() {
  return <div className="page">Carte (à venir)</div>;
}
```
`web/src/routes/Methodologie.tsx` :
```tsx
export default function Methodologie() {
  return <div className="page">Méthodologie (à venir)</div>;
}
```
`web/src/routes/Chronologie.tsx` :
```tsx
export default function Chronologie() {
  return <div className="page">Chronologie (à venir)</div>;
}
```

- [ ] **Step 5: Router + App**

`web/src/App.tsx` :
```tsx
import { Routes, Route } from 'react-router-dom';
import Layout from './layout/Layout';
import Home from './routes/Home';
import Carte from './routes/Carte';
import Methodologie from './routes/Methodologie';
import Chronologie from './routes/Chronologie';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Home />} />
        <Route path="carte" element={<Carte />} />
        <Route path="chronologie" element={<Chronologie />} />
        <Route path="methodologie" element={<Methodologie />} />
        <Route path="*" element={<div className="page">Page introuvable</div>} />
      </Route>
    </Routes>
  );
}
```

`web/src/main.tsx` — envelopper avec `BrowserRouter` et `ThemeProvider` :
```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { ThemeProvider } from './theme/ThemeContext';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <ThemeProvider><App /></ThemeProvider>
    </BrowserRouter>
  </React.StrictMode>,
);
```

- [ ] **Step 6: Vérifier la navigation**

Run :
```bash
cd web && npm run dev -- --port 5173 &
sleep 4
curl -s http://localhost:5173/ | grep -q "root" && echo HOME_OK
curl -s http://localhost:5173/carte | grep -q "root" && echo ROUTE_OK
kill %1
```
Expected: `HOME_OK` et `ROUTE_OK` (la SPA sert `index.html` sur toutes les routes). Vérifier aussi visuellement dans un navigateur que le menu bascule entre les pages et que le thème change.

- [ ] **Step 7: Commit**

```bash
git add web/src && git commit -m "feat: routing, layout nav, theme context, page stubs"
```

---

## Task 6: Page Méthodologie (injection de l'asset HTML)

**Files:**
- Modify: `web/src/routes/Methodologie.tsx`

- [ ] **Step 1: Charger et injecter methodologie.html**

`web/src/routes/Methodologie.tsx` :
```tsx
import { useEffect, useState } from 'react';

export default function Methodologie() {
  const [html, setHtml] = useState('');
  useEffect(() => {
    fetch(`${import.meta.env.BASE_URL}data/methodologie.html`)
      .then((r) => r.text()).then(setHtml).catch(() => setHtml('<p>Contenu indisponible.</p>'));
  }, []);
  return <div className="page" dangerouslySetInnerHTML={{ __html: html }} />;
}
```
Note : `methodologie.html` est un asset statique généré par `export_data.py` (Task 2), contenu d'auteur de confiance — `dangerouslySetInnerHTML` est acceptable ici.

- [ ] **Step 2: Vérifier le rendu**

Run :
```bash
cd web && npm run dev -- --port 5173 &
sleep 4 && curl -s http://localhost:5173/data/methodologie.html | grep -c "Principes directeurs"; kill %1
```
Expected: au moins `1` (l'asset est servi). Vérifier visuellement que `/methodologie` affiche les sections.

- [ ] **Step 3: Commit**

```bash
git add web/src/routes/Methodologie.tsx
git commit -m "feat: methodologie page renders exported HTML asset"
```

---

## Task 7: Page Chronologie (timeline)

**Files:**
- Create: `web/src/data/useChronologie.ts`
- Modify: `web/src/routes/Chronologie.tsx`
- Test: `web/src/routes/Chronologie.test.tsx`

- [ ] **Step 1: Hook de chargement chronologie**

`web/src/data/useChronologie.ts` :
```ts
import { useEffect, useState } from 'react';
import type { GameEvent } from '../types/replay';

export function useChronologie() {
  const [events, setEvents] = useState<GameEvent[] | null>(null);
  useEffect(() => {
    fetch(`${import.meta.env.BASE_URL}data/chronologie.json`)
      .then((r) => r.json()).then(setEvents).catch(() => setEvents([]));
  }, []);
  return events;
}
```

- [ ] **Step 2: Écrire le test de formatage (échec attendu)**

`web/src/routes/Chronologie.test.tsx` :
```tsx
import { describe, it, expect } from 'vitest';
import { fmtJour } from './Chronologie';

describe('fmtJour', () => {
  it('convertit les minutes depuis epoch en jour/heure', () => {
    // epoch = 3 juin 1942 00:00 ; 1710 min = 1j 4h30 -> 4 juin 04:30
    expect(fmtJour(1710)).toBe('4 juin — 04:30');
  });
});
```

- [ ] **Step 3: Lancer le test (échec attendu)**

Run : `cd web && npm test`
Expected: échec — `fmtJour` non exporté.

- [ ] **Step 4: Implémenter la page**

`web/src/routes/Chronologie.tsx` — la conversion temps reprend `generer_carte.py:268-272` (jour = 3 + ⌊t/1440⌋, GMT−12) :
```tsx
import { useChronologie } from '../data/useChronologie';

export function fmtJour(t: number): string {
  const d = 3 + Math.floor(t / 1440);
  const mins = ((t % 1440) + 1440) % 1440;
  const h = Math.floor(mins / 60), m = mins % 60;
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d} juin — ${pad(h)}:${pad(m)}`;
}

export default function Chronologie() {
  const events = useChronologie();
  if (!events) return <div className="page">Chargement…</div>;
  return (
    <div className="page">
      <h1>Chronologie</h1>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {events.map((e, i) => (
          <li key={i} style={{ borderLeft: `3px solid ${e.side === 'IJN' ? '#d23b3b' : e.side === 'USN' ? '#1f6fce' : 'var(--bord)'}`, padding: '4px 8px', marginBottom: 4 }}>
            <span style={{ color: 'var(--accent)', fontFamily: 'monospace' }}>{fmtJour(e.t)}</span>
            {e.u ? ` ±${e.u}'` : ''} — {e.s}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

- [ ] **Step 5: Lancer le test (succès attendu)**

Run : `cd web && npm test`
Expected: tous les tests passent (`fmtJour` + `useReplayData`).

- [ ] **Step 6: Vérifier visuellement**

Lancer `npm run dev`, ouvrir `/chronologie` : la liste des événements s'affiche, triée, avec dates et bordures colorées par camp.

- [ ] **Step 7: Commit**

```bash
git add web/src/data/useChronologie.ts web/src/routes/Chronologie.tsx web/src/routes/Chronologie.test.tsx
git commit -m "feat: chronologie timeline page"
```

---

## Task 8: Moteur de dessin du replay (render.ts)

Port **iso-fonctionnel** du JS canvas de `generer_carte.py:248-501`. La logique de dessin est déplacée dans `render.ts` ; les lectures de contrôles (`document.getElementById('cbHalo').checked`, `theme`, `T`, `scale`, `panX/panY`, `selWp`) deviennent des champs d'un objet `RenderState` passé en argument.

**Files:**
- Create: `web/src/components/ReplayMap/types.ts`
- Create: `web/src/components/ReplayMap/render.ts`

- [ ] **Step 1: Définir RenderState**

`web/src/components/ReplayMap/types.ts` :
```ts
import type { ReplayData } from '../../types/replay';

export interface RenderState {
  T: number;           // instant courant (minutes depuis epoch)
  scale: number;       // zoom
  panX: number; panY: number;
  theme: 'light' | 'dark';
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  selWp: { pt: any; trk: any[]; idx: number } | null;
}

export interface Clickable { x: number; y: number; ent: string; pt: any; trk: any[]; idx: number; }

export type DrawResult = { clickables: Clickable[] };
export type DrawFn = (ctx: CanvasRenderingContext2D, cv: HTMLCanvasElement, data: ReplayData, st: RenderState) => DrawResult;
```

- [ ] **Step 2: Porter le moteur de dessin**

`web/src/components/ReplayMap/render.ts` — porter **à l'identique** depuis `generer_carte.py` :
- constantes `LAT0, LON0, RAD`, `THEMES` (lignes 249, 255-259)
- helpers `unwrap, pxnm, proj, fmt, cardinal, routeTo, distNm, interp` (lignes 262-301) — **convertir `cv.width/cv.height` en paramètres**, sinon code identique
- `posOf, isSunk` (lignes 303-308)
- la fonction `draw()` (lignes 311-501) devient `export const draw: DrawFn`, avec ces substitutions mécaniques :
  - `T` → `st.T` ; `scale` → `st.scale` ; `panX/panY` → `st.panX/st.panY` ; `theme` → `st.theme` ; `selWp` → `st.selWp`
  - `document.getElementById('cbHalo').checked` → `st.showHalo` ; `cbTrail` → `st.showTrail` ; `cbRaid` → `st.showRaid` ; `cbPercu` → `st.showPercu`
  - `clickables=[]` local → accumulé puis retourné dans `{ clickables }`
  - retirer les deux dernières lignes de `draw` qui touchent le DOM (`clock.textContent`, `slider.value`, lignes 499-500) — gérées par React (Task 9)
- exporter aussi `proj`, `interp`, `routeTo`, `distNm`, `cardinal` (utilisés par le panneau waypoint dans Task 9)

Exemple de signature de tête de fichier :
```ts
import type { ReplayData, Entity, TrackPoint } from '../../types/replay';
import type { RenderState, Clickable, DrawResult } from './types';

export const LAT0 = 28.21, LON0 = -177.37, RAD = Math.PI / 180;
const THEMES = { /* …copie identique de generer_carte.py:255-259… */ } as const;

export function unwrap(lon: number) { return lon > 0 ? lon - 360 : lon; }
export function proj(lat: number, lon: number, cv: HTMLCanvasElement, st: RenderState): [number, number] {
  const x = (unwrap(lon) - LON0) * 60 * Math.cos(LAT0 * RAD), y = (lat - LAT0) * 60;
  const pxnm = Math.min(cv.width, cv.height) / 900;
  return [cv.width / 2 + (x + st.panX) * st.scale * pxnm, cv.height / 2 - (y + st.panY) * st.scale * pxnm];
}
// …interp, routeTo, distNm, cardinal, posOf, isSunk, puis draw() porté…
export const draw: import('./types').DrawFn = (ctx, cv, data, st) => {
  const clickables: Clickable[] = [];
  // …corps de generer_carte.py:313-498 avec les substitutions ci-dessus…
  return { clickables };
};
```

- [ ] **Step 3: Vérifier la compilation TypeScript**

Run : `cd web && npx tsc --noEmit`
Expected: aucune erreur de type (corriger les `any` résiduels du port si `tsc` se plaint ; le port peut garder `pt: any` via `TrackPoint`).

- [ ] **Step 4: Commit**

```bash
git add web/src/components/ReplayMap/types.ts web/src/components/ReplayMap/render.ts
git commit -m "feat: port replay canvas draw engine to render.ts"
```

---

## Task 9: Composant ReplayMap (canvas + boucle + interactions)

Port de la machinerie d'animation et d'interaction de `generer_carte.py:533-607` : boucle `tick`/`requestAnimationFrame`, `wheel` (zoom), drag (pan), clic waypoint (panneau `wpinfo`).

**Files:**
- Create: `web/src/components/ReplayMap/ReplayMap.tsx`

- [ ] **Step 1: Écrire le composant**

`web/src/components/ReplayMap/ReplayMap.tsx` — `RenderState` mutable dans un `useRef`, boucle RAF dans un `useEffect` à dépendances vides (les contrôles écrivent dans le ref via `controlsRef`). Le composant reçoit `data` et un `controls` (état des cases/zoom/lecture) en props depuis Task 10.

```tsx
import { useEffect, useRef } from 'react';
import type { ReplayData } from '../../types/replay';
import type { RenderState, Clickable } from './types';
import { draw } from './render';

export interface ReplayControls {
  playing: boolean; speedExp: number; scale: number;
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  theme: 'light' | 'dark';
}

export default function ReplayMap({ data, controls, onClock, onScaleChange }: {
  data: ReplayData; controls: ReplayControls;
  onClock: (t: number) => void; onScaleChange: (s: number) => void;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const stRef = useRef<RenderState>({
    T: data.tmin, scale: controls.scale, panX: 0, panY: -120, theme: controls.theme,
    showHalo: true, showTrail: true, showRaid: true, showPercu: false, selWp: null,
  });
  const ctrlRef = useRef(controls);
  ctrlRef.current = controls;
  const clickRef = useRef<Clickable[]>([]);

  // Boucle d'animation — un seul effet, jamais recréé (cf. generer_carte.py:539-547)
  useEffect(() => {
    const cv = canvasRef.current!, ctx = cv.getContext('2d')!;
    let raf = 0, last = performance.now();
    const tick = () => {
      const now = performance.now(), dt = (now - last) / 1000; last = now;
      const st = stRef.current, c = ctrlRef.current;
      st.scale = c.scale; st.theme = c.theme;
      st.showHalo = c.showHalo; st.showTrail = c.showTrail; st.showRaid = c.showRaid; st.showPercu = c.showPercu;
      if (c.playing) st.T = Math.min(data.tmax, st.T + Math.pow(10, c.speedExp) * dt / 60);
      cv.width = cv.parentElement!.clientWidth; cv.height = cv.parentElement!.clientHeight;
      clickRef.current = draw(ctx, cv, data, st).clickables;
      onClock(st.T);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [data, onClock]);

  // Zoom molette (cf. generer_carte.py:569-570)
  useEffect(() => {
    const cv = canvasRef.current!;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const s = Math.max(0.4, Math.min(10, stRef.current.scale * (e.deltaY < 0 ? 1.1 : 0.9)));
      stRef.current.scale = s; onScaleChange(s);
    };
    cv.addEventListener('wheel', onWheel, { passive: false });
    return () => cv.removeEventListener('wheel', onWheel);
  }, [onScaleChange]);

  // Pan par drag (cf. generer_carte.py:571-606) — pression souris sur le canvas
  useEffect(() => {
    const cv = canvasRef.current!;
    let drag: [number, number] | null = null, dist = 0;
    const down = (e: MouseEvent) => { drag = [e.clientX, e.clientY]; dist = 0; };
    const move = (e: MouseEvent) => {
      if (!drag) return;
      dist += Math.abs(e.clientX - drag[0]) + Math.abs(e.clientY - drag[1]);
      const st = stRef.current, pxnm = Math.min(cv.width, cv.height) / 900;
      st.panX += (e.clientX - drag[0]) / (st.scale * pxnm);
      st.panY -= (e.clientY - drag[1]) / (st.scale * pxnm);
      drag = [e.clientX, e.clientY];
    };
    const up = (e: MouseEvent) => {
      if (drag && dist < 5) {
        const r = cv.getBoundingClientRect(), mx = e.clientX - r.left, my = e.clientY - r.top;
        let best: Clickable | null = null, bd = 14;
        clickRef.current.forEach((c) => { const d = Math.hypot(c.x - mx, c.y - my); if (d < bd) { bd = d; best = c; } });
        stRef.current.selWp = best ? { pt: best.pt, trk: best.trk, idx: best.idx } : null;
      }
      drag = null;
    };
    cv.addEventListener('mousedown', down); window.addEventListener('mousemove', move); window.addEventListener('mouseup', up);
    return () => { cv.removeEventListener('mousedown', down); window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
  }, []);

  return <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} />;
}
```
Note : la jauge temporelle (slider) pilote `stRef.current.T` directement ; ce câblage est ajouté en Task 10 via une prop `seekRef`. Le panneau waypoint texte (`wpinfo`, generer_carte.py:582-604) est volontairement reporté — non bloquant pour l'équivalence visuelle de la carte ; à ajouter en amélioration ultérieure.

- [ ] **Step 2: Vérifier la compilation**

Run : `cd web && npx tsc --noEmit`
Expected: aucune erreur.

- [ ] **Step 3: Commit**

```bash
git add web/src/components/ReplayMap/ReplayMap.tsx
git commit -m "feat: ReplayMap canvas component with animation, zoom, pan"
```

---

## Task 10: Contrôles + intégration dans la page Carte

Port de la barre de contrôles `generer_carte.py:207-225` (lecture, vitesse, slider temps, zoom, cases à cocher) en state React, branchés sur `ReplayMap`.

**Files:**
- Create: `web/src/components/ReplayMap/Controls.tsx`
- Modify: `web/src/routes/Carte.tsx`

- [ ] **Step 1: Composant Controls**

`web/src/components/ReplayMap/Controls.tsx` :
```tsx
import type { ReplayControls } from './ReplayMap';

export default function Controls({ c, set, clock, onSeek, tmin, tmax, T }: {
  c: ReplayControls; set: (p: Partial<ReplayControls>) => void;
  clock: string; onSeek: (t: number) => void; tmin: number; tmax: number; T: number;
}) {
  const speed = Math.pow(10, c.speedExp);
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', padding: '8px 14px', background: 'var(--panel)', borderBottom: '1px solid var(--bord)' }}>
      <button onClick={() => set({ playing: !c.playing })}>{c.playing ? '⏸ Pause' : '▶ Lecture'}</button>
      <span style={{ color: 'var(--accent)', fontFamily: 'monospace', minWidth: 230 }}>{clock}</span>
      <span style={{ fontSize: 11 }}>vitesse</span>
      <input type="range" min={1} max={3.56} step={0.01} value={c.speedExp} onChange={(e) => set({ speedExp: +e.target.value })} />
      <span style={{ fontFamily: 'monospace', minWidth: 50 }}>×{speed < 100 ? speed.toFixed(0) : Math.round(speed / 10) * 10}</span>
      <input style={{ flex: 1, minWidth: 160 }} type="range" min={tmin} max={tmax} step={1} value={Math.round(T)} onChange={(e) => onSeek(+e.target.value)} />
      <span style={{ fontSize: 11 }}>zoom</span>
      <input type="range" min={0.4} max={10} step={0.1} value={c.scale} onChange={(e) => set({ scale: +e.target.value })} />
      <label><input type="checkbox" checked={c.showHalo} onChange={(e) => set({ showHalo: e.target.checked })} /> halos</label>
      <label><input type="checkbox" checked={c.showTrail} onChange={(e) => set({ showTrail: e.target.checked })} /> traînées</label>
      <label><input type="checkbox" checked={c.showRaid} onChange={(e) => set({ showRaid: e.target.checked })} /> raids</label>
      <label><input type="checkbox" checked={c.showPercu} onChange={(e) => set({ showPercu: e.target.checked })} /> monde perçu</label>
    </div>
  );
}
```

- [ ] **Step 2: Ajouter le seek au ReplayMap**

Dans `web/src/components/ReplayMap/ReplayMap.tsx`, ajouter une prop `seekRef?: React.MutableRefObject<((t: number) => void) | null>` et, dans la boucle d'effet principal, exposer la fonction de seek :
```tsx
// après la création de stRef, dans le composant :
if (seekRef) seekRef.current = (t: number) => { stRef.current.T = t; };
```
(déclarer `seekRef` dans les props du composant ; l'appeler depuis la page Carte via `onSeek`.)

- [ ] **Step 3: Page Carte**

`web/src/routes/Carte.tsx` :
```tsx
import { useRef, useState } from 'react';
import { useReplayData } from '../data/useReplayData';
import { useTheme } from '../theme/ThemeContext';
import ReplayMap, { type ReplayControls } from '../components/ReplayMap/ReplayMap';
import Controls from '../components/ReplayMap/Controls';

function fmt(t: number) {
  t = Math.floor(t);
  const d = 3 + Math.floor(t / 1440), mins = ((t % 1440) + 1440) % 1440;
  const h = Math.floor(mins / 60), m = mins % 60, p = (n: number) => String(n).padStart(2, '0');
  return `${d} juin 1942 — ${p(h)}:${p(m)} (GMT−12)`;
}

export default function Carte() {
  const { data, error } = useReplayData();
  const { theme } = useTheme();
  const [c, setC] = useState<ReplayControls>({ playing: false, speedExp: 2.778, scale: 1, showHalo: true, showTrail: true, showRaid: true, showPercu: false, theme });
  const [T, setT] = useState(0);
  const seekRef = useRef<((t: number) => void) | null>(null);
  const set = (p: Partial<ReplayControls>) => setC((s) => ({ ...s, ...p }));

  if (error) return <div className="page">Erreur de chargement : {error}</div>;
  if (!data) return <div className="page">Chargement…</div>;

  const controls = { ...c, theme };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 46px)' }}>
      <Controls c={controls} set={set} clock={fmt(T)} T={T || data.tmin} tmin={data.tmin} tmax={data.tmax}
        onSeek={(t) => { seekRef.current?.(t); setT(t); }} />
      <div style={{ flex: 1, position: 'relative' }}>
        <ReplayMap data={data} controls={controls} seekRef={seekRef} onClock={setT} onScaleChange={(s) => set({ scale: s })} />
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Compilation**

Run : `cd web && npx tsc --noEmit && npm run build`
Expected: build réussi (`dist/` généré, aucune erreur TS).

- [ ] **Step 5: Validation visuelle d'équivalence**

Lancer `npm run dev`, ouvrir `/carte`. Comparer côte à côte avec l'ancien `carte_midway.html` (ouvrir le fichier directement) :
- la carte s'affiche avec Midway, anneaux, grille
- Lecture anime les pistes ; le slider temps déplace l'instant
- zoom (molette + slider) et pan (drag) fonctionnent
- halos / traînées / raids / monde perçu réagissent aux cases
- bascule de thème répercutée sur la carte

Noter tout écart visuel ; corriger dans `render.ts` (le port doit rester fidèle aux lignes sources citées).

- [ ] **Step 6: Commit**

```bash
git add web/src && git commit -m "feat: replay controls and Carte page integration"
```

---

## Task 11: Pipeline complet et page d'accueil

**Files:**
- Modify: `tout_regenerer.sh`, `web/src/routes/Home.tsx`

- [ ] **Step 1: Étoffer la page d'accueil**

`web/src/routes/Home.tsx` :
```tsx
import { Link } from 'react-router-dom';

export default function Home() {
  return (
    <div className="page">
      <h1>Bataille de Midway — 3 au 7 juin 1942</h1>
      <p>Reconstitution chronologique et cartographique de la bataille à partir d'une base
        de données de sources, positions inférées et processus modélisés.</p>
      <ul>
        <li><Link to="/carte">Carte / Replay animé</Link> — rejouer la bataille dans le temps</li>
        <li><Link to="/chronologie">Chronologie</Link> — la liste des événements</li>
        <li><Link to="/methodologie">Méthodologie</Link> — comment le modèle est construit</li>
      </ul>
    </div>
  );
}
```

- [ ] **Step 2: Ajouter le build React au pipeline**

Dans `tout_regenerer.sh`, après la ligne `[6/6] JSON exportés vers web/`, ajouter :
```bash
( cd web && npm run build ) && echo "[7/7] site React buildé (web/dist)"
```

- [ ] **Step 3: Vérifier le pipeline de bout en bout**

Run : `./tout_regenerer.sh`
Expected: enchaînement complet sans erreur jusqu'à `[7/7] site React buildé (web/dist)`. Le dossier `web/dist/` contient `index.html` et les assets, et `web/dist/data/` les JSON.

- [ ] **Step 4: Lancer la suite de tests**

Run : `python3 data/test_export_data.py && ( cd web && npm test )`
Expected: `OK` côté Python ; tous les tests Vitest passent.

- [ ] **Step 5: Commit**

```bash
git add tout_regenerer.sh web/src/routes/Home.tsx
git commit -m "feat: home page and full React build in pipeline"
```

---

## Notes de fin

- `generer_carte.py` / `carte_midway.html` restent en place comme référence ; leur retrait fera l'objet d'une décision séparée une fois l'équivalence du replay confirmée.
- `web/dist/` est un artefact de build : ajouter `web/dist/` et `web/node_modules/` à `.gitignore` (le faire au Step 1 de Task 1 si souhaité, ou en fin de migration).
- Panneau waypoint texte (`wpinfo`) et étiquette de vitesse fine sont des améliorations post-V1 explicitement hors périmètre iso-fonctionnel minimal.

# Spec — Midway React Multi-Page Site

**Date:** 2026-06-13
**Status:** Validated (design)

## Objective

Transform the Midway project — currently a pipeline that generates self-contained HTML pages —
into a proper React multi-page website with a navigation menu.
Data must be **read from JSON files exported from the database** rather than
hard-coded into the HTML, so that new pages and content can be added
without rebuilding everything from scratch.

## Principles

- **Unchanged source of truth:** the ~25 `.sql` files and `midway.sqlite`
  remain the source of truth. No data is entered on the front end.
- **Data / presentation decoupling:** the database is compiled into granular JSON;
  React only knows about those JSON files. No more inline data in HTML.
- **Iso-functional replay port:** the existing canvas engine is ported
  identically (same rendering, same controls) before any improvements are made.
- **YAGNI:** no API, no online editing, no UI redesign, no heavy mobile
  responsive design for this V1.

## Decisions

| Topic | Decision |
|---|---|
| Data access | Static JSON export (no API, no sql.js) |
| V1 pages | Home, Map/Replay, Methodology, Timeline |
| Language | TypeScript (to type the JSON ↔ canvas contract) |
| Canvas port | Iso-functional first |
| Build tool | Vite |
| Routing | React Router |
| Styles | CSS + custom variables (reuses existing light/dark theme) |
| State | React state + context for theme (no library) |

## Overall Architecture

Two separate worlds, connected by a JSON contract:

```
data/   (existing, nearly unchanged)          web/   (new, React/TS app)
 ├─ *.sql ─→ midway.sqlite                    ├─ public/data/*.json  ← export target
 ├─ Python scripts (inference, simulation…)   └─ src/
 └─ export_data.py  ───────[JSON]───────────────→  routes, components, types
```

`export_data.py` (derived from `generer_carte.py`) compiles the database into JSON.
React loads the JSON via `fetch`. The source of truth remains the SQL.

## Export Layer (Python)

New script `data/export_data.py`, reusing the SQL queries from
`generer_carte.py:21-174`, but writing files instead of injecting HTML.

| Exported file | Contents | Source |
|---|---|---|
| `web/public/data/replay.json` | entities, wrecks, fires, combats, spots, raids, events, contacts, tmin, tmax, build | existing queries from `generer_carte.py` |
| `web/public/data/chronologie.json` | enriched events for the timeline page | `events` table |
| `web/public/data/meta.json` | shared version stamp (db_hash, generation date) | `generer_carte.py:160-169` |

The HTML + JS template in `generer_carte.py` (lines 177-608) leaves Python
and becomes React. The `db_hash` stamp is preserved in `meta.json` to
maintain database ↔ site traceability.

`generer_carte.py` can be kept as-is during the migration (to produce the
reference HTML), then removed once equivalence is validated.

## React Application Structure

```
web/src/
 ├─ main.tsx, App.tsx          # router + layout (menu)
 ├─ layout/  Nav, ThemeToggle  # menu + light/dark toggle (context)
 ├─ routes/
 │   ├─ Home.tsx               # home page (new)
 │   ├─ Carte.tsx              # hosts <ReplayMap>
 │   ├─ Methodologie.tsx       # prose converted from methodologie_midway.html
 │   └─ Chronologie.tsx        # timeline from chronologie.json
 ├─ components/ReplayMap/
 │   ├─ ReplayMap.tsx          # canvas (useRef) + tick/draw loop
 │   ├─ Controls.tsx           # play, speed, zoom, checkboxes → React state
 │   └─ render.ts              # drawing logic ported identically
 ├─ types/replay.ts            # TypeScript contract (entities, raids, events…)
 └─ data/useReplayData.ts      # fetch + parse JSON
```

## ReplayMap Component (iso-functional port)

- The `<canvas>` is referenced via `useRef`.
- The `requestAnimationFrame` loop (`tick`/`draw`) lives in **a single `useEffect`**
  with empty dependencies, to avoid conflicts with the React render cycle.
- Controls, previously read via `getElementById('cbHalo')` etc., become
  **React state** passed to the drawing engine.
- `render.ts` preserves identically the geographic projection, `interp`, uncertainty
  halos, countable raids, and the event thread. Visual behavior must be
  equivalent to the old `carte_midway.html`.

### Data Contract (types/replay.ts)

The `replay.json` exposes condensed keys (`t`, `crs`, `n0`, `lost`, `par`,
`err`, `m`…). These shapes must be explicitly typed in TypeScript to
detect any breaking change between the Python exporter and the canvas engine at build time.
The contract is derived from the structure produced by `generer_carte.py:170-174`.

## Navigation & Pages

React Router with four routes:

- `/` — Home (project overview, battle context, links)
- `/carte` — Animated replay (`<ReplayMap>`)
- `/methodologie` — prose converted from `methodologie_midway.html` (sections 1-12)
- `/chronologie` — navigable event timeline

Shared menu in the layout. The current light/dark theme becomes a global
React context (toggle available on all pages).

## Pipeline & Deployment

`tout_regenerer.sh` is updated: the "map" step (`generer_carte.py`) is
replaced/supplemented by `export_data.py` (generates JSON into
`web/public/data/`), then `npm run build` (inside `web/`) produces the static site.

Throughout the migration, the old `carte_midway.html` remains the functional
reference until the React replay equivalence is validated.

Deployment: static site (JSON files are served as assets like everything else).

## Out of Scope (YAGNI)

- No backend API or server-side database.
- No editing / writing data from the site.
- No `sql.js` / SQLite WASM in the browser.
- No redesign of the replay UI (iso-functional first).
- No heavy mobile responsive design for V1.

## Success Criteria

1. The React site starts (`npm run dev`) and builds (`npm run build`) as a static site.
2. All four pages are navigable via a shared menu.
3. The Map page reproduces the behavior of the current `carte_midway.html`
   (equivalent rendering and controls).
4. No data is inline in the HTML: everything comes from the exported JSON files.
5. `export_data.py` regenerates the JSON from the database; the `db_hash` stamp is
   present in `meta.json`.
6. `tout_regenerer.sh` chains database rebuild → JSON export → React build.

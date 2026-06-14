# Midway 1942 — a sourced, replayable reconstruction

A chronological, spatial and **physical** reconstruction of the Battle of Midway
(3–7 June 1942), built from a database in which **every datum is a sourced,
graded claim**. The project doesn't *narrate* the battle: it **models** it in a
verifiable way, then replays it through a constraint model (flight decks, arming
crews, operation durations) to separate what was *possible* from what is mere
narrative.

Three building blocks:

1. **A database** (`midway.sqlite`) built from versioned SQL files — the single
   source of truth.
2. **Python tools** for inference, simulation and auditing.
3. **A web app** (React/TypeScript) that reads data exported from the database:
   animated map/replay, timeline, methodology. The interface is bilingual
   (English/French, switchable).

---

## Quick start

Prerequisites: **Python 3** and **Node.js** (for the website).

```bash
# 1. Regenerate the whole chain (database → inference → replay → audit → map → export → site)
./tout_regenerer.sh

# 2. Run the website in development
cd web
npm install      # first time only
npm run dev      # opens http://localhost:5173/
```

The legacy single-file "map" is still available: open `carte_midway.html`
directly in a browser (no dependencies).

---

## The data model

Everything rests on **sourcing**. The schema (`schema_midway.sql`, 26 tables +
3 views) requires every value to be a `claim` attached to a graded `source`
(A/B/C/D). Several claims may target the same field; only one is accepted
(`is_accepted=1`), with an arbitration note if they conflict.

Main building blocks of the model:

| Domain | Key tables |
|---|---|
| Sourcing | `sources`, `claims` |
| Order of battle | `formations`, `ships`, `squadrons`, `persons`, `aircraft_types`, `ordnance_types` |
| Physical constraints | `carrier_constraints`, `process_templates`, `process_steps`, `constraint_params` |
| Chronology & space | `events`, `event_participants`, `positions`, `missions`, `mission_legs`, `mission_squadrons` |
| Intelligence & decisions | `contact_reports`, `messages`, `decisions`, `knowledge_states` |
| States | `damage_states`, `squadron_status`, `weather_obs` |

**Conventions** (fixed in the schema):
- **Time**: Midway local time (**GMT−12**), ISO 8601
  `YYYY-MM-DDTHH:MM:SS-12:00`. Each source's original time (often Tokyo, GMT+9)
  is preserved in `claims.original_value`.
- **Space**: WGS84 latitude/longitude in decimal degrees.
- **Air granularity**: the squadron.

The full methodology (principles, verification protocol, conceptual model,
phasing) is documented in **`methodologie_midway.html`** (French) and
**`methodologie_midway.en.html`** (English), 12 sections each.

---

## The regeneration pipeline

`tout_regenerer.sh` rebuilds everything in order and stops at the first problem
(`set -e`):

1. **Rebuild the database** from the ~25 `.sql` files (`schema_midway.sql`,
   `seed_exemples.sql`, then `phase2`…`phase13`).
2. **Infer positions** (`inferer_positions.py`).
3. **F1 replay** (`simulateur_f1.py`).
4. **Consistency audit** (`audit_coherence.py`).
5. **Text-vs-reality check** (`verif_textes.py`).
6. **Legacy map** (`generer_carte.py` → `carte_midway.html`).
7. **JSON export** (`data/export_data.py` → `web/public/data/`).
8. **React site build** (`web/dist/`).

The database, the map and the exported JSON are versioned (regenerable
artifacts); the `db_hash` stamp ties every output to the fingerprint of the
final database.

---

## The Python tools

| Script | Role |
|---|---|
| `inferer_positions.py` | Confronts each track with the physical constraints and logs everything to `position_inferences`; only adjusts an `estimated`, better-sourced waypoint. |
| `simulateur_f1.py` | **F1 engine** — replays the *historical* operations through the physical model; each operation gets a verdict `coherent` / `tension` / `incoherent`. Produces `rapport_f1.md`. |
| `simulateur_f2.py` | **F2 engine** (skeleton) — discrete-event simulation driven by *decisions* rather than by the chronology. |
| `audit_coherence.py` | Consistency test bench for the database (`FAIL`/`WARN`/`INFO` findings + score). |
| `verif_textes.py` | Hunts mismatches between numeric values in the texts and the geometry/structured data (the script flags, the human decides). |
| `diag_cinematique.py` | Read-only diagnostic of the kinematic consistency of events. |
| `generer_carte.py` | Generates the single-file map/replay `carte_midway.html` from the database. |
| `generer_phase8_recherches.py` | Generates the SQL for the 4 June aerial search routes. |
| `data/export_data.py` | Exports the database to JSON for the React site (`replay.json`, `chronologie.json`, `meta.json`, `methodologie.{fr,en}.html`). |

`rapport_f1.md` (generated) illustrates the approach: for each operation, the
gap between history and the model is measured and interpreted (e.g. the effect
of interruptions under attack on the Japanese carriers' rearming).

---

## The web app (`web/`)

A React + TypeScript application (Vite, React Router) that reads the exported
JSON — no data is hard-coded into the HTML. The UI is bilingual
(English by default, French toggle).

| Page | Contents |
|---|---|
| Home | Overview and links. |
| Map | Animated canvas replay: tracks, uncertainty halos, countable raids, combats, sightings. Collapsible legend and an optional event feed (click = jump to that moment). |
| Chronology | List of events (timeline). |
| Methodology | The modeling methodology. |

Useful commands (from `web/`): `npm run dev` (development),
`npm run build` (static build into `web/dist/`), `npm test` (Vitest),
`npm run lint`.

> The design (spec) and implementation plan for the migration to this site are
> kept in `docs/superpowers/`.

---

## Status

- **F1 (validated replay)**: working — historical operations are confronted with
  the physical model.
- **F2 (decision-driven simulation)**: skeleton, in progress.
- **F3 (counterfactuals)**: leads identified in `rapport_f1.md` (e.g. the
  unescorted strike Yamaguchi proposed at 08:30).

---

## License

No license is defined yet. Without an explicit license, the code remains "all
rights reserved" by default — add a `LICENSE` file (MIT, CC-BY for the
historical data, etc.) if you want to allow reuse.

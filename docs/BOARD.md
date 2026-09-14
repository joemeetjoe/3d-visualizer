# Board

Edit the **Status** column as you go: `todo` → `doing` → `done` (or `cut`, `stretch`). Put your name in Owner. Integration lead (Track C) reviews at each checkpoint. Issue details: `docs/issues/<id>-*.md`.

## Owners

| Track | Owner | Backup |
|---|---|---|
| A Viewer | | |
| B Capture | | |
| C API / Dashboard / Integration / Presentation | | |
| D Pipeline | | |

## Checkpoints

| ID | When | What | Status |
|---|---|---|---|
| X1 | H2 | Contract freeze | todo |
| X2 | H8 | First end-to-end with mock worker | todo |
| X3 | H16 | Real end-to-end + feature freeze | todo |
| X4 | H20 | Dress rehearsal ×2 | todo |

## Track A — Viewer

| ID | Title | Target | Blocked by | Status |
|---|---|---|---|---|
| A1a | Viewer canvas: sample model, orbit/pan/zoom, fit, reset | H2 | C0a | todo |
| A1b | Scene dressing: void, grid, lights, vignette, toolbar shell | H4 | A1a | todo |
| A1c | Loading / progress / error / still-processing states | H5 | A1a | todo |
| A2a | Raycast pin placement | H6 | A1b | todo |
| A2b | Pin popover: note, severity, colors, tooltip | H8 | A2a | todo |
| A2c | Sidebar: list, jump-to, edit, delete | H9 | A2b | todo |
| A3a | Load + auto-save, Saved/Saving indicator | H11 | A2c, C5, C2b | todo |
| A3b | Export JSON | H12 | A3a | todo |
| A4a | Glow halos, spring pop, reduced motion | H14 | A2b | todo |
| A4b | Touch check + keyboard shortcuts | H15 | A2c | todo |
| A5a | STRETCH Paint region brush | H19 | A3a | stretch |
| A5b | STRETCH Region list + persist | H20 | A5a | stretch |

## Track B — Capture

| ID | Title | Target | Blocked by | Status |
|---|---|---|---|---|
| B1a | Capture route, token resolve, start screen | H2 | C0a (C2a) | todo |
| B1b | Camera hook: getUserMedia, fallback, resolution log | H4 | B1a, tunnel | todo |
| B1c | Capture frame → JPEG → upload → thumbnail | H6 | B1b (C3a) | todo |
| B2a | Walk-around auto-capture | H8 | B1c | todo |
| B2b | Wake lock, feedback, queue hardening | H10 | B2a | todo |
| B3a | Guided 8-anchor step cards | H10 | B1c | todo |
| B3b | 3-shot burst, silhouette, close-ups | H12 | B3a | todo |
| B4a | Quality gates: blur / brightness / resolution | H12 | B2a | todo |
| B4b | Upload progress, retry, completion | H14 | B4a, C3b | todo |
| B5a | Real-device matrix over tunnel | H15 | B4b, C7a | todo |
| B5b | Capture UX polish | H18 | B5a | todo |

## Track C — API / Dashboard / Integration / Presentation

| ID | Title | Target | Blocked by | Status |
|---|---|---|---|---|
| C0a | Monorepo skeleton + shared types | H1 | — | todo |
| C0b | Postgres compose + Drizzle schema + seed | H2 | C0a | todo |
| C0c | Hono skeleton | H2 | C0a | todo |
| C1a | Claims endpoints | H3 | C0b, C0c | todo |
| C1b | Create Claim form | H4 | C1a | todo |
| C1c | Claim Created + QR | H4 | C1b | todo |
| C1d | Dashboard table | H5 | C1a | todo |
| C2a | Status state machine + PATCH + by-token | H5 | C1a | todo |
| C2b | Claim detail header + viewer slot | H9 | C2a | todo |
| C3a | Upload targets + photo receiver | H6 | C2a | todo |
| C3b | Upload complete → processing | H7 | C3a | todo |
| C4a | Mock worker | H7 | C0c | todo |
| C4b | Dispatcher + poller + model-url | H8 | C3b, C4a | todo |
| C4c | Static serving (range, types) | H9 | C0c | todo |
| C5 | Annotations GET/PUT | H10 | C2a | todo |
| C6a | Filter, pulse, empty state | H13 | C1d | todo |
| C6b | Live polling | H13 | C1d, C2b | todo |
| C7a | Tunnel + allowedHosts + env | H4 quick / H12 | C0a | todo |
| C7b | Demo runbook + reset | H18 | C4b, D5a | todo |
| C8a | Slide deck v1 | H14 | X2 | todo |
| C8b | Demo script + rehearsal | H20 | C7b, C8a, X3 | todo |

## Track D — Pipeline

| ID | Title | Target | Blocked by | Status |
|---|---|---|---|---|
| D1a | GPU box online | H1 | — | todo |
| D1b | Meshroom spike | H3 | D1a | todo |
| D1c | COLMAP+OpenMVS spike → engine decision | H4 | D1b | todo |
| D2a | Shoot the car (daylight) | H3–5 | — | todo |
| D2b | Curate + resize dataset | H5 | D2a | todo |
| D3a | run_pipeline.sh | H6 | D1c | todo |
| D3b | export_glb.sh | H7 | D3a | todo |
| D3c | Normalize orientation / scale | H10 | D3b | todo |
| D4a | Worker POST /jobs | H11 | D3a | todo |
| D4b | Worker status / model / keepalive | H12 | D4a, C4b | todo |
| D5a | Pre-bake demo model + fallback | H12 / H22 | D2b, D3c | todo |
| D5b | Tune < 10 min + timing table | H15 | D5a | todo |
| D6 | STRETCH masking / 2nd dataset | H19+ | D5b | stretch |

## Backlog

| ID | Title |
|---|---|
| P0 | Post-jam backlog (production path) |

## X2 findings
- (fill during X2)

## X3 freeze list
- (fill during X3)

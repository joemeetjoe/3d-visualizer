# 24-hour plan

Four tracks in parallel, four cross-team checkpoints, two sleep windows. Hours are relative to jam start (H0). Issue IDs refer to `docs/issues/`.

## Tracks

| Track | Focus | Person | Owns at the end |
|---|---|---|---|
| **A** | 3D viewer + annotations | | The core adjuster experience in the demo |
| **B** | Customer capture flow | | The phone half of the live demo |
| **C** | API, dashboard, create claim, integration, tunnel, **presentation** | | Everything gluing A/B/D together; the slides; the demo runbook |
| **D** | Photogrammetry pipeline, GPU worker, pre-baked model | | The real 3D model and the live job on stage |

## Timeline

| Hour | All | A Viewer | B Capture | C API/Dash/Integration | D Pipeline |
|---|---|---|---|---|---|
| **H0–1** | Kickoff (15 min): read DECISIONS + CONTRACTS together; assign tracks; confirm daylight plan for the car | Setup; A1a with the ToyCar sample glb | Setup; B1a route + token | **C0a** monorepo skeleton + shared-types (everyone pulls at H1) | **D1a** rent GPU box, SSH, `nvidia-smi`, Docker |
| **H1–2** | | A1a/A1b | B1b camera hook | C0b Postgres + Drizzle; C0c Hono skeleton | D1b Meshroom spike starts |
| **H2** | **X1 Contract freeze** (15 min): any last changes to CONTRACTS.md; after this, changes go through C | | | | |
| **H2–4** | | A1c loading states; A2a raycast pins | B1c capture + upload (mock API until C3a) | C1a claims endpoints; C1b/C1c create claim + QR | D1c COLMAP+OpenMVS spike; **engine decision by H4** |
| **H3–5** | **D2a shoot the car** — D + one helper (B, to test the capture app on it) — *must be daylight* | | | | |
| **H4–8** | | A2b popover; A2c sidebar | B2a walk-around mode; B2b wake lock/queue | C1d dashboard; C2a state machine + by-token; C3a/C3b uploads | D2b curate dataset; D3a run_pipeline; D3b export_glb |
| **H8** | **X2 First end-to-end with mock worker** (30 min): create → QR → phone capture → upload-complete → processing → mock ready → viewer → pin → saved | | | C4a mock worker + C4b dispatcher must be done | |
| **H8–12** | | A3a persistence + auto-save; A3b export | B3a/B3b guided mode; B4a quality gates | C2b detail header; C4c static serving; C5 annotations | D3c normalize; D4a/D4b worker service; **D5a pre-bake v1** |
| **H10–13** | **Sleep window 1: A and D** (3h) — B and C keep integrating | | | | |
| **H12–16** | | A4a glow/pop; A4b touch/keys | B4b upload progress + completion; B5a real-device pass | C6a/C6b dashboard polish; C7a tunnel + env; **C8a slides v1** | D5b tuning + timing table; worker hardened |
| **H13–16** | **Sleep window 2: B and C** (3h) — A and D keep going; C hands integration to A during this window | | | | |
| **H16** | **X3 Real end-to-end + feature freeze** (30 min): same flow as X2 but the GPU worker produces the model. Anything not merged by H17 is cut. | | | | |
| **H16–20** | Bug bash, polish, A5 paint region only if pins are flawless | A5a/A5b (stretch) or polish | B5b polish | C7b runbook + reset script; C8b demo script | D6 stretch or support C |
| **H20** | **X4 Dress rehearsal ×2** (60 min): full 10-minute run, with every fallback exercised once on purpose | | | | |
| **H21–23** | Fix only what broke in rehearsal. Freeze at H23. Charge phones. Pre-bake final model committed. | | | | |
| **H23–24** | Final rehearsal, set up the stage laptop (see `docs/presentation/FALLBACK_PLAN.md` pre-flight), breathe. | | | | |

## Rules of the road

- **Trunk-based.** Everyone on `main`, small commits, `git pull --rebase` before push. No long-lived branches — merges at H16 are how jams die.
- **Contract changes go through C.** After X1, a change to `packages/shared-types` or any route shape needs C's ok and a message in the group chat.
- **Mock before real.** A and B build against `C4a` mock worker and static fixtures until the real thing lands. Never block on another track.
- **Show it.** Each issue ends with a 20-second screen recording or a demo to a teammate. Post it in chat — it becomes b-roll for the presentation.
- **Time-box spikes.** D1b/D1c are 90 minutes each, hard stop. Pick and move.
- **The board is truth.** Update `docs/BOARD.md` status when you start and when you finish. Integration lead reviews it at every checkpoint.

## Sleep

Two 3-hour windows, staggered so the integration path always has two people awake. Swap if someone is on a critical bug. Nobody presents on zero sleep.

## Definition of "demoable" per track (what X3 checks)

- **A:** Load real model → orbit → place 3 pins of different severities → reload page → pins persist → export JSON.
- **B:** On a real iPhone and a real Android over the tunnel: scan QR → walk-around 40+ photos → completion screen. No permission loops, no crash on rotate.
- **C:** Dashboard reflects every status transition without manual refresh; create claim in < 30s; reset script returns to clean state in < 10s.
- **D:** `POST /jobs` with the demo dataset → `ready` glb in < 10 min; pre-baked model committed; timing table in the guide.

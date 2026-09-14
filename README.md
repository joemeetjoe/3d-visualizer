# 3D Vehicle Damage Visualizer — Jam Kit

Everything a 4-person team needs to build and present the **3D Vehicle Damage Visualizer** POC in a single 24-hour coding jam. No application code lives here yet (jam rules) — this folder is the *plan, the contracts, the docs, and the AI skills*. Clone it, read it, and start at hour 0 with no ambiguity.

> Source of truth for *what* we're building: [`prd.md`](prd.md).
> Source of truth for *what we decided to cut and why*: [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Start here (15 minutes, everyone)

1. [`docs/DECISIONS.md`](docs/DECISIONS.md) — what's in scope for 24h, what's not, and why. **Read this first.**
2. [`docs/PLAN.md`](docs/PLAN.md) — the four tracks, the hour-by-hour timeline, checkpoints, sleep windows.
3. [`docs/CONTRACTS.md`](docs/CONTRACTS.md) — shared types, API endpoints, status state machine, worker API, file layout. **Every track codes against this.**
4. [`docs/BOARD.md`](docs/BOARD.md) — the issue board. Find your track, pick the next unblocked issue.
5. [`docs/SETUP.md`](docs/SETUP.md) — hour-0 machine setup (versions, tools, tunnel, GPU box).
6. [`docs/LEARNING_PATHS.md`](docs/LEARNING_PATHS.md) — per-track reading order for the guides, with 20-minute exercises.
7. [`docs/PREFLIGHT.md`](docs/PREFLIGHT.md) — **before the jam**: Nexus warm-up, Docker Hub, cloudflared on the corporate network, AWS G-instance quota, phones, the car.

## Tracks

| Track | Owner | Scope | Guide |
|---|---|---|---|
| **A** Viewer | — | Three.js / R3F viewer, damage pins, annotations, auto-save | [`guides/01`](docs/guides/01-three-js-and-r3f.md), [`guides/02`](docs/guides/02-viewer-annotations-deep-dive.md) |
| **B** Capture | — | Mobile camera flow, walk-around + guided modes, quality gates, uploads | [`guides/03`](docs/guides/03-camera-capture.md) |
| **C** API + Dashboard + Integration + Presentation | — | Hono API, Postgres, dashboard, create claim, pipeline dispatch, tunnel, slides | [`guides/05`](docs/guides/05-api-hono-drizzle.md), [`guides/06`](docs/guides/06-frontend-stack.md), [`presentation/`](docs/presentation/) |
| **D** Pipeline | — | GPU box, Meshroom / COLMAP+OpenMVS, .glb export, job worker, pre-baked demo model | [`guides/04`](docs/guides/04-photogrammetry.md), [`guides/07`](docs/guides/07-shooting-a-car.md) |

Write your name in the Owner column of [`docs/BOARD.md`](docs/BOARD.md) when you pick a track.

## Folder map

```
prd.md                      The PRD (unchanged)
CLAUDE.md                   Project conventions loaded by everyone's Claude Code
preflight/                  Resolved dependency tree (pnpm-lock + PACKAGES.txt) for Nexus warm-up
assets/samples/             ToyCar sample glb (CC BY 4.0) so the viewer works at minute one
docs/
  PREFLIGHT.md              Pre-jam checklist (network, AWS quota, phones, car)
  DECISIONS.md              Scope decisions from the planning session
  PLAN.md                   24h timeline, tracks, checkpoints
  CONTRACTS.md              Types, endpoints, state machine, worker API, file layout
  BOARD.md                  Issue board (edit status here)
  SETUP.md                  Hour-0 setup
  LEARNING_PATHS.md         What to read, per track, in what order
  issues/                   One markdown file per issue (56)
  guides/                   Deep, current (Sept 2026) library guides
  presentation/             Demo script, slide outline, fallback plan
.claude/skills/             Skills your Claude Code loads automatically in this repo
```

## Using the AI skills

Because the skills live in `.claude/skills/` inside this repo, anyone who opens the repo in Claude Code has them. Useful invocations:

- `/jam-issue B2a` — plan and implement an issue from the board, checking acceptance criteria.
- `/jam-teach raycasting` — mentor-mode explanation of a concept, scoped to this project.
- `/r3f-viewer`, `/camera-capture`, `/photogrammetry-pipeline`, `/hono-api` — library-specific expertise; they also auto-load when you work in those areas.
- `/jam-conventions` — the code-quality rules we agreed on (auto-applied).
- `/demo-presentation` — help with slides, the demo script, and the narrative for executives.

## The one rule

**Demoable beats complete.** Every issue ends with something you can show. If you're 3 hours into something with nothing to show, stop and ask the integration lead.

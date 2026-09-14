# 3D Vehicle Damage Visualizer — project instructions

This repo is a 24-hour jam build of the POC described in `prd.md`. Scope was deliberately cut; **`docs/DECISIONS.md` overrides the PRD wherever they disagree.**

## Before you write code

1. Read `docs/CONTRACTS.md`. Types, endpoint shapes, status transitions, and folder layout are frozen at hour 2 (checkpoint X1). Do not invent new fields or routes — propose a change to the integration lead (Track C) instead.
2. Find the issue in `docs/issues/` and check its acceptance criteria and "Read first" links.
3. Load the guide for your area (`docs/guides/`). They're current as of September 2026 and encode library versions and gotchas that differ from older training data.

## Stack (pinned — see docs/SETUP.md for exact versions)

- **Web:** Vite 8 · React 19 · TypeScript 6 (not 7 — tooling gap) · React Router 8 (`react-router`, NOT `react-router-dom`) · Tailwind 4 · Zustand 5 · Axios
- **3D:** three r186 · @react-three/fiber 9 (NOT v10 alpha) · @react-three/drei 10
- **API:** Hono 4 on `@hono/node-server` · Drizzle ORM · Postgres 16 in Docker Compose · zod
- **Pipeline:** Meshroom 2025.1 or COLMAP 4.2 + OpenMVS on a rented NVIDIA Linux box · obj2gltf · gltf-transform
- **Monorepo:** pnpm workspaces: `apps/web`, `apps/api`, `packages/shared-types`, `pipeline/`, `worker/`

## Conventions (enforced by the `jam-conventions` skill)

- TypeScript strict. No `any`. Explicit return types on exported functions. Types come from `@vdv/shared-types`.
- Files: `kebab-case.ts(x)`. Components: `PascalCase`. Hooks: `useX`. Zustand stores: `use-x-store.ts` exporting `useXStore`.
- Frontend layering: `pages/` (route components) → `components/` + `viewer/` + `capture/` (UI) → `store/` (Zustand) → `api/` (Axios client). No Axios calls inside components.
- API layering: `routes/` (Hono handlers, zod-validated) → `services/` (logic) → `db/` (Drizzle queries). Handlers never touch Drizzle directly.
- Errors: services throw `AppError(status, code, message)`; one Hono `onError` maps to JSON `{ error: { code, message } }`.
- Commits: `type(scope): subject` — `feat(viewer): place pin via raycast`. Push to `main` often, rebase before push, never force-push.
- Jam rule: prefer the boring, working solution. No new dependencies without a one-line reason in the commit message. No abstractions for one call site.

## Definition of done for any issue

- Acceptance criteria in the issue file are all checked.
- `pnpm typecheck` and `pnpm lint` pass in the touched package.
- It's been shown to one other person (or a screen recording exists).
- `docs/BOARD.md` status updated.

## Demo-first mindset

If a choice is between "correct for production" and "works for the 10-minute demo and is honest about it", pick the demo, and add the production note to `docs/issues/P0-post-jam-backlog.md`.

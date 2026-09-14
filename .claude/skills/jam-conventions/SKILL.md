---
name: jam-conventions
description: Code quality and workflow rules for the 3D Vehicle Damage Visualizer jam. Use whenever writing, reviewing, or refactoring code in this repo — TypeScript strictness, layering (routes/services/db, pages/components/store/api), naming, error handling, commits, and the "demoable beats complete" rule. Auto-apply; also invoked as /jam-conventions for a review pass.
---

# Jam conventions

You are pairing with a developer during a 24-hour build. The goal is a **working, presentable prototype** at hour 24. Optimize for: no regressions, no surprises for teammates, code a teammate can read at 3 a.m.

## Before writing code
1. Identify the issue (`docs/issues/<ID>-*.md`) and read its acceptance criteria and "Read first" links.
2. Read `docs/CONTRACTS.md` for any type, route, status, or file path you touch. **Never invent a field, route, or status.** If the contract is missing something, say so and propose the smallest addition — the integration lead (Track C) approves.
3. Check the relevant guide in `docs/guides/` for the current API of the library (versions differ from older training data: React Router 8 = `react-router` only; R3F 9; Vite 8; TS 6; Tailwind 4 `@theme`).

## Code rules
- **TypeScript strict.** No `any`; use `unknown` + narrowing. Explicit return types on exported functions. `import type` for types. Types come from `@vdv/shared-types` — don't redeclare `Claim`, `Annotation`, `ClaimStatus`.
- **Layering.** Web: `pages/` → `components|viewer|capture/` → `store/` (Zustand) → `api/` (Axios). Components never call Axios directly. API: `routes/` (validate, call service) → `services/` (logic) → `db/` (Drizzle only). Handlers never import Drizzle.
- **Errors.** API: throw `AppError(status, code, message, details?)`; the global handler formats it. Web: `api/*` functions reject with `Error(message)`; UI shows a toast or inline state — never `alert()`, never swallow.
- **Naming.** Files `kebab-case.ts(x)`; components `PascalCase`; hooks `useX`; stores `use-x-store.ts` → `useXStore`; constants `UPPER_SNAKE`. Match existing names in the folder.
- **State.** Zustand for shared/cross-component state; `useState` for local UI; refs for per-frame values in R3F. No React Context for app state.
- **Async.** `async/await`; every awaited network call has a timeout and a visible failure state.
- **No new dependencies** without a one-line justification in the commit message. Prefer what's already in `docs/SETUP.md`.
- **No abstractions for one call site.** No "utils" grab-bags. Three similar lines beat a premature helper — until the third copy, then extract.
- **Comments** explain *why* (a constraint, a gotcha, a contract), not *what*. Link the guide section when a line exists because of a gotcha (e.g., `// iOS: no ImageCapture — guide 03 §4`).
- **Accessibility floor.** Buttons are `<button>`, inputs have labels, focus visible, `prefers-reduced-motion` respected (the global CSS handles animations; JS animations must check `useReducedMotion`).
- **Style.** Tailwind utility classes with the `@theme` tokens (`bg-surface`, `text-text-secondary`, `text-accent`); no inline hex except in three.js materials. Prettier formats; don't argue with it.

## Workflow rules
- Trunk-based on `main`. Commit small and often: `type(scope): imperative subject` (`feat(capture): walk-around auto-capture ring`, `fix(api): 415 on non-JPEG upload`). `git pull --rebase` before push. Never force-push. Never commit `.env`, `data/`, or models > 25 MB (the demo glb is the one exception; use Git LFS if available, else keep it under 25 MB).
- Before saying "done": acceptance criteria checked one by one, `pnpm typecheck` and `pnpm lint` clean in the touched package, shown to a teammate or a 20-s recording posted, `docs/BOARD.md` status updated.
- Time-box. If 60 minutes pass with nothing demoable, stop, write down what's blocking, and ask in chat. Stretch issues (A5, D6) are cut without ceremony at H16.
- Demo-first trade-offs are fine **if written down** in `docs/issues/P0-post-jam-backlog.md`.

## Review pass (when invoked as /jam-conventions)
Run through the changed files and report, tersely, in this order: (1) contract violations, (2) layering violations, (3) error paths that show nothing to the user, (4) type holes (`any`, non-null assertions without a comment), (5) perf traps for the viewer/capture (state in `useFrame`, Blobs in React state, unbounded polling), (6) naming/style. Then give a one-line verdict: merge / fix-then-merge / stop.

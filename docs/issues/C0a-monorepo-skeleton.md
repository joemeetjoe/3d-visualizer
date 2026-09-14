# C0a — Monorepo skeleton + shared types

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H1 | todo |

## What to build
A pnpm-workspace monorepo everyone can `git pull` at H1 and immediately run. Packages: `apps/web` (Vite 8 + React 19 + TS + Tailwind 4 + React Router 8, routes stubbed with placeholder pages for `/`, `/claims/new`, `/claims/:claimId`, `/capture/:token`), `apps/api` (empty Hono app, see C0c), `packages/shared-types` (the exact types from `docs/CONTRACTS.md §1`, exported from `@vdv/shared-types`), plus root scripts `pnpm dev` (runs web + api concurrently), `pnpm typecheck`, `pnpm lint`. ESLint (typescript-eslint, react-hooks) + Prettier configured once at the root. `.gitignore` covers `data/`, `.env`, `node_modules`, `dist`.

## Acceptance criteria
- [ ] Fresh clone → `pnpm install && pnpm dev` starts web on :5173 and api on :3000 with no errors
- [ ] All four routes render a placeholder page with the route name and params
- [ ] `import type { Claim } from '@vdv/shared-types'` works from both apps
- [ ] `pnpm typecheck && pnpm lint` pass on the skeleton
- [ ] Versions match `docs/SETUP.md` pins (TS 6.0.x, react-router not react-router-dom, R3F 9)
- [ ] Tailwind 4 theme tokens from PRD §13 defined in `apps/web/src/index.css` under `@theme` (`--color-bg`, `--color-surface`, `--color-surface-elevated`, `--color-accent`, `--color-damage`, `--color-text`, `--color-text-secondary`, status colors) and Inter + JetBrains Mono loaded

## Blocked by
None — start at H0.

## Unblocks
Everything. Announce in chat the moment it's pushed.

## Read first
`docs/CONTRACTS.md §1, §8`, `docs/SETUP.md`, `docs/guides/06-frontend-stack.md`

## Notes
- Don't hand-roll the Vite app: `pnpm create vite apps/web --template react-ts`, then add Tailwind via `@tailwindcss/vite`, then pin versions.
- `packages/shared-types` can be plain TS with `"exports": "./src/index.ts"` consumed directly (Vite and tsx handle TS source) — no build step.
- Put the severity color map and `CLAIM_STATUSES` array in shared-types so dashboard badges and viewer pins agree.

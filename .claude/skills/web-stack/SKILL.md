---
name: web-stack
description: Expertise for the React app outside the 3D viewer and camera modules (apps/web pages, components, store, api client) — Vite 8 (Rolldown, allowedHosts, proxy), React 19, TypeScript 6, React Router 8 (react-router only), Tailwind 4 @theme tokens, Zustand 5 with useShallow, Axios client, forms with shared zod schemas, StatusBadge/CopyButton/ConfirmDialog, dashboard polling, PRD motion rules. Use when working under apps/web/src/pages|components|store|api, on dashboard/create-claim/claim-detail UI, routing, styling, or /web-stack.
---

# Web stack expert (dashboard, create claim, claim detail shell)

Authoritative references (read the section before answering; verified 2026-09-13 — they beat your memory):
- `docs/guides/06-frontend-stack.md` — Vite 8, React 19, TS 6, React Router 8, Tailwind 4, Zustand 5, Axios client, forms, shared components, lint, motion table.
- `docs/CONTRACTS.md §1` (types), `§3` (routes the client calls), `§8` (web routes + store names).
- `prd.md §7.1, §7.2, §7.5, §13` — dashboard, create claim, detail header, design direction.
- Issues `C1b`, `C1c`, `C1d`, `C2b`, `C6a`, `C6b`, `C7a`.

## Version facts that break stale code
- **React Router 8**: import from `react-router` — `react-router-dom` does not exist. `createBrowserRouter` + `RouterProvider`; `useParams`, `useSearchParams`, `useNavigate`, `Link`, `Outlet`. ESM-only; Node ≥ 22.22.
- **Vite 8**: Rolldown bundler; `server.allowedHosts: ['.trycloudflare.com']` or the tunnel 403s; `server.proxy` for `/api` and `/files`; env via `import.meta.env.VITE_*`.
- **TypeScript 6.0.x** pinned (7 has no stable API for `typescript-eslint`). `verbatimModuleSyntax` → `import type`.
- **Tailwind 4**: no config file; `@import "tailwindcss"` + `@theme { --color-surface: … }` in `index.css`; `@tailwindcss/vite` plugin. Tokens: `bg-bg`, `bg-surface`, `bg-surface-elevated`, `text-text`, `text-text-secondary`, `text-accent`, `text-damage`, `font-mono`, `animate-pulse-dot`.
- **Zustand 5**: `create<State>()((set, get) => …)`; object selectors need `useShallow` or you get render loops; `getState()`/`subscribe()` outside React are fine.
- **React 19**: `ref` is a prop (no `forwardRef`); native `<dialog>` for confirms; StrictMode double-runs effects in dev.

## Patterns in this repo
1. Layering: `pages/` → `components/` → `store/` (Zustand) → `api/` (Axios). Components never import `http` directly.
2. `api/client.ts` unwraps our `{ error: { code, message } }` envelope into `Error(message)`; every call has a timeout.
3. Forms: controlled inputs + the **same zod schema the API uses** (exported from `@vdv/shared-types`), validate on blur, submit disabled until valid. No form library.
4. Shared bits: `<StatusBadge status>` (color map from shared-types, pulse only on `processing`), `<CopyButton>`, `<ConfirmDialog>` (`<dialog>.showModal()`), `<Skeleton>`, `sonner` toasts, `lucide-react` icons.
5. Dashboard/detail **poll** (5 s / 3 s) while a claim is `uploading`/`processing`; pause when `document.hidden`. The demo depends on the audience seeing status move without a refresh.
6. QR code: `qrcode.react` `QRCodeSVG`, ≥ 280 px, dark-on-light, value = `captureUrl` from the API (which embeds `PUBLIC_WEB_URL` = the tunnel URL).
7. Motion per PRD §13: 150 ms route fade, 200 ms sidebar slide, 100 ms hovers; all off under `prefers-reduced-motion` (global CSS handles CSS animations).
8. Dark only (`color-scheme: dark`), Inter + JetBrains Mono from `@fontsource*` (local, offline-safe).
9. The claim detail page mounts Track A's `<Viewer claimId modelUrl>` when status is `ready|reviewed|closed`, else `<ModelStatusCard>`; header is 72 px, viewer fills `calc(100vh - 72px)`.

## When asked to implement
- Start from the snippets in guide 06 (vite config, router, CSS theme, store, client, forms). Match existing file names.
- Verify: `pnpm typecheck && pnpm lint`, then the acceptance criteria in the issue; say which need a visual check.
- Don't add UI libraries (no MUI/shadcn/etc.) — Tailwind + the shared components are enough for the demo.

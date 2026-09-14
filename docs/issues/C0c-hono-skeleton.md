# C0c — Hono API skeleton

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 45m | H2 | todo |

## What to build
`apps/api/src/index.ts` with Hono on `@hono/node-server`: `GET /api/v1/health` (checks DB with `select 1`, pings worker `/health` with a 1s timeout), CORS for `localhost:5173` and `*.trycloudflare.com`, request logging, a global `onError` mapping `AppError` → `{ error: { code, message } }` and unknown errors → 500, `.env` loading, `tsx watch` dev script. Route files under `src/routes/` mounted from one `app.route()` list. Static file serving for `/files/*` from `DATA_DIR` (range requests — see C4c for the hardening; a basic `serveStatic` is fine here).

## Acceptance criteria
- [ ] `curl localhost:3000/api/v1/health` → `{ ok: true, db: true, worker: 'unreachable' }`
- [ ] Throwing `new AppError(404, 'CLAIM_NOT_FOUND', '...')` anywhere returns that JSON with 404
- [ ] Unknown route → 404 JSON, not HTML
- [ ] `pnpm dev` at root restarts the API on file change

## Blocked by
C0a

## Unblocks
C1a, C3a, C4a

## Read first
`docs/guides/05-api-hono-drizzle.md`, `docs/CONTRACTS.md §3, §7`

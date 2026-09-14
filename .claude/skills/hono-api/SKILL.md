---
name: hono-api
description: Expertise for the API (apps/api) — Hono 4 on @hono/node-server, zod validation with our error envelope, Drizzle 0.45 + Postgres 16 schema/queries/transactions, the claim status state machine, raw-JPEG uploads to disk with atomic writes, range-capable static file serving, the pipeline dispatcher/poller against the worker API, the mock worker, seeds and demo reset scripts. Use for anything under apps/api, packages/shared-types, docker-compose, or /hono-api.
---

# API expert (Hono + Drizzle + Postgres)

Authoritative references (read before answering; versions verified 2026-09-13):
- `docs/CONTRACTS.md` — **the spec**: types §1, state machine §2, HTTP routes §3, worker API §4, disk layout §5, env §7. Never deviate; propose changes explicitly.
- `docs/guides/05-api-hono-drizzle.md` — layout, `createApp`, `AppError` + `onError`, `zValidator` hook for our envelope, Drizzle schema (PRD §9 + `customer_email`, `job_error`), queries, transactional replace-all annotations, `transition()`, raw-body upload + `writeAtomic`, range static handler, worker client + poller, seed plan, gotchas.
- `docs/guides/06-frontend-stack.md` — for the dashboard/create-claim pages Track C also owns.
- Issues `C0a`–`C8b`.

## Facts you must respect
- `hono@4.13`, `@hono/node-server@2.1`, `@hono/zod-validator`, `zod@4`, `drizzle-orm@0.45`, `drizzle-kit@0.31` (`push`, `studio`), `pg@8.23`, Postgres 16 (`postgres:16-alpine` in compose), Node 22+, TS 6 (not 7).
- Layering: `routes/` validate → `services/` logic → `db/` Drizzle. Handlers never import Drizzle. Every status change goes through `services/claim-status.ts#transition()` (409 `INVALID_TRANSITION` otherwise).
- Error envelope everywhere: `{ error: { code, message, details? } }`; 400 validation (zod issues in `details`), 404 `CLAIM_NOT_FOUND`, 409 `INVALID_TRANSITION` / `MODEL_NOT_READY` / `NOT_ENOUGH_PHOTOS`, 413/415 on uploads.
- Customer routes are token-scoped `/api/v1/capture/:token/...`; adjuster routes `/api/v1/claims/...`; files `/files/...` with `Accept-Ranges`, `Content-Length`, `model/gltf-binary`, path-traversal guard. Vite proxies `/api` and `/files` — one origin for the phone.
- Uploads are raw `image/jpeg` PUT bodies (`c.req.arrayBuffer()`), key validated by regex, atomic temp+rename to `DATA_DIR/claims/<id>/raw/<key>.jpg`, manifest updated, first photo → `uploading` (idempotent).
- `upload-complete` requires ≥ 12 JPEGs → `processing` → `dispatchJob` (zip flat → `POST ${WORKER_URL}/jobs` with `X-Worker-Token`). One poller (`JOB_POLL_INTERVAL_MS`) scans `processing` claims with a jobId; `done` → download glb to `model/model.glb`, set `modelKey`, `ready`; `failed` → `jobError`, `failed`. Resumes on boot. Retry = `PATCH status processing` re-dispatches.
- `PUT /annotations` replace-all in a transaction; `ready → reviewed` on first save.
- `captureUrl = ${PUBLIC_WEB_URL}/capture/${token}` — `PUBLIC_WEB_URL` must be the tunnel URL for QR codes; read it per request (C7a writes it).
- Mock worker (`apps/api/mock-worker`) implements the same API with fake stages and serves `samples/toycar.glb`; `MOCK_WORKER_FAIL=1` simulates failure.
- Seeds use fixed UUIDs: closed (with annotations), ready (pre-baked model, 2 pins), processing, awaiting_capture (the live one). `demo:reset` recreates them; `demo:force-ready <id>` and `demo:upload-dataset <id>` exist for fallbacks.

## When asked to implement
- Start from the guide 05 snippets; keep file names from its layout. Provide a `.http`/curl script for every route you add (`apps/api/http/`).
- Verify with curl in the response (status code + body), and state what needs the phone/worker to confirm.
- The only test we require: the vitest table over the transition matrix (C2a). Don't write more unless asked.
- Don't add S3/SES/Lambda code; note the production swap points in comments instead (`// prod: presigned S3 PUT`).

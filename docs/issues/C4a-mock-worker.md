# C4a — Mock pipeline worker

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H7 | todo |

## What to build
`apps/api/mock-worker/index.ts`: a standalone Hono server on :8080 implementing the **worker API** from `CONTRACTS.md §4` exactly, checking `X-Worker-Token`. `POST /jobs` accepts the multipart zip (just stores it), returns `queued`; a timer advances `stage` through `feature_extraction → matching → sfm → depth → mesh → texture → export` every ~2s with `progress`, then `done` after ~15s; `GET /jobs/:id/model.glb` streams `apps/api/samples/toycar.glb`. `MOCK_WORKER_FAIL=1` → `failed` at the `depth` stage with an error string. `MOCK_WORKER_DELAY_MS` overrides timing. `pnpm --filter api mock-worker` script.

## Acceptance criteria
- [ ] The real dispatcher (C4b) works against it with zero code changes — only `WORKER_URL` differs
- [ ] Missing/wrong token → 401
- [ ] Fail mode produces `status: failed, error: '...'`
- [ ] Track D can run the same curl script (`worker/http/jobs.http`) against mock and real and get identical shapes

## Blocked by
C0c

## Unblocks
C4b, X2, and Track D (they use it as the reference implementation)

## Read first
`docs/CONTRACTS.md §4`

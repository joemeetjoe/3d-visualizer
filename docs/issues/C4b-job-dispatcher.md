# C4b — Job dispatcher + poller + model-url

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 2h | H8 | todo |

## What to build
`services/pipeline.ts`: `dispatchJob(claimId)` zips `raw/*.jpg` (archiver, streaming, flat), `POST`s to `${WORKER_URL}/jobs` with the token, stores `jobId`. A single in-process poller (`setInterval` `JOB_POLL_INTERVAL_MS`) scans claims in `processing` with a `jobId`, hits `GET /jobs/:id`, caches the `Job` in `model/job.json`, and on `done` streams the glb to `model/model.glb`, sets `modelKey`, transitions to `ready`; on `failed` sets `jobError`, transitions to `failed`. On API boot, the poller resumes any in-flight claims. `GET /claims/:id/model-url` → `{ url: '/files/claims/<id>/model/model.glb', sizeBytes }` or 409. `GET /claims/:id/job` → last cached `Job`. Retry (`failed → processing` via PATCH) re-dispatches.

## Acceptance criteria
- [ ] End-to-end with mock worker: `upload-complete` → ~20s later status `ready` and `model.glb` on disk, with no manual step
- [ ] Kill and restart the API mid-job → still completes
- [ ] Worker unreachable at dispatch → claim goes `failed` with a clear `jobError`, dashboard shows Retry
- [ ] Zip of 60 × 3 MB photos is streamed, not buffered (memory stays flat)
- [ ] `/model-url` for seed claim #1 returns the sample

## Blocked by
C3b, C4a

## Unblocks
X2, A3a (real `ready` claims), D4a (contract partner)

## Read first
`docs/CONTRACTS.md §4, §5`, `docs/guides/05-api-hono-drizzle.md §Calling the worker`

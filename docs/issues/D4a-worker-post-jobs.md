# D4a — Worker service: POST /jobs

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1.5h | H11 | todo |

## What to build
`worker/` — a small Python FastAPI (or Node Hono) service on the box implementing `CONTRACTS.md §4`: `X-Worker-Token` check, `POST /jobs` multipart (`photos` zip + `claimId`) → unzip to `/data/jobs/<jobId>/images`, enqueue (single worker thread — one GPU), run `run_pipeline.sh` + `export_glb.sh` + normalize as a subprocess, capturing stdout to `log.txt` and parsing `[stage]` lines into `stage`/`progress`. `job.json` persisted per job. Use the mock worker (C4a) as the behavioural reference and `worker/http/jobs.http` for identical curls.

## Acceptance criteria
- [ ] `curl -F photos=@demo.zip -F claimId=x -H 'X-Worker-Token: …' :8080/jobs` → 202 `{ job }`
- [ ] Wrong token → 401; second job queues behind the first
- [ ] Log + stage parsing visible in `GET /jobs/:id` (D4b)

## Blocked by
D3a (script must exist)

## Unblocks
D4b

## Read first
`docs/CONTRACTS.md §4`, `docs/guides/04-photogrammetry.md §Worker`

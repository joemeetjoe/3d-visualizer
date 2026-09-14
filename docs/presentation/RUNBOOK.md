# Runbook (C7b fills the exact commands; skeleton here so it exists from H0)

## Boot (two terminals, or `pnpm demo:up` which does all of it)
```bash
docker compose up -d                      # Postgres
pnpm --filter api db:push && pnpm --filter api db:seed
pnpm dev                                  # web :5173 + api :3000
pnpm tunnel                               # prints https://….trycloudflare.com and writes PUBLIC_WEB_URL
# real worker: WORKER_URL=http://<gpu-ip>:8080 in apps/api/.env ; mock: pnpm --filter api mock-worker
```

## Reset to clean demo state
```bash
pnpm demo:reset       # db reset + seed + wipe data/claims + copy demo-car.glb into the seeded ready claim
```

## Verify (60 seconds)
- http://localhost:5173 → dashboard shows 4 seeded claims
- Open the `ready` claim → real model loads, 2 pins
- Phone → tunnel URL → `/capture/<live token>` → camera opens
- `curl -H "X-Worker-Token: $WORKER_TOKEN" $WORKER_URL/health`

## Emergency
- `pnpm demo:force-ready <claimId>` — attach the pre-baked model to any claim
- `pnpm demo:upload-dataset <claimId>` — push `pipeline/datasets/democar/images_2000/*.jpg` through the capture API
- Backup video: `~/Desktop/demo-backup.mp4`

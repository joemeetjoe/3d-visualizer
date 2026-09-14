# C0b — Postgres in Docker Compose + Drizzle schema + seed

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H2 | todo |

## What to build
`docker-compose.yml` at root with `postgres:16-alpine` (user/pass/db `vdv`, port 5432, named volume, healthcheck). Drizzle schema in `apps/api/src/db/schema.ts` implementing PRD §9 (`claims`, `annotations` with JSONB `data`, indexes) plus `customer_email`, `job_id`, `job_error`. `drizzle.config.ts`, `pnpm --filter api db:push`, `pnpm --filter api db:seed` inserting 4 claims spanning statuses (one `ready` pointing at the sample glb key so the viewer has something at H2).

## Acceptance criteria
- [ ] `docker compose up -d` → healthy Postgres in < 30s
- [ ] `pnpm --filter api db:push` creates both tables and indexes; `db:seed` is idempotent (upsert by fixed UUIDs)
- [ ] Column types: uuid PK `defaultRandom()`, `status` varchar(30) with app-level check against `CLAIM_STATUSES`, `data` jsonb typed as `Annotation` in Drizzle (`$type<Annotation>()`)
- [ ] `updated_at` is bumped by every write path (Drizzle `$onUpdate(() => new Date())`)
- [ ] `pnpm --filter api db:reset` drops + recreates + seeds (used by C7b)

## Blocked by
C0a

## Unblocks
C1a, C5

## Read first
`docs/guides/05-api-hono-drizzle.md §Drizzle`, `prd.md §9`

## Notes
- Seed claim #1 should be `ready` with `model_key = 'samples/toycar.glb'` so `GET /model-url` works before the pipeline exists.
- Keep the annotations table even though we use replace-all writes — the PRD schema is a talking point.

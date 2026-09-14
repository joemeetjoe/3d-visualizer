# C1a — Claims endpoints (create / list / get / patch notes)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1.5h | H3 | todo |

## What to build
`POST /claims`, `GET /claims?status=`, `GET /claims/:claimId`, `PATCH /claims/:claimId` exactly per `CONTRACTS.md §3`, with `@hono/zod-validator` schemas derived from `CreateClaimInput` (year 1980..now+1, make/model 1..50, color ≤30). `captureUrl` built from `PUBLIC_WEB_URL`. `photoCount` computed by counting `raw/*.jpg` on disk (cheap; cache not needed). Service layer `services/claims.ts`; DB layer `db/claims.ts`.

## Acceptance criteria
- [ ] `POST /claims` with a bad year → `400 VALIDATION_ERROR` with zod `details`
- [ ] Valid POST → `201 { claim, captureUrl }`, status `awaiting_capture`, `captureUrl` contains the token
- [ ] `GET /claims?status=ready` filters; unknown status → 400
- [ ] `GET /claims/<unknown>` → `404 CLAIM_NOT_FOUND`
- [ ] `PATCH` notes updates `adjusterNotes` and `updatedAt`
- [ ] A 6-line `apps/api/http/claims.http` (or curl script) exercising all four is committed

## Blocked by
C0b, C0c

## Unblocks
C1b, C1d, C2a

## Read first
`docs/CONTRACTS.md §1, §3`, `docs/guides/05-api-hono-drizzle.md §Validation`

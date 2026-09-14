# C2a — Status state machine + PATCH /status + GET /capture/:token

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H5 | todo |

## What to build
`services/claim-status.ts` with the allowed-transition table from `CONTRACTS.md §2` and a single `transition(claimId, to)` used by *every* status change in the codebase (uploads, dispatcher, annotations, buttons). `PATCH /claims/:claimId/status` validates and returns 409 `INVALID_TRANSITION` with `{ from, to }` details. `GET /capture/:token` → `PublicClaim` (404 on unknown token) for Track B.

## Acceptance criteria
- [ ] `ready → closed` ok; `closed → ready` 409; `awaiting_capture → ready` 409
- [ ] Unit test (vitest) table-drives every transition in §2 — this is the one test worth writing today
- [ ] `GET /capture/<seed token>` returns only the `PublicClaim` fields (no notes/email/token)
- [ ] All other code paths call `transition()` — grep confirms no direct `status:` writes elsewhere

## Blocked by
C1a

## Unblocks
C2b, C3a, B1a

## Read first
`docs/CONTRACTS.md §2, §3`

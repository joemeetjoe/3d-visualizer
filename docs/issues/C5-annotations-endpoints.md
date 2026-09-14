# C5 — Annotations GET/PUT (JSONB, replace-all)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H10 | todo |

## What to build
`GET /claims/:id/annotations` → all rows as `Annotation[]` (row `data` + `type`). `PUT /claims/:id/annotations { annotations }` validates with a zod discriminated union over `PinAnnotation | RegionAnnotation`, then in one transaction: delete all rows for the claim, insert the new set (preserving client `id`s as row ids), and if claim status is `ready` → `transition('reviewed')`. Returns the stored set. Idempotent; last write wins (the viewer debounces).

## Acceptance criteria
- [ ] PUT 3 pins → GET returns 3 with identical ids; PUT 2 → GET returns 2
- [ ] Invalid severity → 400 with the failing index in `details`
- [ ] First PUT on a `ready` claim flips it to `reviewed`; later PUTs don't error
- [ ] 200 annotations round-trip in < 100ms locally

## Blocked by
C2a

## Unblocks
A3a

## Read first
`docs/CONTRACTS.md §1 (annotation shapes), §2`, `prd.md §9`

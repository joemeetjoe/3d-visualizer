# C3b — Upload complete → processing

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 45m | H7 | todo |

## What to build
`POST /capture/:token/upload-complete { mode, photoCount }`: counts JPEGs on disk, rejects with `409 NOT_ENOUGH_PHOTOS` if < 12, writes `mode` into the manifest, transitions to `processing`, and calls `dispatchJob(claimId)` (C4b — until it exists, log "would dispatch"). Returns `PublicClaim`.

## Acceptance criteria
- [ ] With 11 photos → 409 with a message the phone can show; with 12+ → 200 and status `processing`
- [ ] Calling twice is safe (second call → 409 INVALID_TRANSITION or no-op; choose no-op and document)
- [ ] Dashboard shows `processing` immediately after (with C6b polling)

## Blocked by
C3a

## Unblocks
C4b, B4b

## Read first
`docs/CONTRACTS.md §2, §3`

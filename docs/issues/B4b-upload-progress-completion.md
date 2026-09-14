# B4b — Upload progress, retry, completion → upload-complete

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1h | H14 | todo |

## What to build
After Finish: "Uploading 47 of 50…" with a progress bar summing the queue, failed items with Retry, and when everything is `done`, `POST /capture/:token/upload-complete { mode, photoCount }` → completion screen: "You're done! Your insurer has been notified and will review your vehicle shortly." with the vehicle name and a subtle checkmark animation. Handle `409 NOT_ENOUGH_PHOTOS` by returning to capture with a message. Prevent double submission.

## Acceptance criteria
- [ ] Completion appears only after the last 204; dashboard flips to `processing` within 5s
- [ ] Refreshing the completion page shows the "already received" state (B1a), not a restart
- [ ] < 12 photos → clear message and back to capture

## Blocked by
B4a, C3b

## Unblocks
X2

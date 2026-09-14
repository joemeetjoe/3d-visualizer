# B2b — Wake lock, capture feedback, upload queue hardening

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1h | H10 | todo |

## What to build
`navigator.wakeLock.request('screen')` while capturing (re-request on `visibilitychange`), a short shutter tick (Web Audio beep, no audio file) + `navigator.vibrate?.(30)` per capture, a subtle white flash on the viewfinder, and an orientation hint if landscape ("Hold your phone upright"). Upload queue: max 3 concurrent, exponential backoff retry ×3, resumes after `online` event, persists nothing (a refresh restarts the session — acceptable, document it).

## Acceptance criteria
- [ ] Screen never dims during a 90s capture session on iOS and Android
- [ ] Audible/haptic tick per capture
- [ ] Toggle wifi off/on mid-session → queue drains automatically after reconnect

## Blocked by
B2a

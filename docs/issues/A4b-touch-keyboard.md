# A4b — Touch controls check + keyboard shortcuts

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 45m | H15 | todo |

## What to build
Verify OrbitControls touch mapping (1-finger orbit, 2-finger pan/pinch — default) on an iPad or phone via the tunnel; ensure pin placement works with tap (R3F pointer events unify mouse/touch). Keyboard: `1` select, `2` pin, `3` paint, `Esc` close popover / back to select, `Delete` removes selected pin, `F` re-frame. Shortcut hints in toolbar tooltips.

## Acceptance criteria
- [ ] All shortcuts work and don't fire while typing in the note textarea
- [ ] Tap-to-pin works on a touch device; orbit doesn't accidentally place pins (use a small movement threshold — R3F's `onClick` already ignores drags)

## Blocked by
A2c

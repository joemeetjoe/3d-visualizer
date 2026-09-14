# B1b — Camera hook: getUserMedia, fallback, resolution logging

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 2h | H4 | todo |

## What to build
`useCamera()` hook: requests `getUserMedia({ video: { facingMode: { ideal: 'environment' }, width: { ideal: 3840 }, height: { ideal: 2160 } }, audio: false })`, attaches the stream to a `<video playsInline muted autoPlay>` (all three attributes are mandatory on iOS), exposes `status: 'idle' | 'requesting' | 'live' | 'denied' | 'unsupported'`, `actualWidth/Height` from `track.getSettings()`, and `stop()` (stop all tracks on unmount and on `pagehide`). On `denied`/`unsupported` (or non-secure context) the capture screen swaps to `<input type="file" accept="image/*" capture="environment">` per shot. Show the actual resolution in a dev overlay (toggle with `?debug=1`) — this decides which mode the demo phone uses.

## Acceptance criteria
- [ ] Over the tunnel on a real iPhone and Android: viewfinder shows the rear camera within 2s of Start
- [ ] Deny permission → file-input fallback works and produces a full-res photo
- [ ] `?debug=1` shows actual `width×height`; you've recorded the numbers for both phones in `docs/guides/03-camera-capture.md §Field notes`
- [ ] Leaving the page stops the camera (LED off)
- [ ] Non-HTTPS (plain LAN IP) shows a clear "open the secure link" message instead of a broken screen

## Blocked by
B1a, C7a-quick (needs HTTPS to test on a phone — ask C for the tunnel early)

## Unblocks
B1c

## Read first
`docs/guides/03-camera-capture.md` (all of §getUserMedia and §iOS quirks)

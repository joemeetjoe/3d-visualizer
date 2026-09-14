# B2a — Walk-around auto-capture mode

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 2h | H8 | todo |

## What to build
Primary mode (DECISIONS D6). Screen: viewfinder, a thin "keep the whole car in frame" bracket overlay, a **ring progress** around a central counter ("23 / 50"), Start / Pause / Finish. On Start, capture a frame every `intervalMs` (default 1500, configurable in the store) using B1c's capture + queue; target 50 (min 40 to enable Finish, max 80). Instruction line cycles: "Walk slowly around the car… keep going… halfway there… now lower the phone slightly for the second lap". Finish → Review screen (grid of thumbnails, failed uploads flagged, Retry all) → Continue to B4b's completion.

## Acceptance criteria
- [ ] A full lap at walking pace yields 40–60 photos on the laptop, evenly spaced (check the manifest timestamps)
- [ ] Ring + counter update per capture; Finish enabled at 40
- [ ] Pause stops capture without stopping the camera; Resume continues numbering
- [ ] Uploads keep up with capture on the venue wifi (queue depth shown in `?debug=1`; never exceeds ~5)

## Blocked by
B1c

## Unblocks
B2b, B4a, X2

## Read first
`docs/guides/03-camera-capture.md §Walk-around mode`, `docs/guides/07-shooting-a-car.md`

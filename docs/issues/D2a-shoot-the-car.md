# D2a — Shoot the real car (daylight)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D (+ B) | HITL | 1h | H3–5, **must be daylight** | todo |

## What to build
The canonical dataset. Follow `docs/guides/07-shooting-a-car.md` exactly: overcast or open shade, car away from walls/other cars, 2 laps (standing height, then chest/knee height), ~30 photos per lap, 60–80% overlap, plus 8 closer 3/4 shots and 4 detail shots of the damage area. Shoot with the **phone's native camera app** (full-res, EXIF) *and*, if B1c is ready, once through the capture app to test it. Copy to the GPU box at `/data/samples/democar/images/`. Also take 3 "hero" photos of the car for the slides.

## Acceptance criteria
- [ ] 60–90 sharp photos on the box; no people walking through; no lens flare
- [ ] Second copy on the laptop (`pipeline/datasets/democar/` — gitignored, shared via drive/AirDrop)
- [ ] Hero photos sent to Track C

## Blocked by
None — but weather/daylight. Do it as early as light allows.

## Unblocks
D2b, D5a

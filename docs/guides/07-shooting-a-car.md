# Guide 07 — Shooting a car for photogrammetry (the dataset is half the result)

For whoever holds the phone (Track D + helper) and for the copy in the capture app (Track B). Read before D2a.

## The rules that matter most, in order

1. **Light: overcast, open shade, or golden hour. Never direct midday sun.** Direct sun = hard reflections that move with you = features that don't match = holes. If it's sunny, move the car into a building's shadow or shoot early/late. Indoor garages with even fluorescent light are great.
2. **Space: 3+ metres clear around the car**, away from other cars, walls closer than ~2 m, and moving people. The ground and surroundings are *good* (they give SfM features) — but a neighbouring car will get reconstructed into your mesh.
3. **Overlap: each photo shares ≥ 60% of its content with the previous one.** Walking a ring: one photo every ~1–1.5 m, i.e., every small step. Don't spin on your heel taking a panorama — move *around* the car; parallax is what creates 3D.
4. **Two laps at two heights.** Lap 1 at chest height, phone level, whole car in frame. Lap 2 at knee/hip height (crouch), tilted slightly up. The second lap fixes the underside of bumpers and the roof/side transitions.
5. **Then a closer ring of 8–12 three-quarter shots** at 1.5–2 m: front-left, side-left, rear-left, … Fill the frame with half the car. These give panel detail and texture resolution.
6. **Then the damage: 4–6 photos from 0.5–1 m, from different angles**, with a bit of context (edge of the panel visible). These are the money shots for the demo — make sure the dent/scratch is sharp.
7. **Hold still for each shot.** Auto-capture in the app fires while you walk, so walk *slowly* and keep the phone steady; the blur gate will drop shaky frames, but a dropped frame is a gap in coverage.
8. **Keep the whole car in the frame during laps.** Cropping the roof or wheels in half the photos hurts more than a bit of extra ground.
9. **Don't change zoom or lens.** No pinch-zoom, no switching to 0.5×. iOS may auto-switch lenses in low light — shoot in decent light so it doesn't.
10. **Same phone for the whole dataset.** Intrinsics stay constant.

## What "good" looks like in numbers

| | Minimum | Target | Notes |
|---|---|---|---|
| Photos | 40 | 60–80 | native camera: 12 MP; app walk mode: whatever `getSettings()` reports (≥ 1080p) |
| Laps | 1 | 2 (+ close ring) | |
| Step between shots | 1.5 m | ~1 m | |
| Sharp frames | 90% | 100% | check a few at 100% zoom on the phone |
| Time | 4 min | 8 min | |

## Reflective paint — optional extra credit

- A light dusting of **dry shampoo / matting spray / chalk spray** on the glossy panels dramatically improves dense reconstruction. Probably not on a colleague's car at a jam, but if it's someone's willing beater — do it and mention it in the talk as "how pros do it" (and that production would rely on more views + AI instead).
- Dirt, dust, and pollen are your friends. Don't wash the car first.
- Windows and chrome will be holey/noisy. Expected. The mesh filter and the viewer's lighting hide most of it.

## Checklist for D2a (print this)

- [ ] Light is even (overcast/shade). Time noted.
- [ ] Car positioned with space; handbrake; wheels straight; doors closed; nothing on the roof.
- [ ] Phone: lens wiped; HDR **off** if the camera app allows (HDR tone-mapping differs per frame); Live Photos off; grid on.
- [ ] Lap 1 (chest height, ~30 photos), lap 2 (knee height, ~30), close ring (~10), damage (~5), 3 hero shots for slides.
- [ ] Also run the capture app once around the car if B1c is ready (tests the real thing).
- [ ] Quick review: swipe through, delete obvious blur/finger-in-lens.
- [ ] Copy originals to the GPU box `/data/samples/democar/images/` and the laptop `pipeline/datasets/democar/`.
- [ ] Write `dataset.md`: phone model, count, time, light, notes.

## For the capture app's copy (Track B)

Short, imperative, one idea per line:
- Start screen: "Walk slowly around your car. Keep the whole car in the frame. Best in shade or on a cloudy day."
- During lap 1: "Keep walking… halfway… almost there…"
- Lap 2 prompt: "Great. Now crouch a little and go around once more."
- Close-ups: "Get within arm's reach of the damage. Take 3–4 photos from different sides."
- Blurry pill: "Hold steady — retaking."

# D5a — Pre-bake the demo model + fallback wiring

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1.5h (mostly waiting) | H12 (v1), H22 (final) | todo |

## What to build
Run the full pipeline on the curated `democar` dataset at the highest quality that finishes in < 20 min; iterate on params (see D5b) and keep the best-looking result. Commit it to `apps/web/public/models/demo-car.glb` **and** copy it to `apps/api/samples/demo-car.glb`; C7b's seed points the "ready" demo claim at it. Also produce a 10-second turntable screen recording for the deck. Note the honest numbers for the script: photo count, capture time, processing time, mesh size.

## Acceptance criteria
- [ ] `demo-car.glb` ≤ 25 MB, looks like the car, no big holes on the visible sides, textures aligned
- [ ] Loads upright/centered in Track A's viewer with zero manual adjustment
- [ ] Numbers written into `docs/presentation/DEMO_SCRIPT.md §Honest numbers`
- [ ] Final version re-run and committed by H22 at the latest

## Blocked by
D2b, D3c

## Unblocks
C7b, X3, C8b

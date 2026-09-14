# D3c — Normalize orientation, scale, and origin

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1.5h | H10 | todo |

## What to build
Photogrammetry output has arbitrary orientation/scale. Add a step (Python with `trimesh`, or `gltf-transform` `center` + a custom node transform) that: removes floating junk (keep the largest connected component, or drop components < 2% of the largest), fits a plane to the lowest vertices to find "up" (or simply use PCA: the smallest-variance axis of the point cloud is up for a car; sanity-check), rotates to **Y-up**, centers on origin, sits on `y=0`, and scales the longest dimension to **4.5** (CONTRACTS §6). Also crop anything farther than ~1.5× the car's bounding radius (ground/background).

## Acceptance criteria
- [ ] The demo model loads in the viewer upright, on the grid, centered, car-sized, without Track A doing anything
- [ ] Junk components removed (compare vertex counts before/after in the log)
- [ ] Documented in the guide with the exact commands

## Blocked by
D3b

## Unblocks
D5a

## Read first
`docs/guides/04-photogrammetry.md §Normalizing`

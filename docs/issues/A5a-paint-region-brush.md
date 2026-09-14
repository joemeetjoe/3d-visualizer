# A5a — STRETCH: Paint region brush → face selection → overlay

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 3h | H19 (only if A1–A4 are flawless by H14) | stretch |

## What to build
`tool === 'paint'`: pointer-down/move over the model raycasts continuously (`onPointerMove` with `e.buttons === 1`), collects `e.faceIndex` plus neighboring faces within a brush radius (use `three-mesh-bvh` for fast sphere queries against the merged geometry, or simply raycast a small jittered cone of rays per move for a cheap "brush"), and stores the set in the current `RegionAnnotation.faceIndices`. Render the overlay by writing vertex colors into a cloned geometry attribute (or a second mesh with the same geometry, `MeshBasicMaterial` red, `transparent`, `opacity` from the region, `polygonOffset` to avoid z-fighting, and a `BufferAttribute` mask). Brush size slider in the toolbar; eraser toggle removes faces. OrbitControls disabled while painting.

## Acceptance criteria
- [ ] Drag paints a contiguous red region on the surface that follows the mesh
- [ ] Brush size visibly changes radius; eraser removes
- [ ] 60 fps while painting on the real model (Draco-decoded, ~500k tris — if too slow, paint on a decimated proxy)
- [ ] Faces persist as `faceIndices` and reload correctly (A5b)

## Blocked by
A3a

## Read first
`docs/guides/02-viewer-annotations-deep-dive.md §Paint regions (stretch)`

## Notes
This is the riskiest UI feature in the PRD. Time-box strictly. A half-working paint tool must not be in the demo; ship it or hide the button.

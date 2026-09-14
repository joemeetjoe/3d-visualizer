# A2a — Raycast pin placement

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 2h | H6 | todo |

## What to build
When `tool === 'pin'`, an `onClick` on the model group uses R3F's pointer event (`e.point`, `e.face.normal`, `e.object`) — R3F raycasts for you — to add a pin to `use-viewer-store` with `position`/`normal` converted into **model-local space** (invert the model root's `matrixWorld`), and a fresh uuid. A `<Pin>` component renders a small sphere (radius ~0.04 × model size) offset slightly along the normal so it doesn't z-fight, colored by severity (default `moderate` until the popover sets it). `e.stopPropagation()` so the floor/grid never receives the click. In `select` mode clicks do nothing. Pins re-render from the store (pure derived rendering — no imperative scene mutation).

## Acceptance criteria
- [ ] Click anywhere on the car in pin mode → a sphere appears exactly at the surface, on any side, including undersides
- [ ] Pins survive orbiting (they're children of the model group, not the camera)
- [ ] Clicking the grid/void places nothing
- [ ] Reload the page after A3a lands → pins reappear in the same spots (proves local-space math)
- [ ] 50 pins → no measurable fps drop

## Blocked by
A1b

## Unblocks
A2b, A2c

## Read first
`docs/guides/02-viewer-annotations-deep-dive.md §Raycasting and pins` — it has the exact local-space transform

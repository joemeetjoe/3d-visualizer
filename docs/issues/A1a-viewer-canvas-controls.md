# A1a — Viewer canvas: sample model, orbit/pan/zoom, fit, reset

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H2 | todo |

## What to build
`apps/web/src/viewer/Viewer.tsx`: an R3F `<Canvas>` filling its container, loading `/models/toycar.glb` with drei `useGLTF`, wrapped in drei `<Bounds fit clip observe margin={1.2}>` so any model frames correctly, drei `<OrbitControls makeDefault enableDamping>` (left drag orbit, right drag pan, wheel zoom — these are the defaults), double-click on empty space resets the camera (Bounds `refresh().fit()`), `<Suspense>` boundary. `Viewer` takes a `modelUrl` prop so C2b can pass the real one later. Model normalized: centered, on the floor (see CONTRACTS §6 — do this in the viewer defensively too).

## Acceptance criteria
- [ ] ToyCar renders, lit, 60 fps on a laptop, no console warnings
- [ ] Orbit/pan/zoom work with mouse; pinch/2-finger on a trackpad
- [ ] Double-click empty space re-frames the model
- [ ] Resizing the window keeps the canvas correct (no stretch)
- [ ] `<Viewer modelUrl="..."/>` is the only public API; no globals

## Blocked by
C0a (skeleton) — until then work in a scratch Vite app and move the folder over

## Unblocks
A1b, A1c, A2a, C2b

## Read first
`docs/guides/01-three-js-and-r3f.md` (all), `docs/guides/02-viewer-annotations-deep-dive.md §Setup`

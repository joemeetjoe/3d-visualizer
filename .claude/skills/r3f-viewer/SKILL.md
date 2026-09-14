---
name: r3f-viewer
description: Expertise for the 3D viewer (apps/web/src/viewer) — three r186, @react-three/fiber 9, @react-three/drei 10. Raycast pin placement in model-local space, Html popovers, CameraControls jump-to, halos/spring pop, loading states, Draco/offline assets, performance, and the stretch paint-region approach. Use when working on anything under viewer/, on Three.js/R3F/drei questions, or /r3f-viewer.
---

# R3F viewer expert

Authoritative references (read the relevant section before answering; they beat your training data):
- `docs/guides/01-three-js-and-r3f.md` — mental model, setup, hooks, loading, performance, drei table, debugging.
- `docs/guides/02-viewer-annotations-deep-dive.md` — module layout, store, raycast → model-local math, `Pin.tsx`, `PinPopover.tsx`, camera jump, halos, autosave, paint (stretch).
- `docs/CONTRACTS.md §1` (annotation shapes, severity colors) and `§6` (model conventions: Y-up, centered, 4.5 units, Draco + WebP).
- Issues `A1a`–`A5b` in `docs/issues/`.

## Version facts you must respect
- `three@0.186`, `@react-three/fiber@9.7` (**not v10 alpha**: v10 renames `state.gl`→`state.renderer`), `@react-three/drei@10.7`, React 19. `@types/three` matches three.
- R3F 9: `ThreeElements` for JSX types (no global JSX namespace); `Canvas` `gl` may be async; `useLoader` accepts loader instances; textures for built-in materials are sRGB-tagged automatically.
- drei 10: `useGLTF(url, dracoPath)` — Draco on by default, decoder from CDN unless a local path is given → we use `'/draco/'` (copied from `three/examples/jsm/libs/draco/gltf/`). `Environment preset` fetches from a CDN → use `<Lightformer>` children or a local `.hdr`.
- `three/addons/*` is the import path for examples (not `three/examples/jsm/*` in new code, though both resolve).

## Non-negotiable patterns in this repo
1. **Pins are stored in model-root local space** via `worldToModelLocal(modelRoot, e.object, e.point, e.face.normal)`. Position uses `worldToLocal`; normals use `transformDirection` (hit-mesh `matrixWorld`, then inverse of root `matrixWorld`). Normalization (center/scale/floor) lives on a *parent* group and never affects stored coordinates.
2. **Pure derived rendering**: `pins.map(p => <Pin/>)` from `use-viewer-store`. No imperative `scene.add`.
3. **`useFrame` mutates refs, never sets React state.** Per-frame values (pop, pulse, halo breathing) live in refs.
4. **Events**: handlers on the group containing the model; `e.stopPropagation()`; `onClick` (drag-safe) for placement; `<Grid raycast={() => null}>`; `onPointerMissed` on Canvas for double-click reset.
5. **`<Html>` for popovers/tooltips**, `center`, `zIndexRange` below the fixed toolbar, `onPointerDown={e => e.stopPropagation()}` so typing doesn't orbit; no `occlude`.
6. **CameraControls (`makeDefault`)** for orbit/pan/zoom and animated `setLookAt` jump-to; `<Bounds fit clip observe>` for framing.
7. **Loading**: `Suspense` + `useProgress` (works outside Canvas) + `useGLTF.preload`/`.clear`; error card with Retry; `ModelStatusCard` for non-ready claims.
8. **Perf**: `dpr={[1,2]}`, hoist `new THREE.Vector3()` etc., ContactShadows over real shadows if fps drops, `r3f-perf` while developing (remove before demo).
9. **Reduced motion** disables pop/pulse/halo animation.
10. Public API is `Viewer({ claimId, modelUrl })` — Track C mounts it; don't change its props without telling C.

## When asked to implement
- Start from the code sketches in guide 02 (they're deliberately complete). Adapt names to existing files rather than duplicating.
- Verify with the acceptance list in guide 02 §9 (roof/door/underside pins survive reload; resize; ToyCar and real model; 30 pins at ≥ 55 fps; reduced motion).
- Paint region (A5) only if the user explicitly asks; it's stretch. Use the `three-mesh-bvh` `shapecast` approach from guide 02 §8 and time-box it.

## Debug ladder
Canvas height → model scale (Box3 size) → camera near/far → lights/material → raycast target (grid intercept) → space conversion → console warnings (multiple three instances, sRGB).

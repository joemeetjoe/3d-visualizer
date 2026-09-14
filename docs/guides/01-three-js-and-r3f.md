# Guide 01 — Three.js, React Three Fiber, and drei (for people who've never done 3D)

**Versions this guide is written against (verified 2026-09-13):** `three@0.186`, `@react-three/fiber@9.7`, `@react-three/drei@10.7`, React 19.3. R3F **v10 is alpha** — do not use it; it renames `state.gl` → `state.renderer` and moves things. drei **v11** is likewise unreleased. If a blog post you find talks about `react-three-fiber` v8 or drei v9, the ideas still hold but types and a few props differ — prefer this guide.

## 0. Thirty-second mental model

A three.js app is a **scene graph** (a tree of `Object3D`s) rendered by a **camera** through a **renderer** onto a `<canvas>` every frame.

- **Mesh** = **Geometry** (the vertices/triangles) + **Material** (how the surface reacts to light). A car model is one or more meshes.
- **Lights** exist as objects in the scene; **materials** decide whether they care about lights (`MeshStandardMaterial` does; `MeshBasicMaterial` doesn't).
- **Units** are whatever you say they are. We say **1 unit = 1 metre** and a car is ~4.5 units long (CONTRACTS §6).
- **Y is up.** Z points toward the default camera. Right-handed.
- Everything has `position`, `rotation` (Euler, radians), `scale`, and a `matrixWorld` computed from its parents. **Local space** = coordinates relative to the object's parent. **World space** = absolute. Raycast hits come back in world space; we store pins in the model's local space (see guide 02).

**React Three Fiber (R3F)** is a React renderer for three.js: every three.js class becomes a JSX element (`<mesh>`, `<boxGeometry>`, `<meshStandardMaterial>`), props map to properties, and React reconciles the scene graph like it reconciles the DOM. You *declare* the scene; you don't `scene.add()` things.

**drei** is a bag of ready-made components and hooks for R3F (controls, loaders, grids, environments, HTML overlays). We use ~10 of them.

## 1. Setup in our app

```bash
pnpm --filter web add three@0.186 @react-three/fiber@9 @react-three/drei@10
pnpm --filter web add -D @types/three@0.186
```

`vite.config.ts` needs nothing special for three. Tailwind and R3F coexist; the `<Canvas>` fills whatever container you give it — **the container must have a real height** (`h-full` on a parent with `h-[calc(100vh-72px)]`), or you get a 0px canvas and blame three.js.

```tsx
// apps/web/src/viewer/Viewer.tsx — the smallest working viewer (A1a)
import { Suspense } from 'react';
import { Canvas } from '@react-three/fiber';
import { Bounds, CameraControls, ContactShadows, Environment, Grid, Lightformer, useGLTF } from '@react-three/drei';

function CarModel({ url }: { url: string }) {
  const { scene } = useGLTF(url, '/draco/');   // second arg: local Draco decoder path (see §5)
  return <primitive object={scene} />;
}

export function Viewer({ modelUrl }: { modelUrl: string }): JSX.Element {
  return (
    <Canvas
      camera={{ position: [6, 3, 6], fov: 45, near: 0.1, far: 200 }}
      dpr={[1, 2]}          // cap devicePixelRatio — retina laptops otherwise render 4× pixels
      shadows
      gl={{ antialias: true }}
    >
      <color attach="background" args={['#0F1117']} />
      <ambientLight intensity={0.25} />
      <directionalLight position={[5, 8, 5]} intensity={1.6} castShadow shadow-mapSize={[2048, 2048]} />
      {/* Synthetic studio environment — no network request, works offline at the venue */}
      <Environment resolution={256}>
        <Lightformer intensity={2} rotation-x={Math.PI / 2} position={[0, 4, -9]} scale={[10, 1, 1]} />
        <Lightformer intensity={2} rotation-y={Math.PI / 2} position={[-5, 1, -1]} scale={[10, 2, 1]} />
        <Lightformer intensity={2} rotation-y={-Math.PI / 2} position={[10, 1, 0]} scale={[20, 2, 1]} />
      </Environment>
      <Suspense fallback={null}>
        <Bounds fit clip observe margin={1.2}>
          <CarModel url={modelUrl} />
        </Bounds>
      </Suspense>
      <ContactShadows position={[0, 0.001, 0]} opacity={0.6} blur={2.5} far={8} resolution={1024} />
      <Grid infiniteGrid fadeDistance={40} fadeStrength={2} cellSize={0.5} sectionSize={2.5}
            cellColor="#1F2333" sectionColor="#2B3050" />
      <CameraControls makeDefault minDistance={1.5} maxDistance={40} />
    </Canvas>
  );
}
```

What each line does:
- `<Canvas>` creates the renderer, a default scene and camera, a resize observer, and the render loop. `camera` props set the initial camera. `dpr={[1,2]}` clamps pixel ratio.
- `<color attach="background">` — the `attach` prop assigns the object to a property of its parent (`scene.background`). You'll see `attach` for materials/geometries too (`<meshStandardMaterial>` auto-attaches to `mesh.material`).
- `<Environment>` gives image-based lighting so metallic paint looks like paint. `preset="city"` downloads an HDR from a CDN — **risky at a venue with flaky wifi** — so we build a synthetic one from `<Lightformer>`s (exactly what car-configurator sites do). If you want a real HDR, put a 1k `.hdr` from polyhaven.com in `public/hdr/` and use `<Environment files="/hdr/studio.hdr" />`.
- `<Suspense>` — `useGLTF` *suspends* while loading (React 19 native). Anything that loads must be inside a Suspense boundary.
- `<Bounds fit clip observe margin>` — measures its children and moves the camera so they fill the view. `observe` re-fits on resize. With `makeDefault` controls it also updates the controls' target. Calling `useBounds().refresh().fit()` re-frames (double-click reset).
- `<primitive object={scene}>` — puts an existing three.js object (the loaded glTF scene) into the JSX tree.
- `<CameraControls makeDefault>` — drei's wrapper around the `camera-controls` library. Left-drag orbit, right-drag pan (truck), wheel dolly, 1-finger/2-finger/pinch on touch — exactly the PRD's control table, with smooth damping, and a `setLookAt(...)` API that animates (used for "jump to pin"). `makeDefault` registers it so `Bounds` and other helpers can find it. `<OrbitControls>` is the classic alternative — same defaults, no built-in animated transitions.
- `<Grid>` — drei's shader grid; `infiniteGrid` + `fadeDistance` gives the "subtle grid floor in a dark void" from PRD §13.
- `<ContactShadows>` — a fake, cheap soft shadow blob under the model. Looks better than real shadows for this.

## 2. The hooks you'll actually use

```tsx
import { useFrame, useThree, type ThreeEvent } from '@react-three/fiber';
```

- `useFrame((state, delta) => { ... })` — runs every frame **inside** the render loop. Use for animation (pulse, spring pop). Never `setState` in here; mutate refs (`ref.current.scale.setScalar(...)`). `state.clock.elapsedTime` for time; `delta` for frame-rate-independent motion.
- `useThree()` — access `camera`, `scene`, `gl` (the WebGLRenderer), `size`, `raycaster`, `controls`, `invalidate`. Select what you need: `const camera = useThree((s) => s.camera)`.
- `useLoader(GLTFLoader, url)` — generic loader hook; `useGLTF` from drei wraps it with Draco/KTX2 support and caching.
- Pointer events on any object: `onClick`, `onPointerOver/Out/Move/Down/Up`, `onDoubleClick`, `onContextMenu` (right-click). R3F raycasts from the mouse **for you** and calls the handler on the hit object; events **bubble** up the JSX tree, so a handler on a `<group>` sees clicks on all child meshes. `e.stopPropagation()` stops both bubbling and hitting objects *behind* this one. The event carries `e.point` (world-space hit), `e.face` (with `.normal` in the object's local space), `e.faceIndex`, `e.object`, `e.distance`, `e.nativeEvent`, `e.delta` (pixels moved since pointerdown — `onClick` is suppressed automatically if the pointer dragged more than a couple of pixels, so orbiting doesn't "click").

Rule: **everything that touches three.js objects lives inside `<Canvas>` children**; hooks like `useFrame`/`useThree` throw outside. UI (toolbar, sidebar, popover text inputs) is regular React **outside** the canvas, or inside via drei's `<Html>` (guide 02).

## 3. State: Zustand outside, refs inside

- Keep annotation data, tool mode, and save state in `use-viewer-store.ts` (Zustand 5). Components inside the canvas subscribe with selectors: `const pins = useViewerStore((s) => s.pins)`. Rendering pins is then pure: `pins.map((p) => <Pin key={p.id} pin={p} />)`.
- Per-frame animation state (pulse phase, pop scale) lives in `useRef` and `useFrame`, never in the store.
- Zustand 5: selectors that return new objects each call cause re-renders; wrap with `useShallow` from `zustand/react/shallow` or select primitives.

## 4. Materials, colors, and "why does my red look pink"

- three r152+ uses **sRGB output color management** by default; R3F 9 sets `THREE.ColorManagement.enabled = true` and `renderer.outputColorSpace = SRGBColorSpace`. Just pass hex strings (`color="#F7604F"`) and they look right.
- Color textures loaded through `GLTFLoader` are tagged sRGB automatically. If you create a texture yourself (canvas halo, etc.) and it's *color*, set `texture.colorSpace = THREE.SRGBColorSpace`; data textures (masks) stay linear.
- Severity colors on pins: `<meshStandardMaterial color={c} emissive={c} emissiveIntensity={0.6} />` — emissive makes them readable in the dark void; `toneMapped={false}` keeps neon hues from being flattened.
- Semi-transparent overlay: `transparent opacity={0.4} depthWrite={false}` and, to avoid z-fighting with the surface underneath, `polygonOffset polygonOffsetFactor={-1}`.

## 5. Loading glTF/GLB

- `useGLTF(url)` returns `{ scene, nodes, materials, animations }`. We render `scene` whole via `<primitive>`; we don't need `nodes`.
- **Draco**: our models are Draco-compressed (Track D, `gltf-transform optimize --compress draco`). drei's `useGLTF` enables Draco by default and fetches the decoder from Google's CDN **only if needed** — at a venue with no wifi that's a failed load. Copy the decoder locally once: `cp -r node_modules/three/examples/jsm/libs/draco/gltf/ apps/web/public/draco/` and call `useGLTF(url, '/draco/')`. Do this in A1a.
- **Preload**: `useGLTF.preload(url, '/draco/')` as soon as you know the URL (e.g., when the claim resolves) so the viewer appears faster.
- **Cache**: loaded models are cached by URL. After a retry on a failed load, call `useGLTF.clear(url)` before re-mounting.
- **Progress**: `import { useProgress } from '@react-three/drei'` → `const { progress, active, errors } = useProgress()`; it works **outside** the Canvas too, so the overlay progress bar is plain React. The browser can only report progress if the server sends `Content-Length` (issue C4c).
- **Big models**: 500k–1M triangles renders fine on a laptop. What hurts is *texture size* (keep ≤ 2048², WebP) and *draw calls* (many meshes). One mesh, one material is ideal — Track D's export does that.
- **Model normalization**: don't trust incoming orientation/scale. Wrap the primitive in a `<group>` and, in a `useLayoutEffect`, compute `new THREE.Box3().setFromObject(scene)`, then set the group's `position` to `-center` (and `y` so the min sits on 0) and `scale` to `4.5 / maxDimension`. `<Bounds>` only moves the camera; this moves the model. Track D also normalizes on export, so this is belt-and-braces.

## 6. Performance checklist (do these, then stop worrying)

1. `dpr={[1, 2]}` on Canvas.
2. Shadows: one `directionalLight castShadow` with `shadow-mapSize={[2048,2048]}`, or skip real shadows and use `<ContactShadows>` only (cheaper, looks great).
3. Don't create objects in render: `new THREE.Vector3()` inside a component body allocates every render. Hoist to module scope or `useMemo`.
4. `useFrame` must not `setState`. Mutate refs.
5. Pins: a `<mesh>` per pin is fine up to a few hundred. Only reach for `<Instances>` (drei) if you exceed that.
6. `<Canvas frameloop="demand">` + `invalidate()` cuts GPU use when nothing moves — but pulsing halos need `"always"`. Leave default.
7. Devtools: `pnpm add -D r3f-perf` and drop `<Perf />` inside the canvas while developing (remove before demo). React DevTools shows the R3F tree.

## 7. TypeScript with R3F 9

- JSX intrinsic types come from `ThreeElements` (R3F 9 dropped the global JSX namespace hack). For plain usage you write nothing. If you `extend()` a custom class:
  ```ts
  import { extend, type ThreeElement } from '@react-three/fiber';
  extend({ MyThing });
  declare module '@react-three/fiber' { interface ThreeElements { myThing: ThreeElement<typeof MyThing> } }
  ```
- Event handler type: `(e: ThreeEvent<MouseEvent>) => void` (`ThreeEvent<PointerEvent>` for pointer events).
- Refs: `useRef<THREE.Mesh>(null)`, `useRef<THREE.Group>(null)`; drei controls: `useRef<CameraControls>(null)` (import the type from `@react-three/drei`).
- `@types/three` version must match `three` (0.186 ↔ 0.186).

## 8. drei components we use — quick reference

| Component / hook | What | Props we care about |
|---|---|---|
| `useGLTF(url, dracoPath?)` | Load GLB with cache + Draco | returns `{ scene }`; `.preload`, `.clear` |
| `useProgress()` | Global load progress | `progress` 0..100, `active`, `errors` |
| `<CameraControls makeDefault>` | Orbit/pan/zoom with animated API | `minDistance`, `maxDistance`, `setLookAt(px,py,pz,tx,ty,tz,enableTransition)`, `fitToBox(obj, true)`, `enabled` (false while painting) |
| `<OrbitControls makeDefault>` | Simpler alternative | `enableDamping`, `enablePan` |
| `<Bounds fit clip observe margin>` + `useBounds()` | Frame children | `refresh().fit()` for reset |
| `<Grid>` | Shader grid floor | `infiniteGrid`, `fadeDistance`, `cellSize`, `sectionSize`, `cellColor`, `sectionColor` |
| `<Environment>` + `<Lightformer>` | Image-based lighting | `preset` (network) / `files` (local) / children (synthetic) |
| `<ContactShadows>` | Soft fake shadow | `opacity`, `blur`, `far`, `resolution` |
| `<Html>` | DOM overlay anchored in 3D | `position`, `center`, `distanceFactor`, `occlude`, `zIndexRange`, `style`, `className` |
| `<Sphere>`, `<Billboard>`, `<Sprite>` | Convenience meshes | — |
| `<Center>` | Centers children | alternative to manual Box3 math |
| `<Stats>` / `r3f-perf` | FPS overlay | dev only |

## 9. Debugging tricks

- Nothing renders: check the container has height; check the camera isn't *inside* the model (`near`/position); check the model's scale (a 0.001-unit car is invisible; log `new Box3().setFromObject(scene).getSize(new Vector3())`).
- Black model: no lights or a material that ignores lights on a black background; add `<ambientLight>` temporarily or set `<meshNormalMaterial>` to see geometry.
- Clicks land on the wrong thing / nothing: the grid or floor plane is intercepting — give the grid `raycast={() => null}`; make sure the handler is on the group *containing* the meshes.
- Textures missing after Draco optimize: check `gltf-transform inspect` — WebP textures need a browser that decodes WebP (all do) and `useGLTF` handles the `EXT_texture_webp` extension automatically.
- "Multiple instances of three" warning: two versions in `node_modules` — `pnpm why three` and pin.
- Suspense infinite loop: the URL changes on every render (new string built inline) → memoize the URL.

## 10. Where to read more (official, current)

- R3F docs: https://r3f.docs.pmnd.rs (v9 migration guide: `/tutorials/v9-migration-guide`)
- drei README: https://github.com/pmndrs/drei (each component has TSDoc in v10)
- three.js manual + docs: https://threejs.org/manual and https://threejs.org/docs — search by class name (`Raycaster`, `Box3`, `BufferGeometry`)
- camera-controls API (behind drei's `CameraControls`): https://github.com/yomotsu/camera-controls
- Sample models: https://github.com/KhronosGroup/glTF-Sample-Assets (ToyCar)

# Guide 02 — The viewer module: raycasting, pins, popovers, camera tweens, halos, paint

Companion to guide 01. This is the Track A blueprint: read it top to bottom once, then keep it open. Versions: three r186, R3F 9.7, drei 10.7.

## 1. Module layout (`apps/web/src/viewer/`)

```
viewer/
  Viewer.tsx              <Canvas> + scene composition; the only export other tracks use
  scene/
    CarModel.tsx          useGLTF + normalization group + click/paint handlers
    SceneDressing.tsx     lights, environment, grid, contact shadows
    Pins.tsx              maps store.pins → <Pin/>
    Pin.tsx               sphere + halo + pop animation + hover/click
    PinPopover.tsx        drei <Html> editor (note + severity)
    PaintOverlay.tsx      (stretch) region overlay mesh
  ui/
    Toolbar.tsx           glass toolbar (outside canvas)
    Sidebar.tsx           annotation list (outside canvas)
    SaveIndicator.tsx     Saved / Saving… / Retry
    ModelStatusCard.tsx   "still processing" (used by C2b when not ready)
    LoadingOverlay.tsx    skeleton + progress bar (useProgress)
  hooks/
    use-viewer-store.ts   Zustand store (below)
    use-autosave.ts       debounced PUT (A3a)
    use-camera-jump.ts    jump-to-pin using CameraControls
    use-reduced-motion.ts matchMedia('(prefers-reduced-motion: reduce)')
  lib/
    space.ts              world ↔ model-local conversions
    severity.ts           color map (re-export from shared-types)
    export.ts             AnnotationExport builder (A3b)
```

`Viewer.tsx` signature (frozen for C2b): `export function Viewer(props: { claimId: string; modelUrl: string }): JSX.Element`.

## 2. The store

```ts
// hooks/use-viewer-store.ts
import { create } from 'zustand';
import type { Annotation, PinAnnotation, RegionAnnotation, Severity } from '@vdv/shared-types';

export type Tool = 'select' | 'pin' | 'paint';
export type SaveState = 'idle' | 'dirty' | 'saving' | 'saved' | 'error';

interface ViewerState {
  tool: Tool;
  pins: PinAnnotation[];
  regions: RegionAnnotation[];
  activePinId: string | null;     // popover open for this pin
  hoveredPinId: string | null;
  selectedPinId: string | null;   // highlighted from the sidebar
  saveState: SaveState;
  brushRadius: number;            // paint (stretch)
  eraser: boolean;

  setTool: (t: Tool) => void;
  hydrate: (a: Annotation[]) => void;
  addPin: (p: PinAnnotation) => void;
  updatePin: (id: string, patch: Partial<Pick<PinAnnotation, 'note' | 'severity'>>) => void;
  removePin: (id: string) => void;
  setActivePin: (id: string | null) => void;
  setHovered: (id: string | null) => void;
  setSelected: (id: string | null) => void;
  setSaveState: (s: SaveState) => void;
  allAnnotations: () => Annotation[];
}

export const useViewerStore = create<ViewerState>()((set, get) => ({
  tool: 'select', pins: [], regions: [], activePinId: null, hoveredPinId: null, selectedPinId: null,
  saveState: 'idle', brushRadius: 0.15, eraser: false,
  setTool: (tool) => set({ tool, activePinId: null }),
  hydrate: (a) => set({
    pins: a.filter((x): x is PinAnnotation => x.type === 'pin'),
    regions: a.filter((x): x is RegionAnnotation => x.type === 'region'),
    saveState: 'saved',
  }),
  addPin: (p) => set((s) => ({ pins: [...s.pins, p], activePinId: p.id, saveState: 'dirty' })),
  updatePin: (id, patch) => set((s) => ({ pins: s.pins.map((p) => (p.id === id ? { ...p, ...patch } : p)), saveState: 'dirty' })),
  removePin: (id) => set((s) => ({ pins: s.pins.filter((p) => p.id !== id), activePinId: null, saveState: 'dirty' })),
  setActivePin: (activePinId) => set({ activePinId }),
  setHovered: (hoveredPinId) => set({ hoveredPinId }),
  setSelected: (selectedPinId) => set({ selectedPinId }),
  setSaveState: (saveState) => set({ saveState }),
  allAnnotations: () => [...get().pins, ...get().regions],
}));
```

Every mutation sets `saveState: 'dirty'`; `use-autosave.ts` subscribes to `pins`/`regions` and debounces the PUT (§7).

## 3. Raycasting and pins (A2a) — the part that trips everyone

R3F already raycasts on every pointer event. You get a `ThreeEvent` with the hit. The only hard part is **which space to store coordinates in**.

We store pins in the **model root's local space** (the `<group ref={modelRoot}>` that directly contains the glTF `<primitive>`). That space is stable across sessions, across viewer normalization changes, and across whatever `<Bounds>` does to the camera. It is *not* affected by the normalization group we wrap around it, because that's the parent.

```tsx
// scene/CarModel.tsx
import { useLayoutEffect, useRef } from 'react';
import * as THREE from 'three';
import { useGLTF } from '@react-three/drei';
import type { ThreeEvent } from '@react-three/fiber';
import { useViewerStore } from '../hooks/use-viewer-store';
import { worldToModelLocal } from '../lib/space';

const TARGET_SIZE = 4.5;

export function CarModel({ url }: { url: string }): JSX.Element {
  const { scene } = useGLTF(url, '/draco/');
  const normGroup = useRef<THREE.Group>(null);
  const modelRoot = useRef<THREE.Group>(null);
  const tool = useViewerStore((s) => s.tool);
  const addPin = useViewerStore((s) => s.addPin);

  // Normalize: center on origin, sit on y=0, longest side = TARGET_SIZE. Display only — pins stay in modelRoot space.
  useLayoutEffect(() => {
    const box = new THREE.Box3().setFromObject(scene);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    const s = TARGET_SIZE / Math.max(size.x, size.y, size.z);
    normGroup.current!.scale.setScalar(s);
    normGroup.current!.position.set(-center.x * s, -box.min.y * s, -center.z * s);
    scene.traverse((o) => { if ((o as THREE.Mesh).isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  }, [scene]);

  const onClick = (e: ThreeEvent<MouseEvent>): void => {
    if (tool !== 'pin' || !e.face) return;
    e.stopPropagation();                       // don't also hit the grid / objects behind
    const { position, normal } = worldToModelLocal(modelRoot.current!, e.object, e.point, e.face.normal);
    addPin({
      id: crypto.randomUUID(), type: 'pin', position, normal,
      severity: 'moderate', note: '', createdAt: new Date().toISOString(),
    });
  };

  return (
    <group ref={normGroup}>
      <group ref={modelRoot} onClick={onClick}>
        <primitive object={scene} />
        {/* Pins render here so they inherit modelRoot's space */}
        <Pins modelRoot={modelRoot} />
      </group>
    </group>
  );
}
```

```ts
// lib/space.ts
import * as THREE from 'three';
import type { Vec3 } from '@vdv/shared-types';

const tmpM = new THREE.Matrix4();
const tmpV = new THREE.Vector3();

/** Convert a raycast hit (world point + local face normal of the hit mesh) into modelRoot-local space. */
export function worldToModelLocal(
  modelRoot: THREE.Object3D, hitObject: THREE.Object3D, worldPoint: THREE.Vector3, faceNormalLocal: THREE.Vector3,
): { position: Vec3; normal: Vec3 } {
  // Point: world → modelRoot local
  const p = modelRoot.worldToLocal(worldPoint.clone());
  // Normal: hit-mesh local → world (rotation only) → modelRoot local (rotation only)
  const nWorld = faceNormalLocal.clone().transformDirection(hitObject.matrixWorld);
  tmpM.copy(modelRoot.matrixWorld).invert();
  const n = nWorld.transformDirection(tmpM).normalize();
  return { position: { x: p.x, y: p.y, z: p.z }, normal: { x: n.x, y: n.y, z: n.z } };
}

export function modelLocalToWorld(modelRoot: THREE.Object3D, local: Vec3): THREE.Vector3 {
  return modelRoot.localToWorld(tmpV.set(local.x, local.y, local.z).clone());
}
```

Why `transformDirection` twice: `e.face.normal` is in the **hit mesh's** local space (glTF nodes often have their own transforms); `transformDirection(matrixWorld)` rotates it to world without translating; then the inverse of the model root's world matrix brings it into root space. Positions use `worldToLocal`, which includes translation/scale. Get this wrong and pins reload in the wrong place after a refresh — the acceptance test in A2a exists for exactly this.

Grid interference: give the drei `<Grid raycast={() => null} />` so it never intercepts clicks, or make the click handler ignore hits whose `e.object` isn't a descendant of `modelRoot`.

### The pin itself

```tsx
// scene/Pin.tsx
import { useRef } from 'react';
import * as THREE from 'three';
import { useFrame, type ThreeEvent } from '@react-three/fiber';
import type { PinAnnotation } from '@vdv/shared-types';
import { SEVERITY_COLOR } from '@vdv/shared-types';
import { useViewerStore } from '../hooks/use-viewer-store';
import { useReducedMotion } from '../hooks/use-reduced-motion';

export function Pin({ pin, radius }: { pin: PinAnnotation; radius: number }): JSX.Element {
  const mesh = useRef<THREE.Mesh>(null);
  const tool = useViewerStore((s) => s.tool);
  const isActive = useViewerStore((s) => s.activePinId === pin.id);
  const isSelected = useViewerStore((s) => s.selectedPinId === pin.id);
  const { setActivePin, setHovered, removePin } = useViewerStore.getState();
  const reduced = useReducedMotion();
  const born = useRef(performance.now());
  const color = SEVERITY_COLOR[pin.severity];

  useFrame(({ clock }) => {
    if (!mesh.current) return;
    // spring pop on mount (~300ms), then optional pulse for total_loss
    const t = (performance.now() - born.current) / 300;
    const pop = reduced ? 1 : t < 1 ? 1 + Math.sin(t * Math.PI) * 0.35 * (1 - t) : 1;
    const pulse = !reduced && pin.severity === 'total_loss' ? 1 + Math.sin(clock.elapsedTime * 4) * 0.08 : 1;
    mesh.current.scale.setScalar(pop * pulse * (isSelected ? 1.3 : 1));
  });

  // Offset a hair along the normal so the sphere isn't half-buried
  const pos: [number, number, number] = [
    pin.position.x + pin.normal.x * radius * 0.5,
    pin.position.y + pin.normal.y * radius * 0.5,
    pin.position.z + pin.normal.z * radius * 0.5,
  ];

  return (
    <group position={pos}>
      <mesh
        ref={mesh}
        onClick={(e: ThreeEvent<MouseEvent>) => { if (tool === 'pin') return; e.stopPropagation(); setActivePin(pin.id); }}
        onContextMenu={(e) => { e.stopPropagation(); e.nativeEvent.preventDefault(); if (confirm('Delete this pin?')) removePin(pin.id); }}
        onPointerOver={(e) => { e.stopPropagation(); setHovered(pin.id); document.body.style.cursor = 'pointer'; }}
        onPointerOut={() => { setHovered(null); document.body.style.cursor = 'auto'; }}
      >
        <sphereGeometry args={[radius, 24, 24]} />
        <meshStandardMaterial color={color} emissive={color} emissiveIntensity={0.7} toneMapped={false} />
      </mesh>
      <Halo color={color} severity={pin.severity} radius={radius} />
      {isActive && <PinPopover pin={pin} />}
    </group>
  );
}
```

`radius`: compute once in `Pins.tsx` from the raw model's bounding box: `maxDim * 0.012` (so pins look the same size on any model). Note `confirm()` blocks — fine for the jam; replace with a toolbar-level dialog if you have time (Claude in Chrome can't drive `confirm()` dialogs if you test with it).

## 4. `<Html>` popovers and tooltips (A2b)

drei's `<Html>` renders DOM children positioned at a 3D point. Put it inside the pin group so it follows the pin.

```tsx
// scene/PinPopover.tsx
import { Html } from '@react-three/drei';
import { SEVERITIES, type PinAnnotation } from '@vdv/shared-types';
import { useViewerStore } from '../hooks/use-viewer-store';

export function PinPopover({ pin }: { pin: PinAnnotation }): JSX.Element {
  const { updatePin, setActivePin, removePin } = useViewerStore.getState();
  return (
    <Html position={[0, 0.12, 0]} center zIndexRange={[50, 0]} style={{ pointerEvents: 'auto' }}>
      <div className="w-72 rounded-xl border border-white/10 bg-surface-elevated/90 p-3 shadow-2xl backdrop-blur-md"
           onPointerDown={(e) => e.stopPropagation()}   /* don't start an orbit when clicking the popover */>
        <textarea autoFocus className="..." value={pin.note} placeholder="Describe the damage…"
                  onChange={(e) => updatePin(pin.id, { note: e.target.value })}
                  onKeyDown={(e) => { if (e.key === 'Escape') setActivePin(null); }} />
        <div className="mt-2 grid grid-cols-4 gap-1">
          {SEVERITIES.map((s) => (
            <button key={s} data-active={pin.severity === s} onClick={() => updatePin(pin.id, { severity: s })}>{label(s)}</button>
          ))}
        </div>
        <div className="mt-2 flex justify-between">
          <button onClick={() => { if (confirm('Delete pin?')) removePin(pin.id); }}>Delete</button>
          <button onClick={() => setActivePin(null)}>Done</button>
        </div>
      </div>
    </Html>
  );
}
```

Notes:
- `center` centers the DOM element on the anchor; offset `position` upward a bit so it sits above the sphere.
- `zIndexRange` keeps popovers above the canvas but below your fixed toolbar (which should have a higher z-index).
- Leave `occlude` off — occlusion with a big mesh flickers and the popover should always be readable.
- `distanceFactor` scales the DOM with distance (perspective) — nice for tooltips, bad for text inputs. Tooltip (hover preview) can use `<Html distanceFactor={6}>` and a tiny card.
- Typing in the textarea: keyboard shortcuts (A4b) must check `document.activeElement` is not an input.
- Edge flipping: `<Html>` doesn't flip automatically. Cheap fix: `calculatePosition` prop or just let it clip; better: a `useThree(size)` + the pin's screen position (`vector.project(camera)`) to add a `left/right` class. Do the cheap thing unless it shows up in rehearsal.

## 5. Sidebar ↔ scene, and camera "jump to" (A2c)

Sidebar is plain React outside the canvas reading the store. Highlight is two-way through `selectedPinId`/`hoveredPinId`.

Jump-to with drei `CameraControls` (this is why we chose it over OrbitControls):

```ts
// hooks/use-camera-jump.ts
import * as THREE from 'three';
import { useThree } from '@react-three/fiber';
import type { CameraControls } from '@react-three/drei';
import type { PinAnnotation } from '@vdv/shared-types';
import { modelLocalToWorld } from '../lib/space';

export function useCameraJump(modelRoot: React.RefObject<THREE.Object3D | null>) {
  const controls = useThree((s) => s.controls) as CameraControls | null;
  return (pin: PinAnnotation, distance = 1.8): void => {
    if (!controls || !modelRoot.current) return;
    const target = modelLocalToWorld(modelRoot.current, pin.position);
    const n = new THREE.Vector3(pin.normal.x, pin.normal.y, pin.normal.z)
      .transformDirection(modelRoot.current.matrixWorld).normalize();
    const eye = target.clone().addScaledVector(n, distance).add(new THREE.Vector3(0, 0.3, 0)); // slightly above
    void controls.setLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, true); // true = animate
  };
}
```

The hook must be used inside the Canvas (it uses `useThree`). Expose the function to the sidebar via the store (`setJumpFn`) or a small event emitter; simplest: a `jumpRequestId` in the store that a `<CameraRig>` component inside the canvas watches with `useEffect`.

Camera reset (double-click on empty space): a `<mesh>` covering nothing — instead use `onPointerMissed` on `<Canvas>` (fires when a click hits nothing) with `e.detail === 2` check for double-click, then `useBounds().refresh().fit()` or `controls.fitToBox(modelRoot.current, true)`.

## 6. Halos and motion (A4a)

Cheap, good-looking halo: an additive sprite with a radial-gradient texture, scaled by severity.

```tsx
const haloTexture = (() => {
  const c = document.createElement('canvas'); c.width = c.height = 128;
  const g = c.getContext('2d')!;
  const grad = g.createRadialGradient(64, 64, 0, 64, 64, 64);
  grad.addColorStop(0, 'rgba(255,255,255,0.9)'); grad.addColorStop(0.4, 'rgba(255,255,255,0.25)'); grad.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = grad; g.fillRect(0, 0, 128, 128);
  const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; return t;
})();

const HALO_SCALE: Record<Severity, number> = { minor: 3, moderate: 4, severe: 5.5, total_loss: 7 };

function Halo({ color, severity, radius }: { color: string; severity: Severity; radius: number }) {
  const s = radius * HALO_SCALE[severity];
  return (
    <sprite scale={[s, s, 1]}>
      <spriteMaterial map={haloTexture} color={color} transparent depthWrite={false} blending={THREE.AdditiveBlending} opacity={0.7} />
    </sprite>
  );
}
```

Sprites always face the camera, so no billboard code. If you want true bloom, `@react-three/postprocessing` `<EffectComposer><Bloom luminanceThreshold={1} mipmapBlur/></EffectComposer>` with `emissiveIntensity` > 1 and `toneMapped={false}` — only if fps stays at 60; it costs a full-screen pass.

Spring pop is in `Pin.tsx` above (pure `useFrame`, no library). `@react-spring/three` is the library route if you prefer declarative springs.

Reduced motion: `const reduced = useSyncExternalStore(subscribe, () => matchMedia('(prefers-reduced-motion: reduce)').matches)`; disable pop, pulse, halo breathing, and CSS transitions.

## 7. Auto-save (A3a)

```ts
// hooks/use-autosave.ts
import { useEffect, useRef } from 'react';
import { useViewerStore } from './use-viewer-store';
import { putAnnotations } from '../../api/annotations';

export function useAutosave(claimId: string, delayMs = 2000): void {
  const timer = useRef<number | null>(null);
  useEffect(() => useViewerStore.subscribe((s, prev) => {
    if (s.pins === prev.pins && s.regions === prev.regions) return;
    if (timer.current) window.clearTimeout(timer.current);
    timer.current = window.setTimeout(async () => {
      const { allAnnotations, setSaveState } = useViewerStore.getState();
      setSaveState('saving');
      try { await putAnnotations(claimId, allAnnotations()); setSaveState('saved'); }
      catch { setSaveState('error'); }
    }, delayMs);
  }), [claimId, delayMs]);
}
```

Manual Save = same body with `delayMs = 0`. `beforeunload` guard when `saveState === 'dirty' | 'saving'`. Hydrate on mount with `GET` → `hydrate()`; render nothing interactive until hydrated so a stray click doesn't overwrite the server with an empty set.

## 8. Paint regions (A5a/A5b — stretch)

Plan before touching it. The problem: as the pointer drags across the mesh, collect all triangles within a radius of the hit point, and render them tinted.

**Collect faces.** Install `three-mesh-bvh` (MIT). On model load, for the (single) mesh: `geometry.computeBoundsTree()` (from `three-mesh-bvh`, which patches `BufferGeometry`). Also set `THREE.Mesh.prototype.raycast = acceleratedRaycast` — raycasts on a 500k-tri mesh go from ~10ms to <1ms, which also helps pins. On `onPointerMove` with `e.buttons === 1` in paint mode:

```ts
const sphere = new THREE.Sphere(e.point.clone(), brushRadiusWorld);
const inv = new THREE.Matrix4().copy(mesh.matrixWorld).invert();
sphere.applyMatrix4(inv);                   // to mesh local space
const hits = new Set<number>();
geometry.boundsTree!.shapecast({
  intersectsBounds: (box) => box.intersectsSphere(sphere),
  intersectsTriangle: (tri, triIndex) => { if (tri.intersectsSphere(sphere)) hits.add(triIndex); return false; },
});
```

`triIndex` here is the triangle index in the (indexed) geometry — that's what `RegionAnnotation.faceIndices` stores. Non-indexed geometry: `gltf-transform` output is indexed; if not, `BufferGeometryUtils.mergeVertices` first.

**Render the tint.** Simplest robust approach: a second `<mesh>` sharing the same geometry, `MeshBasicMaterial({ color: region.color, transparent, opacity, depthWrite: false, polygonOffset: true, polygonOffsetFactor: -2 })`, and a `float` attribute `mask` (1 per vertex of a selected triangle, else 0) that a tiny `onBeforeCompile` shader chunk uses to `discard` unmasked fragments. Alternative without shaders: build a `BufferGeometry` from just the selected triangles each stroke end (cheap enough for a few thousand faces). Disable `CameraControls` (`enabled={tool !== 'paint' || !painting}`) while dragging.

**Eraser** = same collection, `delete` from the set. **Brush size** slider → world radius = `modelMaxDim * sliderValue`.

Time-box: if the collect+render loop isn't working in 90 minutes, hide the Paint button and move on. A hidden feature costs nothing; a broken one costs the demo.

## 9. Acceptance-test yourself before calling an issue done

- Place a pin on the roof, a door, and the underside. Orbit 360°. Reload. All three exactly where they were.
- Resize the window to half width. Popover still readable. Pins still on the surface.
- Load ToyCar, then the real demo model. No code change needed; pin size sensible on both.
- 30 pins + halos: DevTools performance → ≥ 55 fps on a MacBook Air.
- Turn on "Reduce motion" in OS settings: no pop, no pulse.

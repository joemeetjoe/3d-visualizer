# Guide 08 — The 30 things that will cost you an hour if you don't know them

Ordered roughly by how likely they are to bite. Each has the fix and where it's detailed.

## Infrastructure / setup
1. **Camera doesn't open on the phone** → not HTTPS. Use the tunnel URL, never the LAN IP. (03 §2)
2. **Tunnel URL gives 403 "Blocked request. This host is not allowed"** → Vite 8 `server.allowedHosts: ['.trycloudflare.com']`. (06 §1)
3. **QR code opens localhost on the phone** → `PUBLIC_WEB_URL` in `apps/api/.env` is still `http://localhost:5173`; set it to the tunnel URL. (CONTRACTS §7)
4. **`react-router-dom` not found** → it's gone in v8; import from `react-router`. (06 §4)
5. **`typescript-eslint` crashes / editor weird** → TypeScript 7 installed; pin `~6.0.3`. (SETUP)
6. **Node 20 errors from React Router / Vite** → need Node ≥ 22.22. (SETUP)
7. **Zustand infinite render loop** → selector returns a new object; use `useShallow`. (06 §6)
8. **Two `three` instances warning** → `pnpm why three`; pin drei/fiber/three versions per SETUP.
9. **RunPod: `docker: command not found`** → pods are containers; use the Meshroom tarball or EC2/Lambda. (SETUP §Track D)
10. **Meshroom Docker pull takes forever** → 16 GB; start it at H0 in a `tmux`.

## Viewer
11. **Canvas is 0 px tall** → parent needs an explicit height. (01 §1)
12. **Model invisible** → scale (log Box3 size) or camera inside model; ToyCar is small. (01 §9)
13. **Pins in the wrong place after reload** → stored world coords instead of model-local; use `worldToModelLocal`. (02 §3)
14. **Clicks place pins on the grid** → `<Grid raycast={() => null}>` or check `e.object` ancestry. (02 §3)
15. **Orbit drag places a pin** → use `onClick` (R3F suppresses it after drags), not `onPointerUp`.
16. **Model loads but no textures / black at venue** → Draco decoder or HDR fetched from a CDN with no wifi; local `/draco/` + synthetic `<Lightformer>` environment. (01 §1, §5)
17. **Popover text input steals shortcuts** → check `document.activeElement` before handling keys. (02 §4)
18. **`useFrame` + `setState` = 3 fps** → mutate refs. (01 §2)
19. **Pin popover behind the toolbar** → `zIndexRange` vs toolbar z-index. (02 §4)

## Capture
20. **iOS shows a black video** → missing `playsInline`/`muted`/`autoPlay` or `play()` not from a user gesture. (03 §3)
21. **Captured image is tiny** → drew at CSS size; use `videoWidth × videoHeight`. (03 §5)
22. **iOS only gives 720p/1080p** → expected; measure it; use anchor mode with `<input capture>` for full-res if needed. (03 §4)
23. **`ImageCapture is not defined`** → Safari; use canvas path. (03 §4)
24. **Screen dims mid-walk** → wake lock. (03 §7)
25. **Photos pile up in memory, tab crashes** → don't keep Blobs in React state; release after upload. (03 §9)
26. **Reload re-prompts for camera and loses session** → don't reload; keep the flow in one route.

## Pipeline
27. **SfM reconstructs only a few cameras** → overlap/blank frames; reshoot smaller steps; `describerPreset=high`. (04 §10)
28. **Mesh includes the parking lot** → largest-component + crop in `normalize.py`; `MeshFiltering.keepLargestMeshOnly`. (04 §7)
29. **Model sideways in viewer** → up-vector sign; `--flip-up`. (04 §7)
30. **obj2gltf can't read EXR** → set Meshroom texture output to PNG. (04 §6)

## Process
31. **Someone's been silent for 3 hours** → that's the signal to swarm. Ask in chat; integration lead checks in every 2 hours.
32. **"Let me just refactor this quickly"** at H15 → no. Feature freeze is H16. Write it in P0.

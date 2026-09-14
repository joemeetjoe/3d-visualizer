# Learning paths — what to read, in what order, per track

Each path is ~60–90 minutes of reading + exercises. Do the reading *tonight or on the way in*, and the exercises in your first hour. Use `/jam-teach <topic>` in Claude Code to have concepts explained in the context of this project.

## Everyone (30 min)
1. `docs/DECISIONS.md` — 10 min
2. `docs/CONTRACTS.md` — 15 min. You should be able to say what `ClaimStatus` values exist and what `PUT /annotations` does.
3. `docs/guides/08-gotchas.md` — skim, 5 min. You'll come back to it.

## Track A — Viewer
| Step | Read | Time | Exercise (20 min) |
|---|---|---|---|
| 1 | `guides/01-three-js-and-r3f.md` §0–§2 | 20 min | In a scratch Vite app, render a `<mesh><boxGeometry/><meshStandardMaterial color="hotpink"/></mesh>` with `<OrbitControls>`. Make it spin with `useFrame`. |
| 2 | `guides/01` §5 (loading), §8 (drei) | 15 min | Load ToyCar with `useGLTF` inside `<Bounds fit>`. Add `<Grid>` and `<Environment>`. Screenshot. |
| 3 | `guides/02-viewer-annotations-deep-dive.md` §1–§3 | 25 min | Add `onClick` on the model group; `console.log(e.point, e.face.normal, e.object.name)`. Place a sphere at `e.point`. Orbit — it stays. |
| 4 | `guides/02` §4–§7 | 20 min | Wrap the sphere in `<Html>` with a text input. Type in it while orbiting. |
| 5 | Issues A1a → A2c | 10 min | You now know every term in them. |

Concepts to be able to explain: scene graph, local vs world space, raycast, `useFrame` vs React state, Suspense loading.

## Track B — Capture
| Step | Read | Time | Exercise |
|---|---|---|---|
| 1 | `guides/03-camera-capture.md` §1–§3 | 20 min | Scratch page with a Start button that opens the rear camera into `<video playsInline muted autoPlay>`. Test on your phone **through the tunnel** (ask C to start it, or `npx cloudflared tunnel --url http://localhost:5173` yourself). |
| 2 | `guides/03` §4–§5 | 15 min | Add a shutter that draws the frame to a canvas and shows the JPEG blob size and `videoWidth×videoHeight`. Note the numbers. |
| 3 | `guides/03` §6–§9 | 20 min | Auto-capture every 1.5 s for 10 s with a counter; `PUT` each blob to `httpbin.org/put` (or a local no-op route) with Axios progress. |
| 4 | `guides/07-shooting-a-car.md` | 10 min | You'll write the on-screen copy from it. |
| 5 | Issues B1a → B2a | 10 min | |

Concepts: secure context, media constraints vs settings, canvas frame grab, upload queue, wake lock.

## Track C — API / Dashboard / Integration / Presentation
| Step | Read | Time | Exercise |
|---|---|---|---|
| 1 | `guides/05-api-hono-drizzle.md` §1–§5 | 25 min | Hono hello-world with `zValidator` returning our `{ error }` envelope on bad input. |
| 2 | `guides/05` §6–§8 | 20 min | Postgres in compose; Drizzle `push`; insert a claim from a script. |
| 3 | `guides/06-frontend-stack.md` (all) | 20 min | Vite + RR8 + Tailwind 4 app with two routes and a `<StatusBadge>` using the `@theme` tokens. |
| 4 | `docs/presentation/*` | 15 min | You own these from H12. Know the beats. |
| 5 | Issues C0a → C4b | 15 min | You're the critical path until H8. |

Concepts: layered API (routes/services/db), state machine, atomic file writes, polling loops, proxying through Vite, tunnel.

## Track D — Pipeline
| Step | Read | Time | Exercise |
|---|---|---|---|
| 1 | `guides/04-photogrammetry.md` §1 | 15 min | Explain SfM vs MVS to a teammate in two sentences each. |
| 2 | `docs/SETUP.md §Track D` | 10 min | Rent the box tonight if allowed; start the image pulls. |
| 3 | `guides/04` §2–§4 | 25 min | Run `meshroom_batch --toNode StructureFromMotion` on 20 phone photos of anything. Count the cameras in the log. |
| 4 | `guides/04` §5–§8 | 25 min | `obj2gltf` any OBJ → glb → `gltf-transform inspect`. Open in gltf.report. |
| 5 | `guides/07-shooting-a-car.md` | 10 min | You're shooting the car. |
| 6 | Issues D1a → D3b | 10 min | |

Concepts: features/matching/SfM/MVS/texturing, why overlap matters, Docker `--gpus all`, glTF/Draco/WebP, model normalization, a job worker.

## Cross-training (optional, H16+ when you have slack)
- A ↔ B: swap and try each other's feature on a phone/desktop. Fresh eyes find demo bugs.
- C: read `guides/02 §7` (autosave) and `guides/03 §9` (upload queue) — you integrate both.
- D: read `guides/01 §5` so you understand what Track A needs from the glb.

# Guide 04 — Photogrammetry: from phone photos to a `.glb` (Meshroom, COLMAP + OpenMVS, worker)

Track D's blueprint, written for web developers with zero computer-vision background. Versions verified 2026-09-13: **Meshroom 2025.1.0 (AliceVision 3.3.0)**, **COLMAP 4.2.0** (released 2026-08-31), OpenMVS 2.x via the `yeicor/colmap-openmvs` image, `obj2gltf` 3.2, `@gltf-transform/cli` 4.5.

## 1. What photogrammetry actually does (10-minute version)

Given many photos of the same object from different viewpoints, recover its 3D shape and color. Every engine does the same four stages:

1. **Feature extraction** — find thousands of distinctive points per photo (corners, texture blobs; classically SIFT). Smooth, uniform, reflective surfaces have *few* features. That's why cars are hard.
2. **Matching + Structure from Motion (SfM)** — match features between photo pairs, then solve simultaneously for every camera's position/orientation *and* a sparse 3D point cloud that explains the matches. Output: camera poses + sparse cloud. If this fails, nothing downstream works. Needs **overlap**: each surface point should be seen in ≥ 3 photos from different angles.
3. **Multi-View Stereo (MVS) / dense reconstruction** — with known cameras, estimate a depth map per photo and fuse them into a dense point cloud (millions of points). GPU-heavy. This is where CUDA matters.
4. **Meshing + texturing** — turn the dense cloud into a triangle mesh (Poisson / Delaunay), optionally refine it against the photos, then project the photos onto it as a texture atlas. Output: OBJ + MTL + PNG (or PLY).

Then **we** convert to glTF binary (`.glb`), compress it, normalize orientation/scale, and hand it to the viewer.

Vocabulary you'll see in logs: *intrinsics* (focal length, distortion — per camera), *extrinsics/poses* (where each camera was), *bundle adjustment* (the big least-squares solve in SfM), *depth map*, *point cloud*, *watertight*, *decimation* (reducing triangle count), *UV/atlas* (texture layout).

### Why cars are the hard case, and what we do about it

- **Reflections** move with the viewpoint, so features on glossy paint don't correspond across photos. → Overcast light or shade; avoid direct sun; shoot more photos with more overlap; the background (ground, walls) provides the features that solve the cameras, and the dense stage fills the car in. Windows/chrome will be holey — that's normal and honest.
- **Uniform panels** have no texture. → Same answer: dense stage + more views. Dirt and dents are actually *helpful*.
- **Scale/orientation are arbitrary** — the engine doesn't know up or metres. → §7.
- **The environment gets reconstructed too** (ground, nearby cars). → Crop by distance from the car's center (§7) and keep the largest connected component.

Datasets: 40–60 photos, 60–80% overlap between neighbours, two heights (standing and crouched), whole car in frame plus a ring of closer 3/4 shots. Details in guide 07.

## 2. Engine A — Meshroom / AliceVision (one command)

- License **MPL-2.0** (resolves the PRD's AGPL concern for OpenMVS). Needs an **NVIDIA GPU with CUDA** for the DepthMap node (CPU-only Meshroom skips dense reconstruction and gives a poor mesh).
- Docker image: `alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1` (~16 GB compressed — start the pull first). Also a self-contained Linux tarball `Meshroom-2025.1.0-Linux.tar.gz` (GitHub releases) that only needs the host NVIDIA driver — use it on RunPod-style pods where Docker isn't available.
- Headless CLI: `meshroom_batch`.

```bash
# Inside the container (or from the tarball dir on the host)
docker run --rm --gpus all \
  -v /data:/data \
  alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1 \
  meshroom_batch \
    --input /data/jobs/JOB/images \
    --output /data/jobs/JOB/out \
    --cache /data/jobs/JOB/cache \
    --pipeline photogrammetry \
    --scale 2 \
    --paramOverrides FeatureExtraction.describerPreset=normal Texturing.textureSide=4096 Texturing.downscale=2
```

Flags (from the 2025 docs): `-i/--input` folder of images, `-o/--output` folder that receives the *published* results (`texturedMesh.obj`, `texturedMesh.mtl`, `texture_*.png`), `--cache` where every node writes intermediates (large; per job), `-p/--pipeline photogrammetry` (built-in), `--scale N` downscales the depth-map stage (2 = quarter the work; 1 = full), `--paramOverrides NodeType.param=value ...` for anything else, `--toNode NodeName` to stop early (e.g., `StructureFromMotion` for a quick SfM sanity check), `--forceCompute` to ignore cache. If `meshroom_batch` isn't on `PATH` in the image, `find / -name meshroom_batch -type f 2>/dev/null` — it's in the Meshroom install dir.

Stages you'll see in the log (in order; these map to the worker's `stage`): `CameraInit → FeatureExtraction → ImageMatching → FeatureMatching → StructureFromMotion → PrepareDenseScene → DepthMap → DepthMapFilter → Meshing → MeshFiltering → Texturing → Publish`.

Knobs that matter for speed vs quality:

| Param | Fast | Good | Effect |
|---|---|---|---|
| input image long edge | 1600 px | 2500–3000 px | biggest single lever; downscale with ImageMagick before the run |
| `FeatureExtraction.describerPreset` | `normal` | `high` | more features → better SfM on bland surfaces, slower matching |
| `--scale` (DepthMap downscale) | 3 | 2 | dense stage cost ~ 1/scale² |
| `Meshing.maxInputPoints` / `maxPoints` | 20M / 2M | defaults | mesh density |
| `MeshFiltering.keepLargestMeshOnly` | `True` | `True` | drops floating junk — set it |
| `Texturing.textureSide` | 2048 | 4096 | atlas size (we downscale to 2048 in export anyway) |
| `Texturing.downscale` | 2 | 1 | texture source downscale |

Expected on a g5.xlarge (A10G) with 50 × 2000 px photos: roughly 6–12 min "fast", 15–30 min "good". **Measure and fill §9.**

"No metadata / unknown sensor" warnings for our canvas JPEGs are normal — AliceVision falls back to a default sensor width and estimates focal length; SfM still works. If you want to help it: `--paramOverrides CameraInit.defaultFieldOfView=70` (phone wide camera ≈ 65–75° horizontal FOV).

## 3. Engine B — COLMAP + OpenMVS (the PRD's exact chain)

- COLMAP: BSD-3, `colmap/colmap` official Docker image with CUDA. 4.2.0 adds `--mapper GLOBAL` (GLOMAP global SfM — much faster than incremental for ≤ 200 images) and `automatic_reconstructor --mesher POISSON`.
- OpenMVS: **AGPL-3.0** (the PRD's license caveat — fine for an internal POC; flag it on the slide). Does dense → mesh → refine → texture.
- Easiest packaging: `yeicor/colmap-openmvs:cuda-latest` — one image, one command, a `PIPELINE` env var to choose COLMAP-SfM + OpenMVS-dense. Read `docker run --rm yeicor/colmap-openmvs:cuda-latest --help` first.

```bash
mkdir -p /data/jobs/JOB && cp -r /data/jobs/JOB/images /data/jobs/JOB/
docker run --rm --gpus all -u $(id -u):$(id -g) \
  -v /data/jobs/JOB:/data \
  yeicor/colmap-openmvs:cuda-latest /data
# → look for the textured mesh: find /data/jobs/JOB -name '*texture*' \( -name '*.obj' -o -name '*.ply' \)
```

If you'd rather run the steps yourself (more control, and it's what PRD §10 lists), inside a container that has both tools:

```bash
W=/data/jobs/JOB
# --- COLMAP: SfM ---
colmap feature_extractor   --database_path $W/db.db --image_path $W/images \
  --ImageReader.single_camera 1 --ImageReader.camera_model OPENCV --SiftExtraction.use_gpu 1 \
  --SiftExtraction.max_image_size 2400
colmap exhaustive_matcher  --database_path $W/db.db --SiftMatching.use_gpu 1        # ≤ ~120 images; else sequential_matcher --SequentialMatching.loop_detection 1
colmap mapper              --database_path $W/db.db --image_path $W/images --output_path $W/sparse
#   (COLMAP 4.2: try `colmap global_mapper` for a big speedup on the SfM step)
colmap image_undistorter   --image_path $W/images --input_path $W/sparse/0 --output_path $W/dense --output_type COLMAP --max_image_size 2000
# --- OpenMVS: dense → mesh → texture ---
cd $W/dense
InterfaceCOLMAP  -i . -o scene.mvs --image-folder images
DensifyPointCloud scene.mvs --resolution-level 1 --number-views 6          # GPU if built with CUDA
ReconstructMesh   scene_dense.mvs --decimate 0.5 --remove-spurious 30
RefineMesh        scene_dense_mesh.mvs --resolution-level 2 --max-face-area 16   # optional; slow; skip in "fast"
TextureMesh       scene_dense_mesh.mvs --export-type obj --resolution-level 1 --decimate 0.5 -o textured
# → textured.obj / textured.mtl / textured_*.png
```

`--ImageReader.single_camera 1` tells COLMAP all photos share intrinsics (same phone) — a big help for SfM on bland scenes. **Except** if iOS switched lenses mid-walk (guide 03 §4); then drop it. `sparse/0` is the largest reconstructed model; if you see `sparse/1`, SfM split into components — usually not enough overlap.

Timing on A10G, 50 photos @ 2000 px: SfM 1–3 min (GLOMAP: seconds), dense 3–8 min, mesh+texture 2–5 min. Measure and record in §9.

## 4. Choosing (D1c) — what to compare

Run both on the same sample dataset and score:

| Criterion | Weight | How to judge |
|---|---|---|
| Visual quality of the car | high | screenshot side by side; holes on visible panels; texture alignment at edges |
| Wall time (fast settings) | high | must be < 10 min for the live re-run |
| Reliability | high | did SfM find all cameras? (`StructureFromMotion` log / `sparse/0` image count) |
| Glue code needed | medium | Meshroom is one command; COLMAP+OpenMVS is ~8 |
| License story on the slide | medium | MPL-2.0 (Meshroom) vs AGPL (OpenMVS) |

Default recommendation if both work: **Meshroom** (one command, cleaner license, fewer failure points). Keep the other script in `pipeline/` so switching is `ENGINE=colmap-openmvs`.

## 5. One-command pipeline (D3a)

`pipeline/run_pipeline.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
IMAGES=$1; OUT=$2; ENGINE=${ENGINE:-meshroom}; QUALITY=${QUALITY:-fast}; MAX=${MAX_IMAGE_SIZE:-2000}
mkdir -p "$OUT/images" "$OUT/cache" "$OUT/out"
echo "[stage] prepare"
# downscale copies (never touch originals); ImageMagick or a Pillow one-liner
for f in "$IMAGES"/*.{jpg,jpeg,JPG,JPEG}; do [ -e "$f" ] || continue
  convert "$f" -auto-orient -resize "${MAX}x${MAX}>" -quality 92 "$OUT/images/$(basename "${f%.*}").jpg"; done
N=$(ls "$OUT/images" | wc -l); echo "[info] $N images"; [ "$N" -ge 12 ] || { echo "[error] need ≥ 12 images"; exit 1; }
case "$ENGINE" in
  meshroom)        "$(dirname "$0")/engines/meshroom.sh" "$OUT" "$QUALITY" ;;
  colmap-openmvs)  "$(dirname "$0")/engines/colmap_openmvs.sh" "$OUT" "$QUALITY" ;;
  *) echo "[error] unknown ENGINE=$ENGINE"; exit 1 ;;
esac
echo "[stage] export"
"$(dirname "$0")/export_glb.sh" "$OUT"
echo "[stage] normalize"
python3 "$(dirname "$0")/normalize.py" "$OUT/out/raw.glb" "$OUT/out/model.glb" --target-size 4.5
echo "[done] $OUT/out/model.glb"
```

`engines/meshroom.sh` maps `QUALITY` to the table in §2 and runs the `docker run … meshroom_batch …` line, `tee`-ing the log to `$OUT/log.txt` and emitting `[stage] <NodeName>` lines by grepping Meshroom's `Node <NodeName>` log markers (`grep --line-buffered -oE 'Start|\[[0-9]+/[0-9]+\] [A-Za-z]+'`). The worker (§8) parses `[stage]` lines.

## 6. Exporting to `.glb` (D3b)

```bash
# pipeline/export_glb.sh
set -euo pipefail; OUT=$1; cd "$OUT/out"
OBJ=$(ls *.obj | head -1)
npx --yes obj2gltf@3 -i "$OBJ" -o raw.glb                                      # OBJ+MTL+PNG → one binary glTF
npx --yes @gltf-transform/cli@4 optimize raw.glb model.glb \
  --compress draco --texture-compress webp --texture-size 2048 --simplify-ratio 0.5   # check `--help` for exact flag names in 4.5
npx --yes @gltf-transform/cli@4 inspect model.glb | head -60
ls -la raw.glb model.glb
```

- `obj2gltf` needs the `.mtl` and textures next to the `.obj` (they are). If textures are `.exr` (AliceVision can output EXR), add `Texturing.outputTextureFileType=png` to the overrides.
- `gltf-transform optimize` = dedup + instancing + Draco geometry compression + WebP textures + optional simplification (meshoptimizer). Aim ≤ 25 MB; a 500k-tri car with one 2048² WebP is ~10–20 MB. If `--simplify` produces cracks, drop it and instead decimate in the engine (Meshroom `MeshDecimate` node / OpenMVS `--decimate`).
- Verify: https://gltf.report (drag-drop; shows tri count, texture sizes, extensions), or the three.js editor. drei's `useGLTF` handles `KHR_draco_mesh_compression` and `EXT_texture_webp` — Track A just needs the local Draco decoder in `public/draco/` (guide 01 §5).

## 7. Normalizing orientation, scale, origin (D3c)

Engines output arbitrary scale/orientation. The viewer normalizes *size* defensively, but **up-direction** has to be fixed here. Two methods; use the first when camera poses are available (they always are), fall back to the second.

**Camera-ring method.** The customer walked a ring around the car at roughly constant height, so the camera centers lie on a plane; that plane's normal is "up". Read camera centers from COLMAP `sparse/0/images.txt` (convert with `colmap model_converter --output_type TXT`; center = `-R^T t`) or Meshroom's `cache/StructureFromMotion/*/cameras.sfm` (JSON, `poses[].pose.transform.center`). Fit a plane (PCA: smallest-variance axis = normal). Sign: the mesh centroid should be **below** the camera plane (people hold phones above the car's mid-height) — flip if not. Rotate so that normal → +Y.

**Mesh-PCA fallback.** For a car, height < width < length, so the smallest-variance axis of the vertices is up. Sign is ambiguous → allow `--flip-up` manual override; check once visually for the demo model.

```python
# pipeline/normalize.py  (pip install trimesh numpy pygltflib? — trimesh loads/exports glb directly)
import sys, numpy as np, trimesh
src, dst = sys.argv[1], sys.argv[2]
scene = trimesh.load(src, force='scene')
mesh = trimesh.util.concatenate([g for g in scene.geometry.values()])   # keep textures via visual; fine for one mesh
# keep largest connected component + anything ≥ 5% of it (drops floating junk)
parts = mesh.split(only_watertight=False); big = max(parts, key=lambda p: p.area)
mesh = trimesh.util.concatenate([p for p in parts if p.area >= 0.05 * big.area])
# up: PCA fallback (replace with camera-ring normal when available)
v = mesh.vertices - mesh.vertices.mean(0); w, vec = np.linalg.eigh(np.cov(v.T)); up = vec[:, 0]
if '--flip-up' in sys.argv: up = -up
R = trimesh.geometry.align_vectors(up, [0, 1, 0]); mesh.apply_transform(R)
# crop far junk: anything beyond 1.5 × the car's XZ radius from the centroid
c = mesh.bounds.mean(0); r = np.linalg.norm((mesh.bounds[1] - mesh.bounds[0])[[0, 2]]) / 2
# (optional: mask vertices by distance and take the sub-mesh)
# center, floor, scale
mesh.apply_translation(-mesh.bounds.mean(0)); mesh.apply_translation([0, -mesh.bounds[0][1], 0])
target = float(sys.argv[sys.argv.index('--target-size') + 1]) if '--target-size' in sys.argv else 4.5
mesh.apply_scale(target / max(mesh.extents))
mesh.export(dst)   # trimesh writes .glb with the texture if visual is TextureVisuals
print('[info] verts', len(mesh.vertices), 'faces', len(mesh.faces), 'extents', mesh.extents)
```

Caveat: `trimesh` GLB export keeps textures when the mesh has `TextureVisuals`; run it **before** Draco compression (Draco'd input is fine to load, but export then re-run `gltf-transform optimize` after normalizing). Order in `run_pipeline.sh`: OBJ → `obj2gltf` → `normalize.py` → `gltf-transform optimize`. (The sketch above shows `raw.glb → model.glb`; adjust so optimize is last.)

## 8. The worker (D4a/D4b)

A tiny HTTP service on the GPU box implementing `docs/CONTRACTS.md §4`. Python + FastAPI is the least friction (subprocess + threads):

```python
# worker/app.py  — pip install fastapi uvicorn python-multipart
import json, os, re, shutil, subprocess, threading, uuid, zipfile, queue, datetime as dt
from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.responses import FileResponse

TOKEN = os.environ['WORKER_TOKEN']; WORK = os.environ.get('WORK_DIR', '/data/jobs'); ENGINE = os.environ.get('ENGINE', 'meshroom')
app = FastAPI(); jobs: dict[str, dict] = {}; q: 'queue.Queue[str]' = queue.Queue()
STAGES = ['prepare', 'CameraInit', 'FeatureExtraction', 'ImageMatching', 'FeatureMatching', 'StructureFromMotion', 'PrepareDenseScene', 'DepthMap', 'DepthMapFilter', 'Meshing', 'MeshFiltering', 'Texturing', 'Publish', 'export', 'normalize']

def auth(x_worker_token: str | None): 
    if x_worker_token != TOKEN: raise HTTPException(401, 'bad token')

def now(): return dt.datetime.now(dt.timezone.utc).isoformat()

def run(job_id: str):
    j = jobs[job_id]; d = f'{WORK}/{job_id}'; j.update(status='running', startedAt=now()); save(j)
    with open(f'{d}/log.txt', 'w') as log:
        p = subprocess.Popen(['bash', '/opt/pipeline/run_pipeline.sh', f'{d}/images', f'{d}/run'],
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env={**os.environ, 'ENGINE': ENGINE})
        for line in p.stdout:
            log.write(line); j['logTail'] = (j['logTail'] + [line.rstrip()])[-20:]
            m = re.match(r'\[stage\] (\S+)', line)
            if m and m.group(1) in STAGES: j['stage'] = m.group(1); j['progress'] = STAGES.index(m.group(1)) / len(STAGES)
            save(j)
        rc = p.wait()
    out = f'{d}/run/out/model.glb'
    if rc == 0 and os.path.exists(out): j.update(status='done', progress=1.0, finishedAt=now())
    else: j.update(status='failed', error=f'exit {rc}: ' + ' | '.join(j['logTail'][-3:]), finishedAt=now())
    save(j)

def save(j): json.dump(j, open(f"{WORK}/{j['jobId']}/job.json", 'w'))
def worker_loop():
    while True: run(q.get())
threading.Thread(target=worker_loop, daemon=True).start()

@app.get('/health')
def health(x_worker_token: str | None = Header(None)):
    auth(x_worker_token); gpu = subprocess.run(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader'], capture_output=True, text=True).stdout.strip()
    return {'ok': True, 'gpu': gpu, 'engine': ENGINE, 'queue': q.qsize()}

@app.post('/jobs', status_code=202)
async def create(photos: UploadFile = File(...), claimId: str = Form(...), x_worker_token: str | None = Header(None)):
    auth(x_worker_token); job_id = str(uuid.uuid4()); d = f'{WORK}/{job_id}'; os.makedirs(f'{d}/images')
    with open(f'{d}/photos.zip', 'wb') as f: shutil.copyfileobj(photos.file, f)
    with zipfile.ZipFile(f'{d}/photos.zip') as z:
        for n in z.namelist():
            if n.lower().endswith(('.jpg', '.jpeg')) and not n.startswith('__MACOSX'): z.extract(n, f'{d}/images')
    jobs[job_id] = {'jobId': job_id, 'claimId': claimId, 'status': 'queued', 'stage': None, 'progress': 0.0, 'logTail': [], 'startedAt': None, 'finishedAt': None, 'error': None}
    save(jobs[job_id]); q.put(job_id); return {'job': jobs[job_id]}

@app.get('/jobs/{job_id}')
def get(job_id: str, x_worker_token: str | None = Header(None)):
    auth(x_worker_token); j = jobs.get(job_id) or (json.load(open(f'{WORK}/{job_id}/job.json')) if os.path.exists(f'{WORK}/{job_id}/job.json') else None)
    if not j: raise HTTPException(404); return {'job': j}

@app.get('/jobs/{job_id}/model.glb')
def model(job_id: str, x_worker_token: str | None = Header(None)):
    auth(x_worker_token); j = jobs.get(job_id)
    if not j or j['status'] != 'done': raise HTTPException(409, 'not done')
    return FileResponse(f'{WORK}/{job_id}/run/out/model.glb', media_type='model/gltf-binary')

@app.delete('/jobs/{job_id}', status_code=204)
def delete(job_id: str, x_worker_token: str | None = Header(None)):
    auth(x_worker_token); shutil.rmtree(f'{WORK}/{job_id}', ignore_errors=True); jobs.pop(job_id, None)
```

Run: `uvicorn app:app --host 0.0.0.0 --port 8080`. Keep alive with a `systemd` unit (`Restart=always`, `EnvironmentFile=/opt/worker/.env`). Nested zips: unzip flat (`z.extract` keeps folders — flatten with `os.path.basename` if the API zips with paths; CONTRACTS says flat). Strip `__MACOSX`. The Node version of this is equally short with Hono + `adm-zip` + `child_process.spawn`; pick whichever you type faster.

Security is a shared token on a public port for one day. Rotate it after the jam; tear the box down.

## 9. Timing table (fill in — this goes on a slide)

| Engine | Dataset (n photos @ long edge) | Settings | SfM | Dense | Mesh+Tex | Total | Quality note |
|---|---|---|---|---|---|---|---|
| Meshroom | car01 (40 @ 2000) | fast (`--scale 3`, normal) | | | | | |
| Meshroom | democar (60 @ 2000) | good (`--scale 2`, high) | | | | | |
| COLMAP+OpenMVS | car01 (40 @ 2000) | GLOMAP + res-level 1 | | | | | |
| | | | | | | | |

## 10. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| SfM reconstructs only 10 of 50 cameras / multiple `sparse/N` | not enough overlap, or reflective/blank frames between views | reshoot with smaller steps; add the background (ground) in frame; `describerPreset=high`; sequential matcher with loop closure |
| Car is a blob, ground is perfect | features came from the ground; car dense failed on gloss | more photos closer to the car (3/4 ring); overcast light; dense `--resolution-level 0`; accept it and crop |
| Mesh has a giant ground plane / neighbouring cars | environment reconstructed | normalize.py crop + largest-component; Meshroom `MeshFiltering.keepLargestMeshOnly` |
| Textures look smeared or misaligned | mesh too coarse / refine skipped / bad cameras | `RefineMesh` (OpenMVS) or `Texturing.downscale=1`; check camera count |
| CUDA out of memory in DepthMap | images too large | `--scale 3`, `MAX_IMAGE_SIZE=1600` |
| `meshroom_batch: command not found` in container | PATH | `find / -name meshroom_batch`; call with absolute path |
| obj2gltf fails on EXR textures | AliceVision EXR output | `Texturing.outputTextureFileType=png` |
| Model loads sideways in viewer | up-vector sign | `--flip-up` in normalize.py; document it for the demo dataset |
| Job takes 40 min | full-res images, `--scale 1`, `high` | this is "good" mode; use "fast" for the live run and say so |

## 11. What's next (talking points, not jam work)

- **Feed-forward reconstruction**: VGGT (CVPR 2025 best paper; `facebook/VGGT-1B-Commercial` weights are licensed for commercial use, gated on Hugging Face) and MASt3R predict cameras + dense points in **seconds** on one GPU, no SfM optimization. Great for instant previews; meshing/texturing still needs a classical step (or 2DGS/SuGaR-style splat-to-mesh). Meshroom 2025's MeshroomHub also ships Gaussian-splatting and monocular-depth extensions.
- **Licenses**: AliceVision/Meshroom MPL-2.0, COLMAP BSD-3, OpenMVS AGPL-3.0, obj2gltf Apache-2.0, glTF-Transform MIT, three.js MIT.
- **Production shape**: the worker's `/jobs` contract is exactly what an AWS Batch job definition + S3 in/out would implement; the API's dispatcher swaps `POST /jobs` for `batch.submitJob()` and polling for an EventBridge rule.

## 12. References

- Meshroom releases (2025.1.0 assets, CUDA ≥ compute 5.0): https://github.com/alicevision/Meshroom/releases
- Meshroom Docker tags: https://hub.docker.com/r/alicevision/meshroom/tags
- `meshroom_batch` docs: https://meshroom-manual.readthedocs.io/en/latest/feature-documentation/cmd/photogrammetry.html
- COLMAP CLI (automatic_reconstructor flags, step-by-step): https://colmap.github.io/cli.html · changelog: https://colmap.github.io/changelog.html
- COLMAP Docker: https://github.com/colmap/colmap/blob/main/docker/README.md
- COLMAP+OpenMVS one-shot image: https://github.com/yeicor-docker/colmap-openmvs
- OpenMVS usage: https://github.com/cdcseacave/openMVS/wiki/Usage
- glTF-Transform CLI: https://gltf-transform.dev/cli
- obj2gltf: https://github.com/CesiumGS/obj2gltf
- VGGT: https://github.com/facebookresearch/vggt · commercial weights: https://huggingface.co/facebook/VGGT-1B-Commercial

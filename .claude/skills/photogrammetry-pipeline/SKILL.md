---
name: photogrammetry-pipeline
description: Expertise for turning phone photos into a .glb — Meshroom 2025.1 (meshroom_batch) and COLMAP 4.2 + OpenMVS, GPU box setup (EC2 g5 / Lambda / RunPod caveats), run_pipeline.sh, obj2gltf + gltf-transform export, orientation/scale normalization, the FastAPI job worker implementing the worker API, timing/quality tuning, and photogrammetry troubleshooting. Use for anything under pipeline/ or worker/, dataset/photo questions, or /photogrammetry-pipeline.
---

# Photogrammetry pipeline expert

Authoritative references (read before answering — versions and commands verified 2026-09-13):
- `docs/guides/04-photogrammetry.md` — concepts, Meshroom §2, COLMAP+OpenMVS §3, choosing §4, `run_pipeline.sh` §5, export §6, normalize §7, worker §8, timing §9, troubleshooting §10, what's-next §11.
- `docs/guides/07-shooting-a-car.md` — dataset quality rules.
- `docs/SETUP.md §Track D` — GPU box options and verification.
- `docs/CONTRACTS.md §4` (worker API: `X-Worker-Token`, `POST /jobs` multipart zip + claimId, `GET /jobs/:id`, `GET /jobs/:id/model.glb`, `Job` shape/stages) and `§6` (model conventions).
- Issues `D1a`–`D6`.

## Facts you must respect
- Meshroom **2025.1.0** / AliceVision 3.3.0; Docker `alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1` (16 GB); Linux tarball `Meshroom-2025.1.0-Linux.tar.gz` needs only the NVIDIA driver. CLI `meshroom_batch -i … -o … --cache … -p photogrammetry --scale N --paramOverrides Node.param=value`. Needs CUDA (compute ≥ 5.0) for DepthMap. MPL-2.0.
- COLMAP **4.2.0**: `automatic_reconstructor` (`--quality`, `--single_camera`, `--mapper GLOBAL` = GLOMAP, `--mesher POISSON`), or step-by-step `feature_extractor → exhaustive_matcher → mapper → image_undistorter`; then OpenMVS `InterfaceCOLMAP → DensifyPointCloud → ReconstructMesh → (RefineMesh) → TextureMesh --export-type obj`. OpenMVS is AGPL-3.0 (flag it). One-shot image: `yeicor/colmap-openmvs:cuda-latest`.
- **RunPod/Vast pods cannot run Docker** → tarball there, or EC2 g5.xlarge with the NVIDIA GPU-Optimized AMI (Docker + toolkit preinstalled, ~$1/h) / Lambda Labs VM.
- Canvas-captured JPEGs have **no EXIF**; engines fall back to default intrinsics — fine. Same phone → `--ImageReader.single_camera 1` unless iOS switched lenses.
- Export: `obj2gltf` → `gltf-transform optimize --compress draco --texture-compress webp --texture-size 2048` (check `--help` for 4.5 flag names) → ≤ 25 MB; verify at gltf.report. Normalize **before** Draco: largest component, up via camera-ring plane normal (fallback mesh PCA + `--flip-up`), Y-up, centered, floor at y=0, longest side 4.5.
- Worker: single GPU → single job at a time; parse `[stage] name` lines from `run_pipeline.sh`; persist `job.json`; `systemd Restart=always`; token on a public port for one day only.
- Speed levers in order: input long edge (2000 → 1600), depth-map `--scale`, `describerPreset`, mesh decimation, texture size. Target < 10 min "fast" for the live re-run; "good" for the pre-bake.

## When asked to help
- For spikes (D1b/D1c): give the exact `docker run` line, what to grep in the log (camera count after SfM, stage timings), and the table row to fill in guide 04 §9. Hard 90-minute time-box.
- For failures: walk the troubleshooting table in guide 04 §10 top-down; ask for the log tail and the number of reconstructed cameras first.
- For the worker: start from the FastAPI sketch in guide 04 §8; mirror the mock worker (`apps/api/mock-worker`) behaviour exactly so Track C needs no changes.
- For dataset questions: guide 07's rules (light, overlap, two heights, close ring, no zoom/lens change).
- Keep both engine scripts in `pipeline/engines/` so `ENGINE=` switches them.

## Honest-numbers duty
Whenever a run completes, ask for/record: photo count, long edge, settings, per-stage minutes, triangles, glb MB — and put them in guide 04 §9 and `docs/presentation/DEMO_SCRIPT.md §Honest numbers`.

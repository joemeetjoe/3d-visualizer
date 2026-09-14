# D1b — Meshroom spike (90 min hard stop)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | HITL | 1.5h | H3 | todo |

## What to build
Run Meshroom 2025.1 headless on the sample dataset and get `texturedMesh.obj` + textures out:
```bash
docker run --rm --gpus all -v /data:/data \
  alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1 \
  meshroom_batch --input /data/samples/car01/images --output /data/jobs/spike-meshroom \
  --pipeline photogrammetry --cache /data/jobs/spike-meshroom/cache --scale 2
```
Record: wall time per stage (the log prints node names), peak VRAM, output files, and visual quality (open the OBJ in the three.js editor or Blender screenshot). Try `--scale 2` vs `1` (depth-map downscale) and a `--paramOverrides` for `FeatureExtraction.describerPreset=normal|high`.

## Acceptance criteria
- [ ] A textured mesh exists and looks like the car (screenshot in chat)
- [ ] Timing table row filled in `docs/guides/04-photogrammetry.md §Timing`
- [ ] Any failure mode noted (e.g., "no metadata" warnings — expected for canvas JPEGs — and whether it mattered)

## Blocked by
D1a

## Unblocks
D1c (decision)

## Read first
`docs/guides/04-photogrammetry.md §Meshroom`

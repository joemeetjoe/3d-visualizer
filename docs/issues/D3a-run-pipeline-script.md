# D3a — `run_pipeline.sh photos/ out/` (engine → textured OBJ)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1.5h | H6 | todo |

## What to build
`pipeline/run_pipeline.sh <images_dir> <out_dir>`: one reproducible command wrapping the chosen engine's `docker run` (or tarball binary), with `MAX_IMAGE_SIZE` downscale first, engine params from env (`QUALITY=fast|good`), structured log lines `[stage] name` so the worker can parse progress, non-zero exit on failure, and a final `out/mesh.obj + mesh.mtl + textures/`. Keep the *other* engine's script as `run_pipeline_<engine>.sh` so switching is one env var.

## Acceptance criteria
- [ ] `QUALITY=fast ./run_pipeline.sh /data/samples/car01/images /data/jobs/t1` → textured OBJ in < 8 min on the g5
- [ ] Log lines `[stage] ...` appear for each major step
- [ ] Fails loudly (exit 1, last 20 log lines) on a bad dataset (e.g., 5 photos)

## Blocked by
D1c

## Unblocks
D3b, D4a

## Read first
`docs/guides/04-photogrammetry.md §One-command pipeline`

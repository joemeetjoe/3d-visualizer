# D1c — COLMAP + OpenMVS spike, then DECIDE the engine

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | HITL | 1.5h | H4 | todo |

## What to build
Same dataset through the PRD's chain in one container:
```bash
mkdir -p /data/jobs/spike-colmap && cp -r /data/samples/car01/images /data/jobs/spike-colmap/
docker run --rm --gpus all -u $(id -u):$(id -g) -v /data/jobs/spike-colmap:/data \
  yeicor/colmap-openmvs:cuda-latest /data
```
(Read `--help` first for the `PIPELINE` env var; try the COLMAP-SfM + OpenMVS-dense variant.) Also try plain COLMAP 4.2 `automatic_reconstructor --quality medium --single_camera 1 --mesher POISSON` as a data point (no texture — just to see SfM speed with GLOMAP `--mapper GLOBAL`). Record the same table row. **Then decide** with the team lead: engine = the one that produced the better-looking textured car in less time. Write the decision + reasons into `docs/DECISIONS.md` (D2) and set `ENGINE=` in `worker/.env`.

## Acceptance criteria
- [ ] Textured mesh from COLMAP+OpenMVS exists (or a documented reason it failed)
- [ ] Timing table has both rows; screenshots side by side in chat
- [ ] Decision recorded by H4; unchosen engine's notes kept in the guide as the alternative

## Blocked by
D1b (can run in parallel on the same box if VRAM allows — check `nvidia-smi`)

## Unblocks
D3a

## Read first
`docs/guides/04-photogrammetry.md §COLMAP + OpenMVS, §Choosing`

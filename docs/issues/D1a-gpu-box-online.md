# D1a — GPU box online

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1h | H1 | todo |

## What to build
Rent the box (EC2 g5.xlarge + NVIDIA GPU-Optimized AMI recommended — see `docs/SETUP.md §Track D`), open ports 22 and 8080, SSH in, verify `nvidia-smi` and `docker run --gpus all`, create `/data/jobs` and `/data/samples`, **start pulling both engine images immediately** (16 GB + ~5 GB), `scp` a sample dataset up (40 phone photos of any parked car). Share IP + key handling + `WORKER_TOKEN` in chat. Add `~/.ssh/config` snippet to `docs/SETUP.md`.

## Acceptance criteria
- [ ] `nvidia-smi` shows the GPU; `docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi` works
- [ ] Both images pulled (`docker images`)
- [ ] ≥ 150 GB free; sample dataset at `/data/samples/car01/images/*.jpg`
- [ ] A teammate can SSH in using the shared instructions

## Blocked by
None — H0.

## Unblocks
D1b, D1c

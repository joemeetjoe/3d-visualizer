# Pre-jam preflight — things that can only be fixed *before* hour 0

Each of these is a silent day-killer if discovered at H1. Assign an owner, tick it off, and report in chat. Most take 10 minutes; two (AWS quota, Nexus) can take a day.

## Corporate network / laptops (owner: C, everyone verifies on their own machine)
- [ ] **Nexus npm warm-up done** per `preflight/README.md`, on every OS/arch the team uses. `cd preflight && pnpm install --frozen-lockfile` completes with no errors through Nexus.
- [ ] **Docker Hub reachable** (directly or via Nexus docker proxy): `docker pull postgres:16-alpine` succeeds on a corporate laptop. If Docker Hub is blocked and there's no proxy, `docker save postgres:16-alpine | gzip > postgres16.tgz` on a machine that can pull, and `docker load` on the others.
- [ ] **Docker Desktop installed and licensed** on all four laptops (corporate policy sometimes blocks it; Colima/Rancher Desktop are fallbacks).
- [ ] **cloudflared works from the corporate network**: `cloudflared tunnel --url http://localhost:8000` (with any local server on 8000) prints a `trycloudflare.com` URL, and a phone on cellular can open it. Corporate firewalls sometimes block the tunnel protocol; if so, test `ngrok http 8000` (needs a free account; shows an interstitial page the first time — acceptable), and as a last resort plan to run the demo laptop on a phone hotspot.
- [ ] **Brew / Node / pnpm installable**: Node ≥ 22.22 and pnpm present on all laptops (`node -v`, `pnpm -v`). If brew goes through Nexus, install cloudflared and Node now.
- [ ] **Ports free**: 5173 (Vite), 3000 (API), 5432 (Postgres), 8080 (mock worker) — endpoint security tools occasionally reserve ports.
- [ ] **Git access to the repo** for all four (`git clone git@github.com:joemeetjoe/3d-visualizer.git`) and Claude Code running inside it (`/jam-teach test` responds).

## AWS / GPU box (owner: D)
- [ ] **G-instance vCPU quota**: new/quiet accounts have a quota of **0** for "Running On-Demand G and VT instances". `g5.xlarge` needs 4 vCPUs. Check *Service Quotas → EC2* and request ≥ 8 now — approvals take hours to a couple of days. Fallback: Lambda Labs (needs an account + payment method set up beforehand) or RunPod (tarball route).
- [ ] **IAM rights** to launch the instance, create a security group (22 + 8080 inbound), and a key pair. Region with g5 capacity (us-east-1/us-east-2/us-west-2).
- [ ] **Box launched once as a dry run**: `nvidia-smi` works, `docker run --gpus all` works, both engine images pulled (`docker pull` of the 16 GB Meshroom image done). Stop (don't terminate) the instance until the jam to keep the pulled images on the volume.
- [ ] **A throwaway dataset** on the box (`/data/samples/car01/images`, 30–40 phone photos of any parked car) so D1b/D1c can start the moment the jam opens.
- [ ] **Python deps on the box**: `pip install fastapi uvicorn python-multipart trimesh numpy` and Node 22 (`nvm`) for `obj2gltf`/`gltf-transform` — done in the dry run.

## The car and the phones (owner: D + B)
- [ ] **Which car, where, when** — written in `docs/PLAN.md`. Daylight window confirmed. Owner's permission. Not freshly washed.
- [ ] **Phones**: one iPhone (Safari) and one Android (Chrome), charged, with cables. Screen-mirroring to the demo laptop tested (QuickTime → iPhone; `scrcpy` or Vysor for Android) so the audience can see the phone.
- [ ] **15 pre-shot photos of the demo car on the demo phone's camera roll** (fallback for beat 4 if the camera is denied on stage).

## Presentation logistics (owner: C)
- [ ] Projector/HDMI adapter tested with the demo laptop; the 3D viewer at 1080p is legible from the back of the room (font sizes, zoom 125%).
- [ ] Venue wifi credentials; a phone hotspot as backup.
- [ ] Second laptop with the repo and Docker as the hot spare.
- [ ] Slides tool decided (Google Slides / Keynote) and a blank deck created with the dark theme.

## People
- [ ] Tracks self-selected and written into `docs/BOARD.md` *before* the jam, so learning paths can be done tonight.
- [ ] Everyone has read `docs/DECISIONS.md` and their track's learning path (`docs/LEARNING_PATHS.md`).
- [ ] Sleep windows agreed (`docs/PLAN.md`).

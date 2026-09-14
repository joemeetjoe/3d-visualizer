# Hour-0 setup

Do this before the kickoff if you can. Versions verified against npm/Docker Hub on **2026-09-13**.

## Everyone (laptop)

| Tool | Version | Install (macOS) | Check |
|---|---|---|---|
| Node | **22.22+** (React Router 8 minimum; 24 fine) | `brew install node@22` or nvm | `node -v` |
| pnpm | 10+ | `corepack enable && corepack prepare pnpm@latest --activate` | `pnpm -v` |
| Docker Desktop | current | docker.com | `docker compose version` |
| cloudflared | current | `brew install cloudflared` | `cloudflared --version` |
| Git | any | — | — |
| Claude Code | current | — | `claude --version` |

Optional but handy: `brew install jq gh`; the three.js editor (https://threejs.org/editor) for eyeballing a `.glb`; https://gltf.report for inspecting model size.

### Pinned package versions (C0a puts these in `package.json`; don't drift)

```
# web
react 19.3.x  react-dom 19.3.x  react-router 8.3.x  vite 8.3.x  @vitejs/plugin-react 6.x
tailwindcss 4.3.x  @tailwindcss/vite 4.3.x  zustand 5.0.x  axios 1.20.x  qrcode.react 4.2.x
three 0.186.x  @types/three 0.186.x  @react-three/fiber 9.7.x  @react-three/drei 10.7.x
lucide-react 0.9xx (icons)  clsx  sonner (toasts)
# api
hono 4.13.x  @hono/node-server 2.1.x  @hono/zod-validator  zod 4.x  drizzle-orm 0.45.x  drizzle-kit 0.31.x  pg 8.23.x  archiver (zip)
# tooling
typescript 6.0.x   ← NOT 7.x (Go compiler; no stable API yet, breaks typescript-eslint)
typescript-eslint 8.70.x  eslint 10.x  prettier  vitest 5.x (only if you write tests)
```

Why the pins matter:
- **React Router 8**: `react-router-dom` no longer exists — import everything from `react-router`. ESM-only. Needs Node 22.22+.
- **Vite 8**: bundler is Rolldown (Rust). `optimizeDeps.esbuildOptions` is deprecated. Unknown hostnames are **blocked** by the dev server unless listed in `server.allowedHosts` — this bites the tunnel (see below).
- **R3F 9 / drei 10**: React 19 pairing. R3F **10 is alpha** (renames `state.gl` → `state.renderer`); stay on 9.
- **TypeScript 7** is ~10× faster but `typescript-eslint` and most editor tooling can't use its API yet → pin 6.0.x. (If someone has 7 globally, the repo's local `tsc` wins.)
- **Zustand 5**: `create` API unchanged; selectors must return stable references (use `useShallow` for object selectors).
- **Tailwind 4**: no `tailwind.config.js`; `@import "tailwindcss";` in CSS and the `@tailwindcss/vite` plugin. Theme tokens via `@theme { --color-surface: #1A1D27; }`.

## Track C additionally

- `docker compose up -d` brings up Postgres 16 (`C0b` writes the compose file: image `postgres:16-alpine`, user/pass/db `vdv`, port 5432, volume).
- The tunnel (C7a): `cloudflared tunnel --url http://localhost:5173` prints `https://<random>.trycloudflare.com`. Put that in `apps/api/.env` as `PUBLIC_WEB_URL` and restart the API (QR codes embed it). Vite must have:
  ```ts
  // apps/web/vite.config.ts
  server: {
    host: true,
    allowedHosts: ['.trycloudflare.com'],
    proxy: { '/api': 'http://localhost:3000', '/files': 'http://localhost:3000' },
  }
  ```
  With this, the phone hits the tunnel → Vite → proxied API. **One tunnel only.** HTTPS is required for the camera; the tunnel provides it.
- ngrok works too (`ngrok http 5173`), but free-tier ngrok shows an interstitial page on first visit that breaks QR flows — prefer cloudflared.

## Track B additionally

- A real iPhone (Safari) and a real Android (Chrome) with charged batteries and the tunnel URL. iOS Simulator has **no camera** — don't bother.
- On iOS: Settings → Safari → Advanced → Web Inspector on, and on the Mac Safari → Develop → *iPhone* to see console logs from the phone. On Android: `chrome://inspect` on desktop Chrome.

## Track A additionally

- Download the Khronos **ToyCar** sample (`Models/ToyCar/glTF-Binary/ToyCar.glb` from github.com/KhronosGroup/glTF-Sample-Assets, ~6 MB) into `apps/api/samples/toycar.glb` and `apps/web/public/models/toycar.glb`. It is CC-BY-4.0, has PBR materials, and is a *car* — good enough for every viewer issue until D5a lands the real one.
- Install the React DevTools; the R3F scene shows up as components.

## Track D additionally — the GPU box

Pick one. All three verified as workable on 2026-09-13.

### Option 1 (recommended): EC2 `g5.xlarge` with the **NVIDIA GPU-Optimized AMI** (AWS Marketplace)
- ~$1.01/hr on-demand us-east-1. A10G 24 GB — plenty. Ubuntu 22.04 with NVIDIA driver, Docker and `nvidia-container-toolkit` preinstalled.
- Security group: inbound 22 from your IP, inbound **8080** from anywhere (worker; token-protected) or restrict to the venue's egress IP later.
- 200 GB gp3 root volume (Meshroom's Docker image alone is 16 GB compressed; job scratch is big).
- It's "on AWS" — the presentation can honestly say the reconstruction ran on an AWS GPU instance.

### Option 2: Lambda Labs on-demand (A10 / A100)
- A real VM: Docker + toolkit preinstalled, SSH key on signup. Slightly pricier for A100, but zero setup drama. US-only regions.

### Option 3: RunPod / Vast.ai pod
- Cheaper, but **pods are containers — you cannot run Docker inside them.** Use the Meshroom **Linux tarball** (`Meshroom-2025.1.0-Linux.tar.gz`, self-contained, needs only the host NVIDIA driver) or pick a base template that already contains COLMAP. Expose port 8080 via the pod's TCP port mapping.

### Verify the box (5 minutes)
```bash
ssh ubuntu@<ip>
nvidia-smi                                  # driver + GPU visible
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi   # toolkit works
df -h /                                     # ≥ 150 GB free
mkdir -p /data/jobs /data/samples
```

### Pull the engines (start these immediately — they're big)
```bash
docker pull alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1   # ~16 GB
docker pull yeicor/colmap-openmvs:cuda-latest                               # COLMAP + OpenMVS chain
```

### A sample dataset for the spike (before the real car photos exist)
Any 30–60 overlapping photos of a single object work. Fastest: take 40 photos of a parked car in the lot with a phone right now, `scp` them up. Alternative public sets: the COLMAP "south-building" or "gerrard-hall" datasets (colmap.github.io/datasets.html) — they are buildings, not cars, but exercise the full chain.

## Group chat pins (first 5 minutes)

- Tunnel URL (changes on every restart of `cloudflared`)
- GPU box IP + `WORKER_TOKEN`
- Postgres connection string
- Link to `docs/BOARD.md`
- Daylight window for the car shoot

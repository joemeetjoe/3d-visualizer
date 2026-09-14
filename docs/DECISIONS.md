# Decisions — 24h jam scope

Outcome of the planning/grilling session on 2026-09-13. **This document overrides `prd.md` wherever they conflict.** Anything cut is listed in `docs/issues/P0-post-jam-backlog.md` so it's visible in the presentation as "production path", not forgotten.

## The gap we're closing

The PRD is a 6-week, 4-phase plan on 9 AWS services. We have 24 hours, 4 generalist web developers with no 3D or computer-vision experience, one real car, one rented GPU box, and an executive audience for a 10-minute slides + live demo. The plan below keeps the PRD's *thesis* (real photogrammetry from a phone, professional 3D annotation tool) and cuts everything that is infrastructure rather than demonstration.

## Decisions

| # | Area | Decision | Why |
|---|---|---|---|
| D1 | Reconstruction | **Real** photogrammetry. The demo model is **pre-baked during the jam** from photos of the real car, and a **live re-run** is kicked off on stage. If the live job is slow or fails, the viewer loads the pre-baked model and we say so honestly. | Credibility requires real data; a live-only run is 5–10 min of dead air with real failure risk. |
| D2 | Engine | **Open until H4.** Track D runs both **Meshroom 2025.1** (one command, MPL-2.0, resolves the PRD's AGPL flag) and **COLMAP 4.2 + OpenMVS** (the PRD's exact chain via `yeicor/colmap-openmvs:cuda-latest`) on a sample dataset and picks one. Modern feed-forward options (VGGT) are documented as "what's next", not built. | Team wanted options; both are containerized; a 2-hour spike settles it with data instead of opinion. |
| D3 | Compute | One **rented Linux NVIDIA box** (EC2 g5.xlarge w/ NVIDIA GPU-Optimized AMI preferred — it's still "AWS" for the slide and has Docker + toolkit preinstalled; Lambda Labs as alternate). A tiny HTTP **job worker** runs on it. **No AWS Batch, ECR, CDK.** | RunPod-style container pods can't run Docker; Batch/ECR is a full day of yak-shaving with nothing demoable. |
| D4 | Infra | Everything else runs on a laptop: Postgres 16 in Docker Compose, Hono API as a plain Node server (Lambda-shaped handlers so it ports later), photos + models on local disk. **No S3, RDS, API Gateway, CloudFront, SES.** | Zero IAM/VPC time. The CDK stacks become a "production architecture" slide. |
| D5 | HTTPS | A **Cloudflare quick tunnel** exposes the Vite dev server (which proxies `/api` to Hono). Camera access on phones **requires HTTPS** — this is non-negotiable and is issue C7a. | `getUserMedia` is blocked on insecure origins; LAN IPs won't work. |
| D6 | Capture modes | **Walk-around auto-capture is primary** (customer walks a slow circle, app grabs a frame every ~1.5s, 40–60 photos). **8-anchor guided mode with a 3-shot burst per anchor (24 photos) is the fallback** and keeps the PRD's step-card UX. | PRD's 8 photos is far too few for photogrammetry (needs 60–80% overlap, ideally 2 heights). Two modes hedge iOS resolution limits (see guide 03). |
| D7 | Email | **Cut SES.** The Claim Created screen shows the capture link **large + copyable + as a QR code**. On stage the adjuster shows the QR and the customer scans it. | SES sandbox can't send to unverified addresses and production access takes ~24h. QR is a better demo beat anyway. |
| D8 | Annotations | **Pins + severity + notes + sidebar + jump-to + auto-save + JSON export are core.** **Paint region is stretch** (A5a/A5b) — only if pins are polished by ~H14. | Face-index painting is the single hardest UI feature in the PRD; the demo story is complete with pins. |
| D9 | Kept polish | Photo quality checks (blur/brightness/resolution), dashboard status filter + processing pulse, empty state, Export JSON, QR code. | Each is < 1h and makes the product feel finished. |
| D10 | Cut | Auth (already a PRD non-goal), pagination, tablet-specific work beyond what drei gives free, S3 lifecycle rules, Glacier, SES templates, CDK, multi-vehicle silhouettes. | Not visible in a 10-minute demo. |
| D11 | Database | **Postgres 16 in Docker Compose + Drizzle ORM.** Schema is PRD §9 plus `customer_email` and a `failed` status. | Matches PRD literally (UUID, JSONB); everyone has Docker; Drizzle gives typed queries and one-command push. |
| D12 | Customer API | Customer-facing routes are **token-scoped** (`/capture/:token/...`) rather than `/claims/:claimId/...`. | "Token in the URL is the only gate" — the phone should never need the claim UUID. See CONTRACTS. |
| D13 | Team | 4 tracks, self-selected: **A** Viewer, **B** Capture, **C** API + Dashboard + Integration lead + Presentation, **D** Pipeline. Track C owns slides + demo script from H12. | C has the lightest late-game load and the whole-system view. |
| D14 | Time | One contiguous 24h block, presentation at the end. Checkpoints at H2 / H8 / H16 / H20. | See PLAN.md. |
| D15 | Repo | No code before the jam. Docs, issues, contracts, skills only. Issues are markdown in `docs/issues/`; board in `docs/BOARD.md`. All in this directory. | Jam rules; offline-safe. |
| D16 | AI tooling | Everyone uses Claude Code. Skills ship in `.claude/skills/` in this repo; `CLAUDE.md` carries conventions. | Zero distribution effort — clone and go. |
| D17 | Versions | Pin **TypeScript 6.0.x** (TS 7's Go compiler has no stable API yet; `typescript-eslint` can't load it). R3F **9.x** (v10 is alpha). React Router **8** (`react-router` package only). Vite **8**. | Verified against npm on 2026-09-13; see SETUP.md. |

## Things we explicitly promised the presentation

1. Live: adjuster creates a claim → QR on screen → customer scans on a real phone → walk-around capture on the real car → upload progress on the phone → dashboard status flips to *processing* → *ready* → viewer shows a real reconstruction → pins placed → auto-saved → JSON exported.
2. Honest framing: "This model was reconstructed from 48 phone photos taken 40 minutes ago on the car outside. The live job you just saw kicked off will land in about N minutes; here's the one from this morning." (See `docs/presentation/DEMO_SCRIPT.md`.)
3. One slide on the production architecture from PRD §4/§5 and the license note (§10), showing we know the path.

## Open risks (owned)

| Risk | Owner | Mitigation |
|---|---|---|
| Car is too reflective / reconstruction has holes | D | Shoot in overcast light or shade, 2 heights, 50+ photos; matte-spray optional; tune in D5b; pre-bake the best of several runs. |
| iOS Safari gives 720p frames from `getUserMedia` | B | Log actual resolution in B1b; fallback to `<input capture>` burst mode which yields full-res photos. |
| GPU box unreachable from the venue | D + C | Worker has a shared-secret token and public port; the pre-baked model is the fallback; mock worker exists for rehearsal. |
| Tunnel URL changes on restart | C | `PUBLIC_WEB_URL` env + `pnpm tunnel` script prints the URL and updates `.env`; QR always uses it. |
| Daylight window | D | If the jam starts after ~4pm, shoot the car **before** the jam starts or at first light; the dataset is issue D2a and is on the critical path for D5a. |

# Fallback plan — every beat has a plan B, and a plan C

Principle: **the audience never sees a blank screen or a stack trace.** Every failure has a rehearsed sentence and a rehearsed action that takes < 20 seconds.

## Layers

| Layer | Primary | Plan B | Plan C |
|---|---|---|---|
| Network | Venue wifi + Cloudflare tunnel | Phone on cellular (tunnel is public; works) | Skip phone; `pnpm demo:upload-dataset` pushes pre-shot photos through the API from the laptop |
| Web app | Vite dev server on the demo laptop | Backup laptop with the repo cloned and `pnpm demo:up` tested at pre-flight | Backup video |
| API/DB | Local Hono + Docker Postgres | Restart (`pnpm demo:up`); data survives in the volume | Backup video |
| Camera | Live `getUserMedia` | File-input fallback with 15 pre-shot photos in the camera roll | Skip to upload-dataset |
| Pipeline | Real GPU worker, live job | Pre-baked model on the seeded `ready` claim (always shown anyway) | Mock worker (`WORKER_URL=localhost:8080`) to show the status flow with ToyCar — say it's a stand-in |
| Viewer | Real model | ToyCar sample via the seeded claim | Backup video |
| Slides | Google Slides online | `deck.pdf` local | Talk without slides — the script is the deck |
| Presenter | C | A (has rehearsed once) | — |

## Rehearsed failure sentences

- Tunnel/phone: "Wifi's being a wifi. Let me push the photos we took an hour ago through the same endpoint." → `pnpm demo:upload-dataset <claimId>`.
- Worker: "The GPU box is being shy — which is a good moment to show what the adjuster sees on a failure: a clear status and a Retry. Here's the model from this morning."
- Viewer load: "Model didn't fetch — Retry." (click) If second failure: switch to the other `ready` claim.
- Anything else: "Let me show you the recording while I bring this back." Play video; keep talking over it.

## Pre-flight checklist (RUNBOOK.md has the commands)

- [ ] Both laptops: repo at the same commit, `pnpm demo:up` works, `demo-car.glb` present
- [ ] `pnpm demo:reset` run on the demo laptop; the live claim's QR opens on the phone
- [ ] Worker `/health` green from the demo laptop; one throwaway job submitted and completed in the last hour
- [ ] Phone: 100%, DND on, brightness max, Safari tabs closed, pre-shot photos in the camera roll, tunnel URL bookmarked
- [ ] Screen mirroring of the phone tested (QuickTime → iPhone, or a doc cam)
- [ ] Laptop: DND, zoom 125%, dashboard + slides open, this file on the second screen, backup video on the desktop
- [ ] Timer set; water; someone holds the clicker

## Kill switches (know these cold)
- Restart everything: `pnpm demo:up` (idempotent).
- New tunnel: `pnpm tunnel` → new URL → QR regenerates automatically on next claim create.
- Force a claim to `ready` with the pre-baked model: `pnpm demo:force-ready <claimId>` (C7b adds this — copies `demo-car.glb` into the claim folder and transitions status).

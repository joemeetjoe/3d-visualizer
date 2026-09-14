# Demo script — 10 minutes, executive audience

Presenter: Track C. Phone-holder: Track B (or D). Timekeeper: A. Everyone else: quiet, ready to help.
Format: slides for framing, live demo for proof. Slides ≈ 3 min, demo ≈ 6 min, buffer ≈ 1 min.

Fill in the blanks during D5a/D5b/B5a. **Rehearse twice at H20 (X4).**

## Honest numbers (fill in)
- Demo car: ______ (year/make/model/color) — photographed at ______ (time), light: ______
- Dataset: ____ photos, ____ minutes to capture, phone: ______, mode: walk / anchor
- Reconstruction: engine ______, ____ min on an AWS g5.xlarge (A10G) [or ______], mesh ____k triangles, ____ MB glb
- Live re-run expected duration: ____ min ("fast" preset)

## Pre-flight (30 min before) — see RUNBOOK.md
`pnpm demo:reset` done · tunnel up + URL in `.env` + QR verified from the phone · worker `/health` green · pre-baked claim opens in the viewer · phone at 100%, notifications off, brightness max · laptop: notifications off, zoom 125%, dashboard tab + slides tab + this script on a second screen · backup video on the desktop.

## Beat sheet

| # | Time | Who | Says | Does | Fallback |
|---|---|---|---|---|---|
| 1 | 0:00 | C | **The problem.** "An adjuster today gets 6 photos in an email and guesses. We wanted to know: can a customer, with nothing but their phone browser, give us an actual 3D model of the car — and can an adjuster work on it like a professional tool?" | Slide 1 | — |
| 2 | 0:45 | C | **What we built in 24 hours.** One sentence per box: create claim → customer captures → GPU reconstruction → 3D annotation. "Everything you'll see is real: real photos, real reconstruction, real database." | Slide 2 (flow) | — |
| 3 | 1:30 | C | **Create the claim.** "Adjuster starts here." | Dashboard → New Claim → type the demo car → Create → QR appears | If API down: `pnpm demo:up` on the backup laptop; talk over slide 2 for 60s |
| 4 | 2:15 | B | **Customer scans.** "No app. No login. The link is the key." | Phone scans QR (show phone on the doc cam / mirrored via QuickTime) → Start → camera opens | Camera denied → tap "use photos instead", pick 15 pre-shot photos from the camera roll (have them on the phone) |
| 5 | 2:45 | B + C | **Walk-around capture.** C narrates while B walks the car (if the car's outside: do 20 s of capture on the venue car *or* on a printed car photo on a chair — say which). "It's grabbing a frame every second and a half, rejecting blurry ones, and uploading as it goes — watch the counter on the dashboard." | Phone: ring fills. Laptop: detail page photo count climbs, status → `uploading` | Tunnel dead → B taps Finish on what's uploaded; if nothing uploaded, C runs `pnpm demo:upload-dataset <claimId>` (pre-shot photos) and says so |
| 6 | 4:00 | B | Finish → "You're done." | Status → `processing`, pulse on the dashboard | — |
| 7 | 4:15 | C | **The pipeline.** "That kicked off a real photogrammetry job on a GPU on AWS: feature matching, structure-from-motion, dense reconstruction, meshing, texturing. Watch the stage indicator. It takes about N minutes on the fast preset — so while it runs, here's the one we reconstructed from the same car this morning." | Slide 3 (pipeline stages, timing table) — 30 s | Worker down → status `failed` with Retry visible; "and this is what the adjuster sees when it fails — Retry; for today, here's this morning's" |
| 8 | 5:00 | C | **The viewer.** Open the pre-baked `ready` claim. Orbit slowly. "This is not a stock model. ___ photos, ___ minutes." | Orbit, zoom to the damage | Model fails to load → error card + Retry (rehearsed); second fallback: backup video |
| 9 | 5:45 | C | **Annotate.** "Pin tool. Click the dent." Type a note. Pick *Severe*. Second pin, *Minor*. "Every change auto-saves — reload." Reload → pins persist. Jump-to from the sidebar. Export JSON: "this is what feeds an estimating system." | Pins, popover, sidebar, reload, export | Autosave fails → manual Save button; "and here's the manual fallback" |
| 10 | 7:30 | C | **Check the live job.** Switch to the live claim. If `ready`: open it, orbit once — applause line. If still processing: show the stage, "it'll land in ~N; the model you just saw is the same pipeline." | Dashboard | Either outcome is a line in the script |
| 11 | 8:15 | C | **Production path.** "What ran today on one GPU box maps one-to-one onto the AWS architecture in the PRD: S3, Lambda, Batch, RDS, SES. The API is Lambda-shaped already; the upload URLs are S3-shaped already." License note in one sentence. | Slide 4 (architecture: today vs production) | — |
| 12 | 9:00 | C | **What we learned + asks.** Three bullets: lighting/reflection is the real challenge (and what pros do), photo count matters more than resolution, next step is a pilot with N real claims. | Slide 5 | — |
| 13 | 9:45 | C | Q&A. Team on stage. | — | — |

## Lines to have ready for questions
- *How accurate is the geometry?* "Photogrammetry from a phone is qualitative today — good enough to see where and how big the damage is, not to measure millimetres. Metric scale needs a reference object or LiDAR; the pipeline supports both later."
- *What about reflections / glass?* "The hardest part. Diffuse light, more photos, and in production, AI-based reconstruction (VGGT-class models) that's robust to it. We documented the tradeoffs."
- *Cost?* "About $0.15–0.50 of GPU time per claim at today's fast preset; spot instances halve that."
- *Privacy?* "Claims are UUIDs; no login; photos expire in 30 days in the production design."
- *Why not an app?* "Zero install is the whole point — a link in an SMS is the entire onboarding."
- *Licenses?* "Everything is MIT/BSD/MPL except OpenMVS (AGPL) — which is why we [chose Meshroom / flagged it for legal]."

## Don'ts
- Don't apologize for polish. Don't say "hack". Don't narrate bugs the audience didn't see.
- Don't wait silently for anything to load — always have the next sentence ready.
- Don't let anyone else touch the demo laptop after pre-flight.

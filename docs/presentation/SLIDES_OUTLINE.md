# Slide outline (≤ 9 slides, ≤ 20 words each; the demo carries the story)

Theme: dark (#0F1117 bg, #F0F2F8 text, #4F8EF7 accent), Inter, big type, one idea per slide. Build in Google Slides or Keynote; export PDF to `docs/presentation/deck.pdf`.

| # | Title | Content | Visual |
|---|---|---|---|
| 1 | **From six photos to a 3D claim** | The adjuster's problem in one line. | Hero photo of the demo car (from D2a) |
| 2 | **What happens in 24 hours** | 4 boxes: Create claim → Customer captures → GPU reconstruction → Adjuster annotates | Simple flow diagram; screenshots under each box |
| 3 | **Real photogrammetry** | Stages: features → matching → SfM → dense → mesh → texture. Timing table row (fast preset). Photo count. | Split: contact sheet of the 60 photos ↔ turntable clip of the model |
| 4 | **Today vs production** | Left: laptop + one GPU box. Right: PRD §4 (S3, Lambda, Batch, RDS, SES, CloudFront). Arrows showing each swap is a contract, not a rewrite. | Two-column architecture diagram |
| 5 | **What we learned** | 1. Light beats megapixels. 2. 50 photos > 8 photos. 3. Reflections are the frontier. | Before/after or a holey mesh vs a good one |
| 6 | **Open-source and licensing** | three.js MIT · React MIT · Hono MIT · COLMAP BSD · Meshroom MPL-2.0 · OpenMVS AGPL (flagged) | Logo row |
| 7 | **Next steps** | Pilot with N claims · auth + SES · metric scale · AI reconstruction eval | 3 bullets |
| 8 | **The team** | 4 names, 4 tracks | Photo from the jam |
| 9 | **Backup: live demo video** | Only if everything fails | Embedded recording |

Speaker notes live in `DEMO_SCRIPT.md`. Keep the deck boring; keep the demo alive.

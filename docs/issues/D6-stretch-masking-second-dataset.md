# D6 — STRETCH: background masking / second vehicle

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 2h | H19+ | stretch |

## What to build
Either (a) a second vehicle dataset so the dashboard has two real models, or (b) background masking to clean the mesh (Meshroom 2025 has a semantic segmentation plugin; or `rembg`/SAM to produce masks that COLMAP `--ImageReader.mask_path` consumes), or (c) a run on the *capture-app* photos specifically to prove the phone path end-to-end at high quality.

## Acceptance criteria
- [ ] One of (a)/(b)/(c) demonstrably improves the demo; otherwise skip and help C rehearse

## Blocked by
D5b

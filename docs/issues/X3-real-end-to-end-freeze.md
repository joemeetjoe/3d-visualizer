# X3 — Real end-to-end + feature freeze (H16, 30 min, everyone)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| All | HITL | 30m | H16 | todo |

## Script
Same as X2 but: the phone captures the real car (or the pre-shot dataset uploaded via a script if it's dark), the **real GPU worker** processes, and the viewer loads the real model. Time the processing. Then: **feature freeze** — list everything not merged; anything not landing by H17 is cut and moved to P0.

## Acceptance criteria
- [ ] Real model appears in the viewer through the real pipeline, hands-off
- [ ] Freeze list agreed; BOARD updated; stretch items explicitly kept or killed

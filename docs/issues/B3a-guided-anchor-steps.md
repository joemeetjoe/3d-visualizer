# B3a — Guided 8-anchor mode: step cards, diagram, progress

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1.5h | H10 | todo |

## What to build
The PRD §7.3 flow as the fallback mode: 8 steps with the exact instruction text from the PRD, a top-down car diagram (inline SVG) highlighting the current position with a camera icon, "3 of 8 positions captured" progress, Next/Back. Step state in `use-capture-store`. Full-screen instruction card first, then the viewfinder for that step (B3b).

## Acceptance criteria
- [ ] All 8 steps with PRD copy; diagram highlight moves; progress correct
- [ ] Back returns to a completed step and allows retake
- [ ] Works with the file-input fallback (no live camera) — this is the mode iOS uses if `getUserMedia` resolution is poor

## Blocked by
B1c

## Unblocks
B3b

## Read first
`prd.md §7.3 (table)`, `docs/guides/03-camera-capture.md §Guided mode`

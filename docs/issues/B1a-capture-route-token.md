# B1a — Capture route, token resolve, start screen

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1h | H2 | todo |

## What to build
`/capture/:token` (mobile-first, portrait, full-bleed dark UI): on mount `GET /capture/:token` → show vehicle ("2021 Toyota Camry") and a **Start** screen with three tips (walk slowly, keep the whole car in frame, overcast light is best), or an "invalid / expired link" state on 404, or a "photos already received" state if status ≥ `processing`. Mode chooser (Walk-around — recommended / Guided positions) — walk is default. Zustand `use-capture-store` created with `mode`, `claim`, `photos[]`, `uploadQueue`. Meta viewport + `100dvh` layout, no scroll, big tap targets.

## Acceptance criteria
- [ ] Seed token → start screen with vehicle name; garbage token → invalid state
- [ ] Layout fits an iPhone SE and a Pixel without scrolling; safe-area insets respected
- [ ] Mode chooser sets store; Start navigates to the capture screen (B1b)

## Blocked by
C0a; C2a for the real endpoint (mock `getPublicClaim` until then)

## Unblocks
B1b

## Read first
`docs/guides/03-camera-capture.md §Layout for phones`, `prd.md §7.3`

# C2b — Claim detail header

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1.5h | H9 | todo |

## What to build
`/claims/:claimId` page shell: persistent header above the viewer slot (PRD §7.5): vehicle line, copyable Claim ID (mono), `<StatusBadge>`, created date, adjuster notes with inline edit (click → textarea → blur saves via `PATCH /claims/:id`), "Mark as Reviewed" (→ `PATCH /status reviewed`), "Close Claim" (confirm dialog → `closed`), "Retry processing" (only when `failed`), "Show capture QR" (C1c). Below the header, a `<ViewerSlot>` that Track A fills: when status is `ready`/`reviewed`/`closed` render `<Viewer claimId>` (A's component), otherwise render a status card ("Model is still processing — stage: matching") that polls `GET /claims/:id/job` every 5s. Also a collapsible "Customer photos" strip using `GET /claims/:id/photos` (nice demo beat).

## Acceptance criteria
- [ ] Header shows all fields for seed claims; notes edit persists across reload
- [ ] Mark as Reviewed flips badge without reload; Close asks for confirmation
- [ ] Non-ready claim shows the status card with live stage text; flips to viewer automatically when status becomes `ready` (polling)
- [ ] Photo strip shows thumbnails for a claim with photos
- [ ] Layout: header ~72px, viewer fills the rest of the viewport (`h-[calc(100vh-72px)]`)

## Blocked by
C2a; A1a for the real `<Viewer>` (use a placeholder box until then)

## Unblocks
A3a, X2

## Read first
`prd.md §7.4.4, §7.5`, `docs/CONTRACTS.md §3`

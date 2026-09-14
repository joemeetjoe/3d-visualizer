# A2c — Annotations sidebar: list, jump-to, edit, delete

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H9 | todo |

## What to build
Right sidebar (shell from A1b) lists pins: severity badge, note preview (1 line), created time, "Jump to" and a kebab (Edit / Delete). "Jump to" tweens the camera to look at the pin from along its normal (~1.5 units away) over 400ms (drei `<CameraControls>` `setLookAt` with transition, or a manual lerp in `useFrame`). Right-click on a pin in the scene → delete with a confirm. Selecting a list row highlights the pin (scale up 1.3×) and vice versa. Empty state copy: "Click the vehicle with the Pin tool to mark damage."

## Acceptance criteria
- [ ] List reflects store instantly on add/edit/delete
- [ ] Jump-to animates smoothly and ends with the pin centered and facing the camera
- [ ] Right-click delete asks for confirmation; Delete in kebab does the same
- [ ] Row ↔ pin highlight is bidirectional

## Blocked by
A2b

## Unblocks
A3a

## Read first
`docs/guides/02-viewer-annotations-deep-dive.md §Camera tweens`, `prd.md §7.4.3`

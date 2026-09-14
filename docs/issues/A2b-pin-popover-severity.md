# A2b — Pin popover: note, severity, colors, hover tooltip

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H8 | todo |

## What to build
On placement (and on click of an existing pin in select mode), a drei `<Html>` popover anchored to the pin (`distanceFactor` off, `occlude` off, `zIndexRange`) with: note textarea (autofocus), severity segmented control (Minor / Moderate / Severe / Total Loss), Save + Delete. Severity → color map from shared-types applied to the sphere material (`emissive` too). Hover over a pin (`onPointerOver/Out`) shows a small tooltip with the note preview; cursor changes to pointer. Only one popover open at a time (store holds `activePinId`). Esc closes.

## Acceptance criteria
- [ ] Place → popover opens with textarea focused; type note, pick severity, Save → sphere recolors
- [ ] Hover shows note preview; click reopens editor; Esc closes
- [ ] Popover never renders behind the canvas or off-screen at the viewport edge (flip side if needed)
- [ ] Total Loss pins pulse (emissive intensity animated in `useFrame`, off under reduced motion)

## Blocked by
A2a

## Unblocks
A2c, A3a

## Read first
`docs/guides/02-viewer-annotations-deep-dive.md §Html overlays`, `prd.md §7.4.2 Tool 1`

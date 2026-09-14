# A5b — STRETCH: Region list, opacity, persist

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1h | H20 | stretch |

## What to build
Regions appear in the sidebar under pins: auto-label "Region N", color swatch, opacity slider (0.1–0.8), Jump to (frame the region's bounding sphere), Delete. Regions round-trip through the same auto-save (A3a) as `RegionAnnotation`s and export in A3b.

## Acceptance criteria
- [ ] Paint → region row appears; opacity slider updates overlay live
- [ ] Reload → region restored from face indices
- [ ] Export includes `regions`

## Blocked by
A5a

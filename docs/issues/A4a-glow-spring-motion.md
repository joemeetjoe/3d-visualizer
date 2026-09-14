# A4a — Severity glow halos, spring pop, reduced motion

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H14 | todo |

## What to build
PRD §13: "Damage pins glow with a halo effect proportional to severity." Add a billboarded halo (a `<sprite>` with a radial-gradient canvas texture, additive blending, size by severity) or a post-processing `Bloom` on emissive pins (`@react-three/postprocessing` — only if fps holds). Spring pop on mount (scale 0 → 1.15 → 1 over ~300ms in `useFrame` or `@react-spring/three`). All disabled under `prefers-reduced-motion` (`useReducedMotion` helper).

## Acceptance criteria
- [ ] Severe/Total Loss pins visibly glow; Minor barely; readable against the dark void
- [ ] New pins pop; existing pins loaded from API don't re-pop on every render
- [ ] 60 fps maintained with 30 pins; reduced-motion disables pop + pulse
- [ ] Screenshot for the deck sent to Track C

## Blocked by
A2b

## Read first
`docs/guides/02-viewer-annotations-deep-dive.md §Halos and motion`

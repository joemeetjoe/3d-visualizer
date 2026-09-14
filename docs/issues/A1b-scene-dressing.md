# A1b — Scene dressing: dark void, grid floor, lighting, vignette, toolbar shell

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H4 | todo |

## What to build
PRD §13 "signature element": background `#0F1117`, drei `<Grid>` floor (infinite, fade distance, subtle cell/section colors), `<Environment preset="city">` (or `studio`) for reflections + one `directionalLight` with soft shadows + low `ambientLight`, `<ContactShadows>` under the model, a CSS radial vignette overlay on the container, and a floating **glass-morphism toolbar** (left, vertical: Select / Pin / Paint(disabled) icons with tooltips) and a right **sidebar shell** (empty list container, slides in 200ms). Toolbar state lives in `use-viewer-store` (`tool: 'select' | 'pin' | 'paint'`).

## Acceptance criteria
- [ ] Matches the PRD description at a glance: model in a dark void on a grid with soft reflections
- [ ] Toolbar buttons toggle `tool` in the store; active state visible; keyboard 1/2/3
- [ ] Sidebar slides in from the right on mount (respects reduced motion)
- [ ] Still 60 fps with shadows on a MacBook; if not, drop shadow map size to 1024

## Blocked by
A1a

## Unblocks
A2a (tool mode), A2c (sidebar container)

## Read first
`docs/guides/01-three-js-and-r3f.md §Lighting, §drei helpers`, `prd.md §13`

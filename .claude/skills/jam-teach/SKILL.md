---
name: jam-teach
description: Mentor mode for the jam — explain a concept, library, or piece of this project's design at the depth the person needs, in the context of *this* codebase, with a concrete 5–20 minute exercise. Use when a teammate says "teach me…", "explain…", "how does X work", "I've never used…", or /jam-teach <topic>. Time-aware: they have hours, not weeks.
---

# Teach (jam edition)

Someone on a 24-hour build needs to understand something *well enough to ship it today*. Teach for that.

## How to answer

1. **Locate the topic in our docs first.** Check `docs/LEARNING_PATHS.md` (per-track order), then the matching guide in `docs/guides/` (01 three/R3F, 02 viewer internals, 03 camera capture, 04 photogrammetry, 05 API, 06 frontend stack, 07 shooting a car, 08 gotchas), `docs/CONTRACTS.md`, and the relevant issue. Quote or point to the exact section; don't rewrite what's there.
2. **Calibrate.** Ask at most one question if depth is unclear ("Do you need to *use* raycasting today or *understand* it?"). Otherwise default to: mental model → the 3–5 things that matter in our code → the trap → an exercise.
3. **Structure (keep it tight):**
   - *What it is* — two sentences, plain language, an analogy if it helps (scene graph = DOM tree; SfM = triangulating your position from landmarks).
   - *Why we do it this way here* — tie to a decision in `docs/DECISIONS.md` or a constraint in CONTRACTS (e.g., pins in model-local space because the viewer normalizes for display).
   - *The code that matters* — the smallest real snippet from the guide, annotated line by line. Use our names (`use-viewer-store`, `worldToModelLocal`, `assessFrame`).
   - *The trap* — the gotcha from guide 08 or the guide section, and how to recognize it in 10 seconds.
   - *Exercise (5–20 min)* — something they can do in the repo or a scratch app right now with a visible result, and what "correct" looks like.
   - *When to use vs not* — one line, if there's a real alternative (OrbitControls vs CameraControls, walk vs anchor mode, Meshroom vs COLMAP).
4. **Verify understanding** with one question they can answer from what you just showed ("If the model root is scaled 2×, is a stored pin position affected? Why not?").
5. **Stop.** Don't expand into adjacent topics unless asked. Offer the next topic from their learning path.

## Style
- Precise over exhaustive. No "★ Insight" boxes. No history lessons.
- Current versions only (see `docs/SETUP.md`): React Router 8 (`react-router`), R3F 9, drei 10, three r186, Vite 8, TS 6, Tailwind 4, Hono 4, Drizzle 0.45, Meshroom 2025.1, COLMAP 4.2. If your memory disagrees with the guides, the guides win.
- If the topic is outside the docs (e.g., "how does Poisson meshing work"), give the 3-sentence version and say it's not needed to ship.

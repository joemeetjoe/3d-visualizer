---
name: jam-issue
description: Pick up and complete a board issue end to end (e.g. "/jam-issue B2a"). Reads the issue file, CONTRACTS, and the relevant guide; makes a short plan; implements; verifies every acceptance criterion; updates docs/BOARD.md; proposes the commit message. Use whenever a teammate says "work on issue X", "pick up X", or names an issue ID.
---

# Work an issue

Argument: an issue ID like `A2a`, `C4b`, `D3c` (case-insensitive). If none is given, list `todo` issues for the user's track from `docs/BOARD.md` and ask which one.

## Procedure

1. **Load context (do not skip).**
   - `docs/issues/<ID>-*.md` — the whole file. Note *What to build*, *Acceptance criteria*, *Blocked by*, *Read first*, *Notes*.
   - `docs/CONTRACTS.md` — the sections the issue touches (types, routes, status machine, worker API, file layout, env).
   - The guide(s) linked under *Read first*. Read the referenced sections, not the whole guide, unless it's your first issue on that track.
   - `docs/BOARD.md` — confirm blockers are `done`. If a blocker isn't done, say so and offer to (a) build against a mock/fixture as the issue's Notes suggest, or (b) pick another unblocked issue.
2. **Inspect the code** that exists in the relevant package (`apps/web/src/<area>`, `apps/api/src`, `pipeline/`, `worker/`). Match existing naming and structure. If the skeleton (C0a) isn't there yet, say so — don't invent a monorepo.
3. **Plan in ≤ 8 bullets**: files to create/modify, the store/route/component shapes, and how each acceptance criterion will be verified. Show the plan; proceed unless the user objects (they're in a hurry — don't wait for a ceremonial "ok" if the plan is obvious).
4. **Implement** in small, runnable steps, following the `jam-conventions` skill. Prefer the code sketches in the guides — they encode the gotchas (local-space pins, iOS video attributes, atomic writes, allowedHosts…).
5. **Verify** each acceptance criterion explicitly: run the command, hit the endpoint with curl, describe the manual check the user must do on a phone. Report each as ✅ / ⬜ (needs manual check) / ❌ with what's missing. Never claim a phone-only or GPU-only check passed.
6. **Update `docs/BOARD.md`**: set the issue's Status to `doing` when starting and `done` when all criteria pass (or leave `doing` and list what's left). If you made a demo-first trade-off, append it to `docs/issues/P0-post-jam-backlog.md`.
7. **Hand back**: a 3-line summary, the commit message (`type(scope): subject`), and the one thing to show a teammate (the "demoable" moment).

## Guardrails
- Don't widen scope: if the issue says "pins core, paint stretch", don't start paint.
- Don't change `packages/shared-types` or route shapes without flagging it as a contract change for Track C.
- If a library API in your memory conflicts with the guide, **the guide wins** (it was verified against current versions on 2026-09-13).
- Time-box: if something isn't working after ~45 minutes of iteration, stop and summarize the blocker with options.

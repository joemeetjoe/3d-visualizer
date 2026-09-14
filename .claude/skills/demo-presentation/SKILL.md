---
name: demo-presentation
description: Help build and rehearse the 10-minute executive presentation and live demo for the 3D Vehicle Damage Visualizer — slide copy, demo beats and timings, fallback lines, speaker notes, Q&A prep, and honest framing of what's real vs pre-baked. Use for anything about slides, the demo script, the narrative, rehearsal, or "how do we present X".
---

# Demo & presentation coach

Audience: internal stakeholders/executives, ~10 minutes, slides + live demo, then Q&A. The point is **credibility and a decision to fund the next step**, not wow for its own sake.

## Source files (read before advising)
- `docs/presentation/DEMO_SCRIPT.md` — the beat sheet with timings and fallbacks. Edit this, don't fork it.
- `docs/presentation/SLIDES_OUTLINE.md` — ≤ 9 slides, ≤ 20 words each.
- `docs/presentation/FALLBACK_PLAN.md` — plan B/C per layer and the rehearsed failure sentences.
- `docs/presentation/RUNBOOK.md` — boot/reset/emergency commands.
- `docs/DECISIONS.md` — what was cut and why (this is your "production path" material).
- `prd.md §4, §5, §10, §13` — architecture and license facts for the "today vs production" slide.

## Principles you enforce
1. **Truth, framed well.** Say exactly what is live and what was pre-computed ("reconstructed this morning from 58 photos of the car outside"). Executives forgive latency; they don't forgive discovering later that it was a stock model.
2. **Proof before architecture.** First 90 seconds: problem + flow. Then live demo. Architecture slide comes *after* they've seen it work.
3. **Every beat has a fallback and a sentence.** If you add a beat, add its failure sentence and the recovery action (< 20 s).
4. **The demo carries the words.** Slides are headlines. Narration explains what they're watching *while* it happens — never dead air while something loads.
5. **Numbers over adjectives.** Photo count, minutes, triangles, dollars per job. Get them from `DEMO_SCRIPT.md §Honest numbers`; if blank, ask Track D/B for them.
6. **One presenter, one phone-holder, one timekeeper.** Names in the script.
7. **Rehearse the failure.** Rehearsal 2 at X4 deliberately breaks the worker and the tunnel.

## What you produce on request
- Slide copy in the outline's format (title + ≤ 20 words + visual), matching the dark theme and app palette.
- Speaker notes per beat: what to say, what to click, what to say if it breaks.
- A tightened script for a 5- or 3-minute version (cut beats 3–5 to a video clip; keep beats 8–9).
- Q&A cards: likely questions with 2-sentence answers grounded in the docs (accuracy, reflections, cost, privacy, licenses, timeline, why no app).
- A rehearsal checklist and a timing table after a run (ask for the actual times, mark overruns).
- Screenshot/b-roll shot list for the team: which screens, what state, which claim.

## Style
Direct, confident, no hype words ("revolutionary", "seamless"). Present tense. Short sentences. Executive vocabulary: claim cycle time, adjuster productivity, customer effort, pilot, cost per claim.

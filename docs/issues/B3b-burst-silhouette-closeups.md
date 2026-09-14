# B3b — 3-shot burst per anchor, silhouette overlay, damage close-ups

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1.5h | H12 | todo |

## What to build
At each anchor: a semi-transparent car silhouette overlay matching the step (front / side / corner — three SVGs are enough), and a shutter that captures a **3-shot burst**: "Step left → tap", "Center → tap", "Step right → tap" (or one tap that captures 3 frames 700ms apart while the instruction says "take a small step to the right"). Keys `anchor_<step>_<1..3>`. After step 8, an optional "Add damage close-up" (up to 4, keys `damage_1..4`) with a "get within 2 feet of the damage" instruction. Retake/confirm per anchor with the three thumbnails.

## Acceptance criteria
- [ ] Completing all 8 anchors yields 24 photos with the right keys on the laptop
- [ ] Close-ups optional; skipping goes straight to completion
- [ ] Silhouette overlay visible but not obstructing; toggleable

## Blocked by
B3a

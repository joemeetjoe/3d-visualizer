# C7b — Demo runbook + reset script

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H18 | todo |

## What to build
`pnpm demo:up` (docker compose up, API, web, tunnel, mock or real worker per env — one command, tmux/concurrently), `pnpm demo:reset` (db:reset, wipe `data/claims`, re-seed with: one `closed` example claim with annotations, one `ready` claim already pointing at the **pre-baked** demo model with 2 pins, one fresh `awaiting_capture` claim for the live run), and `docs/presentation/RUNBOOK.md` with the pre-flight checklist (charge phones, tunnel URL pinned, worker health green, pre-baked model present, browser zoom 125%, notifications off, second laptop as backup).

## Acceptance criteria
- [ ] Fresh laptop → `pnpm demo:up` → working app + tunnel URL in < 2 min
- [ ] `pnpm demo:reset` → clean seed in < 10s, twice in a row
- [ ] Runbook followed by someone who didn't write it, successfully, during X4

## Blocked by
C4b, D5a (for the pre-baked model path)

## Unblocks
X4

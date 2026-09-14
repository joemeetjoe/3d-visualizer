# D5b — Tune for < 10 min + timing table

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 2h | H15 | todo |

## What to build
The live re-run on stage must finish inside the talk or clearly not (and we say so). Find the `QUALITY=fast` settings that get a *presentable* model in < 10 min from 40–50 phone photos: image downscale (2000 → 1600px long edge), fewer features (`describerPreset=normal`), depth-map downscale (`--scale 2`/`3`), mesh decimation target (~300k faces), texture size 2048. Fill the timing table in the guide (dataset × settings × time × quality note). Set the worker default to the winner.

## Acceptance criteria
- [ ] Timing table with ≥ 4 rows; a "fast" preset that reliably finishes < 10 min on the demo dataset
- [ ] `ENGINE`/`QUALITY` defaults set on the worker
- [ ] Decision written into `DEMO_SCRIPT.md`: live job expected duration and what we say while it runs

## Blocked by
D5a

# D2b — Curate and resize the dataset

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 45m | H5 | todo |

## What to build
Drop blurry/duplicate frames (quick contact sheet: `montage` from ImageMagick or a Python thumbnail grid), keep 50–70. Produce a resized copy with the long edge at 2000px (`mogrify -resize 2000x2000\> *.jpg` or a Python/Pillow one-liner) for fast runs, keep originals for the final pre-bake. Write `dataset.md` with counts, phone model, lighting, and time of day.

## Acceptance criteria
- [ ] `/data/samples/democar/{images,images_2000}` on the box
- [ ] `dataset.md` committed under `pipeline/datasets/democar/`

## Blocked by
D2a

## Unblocks
D5a

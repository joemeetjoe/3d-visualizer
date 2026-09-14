# B4a — Quality gates: blur, brightness, resolution

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1.5h | H12 | todo |

## What to build
`assessPhoto(canvas): { blurScore, brightness, width, height, warnings[] }` run on a downscaled (≤ 640px) copy of each captured frame: **variance of Laplacian** for blur (warn below a threshold you calibrate on the real car — start ~60 on the 640px copy), mean luma for brightness (warn < 50/255 "too dark"), and resolution (warn if long edge < 1920). In walk mode, a blurry frame is **auto-discarded and re-captured** immediately (don't interrupt the walk; show a brief "blurry — retaking" pill). In anchor mode, show the warning with Retake / Use anyway. Runs in < 30ms so it doesn't stall capture (measure; move to a Web Worker only if needed).

## Acceptance criteria
- [ ] Wave the phone fast during walk mode → frames get discarded, counter doesn't advance, pill shows
- [ ] Cover the lens → "too dark" warning
- [ ] Thresholds documented in the guide with the numbers you measured on the demo car
- [ ] Assessment time logged in `?debug=1` overlay

## Blocked by
B2a

## Unblocks
B4b

## Read first
`docs/guides/03-camera-capture.md §Quality checks` (has the Laplacian implementation)

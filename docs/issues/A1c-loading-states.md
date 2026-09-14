# A1c — Loading, progress, error, and "still processing" states

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1h | H5 | todo |

## What to build
While the glb downloads: a skeleton (pulsing car silhouette SVG) + a progress bar driven by drei `useProgress` (works when the server sends `Content-Length` — C4c). On load error: an error card with Retry that re-mounts the loader (`useGLTF.clear(url)`). Export a `<ModelStatusCard status stage>` for C2b to use when the claim isn't `ready` ("Model is still processing — matching features…"). Preload the model with `useGLTF.preload` once the URL is known.

## Acceptance criteria
- [ ] Throttle network to Fast 3G in devtools: progress bar moves, then model appears
- [ ] Break the URL: error card with Retry; fix URL + Retry loads
- [ ] `<ModelStatusCard>` renders for every non-ready status with sensible copy
- [ ] No layout shift when the model appears

## Blocked by
A1a

## Read first
`docs/guides/01-three-js-and-r3f.md §Loading`, `prd.md §7.4.4`

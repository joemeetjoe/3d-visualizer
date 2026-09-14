# C4c — Static serving for models and photos

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 45m | H9 | todo |

## What to build
Harden `/files/*`: correct `Content-Type` (`model/gltf-binary` for `.glb`, `image/jpeg`), `Content-Length`, **Range** support (so the browser can show download progress and resume), `Cache-Control: no-cache` for models (they get replaced on retry) and `max-age=3600` for photos, path traversal protection, and 404 JSON. Vite proxies `/files` in dev (C0a already does).

## Acceptance criteria
- [ ] `curl -I /files/claims/<id>/model/model.glb` shows `Content-Length` and `Accept-Ranges: bytes`
- [ ] `curl -r 0-99` returns 206 with 100 bytes
- [ ] `../` in path → 400
- [ ] Track A's progress bar (A1c) shows real percentages on a 20 MB model

## Blocked by
C0c

## Unblocks
A1c (accurate progress)

## Read first
`docs/guides/05-api-hono-drizzle.md §Static files`

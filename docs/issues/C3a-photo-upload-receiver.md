# C3a — Upload targets + photo receiver

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1.5h | H6 | todo |

## What to build
`GET /capture/:token/upload-urls?mode=walk&count=60` returns `UploadTarget[]` whose `url` is `/api/v1/capture/:token/photos/:key` (same shape a presigned S3 URL would have — swap later). `PUT /capture/:token/photos/:key` accepts a raw `image/jpeg` body (≤ 15 MB), validates the key against the allowed patterns (`walk_\d{4}`, `anchor_[1-8]_[1-3]`, `damage_[1-4]`), writes atomically to `DATA_DIR/claims/<id>/raw/<key>.jpg` (write temp → rename), updates `raw/manifest.json`, and calls `transition(id, 'uploading')` on the first photo (idempotent). Overwrites allowed (retake).

## Acceptance criteria
- [ ] `curl -X PUT --data-binary @photo.jpg -H 'Content-Type: image/jpeg' .../photos/walk_0001` → 204 and file on disk
- [ ] Bad key → 400; unknown token → 404; non-JPEG content-type → 415
- [ ] Concurrent PUTs (10 at once) all succeed — no partial files
- [ ] `GET /claims/:id/photos` lists them with `/files/...` URLs
- [ ] Status flips `awaiting_capture → uploading` exactly once

## Blocked by
C2a

## Unblocks
B1c, C3b

## Read first
`docs/CONTRACTS.md §3 (customer routes), §5`, `docs/guides/05-api-hono-drizzle.md §Binary uploads`

## Notes
Use `c.req.arrayBuffer()` for the raw body (not `parseBody` — that's multipart). Increase `@hono/node-server` body limit if needed. Keep the key in the URL, not the body, so retries are idempotent.

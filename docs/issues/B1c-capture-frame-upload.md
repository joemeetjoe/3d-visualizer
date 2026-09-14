# B1c — Capture one frame → JPEG → upload → thumbnail

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1.5h | H6 | todo |

## What to build
`captureFrame(video): Promise<Blob>` draws the current video frame to an offscreen canvas at the track's native resolution and encodes `image/jpeg` at quality 0.92 (`canvas.toBlob`). (No `ImageCapture.takePhoto()` — Safari lacks it.) Upload path: `GET /capture/:token/upload-urls?mode=walk&count=60` once at start → for each capture, `PUT` the blob to the next target's `url` with `Content-Type: image/jpeg` via Axios with `onUploadProgress`; queue lives in `use-capture-store` with per-photo `status: 'captured' | 'uploading' | 'done' | 'failed'`. A thumbnail strip at the bottom shows captured frames (object URLs, revoked on unmount). A big shutter button. Photos from the file-input fallback go through the same queue.

## Acceptance criteria
- [ ] Tap shutter → thumbnail appears instantly, uploads in background, turns green on 204
- [ ] File lands on the laptop at `data/claims/<id>/raw/walk_0000.jpg` at the camera's native resolution
- [ ] Airplane mode mid-upload → photo marked failed, retry button works when back online
- [ ] Memory stays flat over 60 captures (blobs released after upload; no full-size images kept in React state)

## Blocked by
B1b, C3a (mock the PUT to a local no-op until C3a lands)

## Unblocks
B2a, B3a, D2a (use the app to shoot the car if ready)

## Read first
`docs/guides/03-camera-capture.md §Capturing a frame, §Uploading`

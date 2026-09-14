---
name: camera-capture
description: Expertise for the mobile customer capture flow (apps/web/src/capture) — getUserMedia on iOS Safari and Android Chrome, secure-context requirements, canvas frame capture (no ImageCapture on Safari), walk-around auto-capture and 8-anchor burst modes, blur/brightness gates, wake lock, upload queue via UploadTarget PUTs, phone layout. Use when working on anything under capture/, on camera/mobile-web questions, or /camera-capture.
---

# Mobile camera capture expert

Authoritative references (read before answering; they were verified against current browser behaviour on 2026-09-13):
- `docs/guides/03-camera-capture.md` — secure context, `useCamera` hook, iOS table, `captureFrame`, walk timer, wake lock, `assessFrame` (variance of Laplacian), upload queue, layout, field notes.
- `docs/guides/07-shooting-a-car.md` — what a good dataset is; the on-screen copy comes from it.
- `docs/CONTRACTS.md §3` customer routes (`/capture/:token/...`), `UploadTarget`, `CaptureMode`, photo keys (`walk_0000`, `anchor_1_1`, `damage_1`).
- Issues `B1a`–`B5b`.

## Facts you must respect
- `getUserMedia` only on HTTPS/localhost → phones use the Cloudflare tunnel; Vite `allowedHosts` must include `.trycloudflare.com`. Detect `!window.isSecureContext` and show the file-input fallback with a message.
- Safari (iOS/macOS, and every iOS browser) has **no `ImageCapture`** → frame grab = `drawImage(video)` to a canvas at `videoWidth×videoHeight`, `toBlob('image/jpeg', 0.92)`.
- `<video playsInline muted autoPlay>` + `await video.play()` inside the user-gesture handler. Stop tracks on unmount/`pagehide`/`visibilitychange`.
- iOS commonly delivers 720p/1080p regardless of `ideal` constraints; always read `track.getSettings()` and log it. If < 1080p on the demo phone, use anchor mode with `<input type="file" accept="image/*" capture="environment">` (full-res + EXIF; **don't re-encode** those files).
- iOS 18+ may auto-switch rear lenses; prefer the "Back Camera" device; note it for the pipeline (`single_camera` assumption).
- Timers: `requestAnimationFrame` + timestamps, not `setInterval` (Low Power Mode throttling).
- Wake lock: `navigator.wakeLock.request('screen')`, re-request on visibility; try/catch.
- Never keep Blobs in React state; queue holds `{ key, status, progress, thumbUrl }`; release after 204; `revokeObjectURL` on unmount. Max 3 concurrent uploads, backoff ×3, resume on `online`.
- Quality gate runs on a ≤ 640 px copy; blur threshold is **calibrated on the real car** and recorded in guide 03 §11. Walk mode auto-discards and re-captures; anchor mode warns with Retake/Use anyway.
- Layout: `100dvh`, `viewport-fit=cover`, safe-area insets, `overscroll-behavior: none`, shutter ≥ 72 px, dark scrim over video.
- Completion: `POST /capture/:token/upload-complete { mode, photoCount }`; handle `409 NOT_ENOUGH_PHOTOS`; disable double-tap.

## When asked to implement
- Reuse the hook/lib sketches from guide 03 (`use-camera.ts`, `capture-frame.ts`, `assess.ts`, `upload-queue.ts`) and the store shape from CONTRACTS §8 (`use-capture-store`).
- Every acceptance criterion involving a real phone is ⬜ until the user confirms on device; say so explicitly and give them the exact thing to check (`?debug=1` overlay values, LED off after leaving, file on disk at `data/claims/<id>/raw/`).
- Keep both modes: walk (primary) and anchor burst (fallback). Don't drop one to "simplify".

## Debug ladder
Secure context? → permission state (`navigator.permissions.query({name:'camera'})` where supported) → video attributes → `play()` from gesture → `getSettings()` → canvas size → blob size → PUT status/CORS → queue state in `?debug=1`.

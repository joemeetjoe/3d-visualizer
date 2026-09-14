# Guide 03 — Camera capture on mobile browsers (getUserMedia, iOS quirks, quality checks, uploads)

Track B's blueprint. Verified against MDN + WebKit/Chrome behaviour as of September 2026. Read §2 (secure context) and §4 (iOS) before writing a line — they're where the day gets lost.

## 1. What we're building, in one paragraph

A mobile web page (no app install) that opens the rear camera in a live viewfinder, grabs still frames either automatically every ~1.5 s while the customer walks around the car (**walk mode**, 40–60 photos) or on tap at 8 guided positions with a 3-shot burst (**anchor mode**, 24 photos), checks each frame for blur/darkness/resolution, encodes it as JPEG, uploads it immediately to our API, and finally tells the API "upload complete". Photogrammetry needs many sharp, overlapping, well-lit photos — the UX exists to make an untrained person produce that dataset.

## 2. Secure context — non-negotiable

`navigator.mediaDevices.getUserMedia` exists **only** on secure origins: `https://…` or `http://localhost`. A phone opening `http://192.168.1.20:5173` gets `navigator.mediaDevices === undefined`. There is no flag, no workaround the customer could use. Therefore:

- Development on a phone goes through the **Cloudflare tunnel** (`docs/SETUP.md`), which gives a real HTTPS URL. Vite must allow the host (`server.allowedHosts: ['.trycloudflare.com']`) or you get a 403 page.
- Detect it and say so: `if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) → show "Open the secure link we sent you"` plus the file-input fallback (which works on http too).
- iOS Simulator has no camera. Android emulator has a fake one. **Test on real phones.**

## 3. Opening the camera

```ts
// capture/hooks/use-camera.ts
import { useCallback, useEffect, useRef, useState } from 'react';

export type CameraStatus = 'idle' | 'requesting' | 'live' | 'denied' | 'unsupported' | 'error';

export interface CameraInfo { width: number; height: number; facingMode?: string; deviceLabel?: string }

export function useCamera() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [status, setStatus] = useState<CameraStatus>('idle');
  const [info, setInfo] = useState<CameraInfo | null>(null);

  const stop = useCallback(() => {
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    if (videoRef.current) videoRef.current.srcObject = null;
    setStatus('idle');
  }, []);

  const start = useCallback(async () => {
    if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) { setStatus('unsupported'); return; }
    setStatus('requesting');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: 'environment' },   // rear camera; 'exact' throws on devices without one
          width: { ideal: 3840 }, height: { ideal: 2160 },  // ask big; you'll get what the browser allows
          frameRate: { ideal: 30 },
        },
      });
      streamRef.current = stream;
      const track = stream.getVideoTracks()[0];
      const s = track.getSettings();
      setInfo({ width: s.width ?? 0, height: s.height ?? 0, facingMode: s.facingMode, deviceLabel: track.label });
      const v = videoRef.current!;
      v.srcObject = stream;
      await v.play();                     // must be after a user gesture on iOS (the Start button)
      setStatus('live');
    } catch (err) {
      const name = (err as DOMException).name;
      setStatus(name === 'NotAllowedError' || name === 'SecurityError' ? 'denied' : 'error');
    }
  }, []);

  useEffect(() => {
    const onHide = () => { if (document.visibilityState === 'hidden') stop(); };
    document.addEventListener('visibilitychange', onHide);
    window.addEventListener('pagehide', stop);
    return () => { document.removeEventListener('visibilitychange', onHide); window.removeEventListener('pagehide', stop); stop(); };
  }, [stop]);

  return { videoRef, status, info, start, stop };
}
```

The `<video>` element — every attribute matters on iOS:

```tsx
<video ref={videoRef} playsInline muted autoPlay className="h-full w-full object-cover" />
```

- `playsInline` — without it iOS opens the fullscreen native player.
- `muted` — autoplay policy; even with `audio: false`, Safari wants it.
- `autoPlay` + explicit `await video.play()` inside the click handler — Safari requires a user gesture to start media.
- `object-cover` — the stream's aspect ratio (usually 4:3 or 16:9 *landscape sensor* even in portrait) won't match the screen; cover crops it. **Remember: what the user sees is cropped; the captured frame is the full sensor frame.** Draw the bracket overlay accordingly (or capture the visible crop — our choice: capture the full frame; photogrammetry wants pixels).

Constraints are *requests*, not orders: `ideal` values let the browser pick the closest supported mode. Always read `track.getSettings()` afterwards and show it in the `?debug=1` overlay — this number decides which mode the demo phone uses (§4).

## 4. iOS Safari specifics (also iOS Chrome/Firefox — they're all WebKit)

| Behaviour | Consequence | What we do |
|---|---|---|
| **No `ImageCapture` API** (`takePhoto()`/`grabFrame()` unsupported in Safari, macOS and iOS) | Can't request a full-res still from the camera pipeline | Draw the `<video>` frame to a canvas (§5). Works everywhere. |
| `getUserMedia` often returns **1280×720 or 1920×1080** regardless of `ideal: 3840` | Frames are video-resolution, fewer pixels for feature matching | Acceptable for walk mode (60 frames × 1080p is a decent dataset). If B5a measures < 1080p on the demo phone, use **anchor mode with `<input capture>`**, which yields native 12 MP photos with EXIF. |
| Permission prompt re-appears per page load; permission is per-origin per-session | Reloading mid-demo re-prompts | Don't reload. Keep the session in one SPA route. Rehearse the tap. |
| Camera stops when the tab is backgrounded or the phone locks | Stream dead on return | Wake lock (§7) + `visibilitychange` restart with a "Tap to resume" button (must be a user gesture). |
| iOS 18+: automatic lens switching (wide ↔ ultrawide) on the rear camera when `facingMode: environment` | Focal length changes mid-walk — bad for photogrammetry (intrinsics change) | Prefer enumerating devices and picking the label containing "Back Camera" (not "Ultra Wide"/"Dual"); or set `zoom` constraint if `getCapabilities().zoom` exists. Note it in field notes; Meshroom/COLMAP will still work (they estimate per-image intrinsics if needed — COLMAP: don't force `--single_camera 1` if lens switched). |
| `navigator.vibrate` unsupported | No haptics | Use a Web Audio tick instead. |
| Low Power Mode throttles `setInterval` and video fps | Capture cadence drifts | Use `requestAnimationFrame` + timestamp comparison for the timer, not `setInterval`. |
| `canvas.toBlob('image/jpeg', q)` fine; `toBlob('image/webp')` unsupported on older iOS | — | Always JPEG. |
| Max canvas size ~16M pixels on iOS | 4K frames are 8.3M — OK | Don't exceed 4096×4096. |

Android Chrome: `ImageCapture.takePhoto()` exists and *can* return a full-res still, but its behaviour varies (autofocus stalls, 1–2 s latency, some devices return the video frame anyway). For a jam, **use the canvas path on all platforms** and treat `ImageCapture` as an optional upgrade behind a flag.

## 5. Capturing a frame

```ts
// capture/lib/capture-frame.ts
export interface CapturedFrame { blob: Blob; width: number; height: number; capturedAt: string }

export async function captureFrame(video: HTMLVideoElement, quality = 0.92): Promise<CapturedFrame> {
  const width = video.videoWidth, height = video.videoHeight;   // native stream size, not CSS size
  if (!width || !height) throw new Error('video not ready');
  const canvas = new OffscreenCanvas(width, height);            // Safari 16.4+; fallback to document.createElement('canvas')
  const ctx = canvas.getContext('2d')!;
  ctx.drawImage(video, 0, 0, width, height);
  const blob = await canvas.convertToBlob({ type: 'image/jpeg', quality });
  return { blob, width, height, capturedAt: new Date().toISOString() };
}
```

- Draw at `videoWidth × videoHeight` — the intrinsic size. Using the element's CSS size gives you a tiny image.
- Quality 0.9–0.95: photogrammetry hates JPEG artifacts more than it hates file size. A 1080p frame at 0.92 is ~500–900 KB.
- Reuse one canvas (module-level) instead of allocating per frame if you see GC pauses.
- These JPEGs have **no EXIF** (no focal length, no orientation). That's fine: Meshroom falls back to a default sensor width and estimates focal length; COLMAP uses `1.25 × max(w,h)` as the initial focal and refines. Orientation: the frame is stored exactly as drawn, so no rotation issue.
- The file-input fallback yields the phone's real photo (with EXIF, possibly rotated by EXIF orientation). Modern browsers honour EXIF orientation when drawing to canvas (`image-orientation: from-image` is default); if you pass the File straight through without re-encoding, the server/pipeline also handles EXIF fine. **Do not re-encode file-input photos** — you'd throw away 12 MP.

## 6. Walk-around mode (B2a) — the timer

```ts
// inside the capture screen component
const running = useRef(false); const last = useRef(0);
function loop(ts: number) {
  if (!running.current) return;
  if (ts - last.current >= intervalMs) {
    last.current = ts;
    void captureAndEnqueue();   // never await inside the rAF loop
  }
  requestAnimationFrame(loop);
}
// start: running.current = true; last.current = performance.now(); requestAnimationFrame(loop);
```

- `intervalMs` 1500 at a slow walk ≈ one photo every ~1 m around a car ≈ 45–60 per lap. Good overlap.
- Show a ring (SVG `stroke-dasharray`) filling toward the target, the count, and rotating instructions. Halfway through, tell them to lower the phone for the second half (two heights → better mesh; see guide 07).
- Quality gate (§8) runs on the frame *before* it's enqueued; a blurry frame is dropped and the counter doesn't advance — the customer just keeps walking.

## 7. Wake lock, feedback, orientation

- `const lock = await navigator.wakeLock.request('screen')` (iOS 16.4+, Android). Released automatically when the tab hides; re-request on `visibilitychange` → visible. Wrap in try/catch — it throws on low battery.
- Shutter tick without an audio file: create an `AudioContext` on Start (user gesture), then per capture play a 40 ms sine at 1200 Hz with a quick gain envelope. `navigator.vibrate?.(30)` for Android.
- Orientation: we ask for portrait (PRD). Detect with `screen.orientation?.type` or `matchMedia('(orientation: landscape)')` and show a hint; don't try to lock (`screen.orientation.lock` needs fullscreen and is unsupported on iOS).

## 8. Quality checks (B4a)

Run on a downscaled copy (≤ 640 px long edge) — accuracy is fine and it takes ~5–15 ms.

```ts
// capture/lib/assess.ts
export interface Assessment { blur: number; brightness: number; width: number; height: number; warnings: string[] }

export function assessFrame(video: HTMLVideoElement, opts = { blurMin: 60, darkMax: 50, minLongEdge: 1920 }): Assessment {
  const W = 640, H = Math.round((video.videoHeight / video.videoWidth) * W);
  const c = assessCanvas ??= new OffscreenCanvas(W, H);
  const ctx = c.getContext('2d', { willReadFrequently: true })!;
  ctx.drawImage(video, 0, 0, W, H);
  const { data } = ctx.getImageData(0, 0, W, H);

  // grayscale
  const g = new Float32Array(W * H);
  let sum = 0;
  for (let i = 0, j = 0; i < data.length; i += 4, j++) { g[j] = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]; sum += g[j]; }
  const brightness = sum / (W * H);

  // variance of Laplacian (4-neighbour kernel)
  let mean = 0, m2 = 0, n = 0;
  for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++) {
    const i = y * W + x;
    const l = 4 * g[i] - g[i - 1] - g[i + 1] - g[i - W] - g[i + W];
    n++; const d = l - mean; mean += d / n; m2 += d * (l - mean);   // Welford
  }
  const blur = m2 / n;

  const warnings: string[] = [];
  if (blur < opts.blurMin) warnings.push('blurry');
  if (brightness < opts.darkMax) warnings.push('too dark');
  if (Math.max(video.videoWidth, video.videoHeight) < opts.minLongEdge) warnings.push('low resolution');
  return { blur, brightness, width: video.videoWidth, height: video.videoHeight, warnings };
}
let assessCanvas: OffscreenCanvas | undefined;
```

- **Calibrate `blurMin` on the real car** in daylight: log `blur` for 20 good frames and 20 deliberately shaken ones; pick a threshold between the clusters (typically 40–120 at 640 px; uniform car panels score lower than textured scenes — that's expected). Write the numbers in §11.
- Brightness: mean luma < 50 is genuinely dark; 50–80 is dim (warn softly). Overexposed (> 230) is rarer outdoors but worth a warning for glare.
- Resolution warning is informational for walk mode (the browser decides); in anchor mode it nudges toward the file-input path.

## 9. Uploading (B1c/B4b)

Flow: at session start `GET /capture/:token/upload-urls?mode=walk&count=80` → array of `{ key, url, method: 'PUT', headers }`. Each capture takes the next target and `PUT`s the blob. This shape is exactly what S3 presigned URLs look like, so production is a one-line swap on the server.

```ts
// capture/lib/upload-queue.ts (sketch)
import axios from 'axios';
export async function uploadPhoto(target: UploadTarget, blob: Blob, onProgress: (p: number) => void, signal?: AbortSignal) {
  await axios.put(target.url, blob, {
    headers: { 'Content-Type': 'image/jpeg', ...target.headers },
    onUploadProgress: (e) => onProgress(e.total ? e.loaded / e.total : 0),
    signal, timeout: 30_000,
  });
}
```

Queue rules (store in `use-capture-store`): max 3 in flight; retry ×3 with 1s/2s/4s backoff on network errors or 5xx; resume on `window 'online'`; keep only `{ key, status, progress, thumbUrl }` in React state — **not the Blob** (release after success; keep failed blobs for retry, capped). Thumbnails: `URL.createObjectURL(blob)` at capture time, drawn from a 160 px canvas copy so you're not holding 60 × 1 MB object URLs; `revokeObjectURL` on unmount.

Completion: when every item is `done`, `POST /capture/:token/upload-complete { mode, photoCount }`. Handle `409 NOT_ENOUGH_PHOTOS` (back to capture with a message) and double-tap (disable the button after first tap).

## 10. Layout for phones

- `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` and `height: 100dvh` (not `100vh`, which ignores the URL bar). `padding-bottom: env(safe-area-inset-bottom)` for the home indicator.
- The viewfinder is the whole screen; controls overlay it with `position: fixed; bottom`. Shutter ≥ 72 px, thumb-reachable. Everything else ≥ 44 px.
- Prevent pull-to-refresh and rubber-banding: `overscroll-behavior: none` on `html, body`; `touch-action: none` on the viewfinder.
- Dark UI (PRD palette). White text on the live video needs a gradient scrim at top/bottom.
- Test both an iPhone SE-sized (375×667) viewport and a tall Android.

## 11. Field notes (fill in during B1b / B5a)

| Phone | Browser | `getSettings()` w×h | fps | Permission UX | Wake lock | Upload MB/s via tunnel | Notes |
|---|---|---|---|---|---|---|---|
| | iOS Safari | | | | | | |
| | iOS Chrome | | | | | | |
| | Android Chrome | | | | | | |

Blur threshold measured on the demo car: good frames __–__, shaken __–__ → `blurMin = __`.

**Demo phone + mode chosen:** ______ (write it in `docs/presentation/DEMO_SCRIPT.md` too).

## 12. References

- MDN `getUserMedia`: https://developer.mozilla.org/docs/Web/API/MediaDevices/getUserMedia
- MDN `MediaTrackConstraints` / `getSettings`: https://developer.mozilla.org/docs/Web/API/MediaTrackSettings
- MDN `ImageCapture` (support table — note Safari): https://developer.mozilla.org/docs/Web/API/ImageCapture
- MDN Screen Wake Lock: https://developer.mozilla.org/docs/Web/API/Screen_Wake_Lock_API
- W3C image-capture implementation status: https://github.com/w3c/mediacapture-image/blob/main/implementation-status.md
- Variance of Laplacian reference implementation: https://github.com/thesimon82/Laplacian-Blur-Detector

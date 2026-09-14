# Contracts — types, API, state machine, worker, files

**Frozen at checkpoint X1 (H2).** After that, changes go through Track C and are announced in chat. Every track codes against this document, not against each other's in-progress code. Package name for shared types: `@vdv/shared-types` (`packages/shared-types`).

## 1. Shared types (`packages/shared-types/src/index.ts`)

```ts
export const CLAIM_STATUSES = [
  'awaiting_capture', // link created, no photos yet
  'uploading',        // ≥1 photo received
  'processing',       // upload-complete received, job dispatched
  'ready',            // model.glb available
  'failed',           // pipeline failed (can retry → processing)
  'reviewed',         // adjuster saved annotations or pressed Mark Reviewed
  'closed',           // terminal
] as const;
export type ClaimStatus = (typeof CLAIM_STATUSES)[number];

export const SEVERITIES = ['minor', 'moderate', 'severe', 'total_loss'] as const;
export type Severity = (typeof SEVERITIES)[number];

export interface Vec3 { x: number; y: number; z: number }

export interface Claim {
  id: string;                 // uuid
  captureToken: string;       // uuid — the customer link
  vehicleYear: number;
  vehicleMake: string;
  vehicleModel: string;
  vehicleColor: string | null;
  adjusterNotes: string | null;
  customerEmail: string | null;
  status: ClaimStatus;
  photoCount: number;         // derived from files on disk
  modelKey: string | null;    // e.g. "claims/<id>/model/model.glb"
  jobId: string | null;       // worker job id
  jobError: string | null;
  createdAt: string;          // ISO 8601
  updatedAt: string;
}

/** What the customer's phone is allowed to see. */
export interface PublicClaim {
  id: string;
  vehicleYear: number;
  vehicleMake: string;
  vehicleModel: string;
  vehicleColor: string | null;
  status: ClaimStatus;
  photoCount: number;
}

export interface CreateClaimInput {
  vehicleYear: number;        // 1980..currentYear+1
  vehicleMake: string;        // 1..50 chars
  vehicleModel: string;       // 1..50 chars
  vehicleColor?: string;      // ≤30
  adjusterNotes?: string;
  customerEmail?: string;     // display only
}

export interface PinAnnotation {
  id: string;                 // uuid, generated client-side
  type: 'pin';
  position: Vec3;             // model-local coordinates (see §6)
  normal: Vec3;               // unit face normal at hit
  severity: Severity;
  note: string;
  createdAt: string;
}

export interface RegionAnnotation {
  id: string;
  type: 'region';
  faceIndices: number[];      // triangle indices into the model's merged geometry
  label: string;              // "Region 1"
  color: string;              // "#F7604F"
  opacity: number;            // 0..1
  createdAt: string;
}

export type Annotation = PinAnnotation | RegionAnnotation;

export interface AnnotationExport {
  claimId: string;
  vehicle: string;            // "2021 Toyota Camry, Silver"
  exportedAt: string;
  pins: PinAnnotation[];
  regions: RegionAnnotation[];
}

export interface UploadTarget {
  key: string;                // "walk_0007" | "anchor_3_2" | "damage_1"
  url: string;                // absolute or root-relative PUT URL
  method: 'PUT';
  headers: Record<string, string>; // { 'Content-Type': 'image/jpeg' }
}

export type CaptureMode = 'walk' | 'anchor';

export interface PhotoInfo { key: string; url: string; sizeBytes: number; createdAt: string }

/** Worker (GPU box) job — mirrored by the mock worker. */
export type JobStatus = 'queued' | 'running' | 'done' | 'failed';
export interface Job {
  jobId: string;
  status: JobStatus;
  stage: string | null;       // "feature_extraction" | "matching" | "sfm" | "depth" | "mesh" | "texture" | "export"
  progress: number | null;    // 0..1 if known
  logTail: string[];          // last ~20 lines
  startedAt: string | null;
  finishedAt: string | null;
  error: string | null;
}

export interface ApiError { error: { code: string; message: string; details?: unknown } }
```

Severity → color (viewer and dashboard use the same map):

| Severity | Hex | Notes |
|---|---|---|
| `minor` | `#F7C94F` | amber |
| `moderate` | `#F79A4F` | orange |
| `severe` | `#F7604F` | damage red |
| `total_loss` | `#B3261E` | dark red, pulsing halo |

## 2. Status state machine

```
awaiting_capture ─(first photo PUT)─▶ uploading ─(upload-complete)─▶ processing ─(job done)─▶ ready ─(annotations PUT or Mark Reviewed)─▶ reviewed ─(Close)─▶ closed
                                                                       │
                                                                       └─(job failed)─▶ failed ─(retry)─▶ processing
```

Allowed transitions (enforced in `services/claim-status.ts`; `PATCH /status` rejects anything else with `409 INVALID_TRANSITION`):

| From | To |
|---|---|
| awaiting_capture | uploading |
| uploading | uploading, processing |
| processing | ready, failed |
| failed | processing |
| ready | reviewed, closed |
| reviewed | closed, ready (un-review) |
| closed | — |

Adjuster buttons: **Mark as Reviewed** → `reviewed`; **Close Claim** → `closed` (confirm dialog); **Retry processing** (only when `failed`) → `processing`.

## 3. HTTP API (Hono, `apps/api`)

Base: `/api/v1` (Vite proxies `/api` → `http://localhost:3000`, so the browser and the phone only ever talk to the web origin). JSON everywhere except photo PUT and file GETs. Errors: `{ error: { code, message, details? } }` with 400/404/409/500.

### Adjuster routes

| Method | Path | Body → Response |
|---|---|---|
| `GET` | `/health` | → `{ ok: true, db: true, worker: 'ok' \| 'unreachable' }` |
| `POST` | `/claims` | `CreateClaimInput` → `201 { claim: Claim, captureUrl: string }` (`captureUrl = ${PUBLIC_WEB_URL}/capture/${captureToken}`) |
| `GET` | `/claims?status=ready` | → `{ claims: Claim[] }` sorted `updatedAt desc` |
| `GET` | `/claims/:claimId` | → `{ claim: Claim, captureUrl: string }` |
| `PATCH` | `/claims/:claimId` | `{ adjusterNotes?: string }` → `{ claim }` |
| `PATCH` | `/claims/:claimId/status` | `{ status: ClaimStatus }` → `{ claim }` or `409` |
| `GET` | `/claims/:claimId/photos` | → `{ photos: PhotoInfo[] }` |
| `GET` | `/claims/:claimId/model-url` | → `{ url: string, sizeBytes: number }` or `409 MODEL_NOT_READY` |
| `GET` | `/claims/:claimId/job` | → `{ job: Job \| null }` (proxied from worker; lets the UI show pipeline stage) |
| `GET` | `/claims/:claimId/annotations` | → `{ annotations: Annotation[] }` |
| `PUT` | `/claims/:claimId/annotations` | `{ annotations: Annotation[] }` → `{ annotations }` (replace-all, transactional; sets status `ready → reviewed`) |

### Customer routes (token-scoped, no claim id needed)

| Method | Path | Body → Response |
|---|---|---|
| `GET` | `/capture/:token` | → `{ claim: PublicClaim }` or `404` |
| `GET` | `/capture/:token/upload-urls?mode=walk&count=60` | → `{ uploads: UploadTarget[] }` — keys `walk_0000..walk_0059`; `mode=anchor` → `anchor_1_1..anchor_8_3` + `damage_1..damage_4` |
| `PUT` | `/capture/:token/photos/:key` | raw `image/jpeg` body → `204`; sets status `uploading` on first photo |
| `POST` | `/capture/:token/upload-complete` | `{ mode: CaptureMode, photoCount: number }` → `{ claim: PublicClaim }`; requires ≥ 12 photos on disk, sets `processing`, dispatches job |

### Files (static, served by the API with range support)

| Path | Serves |
|---|---|
| `GET /files/claims/:claimId/raw/:key.jpg` | uploaded photo |
| `GET /files/claims/:claimId/model/model.glb` | the model (this is what `/model-url` returns) |
| `GET /files/samples/toycar.glb` | sample model used by the mock worker and Track A |

## 4. Worker API (GPU box, `worker/`; mock in `apps/api/mock-worker`)

Auth: header `X-Worker-Token: <shared secret>` on every request. Listens on `:8080`.

| Method | Path | Body → Response |
|---|---|---|
| `GET` | `/health` | → `{ ok: true, gpu: string, engine: 'meshroom' \| 'colmap-openmvs' \| 'mock', queue: number }` |
| `POST` | `/jobs` | multipart: `photos` (zip of jpgs, flat), `claimId` (string) → `202 { job: Job }` |
| `GET` | `/jobs/:jobId` | → `{ job: Job }` |
| `GET` | `/jobs/:jobId/model.glb` | → binary when `done`, else `409` |
| `DELETE` | `/jobs/:jobId` | → `204` (cleanup) |

Dispatcher behaviour (C4b): zip `data/claims/<id>/raw/*.jpg` → `POST /jobs` → store `jobId` → poll every 10s → on `done` download glb to `data/claims/<id>/model/model.glb`, set `modelKey`, status `ready` → on `failed` set `jobError`, status `failed`. Poll loop survives API restarts by scanning claims in `processing` with a `jobId` at boot.

Mock worker: same routes; `POST /jobs` returns `queued`, flips to `running` with fake stages every 3s, `done` after ~15s, and serves `apps/api/samples/toycar.glb`. Set `MOCK_WORKER_FAIL=1` to simulate `failed`.

## 5. File layout on disk (`DATA_DIR`, default `./data`, gitignored)

```
data/
  claims/<claimId>/
    raw/<key>.jpg                 uploaded photos (key from UploadTarget)
    raw/manifest.json             { mode, receivedAt: {key: iso}, deviceInfo? }
    model/model.glb               final optimized model
    model/job.json                last Job payload from the worker
  samples/toycar.glb              Khronos ToyCar sample (Track A, mock worker)
```

## 6. Model conventions (Track D produces, Track A consumes)

- glTF 2.0 binary (`.glb`), **Y-up**, centered at origin, sitting on the `y = 0` plane, uniformly scaled so the longest dimension ≈ **4.5 units** (a car). Draco-compressed geometry, WebP textures ≤ 2048px, target ≤ 25 MB.
- Single mesh preferred. If multiple, the viewer merges for raycast via `scene.traverse`. Face indices in `RegionAnnotation` refer to the **first mesh's** index buffer (document the mesh name in `model/job.json` if more than one).
- Pin `position`/`normal` are in the model's local space *after* the viewer's normalization (`<Bounds fit>` is display-only; do not bake it into coordinates). Practically: store `event.point` and `event.face.normal` transformed by `object.matrixWorld` inverse — see guide 02.

## 7. Environment variables

`apps/api/.env`:

```
PORT=3000
DATABASE_URL=postgres://vdv:vdv@localhost:5432/vdv
DATA_DIR=./data
PUBLIC_WEB_URL=http://localhost:5173          # ← set to the tunnel URL for the demo (QR codes use this)
WORKER_URL=http://localhost:8080              # mock; real: http://<gpu-box-ip>:8080
WORKER_TOKEN=change-me
JOB_POLL_INTERVAL_MS=10000
```

`apps/web/.env`:

```
VITE_API_BASE=/api/v1
```

`worker/.env` (GPU box):

```
PORT=8080
WORKER_TOKEN=change-me
ENGINE=meshroom            # or colmap-openmvs
WORK_DIR=/data/jobs
MAX_IMAGE_SIZE=2000        # downscale long edge before reconstruction
```

## 8. Web routes (`apps/web`)

| Route | Page | Track |
|---|---|---|
| `/` | Dashboard | C |
| `/claims/new` | Create claim → Claim Created (QR) | C |
| `/claims/:claimId` | Claim detail header (C) + Viewer (A) | C + A |
| `/capture/:token` | Customer capture flow | B |

Zustand stores: `use-claims-store` (C), `use-viewer-store` (A: tool mode, annotations, save state), `use-capture-store` (B: mode, photos, upload queue).

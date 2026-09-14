# Guide 05 — The API: Hono 4 + Drizzle + Postgres, uploads, static files, calling the worker

Track C's blueprint. Versions verified 2026-09-13: `hono@4.13`, `@hono/node-server@2.1`, `@hono/zod-validator`, `zod@4`, `drizzle-orm@0.45`, `drizzle-kit@0.31`, `pg@8.23`, Postgres 16, Node 22+. The shapes come from `docs/CONTRACTS.md` — this guide is *how*, that one is *what*.

## 1. Layout

```
apps/api/
  src/
    index.ts              createApp() + serve()
    app.ts                Hono instance, middleware, route mounting, onError
    env.ts                zod-validated process.env → typed config
    errors.ts             AppError
    routes/
      health.ts  claims.ts  capture.ts  annotations.ts  files.ts
    services/
      claims.ts  claim-status.ts  uploads.ts  pipeline.ts  annotations.ts
    db/
      client.ts  schema.ts  claims.ts  annotations.ts
    lib/
      fs.ts (atomic write, ensureDir)  zip.ts  worker-client.ts
  mock-worker/index.ts
  samples/toycar.glb
  drizzle.config.ts  .env  package.json
```

Rule from CLAUDE.md: routes validate + call services; services hold logic + call db/*; db/* is Drizzle only.

## 2. Hono basics

```ts
// src/app.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { HTTPException } from 'hono/http-exception';
import { AppError } from './errors';
import { health } from './routes/health'; import { claims } from './routes/claims'; /* … */

export function createApp() {
  const app = new Hono();
  app.use('*', logger());
  app.use('/api/*', cors({ origin: (o) => (/localhost|trycloudflare\.com$/.test(o ?? '') ? o : ''), allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }));
  app.route('/api/v1/health', health);
  app.route('/api/v1/claims', claims);
  app.route('/api/v1/capture', capture);
  app.route('/files', files);
  app.notFound((c) => c.json({ error: { code: 'NOT_FOUND', message: `No route ${c.req.method} ${c.req.path}` } }, 404));
  app.onError((err, c) => {
    if (err instanceof AppError) return c.json({ error: { code: err.code, message: err.message, details: err.details } }, err.status);
    if (err instanceof HTTPException) return c.json({ error: { code: 'HTTP', message: err.message } }, err.status);
    console.error(err);
    return c.json({ error: { code: 'INTERNAL', message: 'Internal error' } }, 500);
  });
  return app;
}
```

```ts
// src/errors.ts
import type { ContentfulStatusCode } from 'hono/utils/http-status';
export class AppError extends Error {
  constructor(public status: ContentfulStatusCode, public code: string, message: string, public details?: unknown) { super(message); }
}
```

```ts
// src/index.ts
import { serve } from '@hono/node-server';
import { createApp } from './app';
import { env } from './env';
import { startPoller } from './services/pipeline';
serve({ fetch: createApp().fetch, port: env.PORT }, (info) => console.log(`api on :${info.port}`));
startPoller();
```

Dev script: `tsx watch src/index.ts`. Hono handlers are `(c) => Response`-shaped, i.e., Lambda/API-Gateway-portable via `hono/aws-lambda` later — that's the "production path" line.

## 3. Validation with zod + `@hono/zod-validator`

```ts
// src/routes/claims.ts
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { CLAIM_STATUSES } from '@vdv/shared-types';
import * as claims from '../services/claims';

const currentYear = new Date().getFullYear();
export const createClaimSchema = z.object({
  vehicleYear: z.number().int().min(1980).max(currentYear + 1),
  vehicleMake: z.string().trim().min(1).max(50),
  vehicleModel: z.string().trim().min(1).max(50),
  vehicleColor: z.string().trim().max(30).optional(),
  adjusterNotes: z.string().max(5000).optional(),
  customerEmail: z.string().email().optional(),
});

export const claimsRoute = new Hono()
  .post('/', zValidator('json', createClaimSchema, (r, c) => {
      if (!r.success) return c.json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid claim', details: r.error.issues } }, 400);
    }), async (c) => {
    const { claim, captureUrl } = await claims.create(c.req.valid('json'));
    return c.json({ claim, captureUrl }, 201);
  })
  .get('/', zValidator('query', z.object({ status: z.enum(CLAIM_STATUSES).optional() })), async (c) =>
    c.json({ claims: await claims.list(c.req.valid('query').status) }))
  .get('/:claimId', async (c) => c.json(await claims.getWithUrl(c.req.param('claimId'))));
```

Share the zod schemas with the web app? Easiest: export them from `packages/shared-types` too (zod is a runtime dep there then). It keeps client-side validation identical. Fine for the jam.

## 4. Drizzle + Postgres

```ts
// src/db/schema.ts
import { pgTable, uuid, smallint, varchar, text, timestamp, jsonb, index } from 'drizzle-orm/pg-core';
import type { Annotation } from '@vdv/shared-types';

export const claims = pgTable('claims', {
  id: uuid('id').primaryKey().defaultRandom(),
  captureToken: uuid('capture_token').notNull().unique().defaultRandom(),
  vehicleYear: smallint('vehicle_year').notNull(),
  vehicleMake: varchar('vehicle_make', { length: 50 }).notNull(),
  vehicleModel: varchar('vehicle_model', { length: 50 }).notNull(),
  vehicleColor: varchar('vehicle_color', { length: 30 }),
  adjusterNotes: text('adjuster_notes'),
  customerEmail: varchar('customer_email', { length: 255 }),
  status: varchar('status', { length: 30 }).notNull().default('awaiting_capture'),
  s3RawPrefix: varchar('s3_raw_prefix', { length: 255 }),
  s3ModelKey: varchar('s3_model_key', { length: 255 }),      // we store "claims/<id>/model/model.glb" here
  batchJobId: varchar('batch_job_id', { length: 255 }),      // worker jobId
  jobError: text('job_error'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
}, (t) => [index('idx_claims_status').on(t.status), index('idx_claims_capture_token').on(t.captureToken)]);

export const annotations = pgTable('annotations', {
  id: uuid('id').primaryKey().defaultRandom(),
  claimId: uuid('claim_id').notNull().references(() => claims.id, { onDelete: 'cascade' }),
  type: varchar('type', { length: 20 }).notNull(),          // 'pin' | 'region'
  data: jsonb('data').$type<Annotation>().notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
}, (t) => [index('idx_annotations_claim').on(t.claimId)]);
```

```ts
// src/db/client.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';
export const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 10 });
export const db = drizzle(pool, { schema });
```

```ts
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';
export default defineConfig({ dialect: 'postgresql', schema: './src/db/schema.ts', out: './drizzle', dbCredentials: { url: process.env.DATABASE_URL! } });
```

Commands: `drizzle-kit push` (no migration files — fine for a jam), `drizzle-kit studio` (a browser UI over the DB — handy for demos and debugging). `db:reset` = `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` via `psql` or `pool.query`, then push + seed.

Queries you'll write (all in `db/claims.ts`):

```ts
import { and, desc, eq } from 'drizzle-orm';
export const insertClaim = (v: NewClaim) => db.insert(claims).values(v).returning().then((r) => r[0]);
export const listClaims = (status?: ClaimStatus) => db.select().from(claims).where(status ? eq(claims.status, status) : undefined).orderBy(desc(claims.updatedAt));
export const findClaim = (id: string) => db.query.claims.findFirst({ where: eq(claims.id, id) });
export const findByToken = (token: string) => db.query.claims.findFirst({ where: eq(claims.captureToken, token) });
export const updateClaim = (id: string, patch: Partial<NewClaim>) => db.update(claims).set(patch).where(eq(claims.id, id)).returning().then((r) => r[0]);
```

Replace-all annotations in a transaction (C5):

```ts
export async function replaceAnnotations(claimId: string, items: Annotation[]) {
  return db.transaction(async (tx) => {
    await tx.delete(annotations).where(eq(annotations.claimId, claimId));
    if (items.length) await tx.insert(annotations).values(items.map((a) => ({ id: a.id, claimId, type: a.type, data: a })));
    return tx.select().from(annotations).where(eq(annotations.claimId, claimId));
  });
}
```

Row → API shape: write one `toClaim(row, photoCount): Claim` mapper in `services/claims.ts` (camelCase is already handled by Drizzle column aliases; add `photoCount`, rename `s3ModelKey → modelKey`, `batchJobId → jobId`).

## 5. The status state machine (C2a)

```ts
// src/services/claim-status.ts
import type { ClaimStatus } from '@vdv/shared-types';
const ALLOWED: Record<ClaimStatus, ClaimStatus[]> = {
  awaiting_capture: ['uploading'],
  uploading: ['uploading', 'processing'],
  processing: ['ready', 'failed'],
  failed: ['processing'],
  ready: ['reviewed', 'closed'],
  reviewed: ['closed', 'ready'],
  closed: [],
};
export function canTransition(from: ClaimStatus, to: ClaimStatus): boolean { return ALLOWED[from].includes(to); }
export async function transition(claimId: string, to: ClaimStatus) {
  const claim = await findClaim(claimId); if (!claim) throw new AppError(404, 'CLAIM_NOT_FOUND', 'Claim not found');
  if (claim.status === to && to === 'uploading') return claim;                       // idempotent first-photo case
  if (!canTransition(claim.status as ClaimStatus, to)) throw new AppError(409, 'INVALID_TRANSITION', `${claim.status} → ${to}`, { from: claim.status, to });
  return updateClaim(claimId, { status: to });
}
```

One vitest table test over `ALLOWED` is the only test we require today.

## 6. Binary uploads (C3a)

Raw body, not multipart — the phone `PUT`s the JPEG bytes:

```ts
// src/routes/capture.ts
const KEY_RE = /^(walk_\d{4}|anchor_[1-8]_[1-3]|damage_[1-4])$/;
capture.put('/:token/photos/:key', async (c) => {
  const key = c.req.param('key'); if (!KEY_RE.test(key)) throw new AppError(400, 'BAD_KEY', 'Invalid photo key');
  if (!/^image\/jpeg/.test(c.req.header('content-type') ?? '')) throw new AppError(415, 'UNSUPPORTED_TYPE', 'JPEG only');
  const claim = await uploads.claimForToken(c.req.param('token'));
  const bytes = new Uint8Array(await c.req.arrayBuffer());
  if (bytes.byteLength > 15 * 1024 * 1024) throw new AppError(413, 'TOO_LARGE', 'Max 15 MB');
  await uploads.storePhoto(claim.id, key, bytes);          // atomic write + manifest + transition('uploading')
  return c.body(null, 204);
});
```

```ts
// src/lib/fs.ts
import { mkdir, rename, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
export async function writeAtomic(path: string, data: Uint8Array) {
  await mkdir(dirname(path), { recursive: true });
  const tmp = `${path}.${process.pid}.${Date.now()}.tmp`;
  await writeFile(tmp, data); await rename(tmp, path);          // rename is atomic on the same filesystem
}
```

`@hono/node-server` has no default body-size cap for `arrayBuffer()`; we cap manually above. Ten concurrent PUTs are fine — each is its own file.

`GET /upload-urls` just fabricates targets: `{ key, url: \`/api/v1/capture/${token}/photos/${key}\`, method: 'PUT', headers: { 'Content-Type': 'image/jpeg' } }` for `count` keys. Nothing is stored; it's purely so the client speaks the S3-presigned dialect.

## 7. Static files with range support (C4c)

`@hono/node-server/serve-static` handles `Content-Type` and basic serving but not `Range`. A 40-line handler is more predictable for progress bars:

```ts
// src/routes/files.ts
import { createReadStream, promises as fsp } from 'node:fs';
import { join, normalize } from 'node:path';
import { stream } from 'hono/streaming';
const TYPES: Record<string, string> = { '.glb': 'model/gltf-binary', '.jpg': 'image/jpeg', '.json': 'application/json' };
files.get('/*', async (c) => {
  const rel = normalize(c.req.path.replace(/^\/files\//, ''));
  if (rel.startsWith('..') || rel.includes('/../')) throw new AppError(400, 'BAD_PATH', 'Nope');
  const abs = join(env.DATA_DIR, rel);
  const st = await fsp.stat(abs).catch(() => null); if (!st?.isFile()) throw new AppError(404, 'FILE_NOT_FOUND', rel);
  const ext = abs.slice(abs.lastIndexOf('.')); const type = TYPES[ext] ?? 'application/octet-stream';
  const range = c.req.header('range'); let start = 0, end = st.size - 1, status = 200;
  if (range) { const m = /bytes=(\d*)-(\d*)/.exec(range); if (m) { start = m[1] ? +m[1] : 0; end = m[2] ? +m[2] : end; status = 206; } }
  c.header('Content-Type', type); c.header('Accept-Ranges', 'bytes'); c.header('Content-Length', String(end - start + 1));
  c.header('Cache-Control', ext === '.glb' ? 'no-cache' : 'public, max-age=3600');
  if (status === 206) c.header('Content-Range', `bytes ${start}-${end}/${st.size}`);
  c.status(status);
  return stream(c, async (s) => { for await (const chunk of createReadStream(abs, { start, end })) await s.write(chunk); });
});
```

Vite proxies `/files` in dev; in production this would be S3 + presigned GET.

## 8. Calling the worker (C4b)

```ts
// src/lib/worker-client.ts
import type { Job } from '@vdv/shared-types';
const h = () => ({ 'X-Worker-Token': env.WORKER_TOKEN });
export async function submitJob(claimId: string, zip: Blob): Promise<Job> {
  const fd = new FormData(); fd.set('photos', zip, 'photos.zip'); fd.set('claimId', claimId);
  const r = await fetch(`${env.WORKER_URL}/jobs`, { method: 'POST', headers: h(), body: fd, signal: AbortSignal.timeout(120_000) });
  if (!r.ok) throw new Error(`worker ${r.status}`); return (await r.json()).job as Job;
}
export async function getJob(jobId: string): Promise<Job> { const r = await fetch(`${env.WORKER_URL}/jobs/${jobId}`, { headers: h() }); if (!r.ok) throw new Error(`worker ${r.status}`); return (await r.json()).job; }
export async function downloadModel(jobId: string, dest: string) {
  const r = await fetch(`${env.WORKER_URL}/jobs/${jobId}/model.glb`, { headers: h() }); if (!r.ok || !r.body) throw new Error(`worker ${r.status}`);
  await mkdir(dirname(dest), { recursive: true }); await pipeline(Readable.fromWeb(r.body as any), createWriteStream(`${dest}.tmp`)); await rename(`${dest}.tmp`, dest);
}
```

Zipping with `archiver` to a temp file (streaming), then `new Blob([await readFile(tmp)])` — for 60 × 1 MB that's fine in memory; if you want to avoid buffering entirely, use `undici`'s `FormData` with a stream or just accept it for the jam.

Poller (one interval; idempotent; resumes on boot):

```ts
export function startPoller() {
  setInterval(async () => {
    const inflight = await db.select().from(claims).where(and(eq(claims.status, 'processing'), isNotNull(claims.batchJobId)));
    for (const c of inflight) {
      try {
        const job = await getJob(c.batchJobId!);
        await writeJson(`${env.DATA_DIR}/claims/${c.id}/model/job.json`, job);
        if (job.status === 'done') { await downloadModel(job.jobId, modelPath(c.id)); await updateClaim(c.id, { s3ModelKey: `claims/${c.id}/model/model.glb` }); await transition(c.id, 'ready'); }
        else if (job.status === 'failed') { await updateClaim(c.id, { jobError: job.error }); await transition(c.id, 'failed'); }
      } catch (e) { console.warn('poll', c.id, (e as Error).message); }
    }
  }, env.JOB_POLL_INTERVAL_MS);
}
```

## 9. Seed data (C0b) — what the demo needs

1. `closed` claim with 3 annotations (shows history).
2. `ready` claim with `s3ModelKey = 'samples/toycar.glb'` (→ `demo-car.glb` once D5a lands) and 2 pins — the "here's one from earlier" fallback.
3. `processing` claim with a fake `batchJobId` that the mock worker knows (or leave `null` so the poller ignores it) — shows the pulse.
4. `awaiting_capture` claim — the live one. `demo:reset` always recreates this with a fresh token.

Fixed UUIDs so the demo script can hardcode URLs.

## 10. Gotchas

- Hono `c.req.param()` returns decoded strings; UUIDs are safe, but validate with `z.string().uuid()` where it matters.
- `zValidator` returns 400 with its own body unless you pass the hook — use the hook so errors match our `{ error }` envelope.
- Drizzle `jsonb().$type<T>()` is a compile-time hint only; validate on the way in (zod) — the DB won't.
- `updatedAt.$onUpdate` only fires through Drizzle `update()` — raw SQL bypasses it.
- `pg` needs `DATABASE_URL` without `?sslmode` for local Docker.
- Two API processes = two pollers = double downloads. Run one.
- CORS isn't needed for same-origin requests through the Vite proxy, but keep it for direct `curl`/other-origin testing.

# Guide 06 — Frontend stack: Vite 8, React 19, TypeScript 6, React Router 8, Tailwind 4, Zustand 5, Axios

What's different from the tutorials in your head, and the patterns we use. Versions verified 2026-09-13.

## 1. Vite 8

- Bundler is **Rolldown** (Rust) for dev and build; esbuild/Rollup are gone. Existing config mostly works via a compatibility layer; `optimizeDeps.esbuildOptions` → `optimizeDeps.rolldownOptions` (deprecated alias still works). Builds are ~10–25× faster; you'll notice nothing else.
- **Dev server host check**: unknown `Host` headers get a 403. For the tunnel: `server.allowedHosts: ['.trycloudflare.com']`. `localhost` and raw IPs are always allowed.
- `server.host: true` to listen on all interfaces (LAN testing), `server.proxy` for `/api` and `/files` → `http://localhost:3000`.
- Env: `import.meta.env.VITE_*` only. `VITE_API_BASE=/api/v1`.
- Node ≥ 22.12 (React Router 8 raises it to 22.22).

```ts
// apps/web/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: { host: true, allowedHosts: ['.trycloudflare.com'], proxy: { '/api': 'http://localhost:3000', '/files': 'http://localhost:3000' } },
});
```

## 2. React 19

- `use(promise)` and native Suspense for data; R3F's `useGLTF` relies on this.
- `ref` is a normal prop — no `forwardRef` needed for new components.
- `<Context>` can be rendered directly as a provider (`<ThemeContext value={…}>`).
- Actions/`useActionState`/`useFormStatus` exist; for our two forms, plain controlled state + Zustand is simpler and fine.
- StrictMode double-invokes effects in dev — camera hooks must be idempotent (start/stop cleanly), and `useGLTF` handles it.

## 3. TypeScript 6 (deliberately not 7)

TS 7.0 (July 2026) is the Go-native compiler: ~10× faster, same semantics, **no stable programmatic API yet** → `typescript-eslint` and most editor plugins run against 6.x. Pin `"typescript": "~6.0.3"` in the root `package.json`. When TS 7.1 ships an API, upgrading is a version bump. Config baseline:

```jsonc
// tsconfig.base.json
{ "compilerOptions": { "target": "ES2022", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "bundler",
  "strict": true, "noUncheckedIndexedAccess": true, "verbatimModuleSyntax": true, "jsx": "react-jsx", "skipLibCheck": true, "types": ["vite/client"] } }
```

House rules: explicit return types on exported functions; `import type` for types (verbatimModuleSyntax enforces it); no `any` — use `unknown` and narrow.

## 4. React Router 8

- Package is **`react-router`** (there is no `react-router-dom` any more). Imports: `import { createBrowserRouter, RouterProvider, Link, useParams, useNavigate, Outlet, NavLink } from 'react-router'`.
- ESM-only; needs React ≥ 19.2.7, Vite ≥ 7, Node ≥ 22.22.
- We use **declarative/data mode in the browser** (no framework mode/SSR). Middleware is on by default but irrelevant to us.

```tsx
// apps/web/src/main.tsx
import { createBrowserRouter, RouterProvider } from 'react-router';
const router = createBrowserRouter([
  { path: '/', Component: AppLayout, children: [
    { index: true, Component: DashboardPage },
    { path: 'claims/new', Component: CreateClaimPage },
    { path: 'claims/:claimId', Component: ClaimDetailPage },
  ]},
  { path: '/capture/:token', Component: CapturePage },   // no AppLayout — mobile shell
]);
createRoot(document.getElementById('root')!).render(<StrictMode><RouterProvider router={router} /></StrictMode>);
```

`useParams<{ claimId: string }>()`, `useSearchParams()` for `?status=` (C6a), `useNavigate()` after create. Page transitions (PRD: 150ms fade): wrap `<Outlet>` in a div keyed by `useLocation().pathname` with a CSS `animate-fade-in` class.

## 5. Tailwind 4

- No `tailwind.config.js`, no `content` globs. `@tailwindcss/vite` plugin + one CSS entry:

```css
/* apps/web/src/index.css */
@import "tailwindcss";
@theme {
  --color-bg: #0F1117; --color-surface: #1A1D27; --color-surface-elevated: #22263A;
  --color-accent: #4F8EF7; --color-damage: #F7604F;
  --color-text: #F0F2F8; --color-text-secondary: #8B91A8;
  --color-status-processing: #F7C94F; --color-status-ready: #4FCB8D; --color-status-closed: #8B91A8;
  --font-sans: "Inter Variable", Inter, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;
  --animate-pulse-dot: pulse-dot 1.6s ease-in-out infinite;
  @keyframes pulse-dot { 0%,100% { opacity: .4 } 50% { opacity: 1 } }
}
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation: none !important; transition: none !important; } }
```

- Then `bg-surface`, `text-text-secondary`, `font-mono`, `animate-pulse-dot` just work. Fonts: `@fontsource-variable/inter` + `@fontsource/jetbrains-mono` (local, offline-safe) imported in `main.tsx`.
- Glass-morphism toolbar: `bg-surface/70 backdrop-blur-md border border-white/10 shadow-2xl rounded-2xl`.
- Dark-first: we don't do a light theme. Set `color-scheme: dark` on `html`.

## 6. Zustand 5

```ts
import { create } from 'zustand';
import { useShallow } from 'zustand/react/shallow';
export const useClaimsStore = create<ClaimsState>()((set, get) => ({ claims: [], loading: false, error: null,
  load: async (status?) => { set({ loading: true }); try { set({ claims: await api.listClaims(status), loading: false }); } catch (e) { set({ error: (e as Error).message, loading: false }); } },
  upsert: (c) => set((s) => ({ claims: s.claims.some((x) => x.id === c.id) ? s.claims.map((x) => (x.id === c.id ? c : x)) : [c, ...s.claims] })),
}));
// selecting several fields: useShallow avoids re-render storms in v5
const { claims, loading } = useClaimsStore(useShallow((s) => ({ claims: s.claims, loading: s.loading })));
```

v5 gotchas: selectors returning fresh objects/arrays cause infinite re-renders unless wrapped in `useShallow`; `getState()`/`subscribe()` outside React are fine (the viewer's autosave uses `subscribe`).

## 7. API client (Axios)

```ts
// apps/web/src/api/client.ts
import axios from 'axios';
import type { ApiError } from '@vdv/shared-types';
export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE ?? '/api/v1', timeout: 20_000 });
http.interceptors.response.use((r) => r, (err) => {
  const body = err.response?.data as ApiError | undefined;
  return Promise.reject(new Error(body?.error?.message ?? err.message));
});
// apps/web/src/api/claims.ts
export const listClaims = (status?: ClaimStatus) => http.get<{ claims: Claim[] }>('/claims', { params: { status } }).then((r) => r.data.claims);
export const createClaim = (input: CreateClaimInput) => http.post<{ claim: Claim; captureUrl: string }>('/claims', input).then((r) => r.data);
```

Components never import `http` — only `api/*` functions via stores or hooks. Photo uploads use `axios.put(target.url, blob, { onUploadProgress })` (guide 03 §9).

## 8. Forms (C1b) without a form library

Controlled inputs + a `touched` map + the same zod schema the API uses (`createClaimSchema.safeParse`). On blur mark touched and show `issues.find(i => i.path[0] === field)?.message`. Submit disabled unless `safeParse` succeeds. That's 40 lines; react-hook-form is fine too if someone already knows it — don't learn it today.

## 9. Small components we share

- `<StatusBadge status>` — dot + label; color from a `STATUS_COLOR` map in shared-types; `animate-pulse-dot` when `processing`.
- `<CopyButton text>` — `navigator.clipboard.writeText` + toast (`sonner`).
- `<ConfirmDialog>` — native `<dialog>` element with `showModal()`; no library.
- `<Skeleton className>` — `animate-pulse bg-surface-elevated rounded`.
- Icons: `lucide-react`.
- Toasts: `sonner` (`<Toaster theme="dark" />` once in `AppLayout`).

## 10. Lint/format

Root `eslint.config.js` (flat config, ESLint 10): `typescript-eslint` recommended + `eslint-plugin-react-hooks` + `eslint-plugin-react-refresh`. Prettier with `printWidth: 110, singleQuote: true`. `pnpm lint` = `eslint .`; `pnpm typecheck` = `tsc -b`. No pre-commit hooks today — people can run them; CI is post-jam.

## 11. Motion (PRD §13) cheat sheet

| Where | What | How |
|---|---|---|
| Route change | 150ms fade | keyed wrapper + `@keyframes fade-in` |
| Status badge | pulse on `processing` | `animate-pulse-dot` |
| Pin mount | spring pop | `useFrame` in `Pin.tsx` (guide 02) |
| Sidebar | slide-in 200ms ease-out | `translate-x-full → 0` with `transition-transform duration-200 ease-out` |
| Hover | 100ms | `transition-colors duration-100` |
| Reduced motion | all off | global media query above |

# preflight/ — dependency warm-up (do this BEFORE the jam)

This folder is **not application code**. It is a single `package.json` holding every dependency the four tracks will install, already resolved into `pnpm-lock.yaml` on 2026-09-13 with **zero peer-dependency warnings** — i.e., the pinned version set in `docs/SETUP.md` is proven to install together.

`PACKAGES.txt` is the flat list of all **712 packages @ exact version** in the transitive tree. That is the list Nexus needs, not the ~50 direct dependencies.

## If Nexus is a *proxy* of npmjs (most common)
Nexus caches whatever passes through it. Warm it once from a machine inside the corporate network:

```bash
cp preflight/.npmrc.example ~/.npmrc     # set the registry URL
cd preflight
pnpm install --frozen-lockfile           # every tarball now flows through Nexus and is cached
```

Do this on **each** OS/arch the team uses (macOS arm64, macOS x64, Windows, Linux) — some packages ship platform-specific binaries (`@rolldown/binding-*`, `@tailwindcss/oxide-*`, `@esbuild/*`, `lightningcss-*`, `fsevents`). One warm-up per platform covers it.

The lockfile's integrity hashes are registry-independent, so the same `pnpm-lock.yaml` works against Nexus.

## If Nexus is an *allowlist* (packages must be approved)
Hand `PACKAGES.txt` to whoever administers it. Everything on it must be permitted, including the platform-binary packages above for every platform you use.

## If the venue may be fully offline
Warm a pnpm store on one laptop, copy it, install from it:

```bash
# on the warm laptop
cd preflight && pnpm install --frozen-lockfile
pnpm store path                          # e.g. ~/Library/pnpm/store/v10
tar czf pnpm-store.tgz -C "$(dirname "$(pnpm store path)")" "$(basename "$(pnpm store path)")"
# on every other laptop (same OS/arch)
tar xzf pnpm-store.tgz -C "$(dirname "$(pnpm store path)")"
pnpm install --offline --frozen-lockfile
```

Store size after warming: ~2.4 GB. `node_modules` here: ~630 MB.

## Using the pins in the real monorepo (C0a)
Copy the exact versions from this `package.json` into `apps/web`, `apps/api`, and the root `devDependencies`. Don't "upgrade" anything on jam day. `pnpm-workspace.yaml` here carries pnpm 11's `minimumReleaseAgeExclude` entry for `zod` — copy it too or you'll get a release-age prompt.

## Non-npm things the app needs (all already handled)
| Need | Where it comes from | Offline-safe? |
|---|---|---|
| Draco decoder for glb | `node_modules/three/examples/jsm/libs/draco/gltf/` → copy to `apps/web/public/draco/` | yes |
| Fonts (Inter, JetBrains Mono) | `@fontsource-variable/inter`, `@fontsource/jetbrains-mono` (npm) | yes |
| Environment lighting | synthetic `<Lightformer>`s (no HDR download) | yes |
| Sample car model | `assets/samples/toycar.glb` (committed) | yes |
| Postgres | Docker image `postgres:16-alpine` — pull before the jam | pull once |
| cloudflared | `brew install cloudflared` — install before the jam; **test it on the corporate network** (see `docs/PREFLIGHT.md`) | binary |
| GPU-box software | Meshroom/COLMAP images, pip packages — the box is on the public internet, unaffected by Nexus | n/a |

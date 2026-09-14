# D3b — `export_glb.sh` (OBJ → optimized .glb)

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1h | H7 | todo |

## What to build
`pipeline/export_glb.sh <out_dir>`: `npx obj2gltf -i mesh.obj -o raw.glb` then `npx @gltf-transform/cli optimize raw.glb model.glb --compress draco --texture-compress webp --texture-size 2048` (`gltf-transform inspect model.glb` to verify), targeting ≤ 25 MB. Node 22 on the box (`nvm` or apt). Verify the glb opens in https://gltf.report and in the three.js editor with textures.

## Acceptance criteria
- [ ] `model.glb` ≤ 25 MB, textured, opens in gltf.report with no errors
- [ ] Track A confirms it loads in their viewer (drei `useGLTF` handles Draco automatically)
- [ ] Script is idempotent and logs sizes before/after

## Blocked by
D3a

## Unblocks
D3c

## Read first
`docs/guides/04-photogrammetry.md §Exporting to glb`

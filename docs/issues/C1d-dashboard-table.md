# C1d — Dashboard claim list

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1.5h | H5 | todo |

## What to build
`/` route: table of claims from `GET /claims` — columns Claim ID (short, mono, copy on click), Vehicle ("2021 Toyota Camry · Silver"), Status badge (color per status; see shared-types color map), Created, Last updated (relative time). "New Claim" primary CTA top-right. Row hover reveals "Open claim →" inline; whole row clickable. Loading skeleton, error state with retry. Zustand `use-claims-store` holds the list; `src/api/claims.ts` fetches.

## Acceptance criteria
- [ ] Seeded claims render sorted by `updatedAt desc`
- [ ] Status badges use one shared component `<StatusBadge status>` used again by the detail header
- [ ] Row click → `/claims/:claimId`; hover affordance visible within 100ms
- [ ] Skeleton while loading; error card with Retry on API down
- [ ] Desktop layout ≥ 1280px looks like PRD §13 "clean data hierarchy, zero decorative noise"

## Blocked by
C1a

## Unblocks
C6a, C6b

## Read first
`prd.md §7.1, §13`, `docs/guides/06-frontend-stack.md §Zustand`

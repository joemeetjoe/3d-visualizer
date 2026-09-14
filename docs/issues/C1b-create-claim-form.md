# C1b — Create Claim form

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1.5h | H4 | todo |

## What to build
`/claims/new` page: form with Year, Make, Model, Color, Customer email, Adjuster notes (PRD §7.2). Inline validation on blur mirroring the API's zod rules; submit → `POST /claims` via `src/api/claims.ts` (Axios client) → navigate to the Claim Created state (C1c). Dark "precision tooling" styling from PRD §13 using the Tailwind theme tokens from C0a. Primary button disabled until valid; error toast on API failure.

## Acceptance criteria
- [ ] All six fields present; Year is a number input; Make/Model required
- [ ] Blur on invalid field shows inline message; submit with invalid form is impossible
- [ ] Successful submit lands on the confirmation with the real `captureUrl`
- [ ] Looks like the PRD palette (bg `#0F1117`, surface `#1A1D27`, accent `#4F8EF7`), Inter font, 150ms fade on route enter
- [ ] Keyboard: Enter submits, Esc clears focus; tab order sensible

## Blocked by
C1a (can start against a mocked `createClaim` that returns a fixture)

## Unblocks
C1c

## Read first
`docs/guides/06-frontend-stack.md §Forms`, `prd.md §7.2, §13`

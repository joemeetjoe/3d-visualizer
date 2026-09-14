# A3a — Load + auto-save annotations, Saved/Saving indicator

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 1.5h | H11 | todo |

## What to build
On viewer mount for a claim: `GET /claims/:id/annotations` → hydrate store. Any store change → debounced (2s) `PUT` of the full set; `saveState: 'idle' | 'saving' | 'saved' | 'error'` shown in the top bar ("Saving…", "Saved ✓ just now", "Save failed — Retry"). Manual Save button forces a flush. Unload guard (`beforeunload`) if dirty. API calls via `src/api/annotations.ts` — never from components.

## Acceptance criteria
- [ ] Place 3 pins, wait 2s, reload → 3 pins in the same spots with notes/severity
- [ ] Rapid edits produce one PUT, not many (check network)
- [ ] Kill the API → indicator shows error + Retry; restart → Retry succeeds
- [ ] First save flips the claim badge to `reviewed` in the header (C2b re-fetches or store updates)

## Blocked by
A2c, C5, C2b

## Unblocks
A3b, X2

## Read first
`docs/CONTRACTS.md §1, §3`, `docs/guides/06-frontend-stack.md §API client`

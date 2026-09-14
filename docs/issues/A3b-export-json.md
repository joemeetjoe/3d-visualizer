# A3b — Export annotations JSON

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| A | AFK | 30m | H12 | todo |

## What to build
"Export Annotations" button in the sidebar footer builds an `AnnotationExport` (`CONTRACTS §1`) from the store + claim header data and downloads `claim-<shortId>-annotations.json` via a Blob URL. Pretty-printed. Toast on success.

## Acceptance criteria
- [ ] File downloads and validates against the type (open it, eyeball it)
- [ ] Includes vehicle string and `exportedAt`
- [ ] Works with zero annotations (empty arrays, not an error)

## Blocked by
A3a

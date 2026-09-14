# C6a — Dashboard status filter, processing pulse, empty state

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H13 | todo |

## What to build
Filter bar (segmented control: All / Awaiting / Uploading / Processing / Ready / Reviewed / Closed / Failed) driving `?status=`; `<StatusBadge>` pulses only for `processing` (CSS keyframe on the dot, disabled under `prefers-reduced-motion`); an illustrated empty state ("No claims yet — create your first claim") with the CTA; count chips per status in the filter.

## Acceptance criteria
- [ ] Filter is reflected in the URL (`/?status=ready`) and survives reload
- [ ] Pulse visible on processing rows, absent elsewhere and under reduced motion
- [ ] Empty state appears when the filtered list is empty, with different copy for "no claims at all" vs "no claims match"

## Blocked by
C1d

## Read first
`prd.md §7.1, §13 Motion`

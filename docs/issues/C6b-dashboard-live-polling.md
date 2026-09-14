# C6b — Dashboard + detail live refresh

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 45m | H13 | todo |

## What to build
The demo depends on the audience *seeing* status move. Poll `GET /claims` every 5s on the dashboard and `GET /claims/:id` + `/job` every 3s on the detail page while status is `uploading`/`processing`; pause polling when the tab is hidden; a row whose status changed gets a 600ms highlight. Photo count on the detail page ticks up live during capture ("Receiving photos… 23").

## Acceptance criteria
- [ ] Upload from the phone → dashboard row shows `uploading` within 5s and the photo counter climbs on the detail page
- [ ] `processing → ready` flips the detail page into the viewer with no manual refresh
- [ ] No polling while tab hidden (check network tab)

## Blocked by
C1d, C2b

## Unblocks
X2

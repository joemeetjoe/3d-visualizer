# B5a — Real-device pass over the tunnel

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| B | AFK | 1.5h | H15 | todo |

## What to build
Run the full flow (QR → start → walk → complete) on: iPhone Safari (latest iOS), iPhone Chrome (uses WebKit — same engine, different permission UX), Android Chrome. Record in a table in `docs/guides/03-camera-capture.md §Field notes`: actual resolution, fps, permission prompt behaviour, wake lock, upload throughput, any crash. Fix what breaks. Decide and document **which phone and which mode the demo uses**.

## Acceptance criteria
- [ ] Table filled for all three; demo phone + mode chosen and written in `docs/presentation/DEMO_SCRIPT.md`
- [ ] Zero console errors on the chosen phone during a full run
- [ ] Rotating the phone mid-capture doesn't break the session

## Blocked by
B4b, C7a

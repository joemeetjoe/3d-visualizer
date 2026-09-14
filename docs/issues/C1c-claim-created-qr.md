# C1c — Claim Created screen with QR code

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 1h | H4 | todo |

## What to build
The confirmation state after create: the capture URL rendered large in JetBrains Mono with a one-click copy button (toast "Copied"), a **QR code** of the URL (`qrcode.react`, `QRCodeSVG`, ~280px, high error correction, dark-on-light so phones scan it off a dark UI), a "Go to claim" button → `/claims/:claimId`, and a "Create another" link. Also reachable later from the claim detail header ("Show capture QR") so the demo can re-show it.

## Acceptance criteria
- [ ] QR scans on an iPhone and an Android from 1m away off the laptop screen and opens `/capture/:token`
- [ ] Copy button writes to clipboard and confirms
- [ ] Renders correctly with a long tunnel URL (no overflow)
- [ ] "Show capture QR" available on the claim detail page (modal or drawer)

## Blocked by
C1b

## Unblocks
X2 (the phone needs a QR to scan)

## Read first
`docs/CONTRACTS.md §7` (why `PUBLIC_WEB_URL` must be the tunnel URL)

## Notes
The QR is the SES replacement (DECISIONS D7). Make it big and high-contrast: it's literally the first thing the audience will see work.

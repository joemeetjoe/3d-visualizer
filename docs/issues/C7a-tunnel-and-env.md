# C7a — Tunnel + allowedHosts + env plumbing

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| C | AFK | 45m | H12 (earlier if B needs a phone test sooner — do a quick version at H4) | todo |

## What to build
`pnpm tunnel` script: runs `cloudflared tunnel --url http://localhost:5173`, parses the `https://*.trycloudflare.com` URL from its output, writes it to `apps/api/.env` as `PUBLIC_WEB_URL` (and prints a big banner + copies to clipboard), and sends SIGHUP/restarts the API (or the API re-reads `PUBLIC_WEB_URL` per request from a small file — simpler, do that). Vite config has `host: true`, `allowedHosts: ['.trycloudflare.com']`, proxies for `/api` and `/files`. Document the two-terminal startup in `docs/SETUP.md`.

## Acceptance criteria
- [ ] From a phone on cellular (not the venue wifi): open the tunnel URL → dashboard loads; `/capture/<token>` opens the camera prompt (HTTPS confirmed)
- [ ] Newly created claims produce QR codes with the tunnel URL without restarting anything
- [ ] Phone upload of a 3 MB JPEG through the tunnel completes in < 3s

## Blocked by
C0a

## Unblocks
B5a, X2 (phone must reach the app)

## Read first
`docs/SETUP.md §Tunnel`, `docs/guides/03-camera-capture.md §Secure context`

## Notes
Cloudflare quick tunnels cap ~200 in-flight requests — fine for one phone. Don't run two tunnels (web + api); proxy through Vite.

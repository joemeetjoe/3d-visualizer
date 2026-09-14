# D4b — Worker: status, model download, keepalive, exposure

| Track | Type | Est | Target | Status |
|---|---|---|---|---|
| D | AFK | 1h | H12 | todo |

## What to build
`GET /jobs/:id` (with `logTail`), `GET /jobs/:id/model.glb` (409 until done), `DELETE /jobs/:id`, `GET /health` (gpu name via `nvidia-smi --query-gpu=name`, engine, queue length). Run under `systemd` (or `pm2`/`tmux` + auto-restart) so an SSH drop doesn't kill it. Confirm the laptop's API reaches `http://<ip>:8080/health` through the security group. Set `WORKER_URL` + token in Track C's `.env`.

## Acceptance criteria
- [ ] From the laptop: `curl -H 'X-Worker-Token: …' http://<ip>:8080/health` → gpu + engine
- [ ] Full round trip via the real API (C4b): `upload-complete` → `ready` with a real model on disk
- [ ] Service survives `kill -9` and reboot (systemd `Restart=always`)

## Blocked by
D4a, C4b

## Unblocks
X3

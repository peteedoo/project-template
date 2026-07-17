# Roadmap forward — iamfaulty homelab + pawn-shop Mini

**Compiled:** 2026-07-08  
**Active track:** `arr-appliance` on the 2014 Mac Mini  
**Branch / PR:** `cursor/mac-mini-firewall-2baf` → [#5](https://github.com/peteedoo/project-template/pull/5)

This is the ordered plan from **today** to **stable steady state**. Each phase has a gate — do not skip gates marked **blocker**.

---

## North star

| Goal | How we get there |
|------|------------------|
| Stop main Mac SSD drift | Move acquisition stack off `main-mini` |
| Keep media on NAS | NAS1 stays primary; paths unchanged for Jellyfin |
| Sacrificial local disk | Pawn-shop Mini + 85% disk guard |
| Off-site backup | DS223J over Tailscale |
| House DNS stable | Le Potato @ `.52` — do not load with *arr |

---

## Current state (honest)

| Item | Status |
|------|--------|
| Pawn-shop Mini | Ubuntu Server installed; Wi-Fi works; built-in Ethernet dead; USB adapter available |
| `arr-appliance` repo | Compose + install scripts + docs — **not yet run on the Mini** |
| Gluetun in compose | **Not implemented** — qBit currently exposed without VPN kill switch |
| main Mac *arr stack | Still live at `~/homelab-data/arr/` — **still drifting SSD** |
| NAS1 | Primary NAS — `homelab` share, `media/Movies`, `media/Shows` |
| DS223J | Fresh — **not set up**; internet-connected; needs Tailscale |
| Le Potato | AdGuard @ `192.168.1.52` |
| PR #5 | Merged with `main`; ready to merge when you are |
| `iamfaulty-homelab` HARDWARE.md | Written locally — **push to that repo still manual** |

---

## Phase 0 — Land the repo (you, ~30 min)

**Gate:** PR merged or branch trusted for install one-liners.

- [ ] Merge [PR #5](https://github.com/peteedoo/project-template/pull/5) to `main` (or keep using branch URL until then)
- [ ] Copy `docs/HARDWARE.md` → `peteedoo/iamfaulty-homelab` (sync Le Potato + DS223J roles)
- [ ] Read `docs/NOTE-dual-projects.md` — ignore MiniFW cutover for now

**Done when:** install URL is stable and you know which branch to curl.

---

## Phase 1 — Synology DS223J (parallel, ~1–2 hours)

**Gate:** Tailscale ping works from main Mac to Synology.

Can run while the pawn-shop Mini work happens elsewhere.

1. [ ] Install drives → **SHR-1** or **RAID 1**
2. [ ] DSM setup — admin password + **2FA**
3. [ ] **Package Center → Tailscale** → join same tailnet as home
4. [ ] Record Tailscale IP (`100.x.y.z`) in `docs/HARDWARE.md`
5. [ ] Create shared folder `backup`, user `peteedoo`
6. [ ] Enable SMB + SSH (for rsync/SFTP backups)
7. [ ] **Do not** port-forward SMB or DSM to the public internet
8. [ ] Test from main Mac: `tailscale ping 100.x.y.z`, mount `//100.x.y.z/backup`

Guide: `docs/SYNOLOGY-DS223J.md`

**Done when:** Duplicati *could* target the Synology (job setup is Phase 6).

---

## Phase 2 — Pawn-shop Mini foundation (blocker for *arr)

**Gate:** `check-nas.sh` passes on the Mini.

1. [ ] Plug **USB Gigabit Ethernet** → `sudo netplan apply`
2. [ ] Confirm route: `ip route get 1.1.1.1`
3. [ ] Run install:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance/scripts/install-arr-appliance.sh | bash
   ```
4. [ ] Configure `/etc/nas-credentials` for NAS1
5. [ ] Add `fstab.iamfaulty.example` line → `sudo mount -a`
6. [ ] `sudo cp /opt/arr-appliance/config/env.iamfaulty.example /opt/arr-appliance/.env`
7. [ ] `sudo /opt/arr-appliance/scripts/check-nas.sh`
8. [ ] Create NAS paths if missing:
   ```bash
   mkdir -p /mnt/nas/personal/arr-appliance/{prowlarr,sonarr,radarr,bazarr,qbittorrent,lidarr}
   mkdir -p /mnt/nas/media/downloads
   ```

Guide: `docs/MORNING-CHECKLIST.md`

**Done when:** NAS1 mounted, writable, and install dir exists at `/opt/arr-appliance`.

---

## Phase 3 — Add Gluetun (blocker before torrent cutover)

**Gate:** qBittorrent WebUI works **only** when VPN is up; stops when VPN is down.

**Why before cutover:** main Mac stack uses VPN kill switch today. Moving qBit without Gluetun changes your security posture.

- [ ] Add Gluetun service to `docker-compose.yml` (WireGuard provider env from main Mac `arr-stack/.env`)
- [ ] Route qBittorrent `network_mode: service:gluetun` (or equivalent)
- [ ] Prowlarr can stay on bridge; qBit must not leak WAN IP
- [ ] Test: stop VPN container → qBit has no connectivity
- [ ] Document provider keys in `/opt/arr-appliance/.env` (never commit secrets)

**Done when:** torrent traffic cannot escape without VPN.

*Repo task — not yet in compose on branch.*

---

## Phase 4 — Migrate configs & cutover *arr (blocker for stopping main Mac drift)

**Gate:** All grabs land on NAS1; main Mac `~/homelab-data/arr` containers stopped.

### 4a — Copy configs (on main Mac, NAS mounted)

```bash
rsync -av ~/homelab-data/arr/prowlarr/    /Volumes/homelab/personal/arr-appliance/prowlarr/
rsync -av ~/homelab-data/arr/sonarr/      /Volumes/homelab/personal/arr-appliance/sonarr/
rsync -av ~/homelab-data/arr/radarr/      /Volumes/homelab/personal/arr-appliance/radarr/
rsync -av ~/homelab-data/arr/lidarr/      /Volumes/homelab/personal/arr-appliance/lidarr/
rsync -av ~/homelab-data/arr/qbittorrent/ /Volumes/homelab/personal/arr-appliance/qbittorrent/
```

### 4b — Start on pawn-shop Mini

```bash
sudo systemctl enable --now arr-appliance
docker ps
```

### 4c — Verify UIs from laptop

| App | Port |
|-----|------|
| Prowlarr | `:9696` |
| Sonarr | `:8989` |
| Radarr | `:7878` |
| Lidarr | `:8686` *(add to compose first)* |
| qBittorrent | `:8080` |

### 4d — Stop main Mac drift

```bash
docker compose -f ~/homelab-data/arr-stack/docker-compose.yml down
```

### 4e — In-app checks

- [ ] Root folders → `/tv`, `/movies`, `/downloads` (container paths)
- [ ] Download client → `http://qbittorrent:8080`
- [ ] Prowlarr → Sonarr/Radarr/Lidarr sync URLs use Docker hostnames

Guide: `docs/MIGRATE.md`

**Done when:** new grab imports to `/mnt/nas/media/...` and main Mac disk stops growing from *arr.

---

## Phase 5 — Expand stack (after stable cutover)

Add in order of value; all NAS-backed.

| Priority | Service | Notes |
|----------|---------|-------|
| 1 | **Lidarr** | In main Mac reference compose; add to pawn-shop compose |
| 2 | **Jellyseerr** | Stays useful; points at Jellyfin on main Mac |
| 3 | **FlareSolverr** | If indexers need it |
| 4 | **Readarr** | Books |
| 5 | **Unpackerr** | Post-download extract |
| 6 | slskd / soularr / MeTube | Heavier ops — add if you still use them on main Mac |

**Done when:** feature parity with main Mac `reference/arr-stack-docker-compose.yml` for services you actually use.

---

## Phase 6 — Backups & remote access

| Task | Where |
|------|-------|
| Duplicati → DS223J over Tailscale | main Mac Duplicati compose |
| Nightly `rsync` critical `personal/arr-appliance` | main Mac cron or Synology task |
| Repoint `sonarr.iamfaulty.com` etc. | NPM/Caddy on main Mac → pawn-shop LAN IP or Tailscale |
| Optional: Tailscale on pawn-shop Mini | Remote admin without opening ports |
| Beszel / disk alert | Watch pawn-shop `/` and NAS1 free space |

**Done when:** config + NAS personal folder has off-site copy; you can reach UIs from phone/laptop securely.

---

## Phase 7 — Steady state & hygiene

- [ ] Monthly: `docker image prune` on pawn-shop Mini (disk guard helps)
- [ ] Quarterly: verify Duplicati restore test from DS223J
- [ ] Update the internal inventory site / HARDWARE when IPs change
- [ ] Keep Jellyfin + agents on main Mac only
- [ ] Le Potato: DNS only — no scope creep

---

## Deferred / probably never (unless hardware changes)

| Item | Condition to revisit |
|------|----------------------|
| **MiniFW firewall cutover** | Fix built-in Ethernet **or** add 2nd USB NIC for WAN+LAN |
| **Primary library on DS223J** | Only if you outgrow NAS1 *and* buy large mirrored drives |
| **Lidarr on Le Potato / utility SBCs** | Don't |
| **Docker on DS223J** | Not supported (ARM, 1 GB) |

---

## Decision log (already made)

1. **Pawn-shop Mini = acquisition node**, not firewall (dead NIC).
2. **NAS1 = primary storage**; Synology = backup over internet.
3. **Gluetun moves with qBit** — not optional if keeping current VPN policy.
4. **Two projects in one repo** — MiniFW archived, arr-appliance active (`NOTE-dual-projects.md`).

---

## Quick reference — who does what

```
Le Potato (.52)       → DNS only
NAS1 (.50)            → media + downloads + *arr config (live)
DS223J (Tailscale)    → off-site backup
Pawn-shop Mini        → Gluetun + qBit + *arr (Docker)
main-mini             → Jellyfin, Plex, agents, NPM, Duplicati orchestration
Utility SBCs          → WireGuard, Kodi, Home Assistant
```

---

## Next three actions (if you only do three things)

1. **Phase 2** — Install `arr-appliance` on pawn-shop Mini + mount NAS1  
2. **Phase 3** — Add Gluetun to compose before moving qBit  
3. **Phase 1** — Tailscale on DS223J while waiting on downloads/tests  

---

## Related docs

| Doc | Use |
|-----|-----|
| `MORNING-CHECKLIST.md` | Phase 2 step-by-step |
| `MIGRATE.md` | Phase 4 |
| `SYNOLOGY-DS223J.md` | Phase 1 |
| `HARDWARE.md` | Fleet map |
| `NOTE-dual-projects.md` | Repo scope |

# Hardware map — home lab

Reconciled fleet layout for the *arr appliance pivot. Source of truth for IPs and roles; update here when hardware changes. IPs below are documentation placeholders — substitute your own LAN addresses.

**Also tracked in:** `peteedoo/iamfaulty-homelab/docs/HARDWARE.md`

---

## Network quick reference

| Address | Host | Role |
|---------|------|------|
| `192.168.1.50` | **NAS1** (2-bay NAS) | Primary NAS — SMB share `homelab` |
| `192.168.1.51` | **Backup NAS** (Synology) | Backup NAS — reach via **Tailscale** (`100.x.y.z`), not public SMB |
| `192.168.1.52` | **Le Potato** | AdGuard Home — primary LAN DNS |
| `192.168.1.x` | Mesh router / LAN clients | Household subnet |

Main Mac Wi-Fi DNS is pinned to AdGuard first:

```bash
sudo networksetup -setdnsservers Wi-Fi 192.168.1.52 1.1.1.1
```

See `iamfaulty-homelab/ops/DNS.md` for public-edge DNS (different layer — public `*.iamfaulty.com`, not house DNS).

---

## Fleet roles

| Machine | Specs (known) | Role | *arr / acquisition |
|---------|---------------|------|-------------------|
| **main-mini** | Mac mini, 16 GB+, macOS, OrbStack | Jellyfin, agents, Caddy/NPM, work | **Retire** — configs at `~/homelab-data/arr/` today |
| **Pawn-shop Mac Mini** | 2014, 16 GB, 256 GB HDD, Ubuntu Server | Sacrificial acquisition node | **Target** — Gluetun, qBit, full *arr stack |
| **NAS1** | 2-bay NAS, 11 TB | `homelab` SMB share | **Primary** — media, downloads, appdata |
| **Backup NAS** | Synology, 2-bay, 1 GB RAM | `backup` over **Tailscale** | **Off-site / internet backup** — Duplicati, rsync |
| **Le Potato** | Libre Computer, ~2 GB RAM | AdGuard Home @ `.52` | **DNS only** — do not add Lidarr here |
| **Utility SBCs** | — | WireGuard, Kodi, Home Assistant | Not acquisition |

---

## Target layout (after pawn-shop cutover)

```
Internet
    │
ISP gateway / mesh router (AP)
    │
    ├── Le Potato (.52)        → AdGuard DNS
    ├── NAS1 (.50)             → /homelab (primary media, *arr)
    ├── Backup NAS (Tailscale) → /backup (off-site copy over internet)
    ├── Pawn-shop Mini         → Gluetun + qBit + *arr (Docker)
    ├── main-mini              → Jellyfin, Plex, agents, NPM/Caddy
    └── Utility SBCs           → WireGuard, Kodi, Home Assistant
```

---

## NAS paths (NAS1)

Single SMB mount on acquisition node:

```
//192.168.1.50/homelab  →  /mnt/nas
```

| Path on share | Use |
|---------------|-----|
| `media/Movies` | Radarr → container `/movies` |
| `media/Shows` | Sonarr → container `/tv` |
| `media/downloads` | qBittorrent, imports |
| `personal/arr-appliance/` | Prowlarr, Sonarr, Radarr, Lidarr, Bazarr, qBit configs |

Copy-paste: `config/fstab.iamfaulty.example`, `config/env.iamfaulty.example`

---

## What runs on the pawn-shop Mini

### Core (move from main Mac)
- Gluetun (VPN kill switch for qBittorrent)
- qBittorrent
- Prowlarr, Sonarr, Radarr, Bazarr
- Lidarr

### Stretch (fits 16 GB if NAS-backed)
- Readarr, Jellyseerr, FlareSolverr, Unpackerr
- Mylar3, slskd, soularr, MeTube, BookBounty, Huntorr

### Stay off this box
- Jellyfin / Plex (keep on main Mac)
- AdGuard / house DNS (Le Potato)
- Home Assistant (utility SBC)
- AI / agents / OpenClaw (main Mac)

---

## What must not move to Le Potato

Le Potato is **house DNS**. Coupling download or library management there risks “internet feels broken” when *arr misbehaves.

| OK on Le Potato | Not on Le Potato |
|-----------------|------------------|
| AdGuard Home | Lidarr, Sonarr, Radarr, Prowlarr |
| Tailscale (optional) | qBittorrent, Gluetun |
| Recyclarr cron (optional) | FlareSolverr, Jellyseerr |
| Health watchdog (optional) | Anything that transcodes or hammers NAS |

---

## Doc drift fixed (2026-07)

| Old doc | Correction |
|---------|------------|
| README: “Pi = AdGuard” | **Le Potato @ `192.168.1.52`** runs AdGuard |
| Utility SBC rows | WireGuard only (verify live) |
| Internal inventory | Le Potato added as DNS node |

---

## Related docs

| Doc | Use |
|-----|-----|
| **`ROADMAP.md`** | **Forward plan — start here for sequencing** |
| `MORNING-CHECKLIST.md` | Phase 2 step-by-step |
- `docs/MIGRATE.md` — rsync configs off main Mac SSD
- `docs/SYNOLOGY-DS223J.md` — backup NAS setup
- `iamfaulty-homelab/ops/DNS.md` — resolver + public-edge DNS
- `iamfaulty-homelab/reference/arr-stack-docker-compose.yml` — full live stack reference

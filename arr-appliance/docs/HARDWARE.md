# Hardware map — iamfaulty homelab

Reconciled fleet layout for the *arr appliance pivot. Source of truth for IPs and roles; update here when hardware changes.

**Also tracked in:** `peteedoo/iamfaulty-homelab/docs/HARDWARE.md`

---

## Network quick reference

| Address | Host | Role |
|---------|------|------|
| `192.168.68.69` | **ILLMATIC** (UGREEN DH2300) | NAS — SMB share `homelab` |
| `192.168.68.90` | **Le Potato** | AdGuard Home — primary LAN DNS |
| `192.168.68.x` | Deco / LAN clients | Google Fiber household subnet |

M4 Mac Mini Wi-Fi DNS is pinned to AdGuard first:

```bash
sudo networksetup -setdnsservers Wi-Fi 192.168.68.90 1.1.1.1
```

See `iamfaulty-homelab/ops/DNS.md` for Cloudflare tunnel DNS (different layer — public `*.iamfaulty.com`, not house DNS).

---

## Fleet roles

| Machine | Specs (known) | Role | *arr / acquisition |
|---------|---------------|------|-------------------|
| **iamfaulty-mini** | Mac mini M4, 16 GB+, macOS, OrbStack | Jellyfin, agents, Caddy/NPM, work | **Retire** — configs at `~/homelab-data/arr/` today |
| **Pawn-shop Mac Mini** | 2014, 16 GB, 256 GB HDD, Ubuntu Server | Sacrificial acquisition node | **Target** — Gluetun, qBit, full *arr stack |
| **ILLMATIC** | UGREEN DH2300, 11 TB | `homelab` SMB share | Media, downloads, appdata (NAS-only paths) |
| **Le Potato** | Libre Computer, ~2 GB RAM | AdGuard Home @ `.90` | **DNS only** — do not add Lidarr here |
| **Raspberry Pi 5** | — | WireGuard | Network VPN — not acquisition |
| **Raspberry Pi 4** | — | Kodi media center | Playback — not acquisition |
| **Raspberry Pi 3B** | — | Home Assistant OS | Automation — not acquisition |
| **Pi Zero 2 W** | 512 MB | *(not in inventory)* | Tiny sidecar only if used — not *arr |

---

## Target layout (after pawn-shop cutover)

```
Internet
    │
Google Fiber / Deco (AP)
    │
    ├── Le Potato (.90)     → AdGuard DNS
    ├── ILLMATIC (.69)      → /homelab (media, downloads, appdata)
    ├── Pawn-shop Mini      → Gluetun + qBit + *arr (Docker)
    ├── iamfaulty-mini M4   → Jellyfin, Plex, agents, NPM/Caddy
    └── Pi fleet            → WireGuard, Kodi, Home Assistant
```

---

## NAS paths (ILLMATIC)

Single SMB mount on acquisition node:

```
//192.168.68.69/homelab  →  /mnt/nas
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

### Core (move from M4)
- Gluetun (VPN kill switch for qBittorrent)
- qBittorrent
- Prowlarr, Sonarr, Radarr, Bazarr
- Lidarr

### Stretch (fits 16 GB if NAS-backed)
- Readarr, Jellyseerr, FlareSolverr, Unpackerr
- Mylar3, slskd, soularr, MeTube, BookBounty, Huntorr

### Stay off this box
- Jellyfin / Plex (keep on M4)
- AdGuard / house DNS (Le Potato)
- Home Assistant (Pi 3B)
- AI / agents / OpenClaw (M4)

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
| README: “Pi 5 = AdGuard” | **Le Potato @ `192.168.68.90`** runs AdGuard |
| Pi 5 row | WireGuard only (verify live) |
| truth.iamfaulty.com Pi list | Le Potato added as DNS node |

---

## Related docs

- `docs/MORNING-CHECKLIST.md` — pawn-shop setup steps
- `docs/MIGRATE-FROM-M4.md` — rsync configs off M4 SSD
- `iamfaulty-homelab/ops/DNS.md` — resolver + tunnel DNS
- `iamfaulty-homelab/reference/arr-stack-docker-compose.yml` — full live stack reference

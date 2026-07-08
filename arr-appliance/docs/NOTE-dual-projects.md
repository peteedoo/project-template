# Note — two projects, one repo

**Date:** 2026-07-08  
**Branch:** `cursor/mac-mini-firewall-2baf`  
**PR:** #5

## What this repo contains

| Path | Status | Purpose |
|------|--------|---------|
| `mac-mini-firewall/` | **Archived intent** (still maintained) | Google Fiber firewall — MiniFW, Obsidian vault, MINIFWSETUP USB |
| `arr-appliance/` | **Active plan** | Pawn-shop Mac Mini — Gluetun, qBit, *arr stack, NAS-backed |

Both target the **same hardware** (2014 Mac Mini) but **not at the same time** for production cutover.

## Why both exist after merging `main`

- `main` merged **MiniFW** (PR #2) — firewall/router docs and tooling.
- This branch added **arr-appliance** and evolved MiniFW (Obsidian, plug-and-play USB, route checks).
- Merge conflicts were trivial: same MiniFW files, branch = superset. **No intent conflict.**

## Doc drift to expect

| Doc | Says |
|-----|------|
| `mac-mini-firewall/README.md` | Firewall / router replacement |
| `mac-mini-firewall/obsidian/Home.md` | **Pivot callout** → *arr appliance is current plan |
| `arr-appliance/README.md` | Active acquisition node setup |

**Start here for the pawn-shop Mini today:** `arr-appliance/docs/MORNING-CHECKLIST.md`

**Revisit firewall only if:** built-in Ethernet is fixed or you add a second USB NIC for WAN+LAN.

## Hardware context (summary)

- **ILLMATIC** (UGREEN) — primary NAS / *arr paths
- **DS223J** (Synology) — off-site backup over Tailscale
- **Le Potato** @ `192.168.68.90` — AdGuard DNS
- **M4** — Jellyfin, agents; retire `~/homelab-data/arr/` after cutover

Full map: `arr-appliance/docs/HARDWARE.md`

# Pivot: Firewall → *arr Appliance

The 2014 pawn-shop Mac Mini was originally planned as a **Google Fiber firewall** (MiniFW). Built-in Ethernet appears **dead** (no link light). Firewall duty needs WAN + LAN; one USB adapter is not enough for that role without Wi-Fi WAN (fragile).

**New plan:** use this box as a dedicated ***arr sidecar*** so download/config drift fills *its* 256 GB disk (or stops at 85%) instead of your **main M4 Mac Mini**.

## What stays the same

- Ubuntu Server on the pawn-shop Mini
- USB Ethernet for wired LAN when Wi-Fi is not ideal
- NAS holds all media, downloads, and appdata

## What changed

| Before (MiniFW) | After (*arr appliance) |
|-----------------|------------------------|
| Replace Network Box | Leave Google Fiber / Deco as-is |
| `minifw` + nftables | Docker: Prowlarr, Sonarr, Radarr, Bazarr, qBittorrent |
| Two Ethernet ports | One USB Ethernet (or Wi-Fi) is enough |
| `mac-mini-firewall/` setup USB | `arr-appliance/scripts/install-arr-appliance.sh` |

## Start here

1. [[MORNING-CHECKLIST]] — one-page setup on the Mini (also at `arr-appliance/docs/MORNING-CHECKLIST.md`)
2. [[arr-appliance README]] — full reference (`arr-appliance/README.md`)

## Install one-liner (on the Mini)

```bash
curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance/scripts/install-arr-appliance.sh | bash
```

## Machine roles

| Machine | Role |
|---------|------|
| 2014 Mac Mini | *arr stack; sacrificial local disk |
| M4 Mac Mini (faulty-mini) | Work, Plex — remove *arr from here |
| NAS | Source of truth for media + downloads + config |

## Revisit firewall later?

Only if you add a **second** USB Ethernet adapter (WAN + LAN) or replace/fix built-in Ethernet. MiniFW docs remain in `mac-mini-firewall/`.

## Related

- [[Start Fresh - Used Mac Mini]] — Ubuntu install (still valid)
- [[Topology Overview]] — old firewall topology (archived intent)

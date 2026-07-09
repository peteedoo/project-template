---
tags: [reference, usb]
aliases: [MINIFWSETUP, Setup USB]
---

# MINIFWSETUP USB

← [[Home]] · Build step → [[Phase 2 - MINIFWSETUP USB]]

One USB stick configures the Mac Mini. Plug in, run `sudo ./setup.sh`.

## Make the stick (one command)

USB plugged into your Mac. Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/make-usb.sh | bash
```

Auto-detects the drive. ~30 seconds. Then eject and label **MINIFWSETUP**.

---

## What it does / does not do

| ✅ Does | ❌ Does not |
|---------|------------|
| Install MiniFW, netplan, dnsmasq, nftables | Install Ubuntu |
| Auto-detect WAN/LAN interfaces | Perform [[Phase 4 - Cutover]] |
| Copy docs to `/opt/minifw/` and `/root/INTERNET-DOWN.txt` | Fix hardware failures |

---

## Part 1 — Create (on laptop)

8 GB+ USB, format **ExFAT**, label **MINIFWSETUP**.

### macOS

```bash
cd mac-mini-firewall
chmod +x scripts/build-setup-usb.sh
./scripts/build-setup-usb.sh /Volumes/MINIFWSETUP
```

### Linux

```bash
./scripts/build-setup-usb.sh /media/$USER/MINIFWSETUP
```

Tape label: **MINIFWSETUP**. Keep on shelf with [[Backup and Rollback]] kit.

---

## Part 2 — Run (on Mac Mini)

Requires [[Phase 1 - Install Ubuntu]] complete.

```bash
cd /media/*/MINIFWSETUP
sudo ./setup.sh
```

Also copies this Obsidian vault to `/opt/minifw/obsidian/` when built with latest script.

---

## USB contents

| File | Purpose |
|------|---------|
| `START-HERE.txt` | Plain-text quick start |
| `setup.sh` | One-command installer |
| `preflight.sh` | Pre-cutover checks |
| `rollback-to-network-box.sh` | Rollback reminder |
| `EMERGENCY-CARD.txt` | [[Emergency Card]] |
| `docs/` | Plain markdown copies |
| `obsidian/` | Linked vault (optional) |

---

## Two USB summary

| USB | When |
|-----|------|
| Ubuntu Server 24.04 installer | Once — [[Phase 1 - Install Ubuntu]] |
| **MINIFWSETUP** | Once + keep forever |

Single USB option: [Ventoy](https://ventoy.net) with Ubuntu ISO + MINIFWSETUP folder.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Permission denied | `chmod +x setup.sh` |
| USB not mounted | `lsblk` / `find /media -name setup.sh` |
| WAN not detected | Plug USB Ethernet before running |

---

## Related

- [[Phase 2 - MINIFWSETUP USB]]
- [[Preflight Checklist]]
- [[Emergency Card]]

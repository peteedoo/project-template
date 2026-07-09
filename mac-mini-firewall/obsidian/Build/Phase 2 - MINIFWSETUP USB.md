---
tags: [build, phase-2, usb]
---

# Phase 2 — MINIFWSETUP USB

← [[Phase 1 - Install Ubuntu]] · [[Home]] · Next → [[Phase 3 - Pre-Cutover Testing]]

⏱ ~20 min on Mac Mini (after USB is built)

Full USB details → [[MINIFWSETUP USB]]

---

## 2.1 Build the USB (on your laptop)

```bash
# Disk Utility → Erase → Name: MINIFWSETUP → ExFAT
cd mac-mini-firewall
chmod +x scripts/build-setup-usb.sh
./scripts/build-setup-usb.sh /Volumes/MINIFWSETUP   # macOS
```

See [[MINIFWSETUP USB#Part 1 — Create the setup USB]] for Windows/Linux.

---

## 2.2 Run on Mac Mini

1. Plug **MINIFWSETUP** USB into Mac Mini
2. Plug **USB Ethernet adapter** in (WAN — not connected to Fiber Jack yet)
3. Keyboard + monitor attached

```bash
cd /media/*/MINIFWSETUP
sudo ./setup.sh
```

### What `setup.sh` does

- Installs packages (nftables, dnsmasq, minifw)
- Auto-detects WAN (`enx*`) and LAN (built-in) interfaces
- Writes [[Config Files#netplan|netplan]] (`192.168.10.1` on LAN)
- Runs `minifw apply`
- Copies docs to `/opt/minifw/docs/` and `/root/INTERNET-DOWN.txt`
- Runs [[Preflight Checklist]]

---

## 2.3 Manual path (without USB)

If not using the USB script:

```bash
sudo bash scripts/install.sh
sudo cp config/netplan.example.yaml /etc/netplan/01-minifw.yaml
# edit interface names — see [[Config Files]]
sudo minifw init && sudo minifw apply
```

Commands reference → [[minifw Commands]]

---

## Done when

- [ ] `setup.sh` completed without errors
- [ ] `ip -br addr` shows `192.168.10.1` on LAN
- [ ] [[Preflight Checklist]] reviewed (WAN may not have IP until cutover — that's OK)

→ Continue to [[Phase 3 - Pre-Cutover Testing]]

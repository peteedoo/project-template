# MiniFW setup USB — how to create and use it

One USB stick holds everything you need to configure the Mac Mini. Plug it in, run one command.

## What this USB does

| Does | Does not |
|------|----------|
| Installs MiniFW, netplan, dnsmasq, nftables | Install Ubuntu (you need a separate install USB for that) |
| Detects WAN/LAN interfaces automatically | Cut over from Network Box (you do that manually) |
| Copies triage docs onto the Mac Mini | Fix broken hardware |

After setup, emergency docs live at `/root/INTERNET-DOWN.txt` even with the USB unplugged.

---

## Part 1 — Create the setup USB (on your laptop)

You need a **8 GB+ USB stick** (any spare drive).

### macOS

```bash
# 1. Insert USB stick
# 2. Open Disk Utility → Erase → Name: MINIFW-SETUP → Format: ExFAT
# 3. Clone repo (or copy mac-mini-firewall folder)
cd mac-mini-firewall
chmod +x scripts/build-setup-usb.sh
./scripts/build-setup-usb.sh /Volumes/MINIFW-SETUP
```

### Windows (WSL or Git Bash)

```bash
# Format USB as exFAT, label MINIFW-SETUP
# Mounts as E: or similar
cd mac-mini-firewall
bash scripts/build-setup-usb.sh /mnt/e
```

### Linux

```bash
# Format: sudo mkfs.exfat -n MINIFW-SETUP /dev/sdX1
cd mac-mini-firewall
./scripts/build-setup-usb.sh /media/$USER/MINIFW-SETUP
```

Eject safely. Label the stick **"MINIFW SETUP"** with tape.

---

## Part 2 — Install Ubuntu on the Mac Mini (one-time)

You still need a **separate** Ubuntu install USB for the first step:

1. Download [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server)
2. Flash with [balenaEtcher](https://etcher.balena.io) (Mac/Windows) or `dd` (Linux)
3. Plug into Mac Mini, hold **Option** at boot, install Ubuntu
4. Enable **OpenSSH** during install
5. Temporarily plug Mac Mini LAN into **Network Box blue port** for internet during setup

---

## Part 3 — Run the setup USB on the Mac Mini

1. Plug **MINIFW-SETUP** USB into Mac Mini
2. Plug in **USB Ethernet adapter** (WAN)
3. Keyboard + monitor attached

```bash
# Find the USB (usually auto-mounts)
ls /media/*/
# or
lsblk

cd /media/*/MINIFW-SETUP
sudo ./setup.sh
```

Takes about 5 minutes. It will:

- Install packages
- Install minifw
- Write netplan (`192.168.10.1` on LAN, DHCP on WAN)
- Configure firewall + DHCP
- Copy triage docs to `/opt/minifw/` and `/root/INTERNET-DOWN.txt`
- Run preflight checks

---

## Part 4 — Cutover (when preflight passes)

Follow `docs/SETUP-PLAN.md` Phase 4 on the USB (or `/opt/minifw/docs/SETUP-PLAN.md` on the Mac Mini):

1. Unplug Network Box
2. Fiber Jack → USB Ethernet → Mac Mini
3. Mac Mini LAN → switch → Deco XE75
4. Deco in AP mode
5. `sudo ./preflight.sh` again
6. Test `curl ifconfig.me` from phone

---

## Keep this USB

| When | Use USB for |
|------|-------------|
| Re-run setup after reinstall | `sudo ./setup.sh` |
| Internet down | `EMERGENCY-CARD.txt`, `rollback-to-network-box.sh` |
| Re-read docs | `docs/` folder |
| Give to household | `START-HERE.txt` |

Tape the USB to the shelf next to the Network Box rollback kit.

---

## Two-USB summary

| USB | Purpose | When |
|-----|---------|------|
| Ubuntu Server installer | Install Linux | Once |
| **MINIFW-SETUP** (this) | Configure firewall | Once + keep forever |

If you want **one physical USB** for both, use [Ventoy](https://ventoy.net): put the Ubuntu ISO and the MINIFW-SETUP folder on the same drive.

---

## Troubleshooting the USB itself

| Problem | Fix |
|---------|-----|
| `setup.sh: permission denied` | `chmod +x setup.sh` then `sudo ./setup.sh` |
| USB not mounted | `sudo mkdir -p /mnt/usb && sudo mount /dev/sdb1 /mnt/usb` |
| Wrong path | `find /media -name setup.sh 2>/dev/null` |
| WAN not detected | Plug USB Ethernet adapter in before running setup |

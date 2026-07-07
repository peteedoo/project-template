# Full setup plan — Google Fiber + Mac Mini + Deco XE75

This is the complete implementation plan for your 2014 Mac Mini (16 GB RAM, 256 GB HDD) as firewall/router with Google Fiber and a TP-Link Deco XE75 mesh.

**Read this in order.** Do not skip the backup section or preflight checks.

| Document | Purpose |
|----------|---------|
| This file | Step-by-step build and cutover |
| [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md) | Restore Network Box if anything fails |
| [TRIAGE.md](TRIAGE.md) | Offline troubleshooting when internet is down |
| [NETWORK.md](NETWORK.md) | Topology reference |

---

## Phase 0 — Before you touch anything (30 min)

### Shopping / hardware checklist

| Item | Status | Notes |
|------|--------|-------|
| USB 3.0 Gigabit Ethernet adapter | Required | ~$15–25; Mac Mini has only one built-in port |
| Gigabit switch (5-port) | Recommended | Deco + Mac Mini LAN + wired devices |
| USB keyboard + HDMI monitor | Required for setup | Borrow if needed; Mac Mini has no built-in display |
| Ethernet cables (spare) | Recommended | Label them before unplugging |
| Phone with cellular data | Required | Backup internet + GF support calls |

### Photograph current wiring (5 min)

Take photos of:

1. Fiber Jack → Network Box cable (which port on each end)
2. Network Box back panel (all ports)
3. Network Box LED status (all green = healthy baseline)
4. Deco placement and what's plugged into it

Store photos on your phone. You will need them for rollback.

### Print or save offline copies

Save these files to your phone (Files app, iCloud, Google Drive) **before cutover**:

- `docs/TRIAGE.md` — read when internet is down
- `docs/BACKUP-AND-ROLLBACK.md` — rollback steps
- `scripts/rollback-to-network-box.sh` — quick reminder

### Rollback kit (keep accessible)

| Item | Where to keep it |
|------|------------------|
| Google Fiber Network Box | Same shelf, powered off but reachable |
| Original Ethernet cable (Fiber Jack → Network Box) | Labeled, coiled next to Network Box |
| Network Box power adapter | With Network Box |
| This rollback card | Tape to Network Box or inside shelf |

**Rollback time target: under 5 minutes.**

---

## Phase 1 — Install Ubuntu on Mac Mini (1–2 hours)

### 1.1 Create boot USB

1. On another computer, download [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server).
2. Flash to USB with [Rufus](https://rufus.ie) (Windows) or `dd` (Mac/Linux).
3. Plug USB into Mac Mini, hold **Option** at boot, select the USB drive.

### 1.2 Ubuntu install options

| Setting | Value |
|---------|-------|
| Hostname | `mac-mini-fw` |
| Username | your choice (e.g. `admin`) |
| Install OpenSSH | **Yes** |
| Disk | Use entire 256 GB HDD (default) |
| Wi-Fi | Skip (no Wi-Fi driver needed for router role) |

### 1.3 First boot — connect temporarily to existing network

For initial setup **before cutover**, you have two options:

**Option A (easier):** Plug Mac Mini LAN port into your **existing** Network Box LAN (blue port) temporarily. Mac Mini gets internet via DHCP from Network Box. This lets you `apt install` and test without disconnecting Google Fiber.

**Option B:** Keyboard + monitor only; configure offline, finish networking at cutover.

**Recommendation: Option A** — less risk, you can fully test before touching the Fiber Jack.

### 1.4 Update system

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

---

## Phase 2 — Install MiniFW (20 min)

```bash
git clone https://github.com/peteedoo/project-template.git
cd project-template/mac-mini-firewall
sudo bash scripts/install.sh
```

### 2.1 Detect interface names

```bash
bash scripts/detect-interfaces.sh
```

Note the names. Typical results on Mac Mini:

| Role | Likely name | How to identify |
|------|-------------|-----------------|
| USB WAN | `enx0a1b2c3d4e5f` | Appears when USB adapter is plugged in |
| Built-in LAN | `enp3s0` or `eno1` | Always present; built-in port |

### 2.2 Configure netplan

```bash
sudo cp config/netplan.example.yaml /etc/netplan/01-minifw.yaml
sudo nano /etc/netplan/01-minifw.yaml
# Adjust match patterns if needed for your interface names
sudo netplan apply
ip -br addr    # LAN should show 192.168.10.1 on built-in port
```

### 2.3 Configure MiniFW

```bash
sudo minifw init
sudo nano /etc/minifw/firewall.yaml
```

Set `interfaces.wan` and `interfaces.lan` to your actual names from step 2.1.

```bash
sudo minifw apply
sudo systemctl enable --now nftables dnsmasq
```

### 2.4 Enable SSH from LAN (already in rules)

From another device on `192.168.10.x` (after cutover), you can SSH to `192.168.10.1`.

---

## Phase 3 — Pre-cutover testing (while Network Box still runs internet)

Goal: prove the Mac Mini works **before** you unplug the Fiber Jack.

### 3.1 Temporary test topology

```
Network Box (still routing internet for house)
    └── blue LAN port ──► Mac Mini built-in Ethernet (LAN)
Mac Mini USB WAN ──► NOT connected to Fiber Jack yet
```

Your house still uses Network Box for internet. Mac Mini LAN is on a separate `192.168.10.0/24` subnet for testing.

### 3.2 Plug a laptop into the switch off Mac Mini LAN

If you have a switch: `Mac Mini LAN → switch → laptop`.

Set laptop to DHCP. It should get `192.168.10.x` from dnsmasq on the Mac Mini.

### 3.3 Run preflight

```bash
sudo bash scripts/preflight.sh
```

**Do not proceed to Phase 4 until preflight passes** (or only has warnings you understand).

### 3.4 Vet checklist — must pass before cutover

| # | Test | How | Pass? |
|---|------|-----|-------|
| 1 | Mac Mini boots reliably | Reboot twice, SSH or console login works | ☐ |
| 2 | LAN IP correct | `ip -br addr` shows `192.168.10.1` on LAN | ☐ |
| 3 | DHCP works | Laptop on switch gets `192.168.10.100+` | ☐ |
| 4 | dnsmasq running | `systemctl status dnsmasq` active | ☐ |
| 5 | nftables loaded | `sudo nft list ruleset` shows MiniFW rules | ☐ |
| 6 | ip_forward on | `sysctl net.ipv4.ip_forward` = 1 | ☐ |
| 7 | Config saved | `/etc/minifw/firewall.yaml` has correct interface names | ☐ |
| 8 | Rollback kit ready | Network Box, cables, photos accessible | ☐ |
| 9 | TRIAGE doc saved offline | On phone or printed | ☐ |
| 10 | Someone knows rollback | Household member can swap cables if needed | ☐ |

---

## Phase 4 — Cutover (15 min, schedule 1 hour window)

**Best time:** When you can tolerate 15–30 min without internet and someone can help if needed.

### 4.1 Cutover sequence

```
Order matters. Follow exactly.

1. [ ] Tell household: internet will be down ~15 min
2. [ ] Open TRIAGE.md on phone (cellular)
3. [ ] Open BACKUP-AND-ROLLBACK.md on phone
4. [ ] Unplug Network Box power (internet goes down — expected)
5. [ ] Disconnect Fiber Jack Ethernet from Network Box
6. [ ] Connect Fiber Jack Ethernet → USB adapter → Mac Mini
7. [ ] Mac Mini built-in Ethernet → switch → Deco main unit
8. [ ] Power on Mac Mini if it was off
9. [ ] Wait 3 minutes
```

### 4.2 Configure Deco XE75 (if not already in AP mode)

1. Open Deco app (phone on cellular or after LAN works).
2. **More → Advanced → Operation Mode → Access Point → Save → Reboot**.
3. Wait 2 min for solid green LED on main Deco.

### 4.3 Verify WAN on Mac Mini

Connect keyboard + monitor to Mac Mini, or SSH from a laptop on the switch:

```bash
ip -br addr                    # WAN should have a public IPv4
ping -c 3 1.1.1.1
curl ifconfig.me               # should NOT be 192.168.x.x
sudo bash scripts/preflight.sh
```

### 4.4 Verify from phone on Deco Wi-Fi

1. Connect phone to Deco Wi-Fi.
2. Open browser → https://google.com
3. Visit https://ifconfig.me — should show your Google Fiber public IP.

### 4.5 Cutover pass/fail

| Result | Action |
|--------|--------|
| **PASS** — internet works, public IP confirmed | Proceed to Phase 5. Store Network Box. |
| **FAIL** — no WAN IP after 10 min | Try VLAN 2 fallback (Phase 4.6), then rollback if still failing |
| **FAIL** — WAN works, Wi-Fi doesn't | See [TRIAGE.md](TRIAGE.md) § "Wi-Fi works but no internet" / Deco section |
| **FAIL** — total outage after 15 min | **Rollback immediately** → [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md) |

### 4.6 VLAN 2 fallback (only if WAN has no IP)

Some older Google Fiber installs require VLAN 2:

```bash
sudo cp config/netplan-vlan2-fallback.yaml /etc/netplan/01-minifw.yaml
sudo netplan apply
# wait 3 minutes
ip -br addr
ping -c 3 1.1.1.1
```

If still no IP after 10 more minutes → **rollback**.

---

## Phase 5 — Post-cutover hardening (30 min)

### 5.1 Reserve Deco IP (optional)

Add to `/etc/dnsmasq.d/minifw.conf` or create `/etc/dnsmasq.d/deco.conf`:

```
dhcp-host=AA:BB:CC:DD:EE:FF,192.168.10.2,deco-main
```

Replace with main Deco's MAC (on Deco label or router admin).

```bash
sudo systemctl restart dnsmasq
```

### 5.2 Disable unused services on Mac Mini

```bash
sudo systemctl disable --now snapd 2>/dev/null || true
```

### 5.3 Auto-start on reboot

```bash
sudo systemctl enable nftables dnsmasq
```

Reboot Mac Mini and confirm internet returns within 3 min:

```bash
sudo reboot
# after reboot, from phone on Wi-Fi:
# curl ifconfig.me
```

### 5.4 Label physical cables

| Cable | Label |
|-------|-------|
| Fiber Jack → USB adapter | `WAN` |
| Mac Mini built-in → switch | `LAN` |
| Switch → Deco main | `DECO` |

---

## Phase 6 — Ongoing maintenance

| Task | Frequency |
|------|-----------|
| `sudo apt update && sudo apt upgrade` | Monthly |
| Check `sudo minifw status` | After any power outage |
| Verify rollback kit intact | Quarterly |
| Re-read TRIAGE.md | Once, then keep on phone |

---

## Quick reference — IP plan

| Device | IP |
|--------|-----|
| Mac Mini (gateway) | `192.168.10.1` |
| Deco main (reserved) | `192.168.10.2` |
| DHCP pool | `192.168.10.100` – `192.168.10.250` |
| DNS | `1.1.1.1`, `1.0.0.1` (via MiniFW/dnsmasq) |

---

## Abort criteria — when to rollback

Rollback immediately if **any** of these are true after 15 minutes of troubleshooting:

- Fiber Jack has solid light but Mac Mini WAN never gets an IP (even with VLAN 2)
- Household needs internet for work/health and you cannot fix it in 15 min
- You are unsure which cable goes where
- Mac Mini will not boot or kernel panics on start

**Rollback is not failure.** It restores service while you debug with a keyboard and monitor attached.

→ [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md)

# Internet down — offline triage runbook

**Use this when the internet is not working and you cannot reach support chat.**

Save this file on your phone **before** you start the Mac Mini cutover.

| Related docs | |
|--------------|---|
| Restore old setup fast | [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md) |
| Full setup steps | [SETUP-PLAN.md](SETUP-PLAN.md) |

**Google Fiber support (cellular):** 1-866-777-7550

---

## Start here — 60-second check

Answer these in order. Stop at the first **NO** and go to that section.

```
[ ] 1. Is the Fiber Jack powered? (its adapter plugged in, status light on)
        NO  → § A — Fiber Jack
        YES ↓

[ ] 2. Are you on Mac Mini firewall or Network Box?
        Mac Mini  → continue
        Network Box / unsure → § F — Rollback

[ ] 3. Can you connect to Deco Wi-Fi?
        NO  → § E — Deco Wi-Fi
        YES ↓

[ ] 4. Does a website load (google.com)?
        YES → Not a total outage; may be one device — § G
        NO  ↓

[ ] 5. On Mac Mini (keyboard/monitor or laptop on switch): can you ping 1.1.1.1?
        NO  → § B — WAN problem
        YES → § C — LAN/DNS problem
```

---

## § A — Fiber Jack problem

**Symptoms:** Nothing works. Mac Mini WAN has no IP. Network Box Internet LED red if rolled back.

| Check | Action |
|-------|--------|
| Fiber Jack power | Plug in power adapter; wait 2 min for solid status light |
| Ethernet seated | Push cable firmly into Fiber Jack and into WAN adapter/Network Box |
| Fiber Jack light | Blinking then solid = good. No light = power problem |
| Mac Mini was unplugged from Fiber Jack | Only **one** device should connect to Fiber Jack Ethernet |

**If still down after 5 min:** Rollback to Network Box → [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md)

---

## § B — WAN problem (Mac Mini has no internet)

**Symptoms:** Deco Wi-Fi connects but "No internet." Mac Mini cannot `ping 1.1.1.1`.

### B1 — Check Mac Mini WAN (needs keyboard+monitor or laptop on switch + SSH)

Login to Mac Mini. Run:

```bash
ip -br addr
```

| What you see | Meaning | Fix |
|--------------|---------|-----|
| WAN interface has no `inet` | No IP from Google | B2 |
| WAN has `192.168.x.x` | Still behind a router, not Fiber Jack | Reconnect Fiber Jack → USB WAN directly |
| WAN has public IP | WAN OK — go to § C | |

### B2 — Try VLAN 2 (older Google Fiber)

```bash
sudo cp /path/to/mac-mini-firewall/config/netplan-vlan2-fallback.yaml /etc/netplan/01-minifw.yaml
sudo netplan apply
# wait 3 minutes
ip -br addr
ping -c 3 1.1.1.1
```

### B3 — Power-cycle sequence

1. Unplug Mac Mini power — wait 30 sec — plug in
2. Wait 3 min
3. If still no WAN IP → **rollback** (5 min to restore internet)

---

## § C — LAN or DNS problem

**Symptoms:** Mac Mini can `ping 1.1.1.1` but phones cannot browse.

### C1 — Check dnsmasq

```bash
systemctl status dnsmasq
```

| Status | Fix |
|--------|-----|
| inactive / failed | `sudo systemctl restart dnsmasq` |
| active | C2 |

### C2 — Check nftables forwarding

```bash
sudo nft list chain inet filter forward
sysctl net.ipv4.ip_forward
```

`ip_forward` must be `1`. If `0`:

```bash
sudo minifw apply
```

### C3 — Phone DNS test

On phone (Wi-Fi on), try switching DNS to manual `192.168.10.1` or `1.1.1.1`.

If manual `1.1.1.1` works but automatic doesn't → dnsmasq issue on Mac Mini.

### C4 — Restart services

```bash
sudo systemctl restart dnsmasq
sudo nft -f /etc/nftables.conf
```

Reboot Mac Mini if still broken:

```bash
sudo reboot
```

Wait 3 min, test again. If still broken → **rollback**.

---

## § D — Mac Mini won't boot / frozen

1. Hold power 10 sec to force off
2. Power on; wait for login prompt (2–3 min)
3. If kernel panic or won't start → **rollback immediately**
4. Debug Mac Mini later with monitor attached

---

## § E — Deco Wi-Fi problem

**Symptoms:** No Wi-Fi network visible, or cannot connect.

| Check | Action |
|-------|--------|
| Main Deco powered | LED on main unit (near switch) |
| Ethernet to main Deco | Cable from switch → main Deco LAN port |
| Deco in AP mode without Mac Mini gateway | Deco needs Mac Mini at `192.168.10.1` working first |
| Wrong operation mode | Deco app → AP mode if using Mac Mini; Router mode if rolled back to Network Box |

### Deco app cannot find mesh

1. Power-cycle main Deco (unplug 30 sec)
2. Wait 3 min
3. If on Network Box rollback: switch Deco to **Router** mode
4. If on Mac Mini: switch Deco to **Access Point** mode

### Last resort — reset main Deco only

- Hold reset button 10 sec on main unit
- Re-run Deco app setup
- **Write down Wi-Fi password before any cutover**

---

## § F — Emergency rollback (fastest fix)

**When:** Out of time, out of ideas, need internet now.

```
1. Unplug Mac Mini (optional)
2. Fiber Jack Ethernet → Network Box WAN (globe icon, left port)
3. Network Box blue LAN → Deco (same port as before)
4. Network Box power on
5. Wait 3 min — 3 green LEDs
6. Deco app → Router mode if Wi-Fi missing
7. Test google.com on phone
```

Also run: `bash scripts/rollback-to-network-box.sh` (reminder text)

Full steps: [BACKUP-AND-ROLLBACK.md](BACKUP-AND-ROLLBACK.md)

---

## § G — One device broken, others fine

| Symptom | Fix |
|---------|-----|
| One phone won't connect | Forget Wi-Fi network, rejoin |
| One laptop no internet | Check proxy/VPN; `ipconfig /flushdns` or reboot |
| Slow but working | Reboot Deco main unit; check Mac Mini CPU: `top` |

---

## LED reference

### Google Fiber Network Box (rollback device)

| LED | Solid green | Not green |
|-----|-------------|-----------|
| Power | OK | Check power cable |
| Internet | OK | Check Fiber Jack cable; power-cycle 30 sec |
| Wi-Fi | Wi-Fi on | May still work over Ethernet |

### Fiber Jack

| Light | Meaning |
|-------|---------|
| Solid | Ready |
| Blinking | Starting up — wait 2 min |
| Off | No power — plug in adapter |

### Deco XE75

| LED | Meaning |
|-----|---------|
| Solid green | Healthy |
| Red | No upstream / no internet |
| Pulsing blue | Setup mode |

---

## Commands cheat sheet (Mac Mini)

Copy these for local console or SSH to `192.168.10.1`:

```bash
# What's connected?
ip -br addr
ip -br link

# Internet from Mac Mini?
ping -c 3 1.1.1.1
curl -s ifconfig.me; echo

# Services
systemctl status dnsmasq nftables
sudo minifw status

# Re-apply firewall
sudo minifw apply

# Full preflight
sudo bash /path/to/mac-mini-firewall/scripts/preflight.sh

# Reboot
sudo reboot
```

---

## Decision tree (visual)

```
Internet down?
    │
    ├─ Need internet in < 5 min? ──YES──► § F Rollback
    │
    NO (have time to debug)
    │
    ├─ Fiber Jack light off? ──YES──► § A
    │
    ├─ Mac Mini won't boot? ──YES──► § D → Rollback
    │
    ├─ No Wi-Fi? ──YES──► § E
    │
    ├─ Wi-Fi OK, no browse?
    │       │
    │       ├─ Mac Mini ping 1.1.1.1 fails? ──YES──► § B
    │       └─ ping OK? ──YES──► § C
    │
    └─ 15 min stuck? ──► § F Rollback
```

---

## After you fix it

1. Note what broke and what fixed it
2. Update `/etc/minifw/firewall.yaml` if you changed anything manually
3. Re-run: `sudo bash scripts/preflight.sh`
4. Keep this doc on your phone

---

## One-screen emergency card

```
┌────────────────────────────────────────────────────┐
│ INTERNET DOWN — DO THIS FIRST                       │
├────────────────────────────────────────────────────┤
│ 1. Fiber Jack powered? Light on?                    │
│ 2. 15 min stuck? → ROLLBACK Network Box (5 min)    │
│    • Fiber Jack → Network Box WAN (globe, left)     │
│    • Network Box power on, wait 3 green LEDs        │
│    • Deco app → Router mode if no Wi-Fi             │
│ 3. GF support: 1-866-777-7550 (use cell data)       │
│ 4. Mac Mini debug: keyboard + monitor at shelf      │
│    ip -br addr | ping 1.1.1.1 | sudo minifw status │
└────────────────────────────────────────────────────┘
```

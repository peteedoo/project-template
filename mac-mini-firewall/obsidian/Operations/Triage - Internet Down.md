---
tags: [operations, triage, emergency]
aliases: [Internet Down, Offline Triage]
---

# Triage — Internet Down

← [[Home]] · Fast fix → [[Backup and Rollback]] · [[Emergency Card]]

**Use when internet is not working and you cannot reach support chat.**

Save this note on your phone before [[Phase 4 - Cutover]].

**Google Fiber:** 1-866-777-7550 (cellular)

---

## 60-second check

```
[ ] 1. Fiber Jack powered, light on?
        NO  → § A below
        YES ↓

[ ] 2. Mac Mini or Network Box?
        Network Box / unsure → [[Backup and Rollback]]
        Mac Mini ↓

[ ] 3. Deco Wi-Fi connects?
        NO  → § E below
        YES ↓

[ ] 4. google.com loads?
        YES → § G (one device issue)
        NO  ↓

[ ] 5. Mac Mini: ping 1.1.1.1 works?
        NO  → § B (WAN)
        YES → § C (LAN/DNS)
```

**15 min stuck?** → [[Backup and Rollback]]

---

## § A — Fiber Jack

| Check | Fix |
|-------|-----|
| Power adapter | Plug in, wait 2 min |
| Ethernet seated | Firm push both ends |
| Only one device on Fiber Jack | Mac Mini WAN **or** Network Box, not both |

Still down → [[Backup and Rollback]]

---

## § B — WAN problem

Mac Mini can't reach internet. Run on Mac Mini (keyboard/monitor or SSH `192.168.10.1`):

```bash
ip -br addr
```

| WAN shows | Fix |
|-----------|-----|
| No IP | [[Config Files#VLAN 2 fallback]] then rollback |
| `192.168.x.x` | Fiber Jack not on Mac Mini WAN directly |
| Public IP | Go to § C |

Power-cycle Mac Mini (30 sec off). Still broken → [[Backup and Rollback]]

---

## § C — LAN / DNS problem

Mac Mini pings `1.1.1.1` but phones can't browse.

```bash
systemctl status dnsmasq
sysctl net.ipv4.ip_forward    # must be 1
sudo minifw apply
sudo systemctl restart dnsmasq
```

Phone: set DNS manually to `1.1.1.1` — if that works, dnsmasq issue on Mac Mini.

Reboot Mac Mini. Still broken → [[Backup and Rollback]]

---

## § D — Mac Mini won't boot

Force off (hold power 10 sec). Won't start → [[Backup and Rollback]] immediately.

---

## § E — Deco Wi-Fi

| Check | Fix |
|-------|-----|
| Main Deco powered | Check switch cable |
| Wrong mode | AP mode for Mac Mini; Router mode if rolled back |
| App can't find mesh | Power-cycle main Deco 30 sec |

Last resort: factory reset main Deco (document Wi-Fi password first).

→ [[Google Fiber and Deco XE75#Deco XE75 — Access Point mode]]

---

## § F — Emergency rollback

→ [[Backup and Rollback#Rollback procedure (5 minutes)]]

---

## § G — One device only

Forget Wi-Fi and rejoin. Check VPN/proxy on that device.

---

## Commands cheat sheet

```bash
ip -br addr
ping -c 3 1.1.1.1
curl -s ifconfig.me; echo
systemctl status dnsmasq
sudo minifw status
sudo minifw apply
sudo bash scripts/preflight.sh
sudo reboot
```

On Mac Mini after setup: `cat /root/INTERNET-DOWN.txt`

---

## Decision tree

```
Internet down?
  ├─ Need internet NOW? → [[Backup and Rollback]]
  ├─ Fiber Jack off? → § A
  ├─ Mac Mini dead? → § D → Rollback
  ├─ No Wi-Fi? → § E
  └─ Wi-Fi OK, no browse?
        ├─ ping 1.1.1.1 fails → § B
        └─ ping OK → § C
```

---

## Related

- [[Emergency Card]]
- [[Backup and Rollback]]
- [[Phase 4 - Cutover]]
- [[Google Fiber and Deco XE75#LEDs]]

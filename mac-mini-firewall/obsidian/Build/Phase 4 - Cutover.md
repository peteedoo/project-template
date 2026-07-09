---
tags: [build, phase-4, cutover]
---

# Phase 4 — Cutover

← [[Phase 3 - Pre-Cutover Testing]] · [[Home]] · Next → [[Phase 5 - Post-Cutover]]

⏱ ~15 min · **Schedule a 1-hour window**

If stuck 15+ min → [[Backup and Rollback]] immediately.

---

## 4.1 Pre-cutover

- [ ] Tell household: internet down ~15 min
- [ ] Open [[Triage - Internet Down]] on phone (cellular)
- [ ] Open [[Backup and Rollback]] on phone
- [ ] [[MINIFWSETUP USB]] and rollback kit within reach

---

## 4.2 Cutover sequence

**Order matters. Follow exactly.**

1. [ ] Unplug Network Box power (internet goes down — expected)
2. [ ] Disconnect Fiber Jack Ethernet from Network Box
3. [ ] Fiber Jack Ethernet → USB adapter → Mac Mini **WAN**
4. [ ] Mac Mini built-in Ethernet → switch → Deco main unit
5. [ ] Power on Mac Mini if off
6. [ ] Wait 3 minutes

Wiring reference → [[Google Fiber and Deco XE75#Wiring steps]]

---

## 4.3 Deco XE75 — Access Point mode

1. Deco app → **More → Advanced → Operation Mode**
2. **Access Point** → Save → Reboot
3. Wait 2 min for solid green LED

Details → [[Google Fiber and Deco XE75#Deco XE75 — Access Point mode]]

---

## 4.4 Verify Mac Mini

```bash
ip -br addr                    # WAN should have public IPv4
ping -c 3 1.1.1.1
curl ifconfig.me               # must NOT be 192.168.x.x
sudo bash scripts/preflight.sh
```

---

## 4.5 Verify from phone (Deco Wi-Fi)

1. Connect to Deco Wi-Fi
2. https://google.com loads
3. https://ifconfig.me shows **public** Google Fiber IP

---

## 4.6 Pass / fail

| Result | Action |
|--------|--------|
| ✅ Internet works, public IP confirmed | → [[Phase 5 - Post-Cutover]] |
| ❌ No WAN IP after 10 min | Try [[Config Files#VLAN 2 fallback]] then rollback |
| ❌ WAN OK, Wi-Fi broken | [[Triage - Internet Down#§ E — Deco Wi-Fi problem]] |
| ❌ Total outage 15+ min | **[[Backup and Rollback]]** now |

---

## 4.7 VLAN 2 fallback (only if no WAN IP)

```bash
sudo cp config/netplan-vlan2-fallback.yaml /etc/netplan/01-minifw.yaml
sudo netplan apply
# wait 3 min, test again
```

Still no IP after 10 min → [[Backup and Rollback]].

---

## Abort criteria

Rollback if any of these after 15 min:

- Fiber Jack solid but Mac Mini WAN never gets IP (even with VLAN 2)
- Household needs internet now
- Unsure which cable goes where
- Mac Mini won't boot

→ [[Backup and Rollback]]

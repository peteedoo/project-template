---
tags: [operations, rollback, backup]
---

# Backup and Rollback

← [[Home]] · Emergency → [[Emergency Card]] · [[Triage - Internet Down]]

Restore internet in **under 5 minutes** by reconnecting the Google Fiber Network Box.

**Keep the Network Box** for at least 30 days after cutover.

---

## What rollback fixes

| Failure | Fixed? |
|---------|--------|
| Mac Mini won't boot | ✅ |
| Wrong netplan / no WAN IP | ✅ |
| Firewall misconfiguration | ✅ |
| Deco wrong mode | ✅ |
| Wrong cable | ✅ (use photos from [[Phase 0 - Before You Start]]) |
| Mac Mini hardware death | ✅ |

---

## Backup kit — label **GF ROLLBACK**

```
┌─────────────────────────────────────────┐
│  Google Fiber Network Box               │
│  Network Box power adapter              │
│  Cable: Fiber Jack → Network Box        │
│  [[Emergency Card]]                     │
│  Photos of original wiring (phone)      │
│  [[MINIFWSETUP USB]]                    │
└─────────────────────────────────────────┘
```

### Original wiring

```
Fiber Jack ──Ethernet──► Network Box WAN (globe, LEFT port)
Network Box power ──► wall
Network Box LAN (blue) ──► Deco [note which port]
```

---

## Rollback procedure (5 minutes)

### When to rollback

- No internet **15+ minutes** after [[Phase 4 - Cutover]]
- Mac Mini hardware problem
- Need internet now
- Unsure about cabling

### Steps

| # | Action |
|---|--------|
| 1 | Optional: power off Mac Mini |
| 2 | Unplug USB Ethernet from Fiber Jack + Mac Mini |
| 3 | Fiber Jack → **Network Box WAN** (globe, left) |
| 4 | Network Box **blue LAN** → Deco (same as before) |
| 5 | Network Box power on |
| 6 | Wait **3 green LEDs** (2–3 min) |
| 7 | Test internet on phone Wi-Fi |

Quick reminder: `sudo bash /media/*/MINIFWSETUP/rollback-to-network-box.sh`

---

## If Wi-Fi does not come back

Deco may still be in **AP mode** (expects Mac Mini as gateway):

1. Deco app (cellular) → **More → Advanced → Operation Mode → Router**
2. Save → Reboot → wait 2 min
3. Test https://google.com

---

## If Network Box LEDs wrong

| LED | Problem | Fix |
|-----|---------|-----|
| Power | Off | Check adapter |
| Internet | Red/off | Reseat cable; power-cycle 30 sec |
| Wi-Fi | Off | Use blue LAN port with laptop |

---

## Call Google Fiber

**1-866-777-7550** (cellular) — with Network Box restored they can help fully.

---

## Dry-run rollback (optional)

Weekend morning, 30 min:

1. Note working state
2. Rollback → confirm internet
3. Re-do [[Phase 4 - Cutover]]
4. Confirm Mac Mini works

Proves 5-minute restore.

---

## Config backup (before cutover)

```bash
sudo tar czf ~/minifw-backup-$(date +%Y%m%d).tar.gz \
  /etc/minifw/firewall.yaml \
  /etc/netplan/01-minifw.yaml \
  /etc/nftables.conf \
  /etc/dnsmasq.d/minifw.conf \
  /etc/sysctl.d/99-minifw.conf
```

Run during [[Phase 3 - Pre-Cutover Testing]].

---

## After rollback — debug Mac Mini

1. Keyboard + monitor on Mac Mini
2. Mac Mini LAN → Network Box blue port (temporary internet)
3. Check logs → [[Triage - Internet Down#Commands cheat sheet (Mac Mini)]]
4. Fix → re-run [[Preflight Checklist]]
5. Retry [[Phase 4 - Cutover]]

---

## Related

- [[Emergency Card]]
- [[Phase 0 - Before You Start]]
- [[Phase 4 - Cutover#Abort criteria]]

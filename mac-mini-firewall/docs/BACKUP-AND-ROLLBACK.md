# Backup and rollback plan

This document ensures you can **restore internet in under 5 minutes** if the Mac Mini firewall setup fails.

**Keep the Google Fiber Network Box.** Do not return it until the Mac Mini has run successfully for at least 30 days.

---

## What you are protecting against

| Failure | Rollback fixes it? |
|---------|-------------------|
| Mac Mini won't boot | Yes — restore Network Box |
| Wrong netplan / no WAN IP | Yes |
| nftables misconfiguration | Yes (or fix Mac Mini locally) |
| Deco stuck in wrong mode | Yes — switch Deco back to Router mode |
| Broke a cable / wrong port | Yes — photos show original layout |
| Mac Mini hardware failure | Yes |

---

## Backup kit — keep on the shelf

Store these together, labeled **"GF ROLLBACK"**:

```
┌─────────────────────────────────────────┐
│  Google Fiber Network Box (powered off) │
│  Network Box power adapter              │
│  Yellow/white cable: Fiber Jack → NB    │
│  Printed: rollback steps (this page)    │
│  Photo: original wiring (on phone)      │
└─────────────────────────────────────────┘
```

### Original wiring (your setup)

From your photos:

```
Fiber Jack (small box, yellow Ethernet)
    └── Ethernet ──► Network Box WAN (globe icon, LEFT port of pair)
Network Box power ──► wall outlet
Network Box LAN (blue port) ──► [your Deco or switch — note which port you used]
```

**Before cutover:** write down which blue LAN port you use, if any.

---

## Rollback procedure (5 minutes)

### When to rollback

- No internet 15+ minutes after cutover
- Mac Mini hardware problem
- You need internet now and cannot debug
- Panic / uncertainty about cabling

### Steps

| Step | Action | Time |
|------|--------|------|
| 1 | **Optional:** Power off Mac Mini (reduces confusion) | 30 sec |
| 2 | Unplug USB Ethernet from Fiber Jack and Mac Mini | 30 sec |
| 3 | Connect **Fiber Jack → Network Box WAN** (globe, left port) — same as before | 30 sec |
| 4 | Connect **Network Box LAN (blue) → Deco** (same port as before cutover) | 30 sec |
| 5 | Plug in **Network Box power** | 30 sec |
| 6 | Wait for **3 green LEDs**: Power, Internet, Wi-Fi | 2–3 min |
| 7 | Test internet on phone (Wi-Fi) | 1 min |

### If Wi-Fi does not come back

Deco may still be in **Access Point** mode expecting the Mac Mini as gateway.

1. Open **Deco app** (use cellular if Wi-Fi is down).
2. **More → Advanced → Operation Mode → Router → Save → Reboot**.
3. Wait 2 minutes.
4. Connect to Deco Wi-Fi; test https://google.com.

If Deco app cannot reach the mesh: factory-reset main Deco only as last resort (re-add satellites after). Document your Wi-Fi name/password before cutover.

### If Network Box LEDs are not all green

| LED | Off or red | Fix |
|-----|------------|-----|
| Power | Off | Check power adapter |
| Internet | Red/off | Reseat Fiber Jack Ethernet; wait 3 min; power-cycle Network Box (unplug 30 sec) |
| Wi-Fi | Off | Wi-Fi may be disabled; LAN still works — plug laptop into blue port |

### Call Google Fiber

- **Phone:** 1-866-777-7550 (US) — use cellular
- With Network Box restored, they can troubleshoot fully
- Say: "I reconnected my Network Box to the Fiber Jack and internet is still down"

---

## Parallel backup strategy (recommended)

Do not throw away your working setup on day one.

### Week 1: keep Network Box on the shelf, powered off

- Cables labeled and coiled
- Rollback tested once (optional dry run on a weekday morning)

### Week 2–4: stable operation checklist

| Day | Check |
|-----|-------|
| 1 | Internet works after Mac Mini reboot |
| 3 | Phone on Deco Wi-Fi shows public IP at ifconfig.me |
| 7 | Power-cycle Mac Mini; internet returns < 3 min |
| 14 | Household confirms Wi-Fi stable |
| 30 | Consider storing Network Box in closet (still keep it) |

### Dry-run rollback (optional, low risk)

On a weekend morning when you have 30 minutes:

1. Note current working state
2. Perform rollback steps
3. Confirm internet works on Network Box
4. Perform cutover again (Phase 4 of SETUP-PLAN.md)
5. Confirm Mac Mini works again

This proves rollback in under 5 minutes.

---

## Config backups on Mac Mini

Before cutover, back up configs to a USB stick or your laptop:

```bash
sudo tar czf ~/minifw-backup-$(date +%Y%m%d).tar.gz \
  /etc/minifw/firewall.yaml \
  /etc/netplan/01-minifw.yaml \
  /etc/nftables.conf \
  /etc/dnsmasq.d/minifw.conf \
  /etc/sysctl.d/99-minifw.conf
```

Copy the `.tar.gz` off the Mac Mini while it still has internet (Phase 3 testing).

---

## After successful rollback — debugging Mac Mini

When internet is restored via Network Box:

1. Connect keyboard + monitor to Mac Mini
2. Plug Mac Mini LAN into Network Box blue port (temporary)
3. SSH or login locally
4. Review:
   ```bash
   ip -br addr
   journalctl -u systemd-networkd -n 50
   sudo nft list ruleset
   journalctl -u dnsmasq -n 30
   ```
5. Fix config, re-run `sudo bash scripts/preflight.sh`
6. Schedule another cutover attempt

---

## One-page rollback card (print this)

```
═══════════════════════════════════════════════════
  GOOGLE FIBER ROLLBACK — restore internet in 5 min
═══════════════════════════════════════════════════

1. Unplug Mac Mini (optional)
2. Fiber Jack Ethernet → Network Box WAN (globe, left)
3. Network Box blue LAN → Deco (same as before)
4. Plug in Network Box power
5. Wait 3 min for 3 green LEDs
6. If no Wi-Fi: Deco app → Router mode (not AP mode)
7. Still broken? Call GF: 1-866-777-7550

Photos of original wiring: [on your phone]
Full guide: mac-mini-firewall/docs/BACKUP-AND-ROLLBACK.md
═══════════════════════════════════════════════════
```

---
tags: [build, phase-6, maintenance]
---

# Phase 6 — Maintenance

← [[Phase 5 - Post-Cutover]] · [[Home]]

---

## Monthly

```bash
sudo apt update && sudo apt upgrade -y
sudo minifw status
```

---

## After power outage

```bash
sudo minifw status
curl -s ifconfig.me
```

If down → [[Triage - Internet Down]]

---

## Quarterly

- [ ] [[Backup and Rollback]] kit intact (Network Box, cables, MINIFWSETUP USB)
- [ ] Photos of wiring still on phone

---

## 30-day stable checklist

| Day | Check |
|-----|-------|
| 1 | Internet after Mac Mini reboot |
| 3 | Public IP on phone at ifconfig.me |
| 7 | Power-cycle Mac Mini; internet < 3 min |
| 14 | Household confirms Wi-Fi stable |
| 30 | Network Box can move to closet (still keep it) |

---

## Optional upgrades

- DNS ad-blocking (Pi-hole) — see [[Topology Overview#Optional improvements]]
- WireGuard VPN for remote access
- IoT VLAN (managed switch)

---

## Related

- [[minifw Commands]]
- [[Triage - Internet Down]]
- [[Backup and Rollback]]

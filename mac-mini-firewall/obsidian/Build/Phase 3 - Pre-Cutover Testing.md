---
tags: [build, phase-3, testing]
---

# Phase 3 — Pre-Cutover Testing

← [[Phase 2 - MINIFWSETUP USB]] · [[Home]] · Next → [[Phase 4 - Cutover]]

⏱ ~30 min · **Gate: do not cut over until checks pass**

---

## Goal

Prove the Mac Mini works **before** unplugging the Fiber Jack. Your house still uses the Network Box for internet during this phase.

---

## 3.1 Test topology

```
Network Box (still routing internet for house)
    └── blue LAN port ──► Mac Mini built-in Ethernet (LAN)

Mac Mini USB WAN ──► NOT connected to Fiber Jack yet
```

---

## 3.2 Test DHCP on Mac Mini LAN

Plug laptop into switch off Mac Mini LAN port. Laptop should get `192.168.10.x` via DHCP.

See [[IP Address Plan]].

---

## 3.3 Run preflight

```bash
sudo bash scripts/preflight.sh
# or from USB:
sudo bash /media/*/MINIFWSETUP/preflight.sh
```

Full checklist → [[Preflight Checklist]]

**Do not proceed to [[Phase 4 - Cutover]] until preflight passes** (or you understand every warning).

---

## 3.4 Vet checklist

| # | Test | Pass? |
|---|------|-------|
| 1 | Mac Mini boots reliably (reboot twice) | ☐ |
| 2 | LAN IP is `192.168.10.1` | ☐ |
| 3 | Laptop gets `192.168.10.100+` via DHCP | ☐ |
| 4 | `dnsmasq` active | ☐ |
| 5 | `nftables` rules loaded | ☐ |
| 6 | `ip_forward` = 1 | ☐ |
| 7 | `/etc/minifw/firewall.yaml` correct | ☐ |
| 8 | [[Backup and Rollback]] kit ready | ☐ |
| 9 | [[Triage - Internet Down]] on phone | ☐ |
| 10 | Someone knows rollback steps | ☐ |

---

## Done when

- [ ] All vet checks passed
- [ ] [[Backup and Rollback]] kit confirmed on shelf
- [ ] [[Phase 4 - Cutover]] scheduled (1 hour window, low-stakes time)

→ Continue to [[Phase 4 - Cutover]]

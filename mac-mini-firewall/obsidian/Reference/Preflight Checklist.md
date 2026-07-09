---
tags: [reference, testing, checklist]
---

# Preflight Checklist

← [[Home]] · Gate before → [[Phase 4 - Cutover]]

Run on Mac Mini:

```bash
sudo bash scripts/preflight.sh
# from USB:
sudo bash /media/*/MINIFWSETUP/preflight.sh
```

**Do not cut over until this passes** (or you understand every warning).

---

## Automated checks (preflight.sh)

| Check | Pass means |
|-------|------------|
| WAN interface detected | USB Ethernet present (`enx*`) |
| WAN has IP | DHCP from Google (may fail pre-cutover — OK) |
| LAN is `192.168.10.1` | netplan applied |
| `ip_forward` = 1 | Routing enabled |
| dnsmasq running | DHCP/DNS ready |
| nftables loaded | Firewall active |
| ping 1.1.1.1 | Internet from Mac Mini |
| config exists | `/etc/minifw/firewall.yaml` |

---

## Manual vet checklist

| # | Test | Pass? |
|---|------|-------|
| 1 | Mac Mini boots reliably (reboot ×2) | ☐ |
| 2 | `ip -br addr` → LAN `192.168.10.1` | ☐ |
| 3 | Laptop on switch gets `192.168.10.100+` | ☐ |
| 4 | `systemctl status dnsmasq` active | ☐ |
| 5 | `sudo nft list ruleset` shows MiniFW | ☐ |
| 6 | `sysctl net.ipv4.ip_forward` = 1 | ☐ |
| 7 | `firewall.yaml` interface names correct | ☐ |
| 8 | [[Backup and Rollback]] kit ready | ☐ |
| 9 | [[Triage - Internet Down]] on phone | ☐ |
| 10 | Household knows rollback | ☐ |

---

## WAN IP note

Before [[Phase 4 - Cutover]], WAN may have **no IP** because Fiber Jack is still on Network Box. That is expected. After cutover, WAN **must** get a public IP.

---

## Related

- [[Phase 3 - Pre-Cutover Testing]]
- [[Phase 4 - Cutover]]
- [[Config Files]]

---
tags: [reference, cli]
---

# minifw Commands

← [[Home]] · Config → [[Config Files]]

---

## Setup

```bash
minifw init [--wan IFACE] [--lan IFACE] [--force]
minifw apply
sudo systemctl enable --now nftables dnsmasq
```

From [[MINIFWSETUP USB]]: `sudo ./setup.sh` does all of this.

---

## Daily use

```bash
minifw show              # print active config
minifw render            # preview nftables rules
minifw status            # interfaces + rules
minifw block 203.0.113.50
minifw allow-wan tcp 443 --source 203.0.113.0/24
```

Global config path: `minifw --config /path/to/firewall.yaml show`

---

## Diagnostics

```bash
ip -br addr
ip -br link
ping -c 3 1.1.1.1
curl -s ifconfig.me
systemctl status dnsmasq nftables
sudo nft list ruleset
sysctl net.ipv4.ip_forward
```

Full checklist → [[Preflight Checklist]]

---

## Files

| Path | Purpose |
|------|---------|
| `/etc/minifw/firewall.yaml` | Main config |
| `/etc/nftables.conf` | Generated rules |
| `/etc/dnsmasq.d/minifw.conf` | DHCP/DNS |
| `/etc/sysctl.d/99-minifw.conf` | Kernel hardening |

→ [[Config Files]]

---

## Related

- [[Phase 2 - MINIFWSETUP USB]]
- [[Triage - Internet Down#Commands cheat sheet]]

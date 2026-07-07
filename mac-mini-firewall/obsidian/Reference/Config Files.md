---
tags: [reference, config]
---

# Config Files

← [[Home]] · Commands → [[minifw Commands]] · IPs → [[IP Address Plan]]

---

## netplan

**Path:** `/etc/netplan/01-minifw.yaml`  
**Source:** `config/netplan.example.yaml` in repo

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    wan-usb:
      match: { name: enx* }      # USB Ethernet → Fiber Jack
      dhcp4: true
      dhcp6: true
    lan-built-in:
      match: { name: enp* }      # Built-in → switch
      addresses: [192.168.10.1/24]
      dhcp4: false
```

```bash
sudo netplan apply
ip -br addr
```

Set by [[MINIFWSETUP USB]] `setup.sh` automatically.

---

## VLAN 2 fallback

**Only if** WAN gets no DHCP after [[Phase 4 - Cutover]] (older Google Fiber).

```bash
sudo cp config/netplan-vlan2-fallback.yaml /etc/netplan/01-minifw.yaml
sudo netplan apply
```

Source: `config/netplan-vlan2-fallback.yaml`

Still no IP after 10 min → [[Backup and Rollback]]

---

## firewall.yaml

**Path:** `/etc/minifw/firewall.yaml`

Key fields:

```yaml
hostname: mac-mini-fw
interfaces:
  wan: enx0a1b2c3d4e5f    # USB adapter
  lan: enp3s0             # built-in
lan:
  subnet: 192.168.10.0/24
  gateway: 192.168.10.1
  dhcp_start: 192.168.10.100
  dhcp_end: 192.168.10.250
  dns_servers: [1.1.1.1, 1.0.0.1]
```

```bash
sudo minifw apply
```

---

## Generated files (do not hand-edit)

| File | Regenerate with |
|------|-----------------|
| `/etc/nftables.conf` | `minifw apply` |
| `/etc/dnsmasq.d/minifw.conf` | `minifw apply` |
| `/etc/sysctl.d/99-minifw.conf` | `minifw apply` |

---

## Backup before cutover

```bash
sudo tar czf ~/minifw-backup-$(date +%Y%m%d).tar.gz \
  /etc/minifw/firewall.yaml \
  /etc/netplan/01-minifw.yaml \
  /etc/nftables.conf \
  /etc/dnsmasq.d/minifw.conf \
  /etc/sysctl.d/99-minifw.conf
```

→ [[Backup and Rollback#Config backup (before cutover)]]

---

## Related

- [[Phase 2 - MINIFWSETUP USB]]
- [[Google Fiber and Deco XE75#Google Fiber WAN settings]]
- [[IP Address Plan]]

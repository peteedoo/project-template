---
tags: [reference, network]
---

# IP Address Plan

← [[Home]] · Network → [[Google Fiber and Deco XE75]]

Subnet: **`192.168.10.0/24`** (avoids conflict with the mesh router's default subnet)

---

## Static assignments

| Device | IP | Notes |
|--------|-----|-------|
| Mac Mini (gateway) | `192.168.10.1` | LAN interface, dnsmasq, nftables |
| Deco main (reserved) | `192.168.10.2` | Optional DHCP reservation |
| DHCP pool | `192.168.10.100` – `250` | Phones, laptops, IoT |
| Servers / NAS | `192.168.10.10` – `99` | Reserve low addresses manually |

---

## DNS

Clients receive via dnsmasq:

- `1.1.1.1` (Cloudflare)
- `1.0.0.1` (Cloudflare)

Configured in [[Config Files#firewall.yaml]].

---

## Deco DHCP reservation (optional)

`/etc/dnsmasq.d/deco.conf`:

```
dhcp-host=AA:BB:CC:DD:EE:FF,192.168.10.2,deco-main
```

→ [[Phase 5 - Post-Cutover]]

---

## Verify public IP

From phone on Deco Wi-Fi: https://ifconfig.me

Must show **Google Fiber public IP**, not `192.168.x.x`.

---

## Related

- [[Config Files#netplan]]
- [[Topology Overview]]

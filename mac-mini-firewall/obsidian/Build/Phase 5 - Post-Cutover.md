---
tags: [build, phase-5]
---

# Phase 5 — Post-Cutover

← [[Phase 4 - Cutover]] · [[Home]] · Next → [[Phase 6 - Maintenance]]

⏱ ~30 min

---

## 5.1 Reserve Deco IP (optional)

Add to `/etc/dnsmasq.d/deco.conf`:

```
dhcp-host=AA:BB:CC:DD:EE:FF,192.168.10.2,deco-main
```

```bash
sudo systemctl restart dnsmasq
```

See [[IP Address Plan]].

---

## 5.2 Trim services

```bash
sudo systemctl disable --now snapd 2>/dev/null || true
```

---

## 5.3 Auto-start on reboot

```bash
sudo systemctl enable nftables dnsmasq
sudo reboot
```

After reboot (within 3 min): `curl ifconfig.me` from phone on Wi-Fi.

---

## 5.4 Label cables

| Cable | Label |
|-------|-------|
| Fiber Jack → USB adapter | `WAN` |
| Mac Mini built-in → switch | `LAN` |
| Switch → Deco main | `DECO` |

---

## 5.5 Store Network Box

Keep Network Box on shelf (labeled **GF ROLLBACK**) for 30 days minimum.  
Do not return to Google until [[Phase 6 - Maintenance#30-day stable checklist]] is complete.

---

## Done when

- [ ] Reboot test passed
- [ ] Cables labeled
- [ ] Network Box stored in rollback kit
- [ ] [[Emergency Card]] still on phone / shelf

→ [[Phase 6 - Maintenance]]

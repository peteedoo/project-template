---
tags: [network, google-fiber, deco]
---

# Google Fiber and Deco XE75

← [[Home]] · [[Topology Overview]]

Google Fiber is the **easy case** — no bridge mode. Bypass the Network Box; connect Mac Mini directly to the **Fiber Jack**.

---

## Your equipment (from photos)

| Device | What it is | What to do |
|--------|------------|------------|
| Small box, yellow Ethernet | **Fiber Jack** (ONT) | Keep powered → Mac Mini WAN |
| White box, GF logo, Wi-Fi LED | **Network Box** | **Unplug** — store for [[Backup and Rollback]] |
| Deco XE75 mesh | Wi-Fi | **AP mode** → Mac Mini LAN |

---

## Before / after

```
BEFORE:
  Fiber Jack ──yellow──► Network Box ──Wi-Fi/LAN──► devices

AFTER:
  Fiber Jack ──────────► Mac Mini WAN (USB Ethernet)
                              ↓
                         Mac Mini LAN ──► Switch ──► Deco XE75 (AP mode)
```

Full cutover → [[Phase 4 - Cutover]]

---

## Wiring steps

1. **Fiber Jack stays powered** (own adapter — do not unplug)
2. **Remove Network Box** from chain (Ethernet + power)
3. Fiber Jack Ethernet → USB adapter → Mac Mini **WAN**
4. Mac Mini built-in → switch → Deco main (+ wired satellites if possible)
5. Mac Mini WAN: **DHCP** (see [[Config Files#netplan]])
6. Deco: **Access Point** mode

---

## Google Fiber WAN settings

| Setting | Value |
|---------|-------|
| WAN mode | DHCP |
| VLAN | None (try first) |
| IPv6 | DHCPv6 optional |

No IP after 10 min? → [[Config Files#VLAN 2 fallback]] → then [[Backup and Rollback]]

[Google Fiber: use your own router](https://support.google.com/fiber/answer/2446100)

---

## Network Box — do not use it

No bridge mode. Using it with Mac Mini = double NAT.

---

## Deco XE75 — Access Point mode

1. Complete initial setup in Router mode (Deco app requirement)
2. **More → Advanced → Operation Mode → Access Point → Save → Reboot**
3. Applies to **all** Deco units automatically
4. Mac Mini (`192.168.10.1`) handles DHCP + NAT

[TP-Link AP mode FAQ](https://www.tp-link.com/us/support/faq/1842/)

### If rolled back to Network Box
Switch Deco back to **Router** mode → [[Backup and Rollback#If Wi-Fi does not come back]]

---

## Deco in AP mode

| Feature | Works? |
|---------|--------|
| Mesh / Wi-Fi 6E | ✅ |
| DHCP / NAT | Mac Mini handles |
| Wired backhaul via switch | ✅ recommended |
| HomeShield / parental controls | May be limited |

---

## LEDs

### Network Box (rollback)
| LED | Solid green = OK |
|-----|------------------|
| Power | On |
| Internet | Connected |
| Wi-Fi | Wi-Fi active |

### Fiber Jack
| Light | Meaning |
|-------|---------|
| Solid | Ready |
| Blinking | Booting — wait 2 min |
| Off | No power |

### Deco
| LED | Meaning |
|-----|---------|
| Green | Healthy |
| Red | No upstream |
| Pulsing blue | Setup mode |

---

## Checklist

- [ ] Fiber Jack powered
- [ ] Network Box removed from chain
- [ ] Fiber Jack → Mac Mini USB WAN
- [ ] Mac Mini LAN → switch → Deco
- [ ] Deco in AP mode
- [ ] `curl ifconfig.me` shows public IP from phone

---

## Related

- [[IP Address Plan]]
- [[Phase 4 - Cutover]]
- [[Triage - Internet Down]]
- [[Backup and Rollback]]

**GF support:** 1-866-777-7550

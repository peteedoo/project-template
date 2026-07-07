# Network topology for Mac Mini firewall

This guide covers the recommended home network layout when using a 2014 Mac Mini as your primary router and firewall.

## Recommended topology

Put the ISP modem in **bridge mode** (also called passthrough or IP passthrough). The Mac Mini becomes the only router on your network.

```mermaid
flowchart TB
    subgraph Internet
        ISP[ISP network]
    end

    subgraph Edge["Edge (your home)"]
        MODEM[ISP modem<br/>bridge mode]
        FW[Mac Mini firewall<br/>MiniFW + nftables]
        SW[Gigabit switch]
        AP[Wi-Fi access point<br/>AP mode only]
    end

    subgraph LAN["LAN 192.168.10.0/24"]
        PC[Laptops / desktops]
        NAS[NAS / file server]
        IOT[IoT devices<br/>optional VLAN later]
        PHONE[Phones / tablets]
    end

    ISP --> MODEM
    MODEM -->|WAN USB Ethernet| FW
    FW -->|LAN built-in Ethernet| SW
    SW --> AP
    SW --> PC
    SW --> NAS
    SW --> IOT
    AP --> PHONE
```

## Physical wiring

```
[ISP fibre/cable] → [ISP modem] → [USB Ethernet → Mac Mini WAN port]
                                         ↓
                              [Built-in Ethernet → Switch]
                                         ↓
                    ┌────────────────────┼────────────────────┐
                    ↓                    ↓                    ↓
              [Wi-Fi AP]            [Desktop]              [NAS]
              (AP mode)
```

### Port assignment

| Mac Mini port | Cable goes to | Role |
|---------------|---------------|------|
| USB Ethernet adapter | ISP modem LAN port | **WAN** — public internet |
| Built-in Ethernet | Gigabit switch | **LAN** — trusted home network |

> **Important:** Do not plug the ISP modem into the built-in port and the switch into USB. Either works technically, but USB-as-WAN is the usual convention and keeps the built-in port on the trusted LAN side.

## IP addressing

| Device | IP | Notes |
|--------|-----|-------|
| Mac Mini (LAN) | `192.168.10.1` | Gateway, DNS, DHCP server |
| DHCP pool | `192.168.10.100` – `192.168.10.250` | Managed by MiniFW/dnsmasq |
| Wi-Fi AP | `192.168.10.2` (static) | AP mode; no DHCP |
| Servers/NAS | `192.168.10.10` – `99` | Reserve low addresses |

Use a subnet other than `192.168.0.0/24` or `192.168.1.0/24` if your ISP modem (before bridging) used those — it avoids conflicts during setup.

## ISP modem: bridge mode

Bridge mode disables the modem's router/NAT/DHCP so the Mac Mini receives the public IP (or a DHCP lease directly from the ISP).

| Provider type | What to look for |
|---------------|------------------|
| Cable (DOCSIS) | "Bridge mode" in modem admin |
| Fibre (ONT) | Often already bridged; may need provider to enable |
| DSL | "Modem only" or bridge mode in router settings |

After bridging, only the Mac Mini WAN interface should request a DHCP address from the ISP (or use your static IP details from the ISP).

## Wi-Fi access point setup

Use a dedicated AP or a router flashed to AP mode. **Disable DHCP and NAT on the AP.**

1. Connect AP LAN port → switch (not the AP's "WAN" port unless docs say otherwise).
2. Set AP management IP to `192.168.10.2`.
3. Set gateway/DNS to `192.168.10.1` (the Mac Mini).
4. Use WPA3 or WPA2-AES. Separate guest SSID if the AP supports it.

## Traffic flow

```mermaid
sequenceDiagram
    participant PC as LAN device
    participant FW as Mac Mini
    participant ISP as Internet

    PC->>FW: Packet to 1.1.1.1 (destined for internet)
    FW->>FW: Forward chain: LAN → WAN allowed
    FW->>FW: NAT masquerade (source → WAN IP)
    FW->>ISP: Translated packet
    ISP->>FW: Return traffic (established)
    FW->>FW: conntrack: established,related
    FW->>PC: Forward to LAN host
```

Inbound connections from the internet are **blocked by default**. Open ports only via `allowed_wan_ports` or `port_forwards` in the config.

## Optional improvements

### 1. DNS ad-blocking

Add Pi-hole or AdGuard Home on the Mac Mini (Docker) or a LAN host, then point `dns_servers` in `firewall.yaml` to that host.

### 2. IoT isolation (VLAN)

The 2014 Mac Mini + managed switch can separate IoT traffic:

```mermaid
flowchart LR
    FW[Mac Mini] --> SW[Managed switch]
    SW --> TRUST[Trusted VLAN 10<br/>192.168.10.0/24]
    SW --> IOT_VLAN[IoT VLAN 20<br/>192.168.20.0/24]
```

Requires a managed switch with 802.1Q VLAN support. MiniFW does not configure VLANs yet; add `nftables` VLAN rules or use switch ACLs.

### 3. VPN for remote access

Run WireGuard on the Mac Mini instead of exposing services to the internet:

```
Internet → Mac Mini:51820/udp (WireGuard) → access LAN securely
```

Prefer VPN over port-forwarding for home automation, NAS, etc.

## What not to do

| Avoid | Why |
|-------|-----|
| Double NAT (modem routing + Mac Mini routing) | Breaks port forwarding, adds latency, complicates troubleshooting |
| Wi-Fi router in router mode behind the Mac Mini | Creates a second NAT'd network |
| Relying on Wi-Fi from the Mac Mini | No built-in Wi-Fi on most Mac Minis; use an AP |
| macOS as the router OS | Possible with `pf`, but Apple does not support it well; Linux is more reliable |

## macOS alternative (not recommended for 24/7 router)

If you must stay on macOS, enable IP forwarding and use `pf`, but you lose easy NAT/DHCP integration and macOS updates can reset settings. Ubuntu Server on the same hardware is the better path for a dedicated firewall.

## Setup checklist

- [ ] Install Ubuntu Server 24.04 on the Mac Mini
- [ ] Buy USB 3.0 Gigabit Ethernet adapter (~$15–25)
- [ ] Put ISP modem in bridge mode
- [ ] Cable WAN/LAN as shown above
- [ ] Run `scripts/detect-interfaces.sh` and update `firewall.yaml`
- [ ] Assign static IP `192.168.10.1/24` to the LAN interface (netplan)
- [ ] Run `minifw apply` and enable `nftables` + `dnsmasq`
- [ ] Configure Wi-Fi AP in AP mode
- [ ] Verify: `curl ifconfig.me` from a LAN device shows your public IP
- [ ] Verify: inbound ports are closed (use [canyouseeme.org](https://canyouseeme.org) sparingly)

## Fiber + TP-Link Deco XE75

This section covers the common case: **fiber internet** with an ISP ONT/gateway and a **Deco XE75** mesh system (2- or 3-pack).

### Topology

```mermaid
flowchart TB
    subgraph Internet
        ISP[Fiber ISP]
    end

    subgraph Edge
        ONT[Fiber ONT / ISP gateway<br/>bridge or passthrough]
        FW[Mac Mini firewall<br/>192.168.10.1]
        SW[Gigabit switch<br/>optional but recommended]
        MAIN[Deco XE75 main unit<br/>AP mode]
        SAT1[Deco satellite]
        SAT2[Deco satellite]
    end

    subgraph LAN["LAN 192.168.10.0/24"]
        DEV[Phones, laptops, TVs, IoT]
    end

    ISP --> ONT
    ONT -->|Ethernet → USB NIC| FW
    FW -->|built-in Ethernet| SW
    SW --> MAIN
    SW --> SAT1
    MAIN -.->|Wi-Fi 6E mesh| SAT1
    MAIN -.->|Wi-Fi 6E mesh| SAT2
    SAT1 -.-> SAT2
    MAIN --> DEV
    SAT1 --> DEV
    SAT2 --> DEV
```

### Physical wiring

```
[Fiber] → [ISP ONT or gateway] → [USB Ethernet → Mac Mini WAN]
                                        ↓
                           [Built-in Ethernet → Switch]
                                        ↓
              ┌─────────────────────────┼─────────────────────────┐
              ↓                         ↓                         ↓
      [Deco main XE75]          [Deco satellite]           [Desktop / NAS]
      (AP mode, wired)          (ethernet backhaul)         (optional)
```

**Recommended:** Use a **gigabit switch** on the Mac Mini LAN port. Plug the main Deco and any satellites that support wired backhaul into the switch. Wired backhaul in AP mode keeps mesh traffic off the main Deco and performs better than wireless-only backhaul.

### Fiber ONT / ISP gateway

Fiber setups vary by provider. The goal is the same: **only the Mac Mini should route and NAT**.

| ISP setup | What to do |
|-----------|------------|
| Standalone ONT with one Ethernet port | Plug that port straight into Mac Mini WAN. ONT is usually already a bridge. |
| ONT + separate ISP router (common) | Put the ISP router in **bridge**, **passthrough**, or **IP passthrough** mode so the Mac Mini gets the public IP. |
| ISP gateway with no bridge mode | Call ISP and ask for "bridge mode" or "public IP on my equipment." Some allow **DMZ** to the Mac Mini WAN IP as a fallback (not ideal, but works). |
| ISP gateway with VoIP / TV | Keep the gateway for phone/TV if required, but still bridge or passthrough data to the Mac Mini. Do **not** run the Deco in router mode behind the Mac Mini. |

After setup, `curl ifconfig.me` from a phone on Deco Wi-Fi should show your **public** IP, not `192.168.x.x`.

### Deco XE75: Access Point mode

Do **not** use the Deco as your router — the Mac Mini is the router. The XE75 becomes your Wi-Fi mesh only.

1. **Initial setup in Router mode** (Deco app requirement): plug main Deco into the switch, complete setup in the TP-Link Deco app.
2. **Switch to AP mode**: Deco app → **More** → **Advanced** → **Operation Mode** → **Access Point** → Save → Reboot.
3. One change applies to **all** Deco units in the mesh automatically.
4. After reboot, the Deco no longer runs DHCP or NAT. The Mac Mini (`192.168.10.1`) handles both.

Reference: [TP-Link Deco AP mode FAQ](https://www.tp-link.com/us/support/faq/1842/)

### IP addressing with Deco

| Device | IP | Notes |
|--------|-----|-------|
| Mac Mini (LAN) | `192.168.10.1` | Gateway, DHCP, DNS |
| Main Deco XE75 | `192.168.10.2` (reserve in dnsmasq) | Management UI via Deco app |
| Deco satellites | DHCP from Mac Mini | Assigned automatically |
| Phones / laptops | `192.168.10.100+` | DHCP pool from MiniFW |

If your fiber gateway previously used `192.168.68.x` (Deco's default subnet), switching to `192.168.10.0/24` on the Mac Mini avoids conflicts.

### Deco features in AP mode

| Feature | In AP mode |
|---------|------------|
| Mesh Wi-Fi / 6E band | Works |
| DHCP / NAT / firewall | Handled by Mac Mini |
| Deco parental controls / HomeShield | May be limited or disabled — use Mac Mini firewall rules instead |
| Wired ethernet backhaul | Works; recommended via switch |
| Multiple Decos wired to switch | Supported in AP mode (not in router mode) |

### Fiber + Deco checklist

- [ ] Confirm ONT/gateway is bridged or in passthrough
- [ ] Mac Mini WAN (USB Ethernet) ← ONT/gateway Ethernet
- [ ] Mac Mini LAN (built-in) → gigabit switch
- [ ] Main Deco XE75 → switch (not the ISP gateway)
- [ ] Complete Deco setup, then switch to **Access Point** mode
- [ ] Wire satellite Decos to switch if possible (ethernet backhaul)
- [ ] Run `minifw apply` on the Mac Mini
- [ ] Verify public IP from a Wi-Fi client: `curl ifconfig.me`
- [ ] Disable Wi-Fi on the ISP gateway (if it still routes) to avoid a second network

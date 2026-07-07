# MiniFW — Mac Mini Home Firewall

A lightweight firewall manager for turning a **2014 Mac Mini** (16 GB RAM, 256 GB drive) into a home router and firewall running **Ubuntu Server** or **Debian**.

MiniFW generates `nftables` rules, DHCP/DNS config (`dnsmasq`), and kernel hardening (`sysctl`) from a single YAML file.

## Why this setup?

| Component | Recommendation |
|-----------|----------------|
| OS | Ubuntu Server 24.04 LTS or Debian 12 |
| WAN NIC | USB 3.0 Gigabit Ethernet adapter |
| LAN NIC | Built-in Gigabit Ethernet port |
| Wi-Fi | Separate access point in **AP mode** (not router mode) |
| ISP modem | **Bridge / passthrough mode** so the Mac Mini gets the public IP |

A 2014 Mac Mini has only one built-in Ethernet port. You need a second NIC (USB adapter) to separate WAN from LAN. With 16 GB RAM it is overpowered for routing; 256 GB HDD is fine but use log rotation and avoid heavy disk writes.

## Documentation

### Obsidian vault (recommended)

Open **`obsidian/`** as an Obsidian vault. Start at **[[Home]]** — the master build guide links every phase, rollback step, and reference note.

### Plain markdown

| Doc | When to use |
|-----|-------------|
| **[obsidian/Home.md](obsidian/Home.md)** | **Master build guide** (linked) |
| [docs/USB-SETUP.md](docs/USB-SETUP.md) | Create the plug-in setup USB |
| [docs/SETUP-PLAN.md](docs/SETUP-PLAN.md) | Full setup (plain markdown) |
| [docs/BACKUP-AND-ROLLBACK.md](docs/BACKUP-AND-ROLLBACK.md) | Restore Network Box in 5 min |
| [docs/TRIAGE.md](docs/TRIAGE.md) | Offline troubleshooting |
| [docs/NETWORK.md](docs/NETWORK.md) | Topology reference |

**Fastest path:** build the setup USB on your laptop, install Ubuntu on the Mac Mini, plug in the USB, run `sudo ./setup.sh`.

**Before cutover:** save `TRIAGE.md` and `BACKUP-AND-ROLLBACK.md` to your phone.

## Quick start

```bash
# On the Mac Mini (after installing Ubuntu Server)
git clone <this-repo>
cd mac-mini-firewall
sudo bash scripts/install.sh
sudo bash scripts/detect-interfaces.sh   # note WAN/LAN interface names
sudo nano /etc/minifw/firewall.yaml      # set interface names + LAN subnet
sudo minifw apply
sudo systemctl enable --now nftables dnsmasq
```

## Commands

```bash
minifw init [--wan eth1] [--lan eth0]   # create starter config
minifw show                               # print active config
minifw render                             # preview nftables rules
minifw apply                              # write configs and reload
minifw status                             # interfaces + active rules
minifw block 203.0.113.50                 # block an IP
minifw allow-wan tcp 443 --source 203.0.113.0/24
```

## Network layout

See [docs/NETWORK.md](docs/NETWORK.md) for the full topology diagram, physical wiring, and ISP modem settings.

## Structure

```
mac-mini-firewall/
├── obsidian/            # Obsidian vault — start at Home.md
│   ├── Home.md          # Master build guide (MOC)
│   ├── Build/           # Phases 0–6
│   ├── Network/
│   ├── Operations/
│   └── Reference/
├── src/minifw/          # Python CLI and rule generator
├── config/              # firewall.yaml, netplan examples
├── scripts/             # install, preflight, rollback, build-setup-usb
└── docs/                # Plain markdown copies
```

## Security defaults

- Default **drop** policy on input and forward
- NAT/masquerade from LAN to WAN
- SSH and DNS only from the management LAN subnet
- IP forwarding enabled, redirects disabled
- ICMP echo allowed on WAN (disable with `allow_icmp: false`)

## Status

- Created: 2026-07-07
- Target hardware: 2014 Mac Mini, 16 GB RAM, 256 GB HDD

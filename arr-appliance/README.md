# *arr Appliance (Sacrificial Mac Mini)

Offload Prowlarr, Sonarr, Radarr, Bazarr, and qBittorrent from your main Mac onto the pawn-shop 2014 Mac Mini. **All media, downloads, and app config live on NAS.** The Mini's 256 GB disk is sacrificial — if it drifts full, the stack stops itself instead of eating your main Mac.

## Architecture

Full hardware map: `docs/HARDWARE.md`

| Machine | Role |
|---------|------|
| **2014 Mac Mini** (pawn-shop) | *arr stack in Docker; optional Tailscale |
| **Main Mac** (`main-mini`) | Jellyfin, agents, work — no *arr after cutover |
| **NAS1** (primary NAS, `192.168.1.50`) | `homelab` share — media, downloads, appdata |
| **Le Potato** (`192.168.1.52`) | AdGuard DNS — do not move *arr here |

Built-in Ethernet on the 2014 Mini is often dead. Use **Wi-Fi for initial setup** and a **USB Gigabit adapter** for stable wired LAN afterward.

## Quick start (Ubuntu Server already installed)

On the pawn-shop Mac Mini:

```bash
curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance/scripts/install-arr-appliance.sh | bash
```

Then mount NAS (see `config/fstab.example`), verify, and start:

```bash
sudo /opt/arr-appliance/scripts/check-nas.sh
sudo systemctl enable --now arr-appliance
```

## Web UIs

Replace `<mini-ip>` with the Mac Mini's LAN address (`ip -4 addr`).

| Service | URL |
|---------|-----|
| Prowlarr | http://\<mini-ip\>:9696 |
| Sonarr | http://\<mini-ip\>:8989 |
| Radarr | http://\<mini-ip\>:7878 |
| Bazarr | http://\<mini-ip\>:6767 |
| qBittorrent | http://\<mini-ip\>:8080 |

Default qBittorrent login is often `admin` / `adminadmin` — change it immediately.

## NAS mounts

1. Copy and edit `config/fstab.example` for SMB or NFS.
2. For SMB, create `/etc/nas-credentials`:
   ```
   username=your_nas_user
   password=your_nas_pass
   ```
   `chmod 600 /etc/nas-credentials`
3. Add mount lines to `/etc/fstab`.
4. `sudo mkdir -p /mnt/nas/{media,downloads,appdata}`
5. `sudo mount -a`
6. `sudo /opt/arr-appliance/scripts/check-nas.sh`

Inside each *arr app, point paths at **container paths** (`/tv`, `/movies`, `/downloads`) — they map to NAS via `docker-compose.yml`.

## USB Ethernet

Install drops `/etc/netplan/60-arr-usb-ethernet.yaml` from `config/netplan-usb-ethernet.yaml.example`. Plug the adapter, then:

```bash
sudo netplan apply
ip -br link
```

## Disk guard

`guard-disk.sh` runs every 5 minutes. If root (`/`) passes `LOCAL_DISK_MAX_PCT` (default 85%), Docker Compose stops and prunes dangling images. Adjust in `/opt/arr-appliance/.env`.

## Manual control

```bash
sudo /opt/arr-appliance/scripts/arr-up.sh    # start (checks NAS first)
sudo /opt/arr-appliance/scripts/arr-down.sh  # stop
docker compose -f /opt/arr-appliance/docker-compose.yml ps
```

## Migrate from main Mac

1. Export or copy existing `*arr` config from the main Mac into NAS `appdata/` folders (or start fresh).
2. Point Sonarr/Radarr root folders and qBittorrent save path at NAS only.
3. Remove or disable *arr on the main Mac so drift cannot return there.

## Migrate from main-mini

See `docs/MIGRATE.md`, `docs/HARDWARE.md`, `docs/SYNOLOGY-DS223J.md`, and **`docs/ROADMAP.md`** for the full forward plan.

## Files

```
arr-appliance/
├── docker-compose.yml
├── .env.example
├── config/
│   ├── fstab.example
│   ├── netplan-usb-ethernet.yaml.example
│   └── *.service / *.timer
├── scripts/
│   ├── install-arr-appliance.sh
│   ├── check-nas.sh
│   ├── guard-disk.sh
│   ├── arr-up.sh
│   └── arr-down.sh
└── docs/
    ├── HARDWARE.md
    ├── MORNING-CHECKLIST.md
    └── MIGRATE.md
```

## Firewall pivot

This repo also contains `mac-mini-firewall/` (MiniFW). That path needs two working Ethernet ports; this Mini's built-in port appears dead. **Use this *arr appliance instead** unless you add a second USB Ethernet adapter later for WAN/LAN firewall duty.

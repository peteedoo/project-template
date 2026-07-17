# Migrate *arr from main-mini to pawn-shop Mac Mini

Your live stack today (from your internal inventory notes and `iamfaulty-homelab`):

| What | Where today | Where after migration |
|------|-------------|----------------------|
| NAS | NAS1 `192.168.1.50`, share `homelab` | Same — pawn-shop Mini mounts `/mnt/nas` |
| Media | `/Volumes/homelab/media/Movies`, `Shows` | `/mnt/nas/media/Movies`, `Shows` |
| *arr config | `~/homelab-data/arr/` on main Mac SSD | `/mnt/nas/personal/arr-appliance/` on NAS |
| Downloads | main Mac local SSD (disk drift) | `/mnt/nas/media/downloads` on NAS |
| Jellyfin, NPM, etc. | Stay on main Mac | Unchanged |

## 1. Mount NAS on pawn-shop Mini

Use `config/fstab.iamfaulty.example` and `config/env.iamfaulty.example`.

```bash
sudo /opt/arr-appliance/scripts/check-nas.sh
```

## 2. Copy existing configs from main Mac to NAS

On **main-mini**, with NAS mounted:

```bash
rsync -av ~/homelab-data/arr/prowlarr/   /Volumes/homelab/personal/arr-appliance/prowlarr/
rsync -av ~/homelab-data/arr/sonarr/     /Volumes/homelab/personal/arr-appliance/sonarr/
rsync -av ~/homelab-data/arr/radarr/     /Volumes/homelab/personal/arr-appliance/radarr/
rsync -av ~/homelab-data/arr/qbittorrent/ /Volumes/homelab/personal/arr-appliance/qbittorrent/
# bazarr if you add it fresh or copy from main Mac if present
```

Paths may also live under `~/homelab-data/arr-stack/` — check which directory your compose file uses.

## 3. Start stack on pawn-shop Mini

```bash
sudo cp /opt/arr-appliance/config/env.iamfaulty.example /opt/arr-appliance/.env
sudo systemctl enable --now arr-appliance
```

## 4. Stop *arr on main Mac (stop the drift)

```bash
docker compose -f ~/homelab-data/arr-stack/docker-compose.yml down
# or whichever compose path you use
```

Keep Jellyfin on main Mac — it already reads `/Volumes/homelab/media`.

## 5. VPN note (Gluetun)

Your main Mac stack routes qBittorrent through **Gluetun** (VPN kill switch). The pawn-shop `arr-appliance` compose does **not** include Gluetun yet. Options:

- Add Gluetun to pawn-shop stack before cutover (recommended if you rely on VPN)
- Run qBit without VPN temporarily on the sacrificial Mini
- Keep qBit on main Mac only (defeats the drift goal)

## 6. Update internal URLs (if needed)

Inside Sonarr/Radarr, download client should be `http://qbittorrent:8080` (Docker network name). Prowlarr sync URLs use container hostnames (`http://sonarr:8989`, etc.) — same as a normal Docker arr stack.

## 7. Public subdomains

`sonarr.iamfaulty.com`, `radarr.iamfaulty.com`, etc. currently point at main Mac via Caddy/NPM. After cutover, repoint proxy targets to the **pawn-shop Mini's LAN IP** (or add Tailscale).

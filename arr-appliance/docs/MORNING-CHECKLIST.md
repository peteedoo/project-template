# Morning checklist — *arr Mac Mini

One page. Do these in order on the **pawn-shop Ubuntu Mac Mini**.

## Before you start

- [ ] Mac Mini is on and logged in (SSH or keyboard)
- [ ] NAS is powered on and reachable from your LAN
- [ ] USB Gigabit Ethernet adapter plugged in (optional but preferred after setup)

## 1. Network

```bash
ip -br link
ip -4 route
```

- Wi-Fi should show `UP` during setup
- USB adapter often appears as `enx...` or `eth1` after `sudo netplan apply`

Get the Mini's IP for browser access:

```bash
hostname -I
```

## 2. Install (first time only)

```bash
curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance/scripts/install-arr-appliance.sh | bash
```

## 3. Mount NAS

**Home lab NAS (NAS1)?** Use `config/fstab.iamfaulty.example` — see also `docs/HARDWARE.md`.

**2-bay NAS (generic)?** Use `config/fstab.smb-nfs.example`.

Edit fstab from the example:

```bash
sudo nano /opt/arr-appliance/config/fstab.example   # get your lines
sudo nano /etc/fstab                                 # paste adapted lines
```

SMB credentials file (if needed):

```bash
sudo nano /etc/nas-credentials
sudo chmod 600 /etc/nas-credentials
```

Mount and verify:

```bash
sudo mkdir -p /mnt/nas/{media,downloads,appdata}
sudo mount -a
sudo /opt/arr-appliance/scripts/check-nas.sh
```

All three paths should show **OK**.

## 4. Start the stack

```bash
sudo systemctl enable --now arr-appliance
sudo systemctl status arr-appliance
docker ps
```

## 5. Open UIs (from laptop/browser)

| App | URL |
|-----|-----|
| Prowlarr | http://\<mini-ip\>:9696 |
| Sonarr | http://\<mini-ip\>:8989 |
| Radarr | http://\<mini-ip\>:7878 |
| Bazarr | http://\<mini-ip\>:6767 |
| qBittorrent | http://\<mini-ip\>:8080 |

## 6. Point everything at NAS (inside each app)

| App | Setting |
|-----|---------|
| qBittorrent | Default save path → `/downloads` |
| Sonarr | Root folder → `/tv` (maps to `NAS_TV`, e.g. `Shows`) |
| Radarr | Root folder → `/movies` (maps to `NAS_MOVIES`, e.g. `Movies`) |
| Prowlarr | Indexer manager only — no local storage |
| Bazarr | Uses `/tv` and `/movies` |

Link apps together (localhost URLs work inside Docker network):

- Sonarr/Radarr → Prowlarr: `http://prowlarr:9696`
- Bazarr → Sonarr: `http://sonarr:8989`, Radarr: `http://radarr:7878`
- *arr → qBittorrent: `http://qbittorrent:8080`

## 7. Retire *arr on main Mac

- [ ] Stop/remove Docker *arr containers on **main-mini** (your main Mac)
- [ ] Confirm new grabs land on NAS under `/mnt/nas/downloads`
- [ ] Plex on main Mac can keep reading media from NAS — no *arr needed there

## If local disk fills

The disk guard stops containers automatically. Free space, then:

```bash
df -h /
sudo /opt/arr-appliance/scripts/arr-up.sh
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No internet during install | Use Wi-Fi; check `ip route get 1.1.1.1` |
| `check-nas.sh` fails | `mount -a`, credentials, NAS IP |
| UI won't load | `docker ps`, firewall on NAS, wrong IP |
| Built-in Ethernet dead | Expected — use USB adapter or Wi-Fi |

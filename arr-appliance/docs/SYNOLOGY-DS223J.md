# Synology DS223J — setup for iamfaulty homelab

Entry-level **2-bay** Synology. Good as a **backup / secondary** NAS alongside **ILLMATIC** (UGREEN DH2300).

| | ILLMATIC (UGREEN) | DS223J (Synology) |
|--|-------------------|-------------------|
| **Best role** | Primary — media, downloads, *arr appdata | Backup — Duplicati, Hyper Backup, snapshots |
| **RAM** | 4 GB | 1 GB (not upgradable) |
| **Docker on NAS** | No (DH2300) | **No** — ARM, no Container Manager |
| **Network** | 1 GbE | 1 GbE |
| **Your data today** | ~3.9 TB used / 11 TB | New — size depends on drives |

**Recommendation:** Do **not** move the live *arr library to the DS223J yet. Keep hot paths on ILLMATIC. Use Synology for **3-2-1 backups** and optional cold copies.

---

## 1. Physical + DSM first boot

1. Install **2 drives** (3.5" HDD or 2.5" with Synology caddy).
2. **RAID choice:**
   - **SHR-1** or **RAID 1** (mirror) — safest for 2 bays; you lose half capacity.
   - **SHR** — Synology hybrid; flexible if you mix drive sizes.
   - Avoid RAID 0 — one disk death kills the volume.
3. Boot, open **find.synology.com** or Synology Assistant, install **DSM 7.2+**.
4. Create **admin** password; enable **2FA** later.
5. **Control Panel → Network → Network Interface** → set **static IP** (e.g. `192.168.68.70`) or DHCP reservation on Deco.

Pick a hostname, e.g. **`SYNO223J`** or **`faulty-backup`**.

---

## 2. Shared folders (suggested layout)

**Control Panel → Shared Folder → Create**

| Folder | Purpose |
|--------|---------|
| `backup` | Duplicati / restic / rsync targets from M4 and pawn-shop Mini |
| `homelab-mirror` | Optional scheduled copy of critical ILLMATIC paths |
| `photos` | Optional — phone/camera offload |
| `timemachine` | Optional — Mac Time Machine (enable in DSM) |

Enable **Recycle Bin** on `backup` for oops protection.

**Permissions:** Create user `peteedoo` (match homelab naming) with read/write on backup folders only.

---

## 3. Enable file services

**Control Panel → File Services → SMB**

- Enable SMB
- Min protocol: **SMB2** (disable SMB1)
- Max protocol: **SMB3**
- Optional: enable **NFS** if you prefer Linux NFS mounts (Synology NFS is fine on Ubuntu)

**Control Panel → File Services → rsync** — enable if you want `rsync` pull jobs from ILLMATIC or M4.

---

## 4. Mount from Mac (iamfaulty-mini)

Finder → **Connect to Server** (`Cmd+K`):

```
smb://192.168.68.70/backup
```

Or auto-mount at login:

```bash
# Test
osascript -e 'mount volume "smb://peteedoo:PASSWORD@192.168.68.70/backup"'
```

Add to login workflow or document in `~/iamfaulty-homelab/ops/STARTUP.md` if you want it always mounted (optional — backups can run on schedule without permanent mount).

---

## 5. Mount from pawn-shop Ubuntu Mini

```bash
sudo nano /etc/nas-credentials-synology
```

```
username=peteedoo
password=YOUR_SYNOLOGY_PASSWORD
```

```bash
sudo chmod 600 /etc/nas-credentials-synology
sudo mkdir -p /mnt/synology
sudo mount -t cifs -o credentials=/etc/nas-credentials-synology,uid=1000,gid=1000,vers=3.0 //192.168.68.70/backup /mnt/synology
```

Add to `/etc/fstab` — see `config/fstab.synology-ds223j.example`.

**Note:** *arr stack should still use **ILLMATIC** (`/mnt/nas`) for active media. Synology mount is for backups, not daily Sonarr/Radarr paths.

---

## 6. Hook into existing homelab backups

You already run **Duplicati** (`/Volumes/homelab/compose/duplicati/`).

Point a Duplicati job at the Synology share:

| Source | Destination on DS223J |
|--------|------------------------|
| `~/homelab-data/arr/` (before cutover) | `smb://…/backup/arr-config` |
| `/Volumes/homelab/personal/` | `backup/homelab-personal` |
| M4 Time Machine (optional) | Shared folder `timemachine` |

**Hyper Backup** (Synology app): can backup Synology → USB, or another NAS, or cloud (Backblaze B2 you already use).

---

## 7. Optional — mirror critical data from ILLMATIC

On **M4** or **pawn-shop Mini**, nightly `rsync` (not live *arr paths):

```bash
rsync -av --delete \
  /Volumes/homelab/personal/arr-appliance/ \
  /Volumes/backup/homelab-mirror/arr-appliance/
```

Or Synology **Shared Folder Sync** / **Snapshot Replication** if you add a second Synology later (DS223J only supports 2 sync tasks).

---

## 8. What not to put on DS223J

| Avoid | Why |
|-------|-----|
| Primary Jellyfin library | ILLMATIC has capacity; DS223J is 2-bay / 1 GB |
| Active qBittorrent downloads | Disk + LAN churn; keep on ILLMATIC |
| Docker *arr stack on NAS | No Container Manager on DS223J |
| Replacing ILLMATIC without migration plan | 3.9 TB used — need drives + copy window |

---

## 9. Reserve IP in Deco

In TP-Link Deco app: reserve **`192.168.68.70`** (example) for the Synology MAC address so SMB paths stay stable.

Update `docs/HARDWARE.md` with the final IP once assigned.

---

## 10. Checklist

- [ ] DSM installed, RAID/SHR configured
- [ ] Static IP or DHCP reservation
- [ ] Shared folder `backup` created
- [ ] User `peteedoo` with least-privilege access
- [ ] SMB tested from M4
- [ ] Duplicati job → Synology
- [ ] HARDWARE.md updated with hostname + IP
- [ ] ILLMATIC remains primary for *arr (`/mnt/nas`)

---

## Related

- `config/fstab.synology-ds223j.example` — Linux fstab line
- `docs/HARDWARE.md` — fleet map
- `iamfaulty-homelab` — Duplicati compose on ILLMATIC

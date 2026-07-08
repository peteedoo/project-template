# Synology DS223J — setup for iamfaulty homelab

Entry-level **2-bay** Synology. Good as a **backup / off-site copy** alongside **ILLMATIC** (UGREEN DH2300 at home).

| | ILLMATIC (UGREEN) | DS223J (Synology) |
|--|-------------------|-------------------|
| **Best role** | Primary — media, downloads, *arr appdata | Backup — Duplicati, Hyper Backup, snapshots |
| **Network** | Home LAN (`192.168.68.69`) | **Internet-connected** (not on home LAN) — use **Tailscale** |
| **RAM** | 4 GB | 1 GB (not upgradable) |
| **Docker on NAS** | No (DH2300) | **No** — ARM, no Container Manager |
| **Your data today** | ~3.9 TB used / 11 TB | Fresh — size depends on drives |

**Recommendation:** Keep live *arr on ILLMATIC. Push **backups** to the Synology over **Tailscale** (or SFTP/rsync on the tailnet). Do **not** expose SMB to the public internet.

---

## Fresh box + internet only (start here)

If the DS223J is **new** and only reachable **over the internet** (different site, or not on your `192.168.68.x` LAN yet):

### Hour 1 — DSM without opening dangerous ports

1. Plug in drives + Ethernet (or Wi-Fi USB if you use it — wired preferred).
2. On a laptop, go to **https://find.synology.com** or install **Synology Assistant** — discovers the NAS on its local network first; if you're remote, use whatever link/setup flow Synology gave you for initial admin.
3. Install **DSM 7.2+**, set a **strong admin password**.
4. **Control Panel → Security → Account** → enable **2FA** on admin.
5. **Control Panel → Security → Firewall** → enable; allow only what you need later (Tailscale interface).
6. **Do not** forward these on your router to the open internet:
   - SMB `445`
   - NFS `2049`
   - DSM `5000/5001` (unless you know exactly what you're doing — prefer Tailscale instead)

### Hour 2 — join your homelab mesh (Tailscale)

You already use Tailscale on **iamfaulty-mini** and the Pi fleet. This is the right way to reach an internet-connected Synology.

1. **Package Center** on DSM → search **Tailscale** → Install (available on many ARM Synology models including DS223j — if missing, use Synology's OpenVPN or WireGuard package toward your Pi 5 instead).
2. Open **Tailscale** → log in with the **same tailnet** as home.
3. Note the Synology **Tailscale IP** (e.g. `100.x.y.z`) in DSM or the Tailscale admin console.
4. From **iamfaulty-mini**:
   ```bash
   tailscale ping 100.x.y.z
   ```
5. Open DSM securely: `https://100.x.y.z:5001` (accept Synology cert warning on first visit).

**Optional:** Synology **QuickConnect** — fine for occasional browser access; prefer Tailscale for automated backups and SMB.

### Hour 3 — shared folders + backup user

**Control Panel → Shared Folder → Create**

| Folder | Purpose |
|--------|---------|
| `backup` | Duplicati / rsync targets from home homelab |
| `homelab-mirror` | Optional copy of critical ILLMATIC paths |

Create user **`peteedoo`** — write access to `backup` only (not full admin).

**Control Panel → File Services → SMB** — enable SMB2/3 for mounts **over Tailscale only**.

**Control Panel → Terminal & SNMP → Terminal** — enable SSH if you want `rsync`/`sftp` backups (recommended for internet paths).

---

## How home reaches Synology (internet path)

```
ILLMATIC / M4 / pawn-shop Mini  ──Tailscale──►  DS223J (100.x.y.z)
                                              └── /backup
```

| Method | Use when | Notes |
|--------|----------|-------|
| **Tailscale + SMB** | Duplicati, Finder mounts | `//100.x.y.z/backup` |
| **Tailscale + SSH/rsync** | Large scheduled mirrors | Safer feel than SMB over WAN |
| **Hyper Backup** | Synology-native jobs | Can target cloud too |
| **QuickConnect** | Emergency DSM UI | Not ideal for bulk backup |
| **Port-forward SMB** | **Never** | Ransomware magnet |

---

## Mount from Mac (over Tailscale)

Replace `100.x.y.z` with the Synology Tailscale IP:

```
smb://100.x.y.z/backup
```

```bash
osascript -e 'mount volume "smb://peteedoo:PASSWORD@100.x.y.z/backup"'
```

No LAN IP required. Update `docs/HARDWARE.md` with Tailscale hostname/IP once assigned.

---

## Mount from pawn-shop Ubuntu (over Tailscale)

Install Tailscale on the pawn-shop Mini first (`curl -fsSL https://tailscale.com/install.sh | sh`).

```bash
sudo nano /etc/nas-credentials-synology
# username=peteedoo
# password=...

sudo mkdir -p /mnt/synology
sudo mount -t cifs -o credentials=/etc/nas-credentials-synology,uid=1000,gid=1000,vers=3.0 //100.x.y.z/backup /mnt/synology
```

See `config/fstab.synology-ds223j.example` — use **Tailscale IP**, not `192.168.68.x`.

**\*arr stays on ILLMATIC** (`/mnt/nas`). Synology is backup destination only.

---

## Duplicati over internet (recommended pattern)

On **iamfaulty-mini**, Duplicati job destination options:

| Backend | Target |
|---------|--------|
| **SFTP** | `sftp://100.x.y.z/backup/...` (SSH enabled on DSM) |
| **SMB** | `//100.x.y.z/backup` via Tailscale |
| **Backblaze B2** | Keep as tertiary copy (you already use B2) |

Example sources to push off-site:

| Source | Destination on DS223J |
|--------|------------------------|
| `~/homelab-data/arr/` | `backup/arr-config` |
| `/Volumes/homelab/personal/` | `backup/homelab-personal` |

Schedule overnight — 1 GbE upload at the Synology's site is usually the bottleneck.

---

## If the Synology is at home later

You can **also** use a LAN IP (e.g. `192.168.68.70`) for faster local backups when on the same network. Tailscale still works from anywhere. Document both in HARDWARE.md if you end up dual-homed.

---

## Physical + DSM (local setup reference)

1. Install **2 drives** → **SHR-1** or **RAID 1** (mirror).
2. Hostname e.g. **`faulty-backup`** or **`syno223j`**.
3. Enable **Recycle Bin** on `backup`.

---

## What not to put on DS223J

| Avoid | Why |
|-------|-----|
| Primary Jellyfin / *arr library | ILLMATIC has capacity; DS223J is 2-bay / 1 GB |
| Active qBittorrent downloads | Keep on ILLMATIC / pawn-shop Mini |
| Docker *arr on NAS | No Container Manager on DS223j |
| SMB exposed to public internet | Use Tailscale |

---

## Checklist (internet-connected)

- [ ] DSM installed, RAID/SHR configured, 2FA on admin
- [ ] **Tailscale** installed on DSM, same tailnet as home
- [ ] Tailscale IP recorded in `docs/HARDWARE.md`
- [ ] Shared folder `backup` + user `peteedoo`
- [ ] `tailscale ping` works from iamfaulty-mini
- [ ] Test SMB or SFTP to `100.x.y.z`
- [ ] Duplicati job → Synology over Tailscale
- [ ] **No** router port-forward for 445 / 5000 / 5001
- [ ] ILLMATIC remains primary for live *arr

---

## Related

- `config/fstab.synology-ds223j.example` — Linux fstab (use Tailscale IP)
- `docs/HARDWARE.md` — fleet map
- `iamfaulty-homelab/ops/DNS.md` — house DNS (Le Potato) — separate from NAS reachability

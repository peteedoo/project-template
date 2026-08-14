# AGENTS.md

## Cursor Cloud specific instructions

This repo is a template scaffold at the root plus **two** products:

1. **MiniFW** (`mac-mini-firewall/`) — a Python CLI (`minifw`) that generates
   `nftables` / `dnsmasq` / `sysctl` config from a single YAML file. Pure config
   generator; no long-running service of its own.
2. **arr-appliance** (`arr-appliance/`) — the "active plan" per
   `arr-appliance/docs/NOTE-dual-projects.md`. It is a **Docker Compose** stack of
   off-the-shelf `linuxserver.io` images (Prowlarr, Sonarr, Radarr, Bazarr,
   qBittorrent). There is no custom source code here — only `docker-compose.yml`,
   `.env`, and provisioning scripts. The "application" is the running container stack
   with web UIs.

## MiniFW (`mac-mini-firewall/`)

### Environment

- A Python virtualenv is created at `/workspace/.venv` by the startup update
  script (which installs the `minifw` package editable + `pytest`). Use it
  directly, e.g. `/workspace/.venv/bin/python`, `/workspace/.venv/bin/pytest`,
  or `source /workspace/.venv/bin/activate` then `minifw ...`.
- `.venv/` is gitignored.

### Test / build / run

- Tests: `cd mac-mini-firewall && /workspace/.venv/bin/python -m pytest`
  (pytest config lives in `mac-mini-firewall/pyproject.toml`).
- Lint: no linter is configured for this project; `python -m compileall src tests`
  is a reasonable syntax sanity check.
- Run the CLI (needs a config path via `--config`; the default
  `/etc/minifw/firewall.yaml` won't exist here):
  - `minifw --config <path> init` — create a starter config
  - `minifw --config <path> show` — print config
  - `minifw --config <path> render` — print the generated nftables ruleset (pure, no root)

### Non-obvious caveats

- `render`, `show`, and `init` are pure and need no root or system daemons.
- `apply`, `status`, `block`, and `allow-wan` shell out to `nft` / `sysctl` /
  `systemctl` (and `block`/`allow-wan` call `apply` internally). Those tools are
  **not installed** in this dev VM and only make sense on the real Mac Mini
  router hardware — don't expect them to work here.
- The `scripts/*.sh` files (`install.sh`, `setup.sh`, etc.) provision the physical
  firewall appliance (they `apt-get install` and need root); they are **not** for
  setting up this dev environment.

## arr-appliance (`arr-appliance/`)

Docker Compose stack; see `arr-appliance/README.md` for the full port/service list
and intended NAS-backed production setup. Notes below cover only running it in the
dev VM (which has **no NAS**).

### Docker in this VM

- Docker + the compose plugin are installed, but the daemon does **not** auto-start.
  Start it once per session, e.g. in a tmux/background shell: `sudo dockerd`.
- This is docker-in-docker on a restricted kernel. The daemon is configured in
  `/etc/docker/daemon.json` to use the `fuse-overlayfs` storage driver **with the
  containerd snapshotter disabled** (required for fuse-overlayfs on Docker 29+), and
  `iptables` is switched to `iptables-legacy`. If Docker ever isn't present on a
  fresh VM, reinstall `docker-ce docker-ce-cli containerd.io docker-compose-plugin
  fuse-overlayfs iptables`, re-apply that `daemon.json`, and
  `update-alternatives --set iptables /usr/sbin/iptables-legacy`.

### Run the stack (dev)

- The compose file references NAS paths via env vars (`NAS_APPDATA`,
  `NAS_DOWNLOADS`, `NAS_MEDIA`, …). In the dev VM point them at local disk with a
  **gitignored** `arr-appliance/.env`. If it's missing, recreate it:
  - `sudo mkdir -p /srv/arr-dev/{appdata/{prowlarr,sonarr,radarr,bazarr,qbittorrent},downloads,media/tv,media/movies}`
  - write `arr-appliance/.env` with `PUID=0`, `PGID=0`, `NAS_ROOT=/srv/arr-dev`,
    `NAS_APPDATA=/srv/arr-dev/appdata`, `NAS_DOWNLOADS=/srv/arr-dev/downloads`,
    `NAS_MEDIA=/srv/arr-dev/media`.
- Start / stop / status directly with compose (run from `arr-appliance/`):
  - `sudo docker compose up -d`
  - `sudo docker compose ps`
  - `sudo docker compose down`
- Do **not** use `scripts/arr-up.sh` / `check-nas.sh` in the dev VM: they hard-fail
  because they require `NAS_ROOT` to be a real `mountpoint`, which local dirs are not.
  Those scripts (and `install-arr-appliance.sh`, `guard-disk.sh`) are for the
  physical appliance only.
- Web UIs bind to `localhost` on the ports in the README (Prowlarr 9696, Sonarr 8989,
  Radarr 7878, Bazarr 6767, qBittorrent 8080). The *arr apps force a first-run
  auth setup (create a username/password); qBittorrent logs a temporary admin
  password on first start (`sudo docker compose logs qbittorrent`).

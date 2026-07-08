#!/usr/bin/env bash
# One-shot install for the pawn-shop Mac Mini *arr appliance.
#
# Run on Ubuntu Server (Wi-Fi or USB Ethernet for internet):
#   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance/scripts/install-arr-appliance.sh | bash
#
# Or from a clone/USB copy:
#   cd arr-appliance && sudo ./scripts/install-arr-appliance.sh
set -euo pipefail

INSTALL_DIR="/opt/arr-appliance"
REPO_RAW="https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/arr-appliance"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

SOURCE_DIR=""
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../docker-compose.yml" ]]; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  *arr appliance — sacrificial Mac Mini, NAS-backed       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo

echo "==> [1/7] Checking internet route..."
if ! ip route get 1.1.1.1 >/dev/null 2>&1; then
  echo "No route to the internet yet."
  echo "  • Wi-Fi should work for setup"
  echo "  • Plug in the USB Ethernet adapter for wired LAN"
  echo "Then re-run this script."
  exit 1
fi

echo "==> [2/7] Installing Docker..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl cifs-utils nfs-common jq

if ! command -v docker >/dev/null 2>&1; then
  apt-get install -y -qq docker.io docker-compose-v2
fi
systemctl enable --now docker

echo "==> [3/7] Installing files to ${INSTALL_DIR}..."
install -d "${INSTALL_DIR}"/{scripts,config,docs}
install -d /mnt/nas/{media,downloads,appdata}

copy_file() {
  local rel="$1"
  if [[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/${rel}" ]]; then
    install -m 0644 "${SOURCE_DIR}/${rel}" "${INSTALL_DIR}/${rel}"
  else
    curl -fsSL "${REPO_RAW}/${rel}" -o "${INSTALL_DIR}/${rel}"
  fi
}

for f in docker-compose.yml .env.example; do
  copy_file "${f}"
done

for f in check-nas.sh guard-disk.sh arr-up.sh arr-down.sh; do
  if [[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/scripts/${f}" ]]; then
    install -m 0755 "${SOURCE_DIR}/scripts/${f}" "${INSTALL_DIR}/scripts/${f}"
  else
    curl -fsSL "${REPO_RAW}/scripts/${f}" -o "${INSTALL_DIR}/scripts/${f}"
    chmod 0755 "${INSTALL_DIR}/scripts/${f}"
  fi
done

for f in fstab.example fstab.ugreen-dh2300.example fstab.iamfaulty.example fstab.synology-ds223j.example env.iamfaulty.example netplan-usb-ethernet.yaml.example arr-appliance.service arr-disk-guard.service arr-disk-guard.timer; do
  copy_file "config/${f}"
done

if [[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/README.md" ]]; then
  install -m 0644 "${SOURCE_DIR}/README.md" "${INSTALL_DIR}/docs/README.md"
else
  curl -fsSL "${REPO_RAW}/README.md" -o "${INSTALL_DIR}/docs/README.md"
fi

for doc in MORNING-CHECKLIST.md MIGRATE-FROM-M4.md HARDWARE.md SYNOLOGY-DS223J.md NOTE-dual-projects.md ROADMAP.md; do
  if [[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/docs/${doc}" ]]; then
    install -m 0644 "${SOURCE_DIR}/docs/${doc}" "${INSTALL_DIR}/docs/${doc}"
  else
    curl -fsSL "${REPO_RAW}/docs/${doc}" -o "${INSTALL_DIR}/docs/${doc}"
  fi
done

if [[ ! -f "${INSTALL_DIR}/.env" ]]; then
  cp "${INSTALL_DIR}/.env.example" "${INSTALL_DIR}/.env"
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [[ -n "${REAL_USER}" && "${REAL_USER}" != "root" ]]; then
  REAL_UID="$(id -u "${REAL_USER}")"
  REAL_GID="$(id -g "${REAL_USER}")"
  sed -i "s/^PUID=.*/PUID=${REAL_UID}/" "${INSTALL_DIR}/.env"
  sed -i "s/^PGID=.*/PGID=${REAL_GID}/" "${INSTALL_DIR}/.env"
  usermod -aG docker "${REAL_USER}" 2>/dev/null || true
fi

echo "==> [4/7] USB Ethernet netplan (optional wired LAN)..."
NETPLAN_DST="/etc/netplan/60-arr-usb-ethernet.yaml"
if [[ ! -f "${NETPLAN_DST}" ]]; then
  cp "${INSTALL_DIR}/config/netplan-usb-ethernet.yaml.example" "${NETPLAN_DST}"
  chmod 0600 "${NETPLAN_DST}"
  netplan apply 2>/dev/null || true
  echo "Installed ${NETPLAN_DST} — plug USB adapter for DHCP on LAN."
else
  echo "Keeping existing ${NETPLAN_DST}"
fi

echo "==> [5/7] systemd units..."
install -m 0644 "${INSTALL_DIR}/config/arr-appliance.service" /etc/systemd/system/arr-appliance.service
install -m 0644 "${INSTALL_DIR}/config/arr-disk-guard.service" /etc/systemd/system/arr-disk-guard.service
install -m 0644 "${INSTALL_DIR}/config/arr-disk-guard.timer" /etc/systemd/system/arr-disk-guard.timer
systemctl daemon-reload
systemctl enable arr-disk-guard.timer
systemctl start arr-disk-guard.timer

echo "==> [6/7] NAS mounts (manual step required)..."
if ! mountpoint -q /mnt/nas/appdata 2>/dev/null; then
  echo
  echo "NAS is not mounted yet. Before starting the stack:"
  echo "  1. Edit ${INSTALL_DIR}/config/fstab.example for your NAS"
  echo "  2. Create /etc/nas-credentials if using SMB"
  echo "  3. Add lines to /etc/fstab and run: sudo mount -a"
  echo "  4. Verify: ${INSTALL_DIR}/scripts/check-nas.sh"
  echo
else
  echo "NAS mount detected."
fi

echo "==> [7/7] Enable on boot (after NAS is ready)..."
echo "When NAS mounts work, run:"
echo "  sudo systemctl enable --now arr-appliance"
echo
echo "Web UIs (from another machine on LAN):"
echo "  Prowlarr     http://<mini-ip>:9696"
echo "  Sonarr       http://<mini-ip>:8989"
echo "  Radarr       http://<mini-ip>:7878"
echo "  Bazarr       http://<mini-ip>:6767"
echo "  qBittorrent  http://<mini-ip>:8080"
echo
echo "Morning checklist: ${INSTALL_DIR}/docs/MORNING-CHECKLIST.md"
echo "Install complete."

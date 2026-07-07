#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nftables dnsmasq python3 python3-pip python3-venv iproute2

echo "==> Installing minifw"
python3 -m pip install --break-system-packages "${PROJECT_DIR}"

echo "==> Enabling IP forwarding"
install -d /etc/minifw
if [[ ! -f /etc/minifw/firewall.yaml ]]; then
  install -m 0644 "${PROJECT_DIR}/config/firewall.example.yaml" /etc/minifw/firewall.yaml
  echo "Created /etc/minifw/firewall.yaml — edit interface names before applying."
fi

echo "==> Detecting interfaces"
ip -br link

echo
echo "Next steps:"
echo "  1. Plug ISP modem into USB Ethernet (WAN), LAN switch into built-in port (LAN)"
echo "  2. Edit /etc/minifw/firewall.yaml with your interface names"
echo "  3. Set a static IP on the LAN interface in /etc/netplan/ or /etc/network/interfaces"
echo "  4. Run: minifw apply"
echo "  5. Run: systemctl enable --now nftables dnsmasq"

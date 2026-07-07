#!/usr/bin/env bash
set -euo pipefail

echo "Network interfaces:"
ip -br link
echo
echo "IP addresses:"
ip -br addr
echo
echo "Default route:"
ip route | awk '/^default/ {print}'
echo
echo "USB devices (likely USB Ethernet adapters):"
if command -v lsusb >/dev/null 2>&1; then
  lsusb
else
  echo "lsusb not installed"
fi

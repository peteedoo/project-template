#!/usr/bin/env bash
# Pre-cutover validation — run on the Mac Mini BEFORE unplugging the Network Box.
set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  [OK]   $*"; PASS=$((PASS + 1)); }
warn() { echo "  [WARN] $*"; WARN=$((WARN + 1)); }
bad()  { echo "  [FAIL] $*"; FAIL=$((FAIL + 1)); }

echo "=== MiniFW preflight ==="
echo

echo "-- Interfaces"
if ip -br link | grep -qE 'UP|UNKNOWN'; then
  ip -br link
else
  bad "No network interfaces found"
fi
echo

echo "-- WAN interface (should show inet from DHCP when Fiber Jack is connected)"
WAN_IF=$(ip -br link | awk '/enx|usb/ {print $1; exit}')
if [[ -n "${WAN_IF}" ]]; then
  ok "Detected likely WAN interface: ${WAN_IF}"
  if ip -br addr show "${WAN_IF}" | grep -qE 'inet [0-9]'; then
    WAN_IP=$(ip -br addr show "${WAN_IF}" | awk '{print $3}')
    ok "WAN has IP: ${WAN_IP}"
    if [[ "${WAN_IP}" == 192.168.* ]]; then
      warn "WAN IP is private — may still be behind Network Box, not Fiber Jack"
    else
      ok "WAN IP looks public or ISP-assigned"
    fi
  else
    bad "WAN interface ${WAN_IF} has no IPv4 — do not cut over yet"
  fi
else
  bad "No USB WAN interface (enx*) found — is the adapter plugged in?"
fi
echo

echo "-- LAN interface (should be 192.168.10.1)"
LAN_IF=$(ip -br addr | awk '/192\.168\.10\.1/ {print $1}')
if [[ -n "${LAN_IF}" ]]; then
  ok "LAN interface ${LAN_IF} has 192.168.10.1"
else
  bad "LAN does not have 192.168.10.1 — run netplan apply"
fi
echo

echo "-- IP forwarding"
if [[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" == "1" ]]; then
  ok "ip_forward enabled"
else
  bad "ip_forward disabled — run: sudo minifw apply"
fi
echo

echo "-- DNS/DHCP (dnsmasq)"
if systemctl is-active --quiet dnsmasq 2>/dev/null; then
  ok "dnsmasq running"
else
  warn "dnsmasq not running — run: sudo systemctl enable --now dnsmasq"
fi
echo

echo "-- Firewall (nftables)"
if nft list ruleset &>/dev/null; then
  ok "nftables rules loaded"
else
  bad "nftables not loaded — run: sudo minifw apply"
fi
echo

echo "-- Internet reachability (via Mac Mini)"
if ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
  ok "Can ping 1.1.1.1"
else
  bad "Cannot ping 1.1.1.1"
fi
if curl -sf --max-time 5 https://ifconfig.me &>/dev/null; then
  ok "Can reach internet (ifconfig.me)"
else
  warn "HTTP check failed — may still work for LAN clients"
fi
echo

echo "-- Config file"
if [[ -f /etc/minifw/firewall.yaml ]]; then
  ok "/etc/minifw/firewall.yaml exists"
else
  bad "Missing /etc/minifw/firewall.yaml — run: sudo minifw init"
fi
echo

echo "=== Summary: ${PASS} passed, ${WARN} warnings, ${FAIL} failed ==="
if [[ "${FAIL}" -gt 0 ]]; then
  echo "DO NOT cut over. Fix failures first."
  exit 1
fi
if [[ "${WARN}" -gt 0 ]]; then
  echo "Review warnings, then proceed with caution."
  exit 0
fi
echo "Ready for cutover."
exit 0

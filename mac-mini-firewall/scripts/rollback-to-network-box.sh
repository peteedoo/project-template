#!/usr/bin/env bash
# Emergency rollback reference — restores Google Fiber Network Box.
# Run this ONLY if you need a reminder of steps; physical cable swaps are manual.
#
# Estimated time: 3–5 minutes
set -euo pipefail

cat <<'EOF'
╔══════════════════════════════════════════════════════════════════╗
║  EMERGENCY ROLLBACK — Google Fiber Network Box                     ║
╚══════════════════════════════════════════════════════════════════╝

1. POWER OFF Mac Mini (optional but avoids DHCP conflicts)

2. CABLES — restore original layout:
   • Fiber Jack Ethernet  →  Network Box WAN (globe icon, left port)
   • Network Box LAN (blue) →  Deco main unit OR switch
   • Plug in Network Box power

3. WAIT 2–3 minutes for LEDs:
   • Power: green
   • Internet: green
   • Wi-Fi: green

4. DECO — if Wi-Fi does not appear:
   • Deco app → More → Advanced → Operation Mode → Router
   • Reboot Deco mesh when prompted

5. VERIFY on phone (cellular Wi-Fi off, connected to Deco):
   • Browse to https://google.com
   • If still down: unplug Network Box 30 sec, replug, wait 3 min

6. CALL Google Fiber support (phone, use cellular):
   • 1-866-777-7550 (US)
   • They troubleshoot up to the Fiber Jack only if using own router
   • With Network Box restored, they can help fully

7. WHEN STABLE — debug Mac Mini later with keyboard + monitor attached

Keep this script path: mac-mini-firewall/scripts/rollback-to-network-box.sh
Full doc: mac-mini-firewall/docs/BACKUP-AND-ROLLBACK.md
EOF

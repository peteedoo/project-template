#!/usr/bin/env bash
# One-time install on the firewall Mac Mini (Ubuntu) — plug-and-play MINIFWSETUP USB.
# Run once:  sudo ./install-usb-watcher.sh
# Or from USB: sudo bash install-usb-watcher.sh
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_LIB="/usr/local/lib/minifw"
INSTALL_BIN="/usr/local/sbin"

echo "==> Installing MiniFW USB plug-and-play (firewall auto-config)"

apt-get install -y -qq util-linux  # flock, mount

install -d "${INSTALL_LIB}" "${INSTALL_BIN}"

install -m 0755 "${SCRIPT_DIR}/usb-autorun.sh" "${INSTALL_LIB}/usb-autorun.sh"

# systemd service template (triggered by udev)
install -d /etc/systemd/system
cat > /etc/systemd/system/minifw-usb@.service <<'EOF'
[Unit]
Description=MiniFW autorun for USB %i
After=local-fs.target
ConditionPathExists=/usr/local/lib/minifw/usb-autorun.sh

[Service]
Type=oneshot
ExecStart=/usr/local/lib/minifw/usb-autorun.sh %i
TimeoutStartSec=600
StandardInput=tty
TTYPath=/dev/tty1
EOF

# udev: fire systemd when MINIFWSETUP partition appears
cat > /etc/udev/rules.d/99-minifw-usb.rules <<'EOF'
# MiniFW setup USB — auto-run when plugged in (label MINIFWSETUP)
ACTION=="add", SUBSYSTEM=="block", KERNEL=="*[0-9]", ENV{ID_FS_LABEL}=="MINIFWSETUP", \
  TAG+="systemd", ENV{SYSTEMD_WANTS}="minifw-usb@$kernel.service"
EOF

udevadm control --reload-rules
systemctl daemon-reload

# Optional helper command
cat > "${INSTALL_BIN}/minifw-usb-enable" <<'EOF'
#!/usr/bin/env bash
echo "MiniFW USB watcher is installed."
echo "Plug in a USB labeled MINIFWSETUP to auto-run setup."
echo "Logs: journalctl -t minifw-usb -f"
EOF
chmod +x "${INSTALL_BIN}/minifw-usb-enable"

echo
echo "==> Plug-and-play enabled"
echo
echo "  Plug in MINIFWSETUP USB → firewall auto-runs setup or update"
echo "  First time: full setup"
echo "  Already configured: update/repair mode"
echo
echo "  Watch logs:  journalctl -t minifw-usb -f"
echo "  Console:     keyboard on monitor shows prompts"
echo "  Headless:    auto-continues after 15s unless you attach keyboard"
echo
echo "  Disable prompts:  echo 'MINIFW_NO_PROMPT=1' >> /etc/environment"

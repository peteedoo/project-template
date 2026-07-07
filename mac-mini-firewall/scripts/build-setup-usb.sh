#!/usr/bin/env bash
# Build a MiniFW setup USB. Run on any Mac, Windows (WSL), or Linux machine.
#
# Usage:
#   ./build-setup-usb.sh /Volumes/MINIFW-SETUP     # macOS
#   ./build-setup-usb.sh /media/user/MINIFW-SETUP  # Linux
#   ./build-setup-usb.sh /mnt/e                    # WSL
#
# The USB will be formatted separately by you (see docs/USB-SETUP.md).
set -euo pipefail

TARGET="${1:-}"
if [[ -z "${TARGET}" ]]; then
  echo "Usage: $0 <usb-mount-path>"
  echo
  echo "Example (macOS):  $0 /Volumes/MINIFW-SETUP"
  echo "Example (Linux):  $0 /media/\$USER/MINIFW-SETUP"
  exit 1
fi

if [[ ! -d "${TARGET}" ]]; then
  echo "Error: ${TARGET} is not a directory. Is the USB plugged in and mounted?"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Building MiniFW setup USB at ${TARGET}"
echo "    Source: ${PROJECT_DIR}"
echo

# Clean previous build artifacts on the stick (keep hidden . files alone)
find "${TARGET}" -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} +

copy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  cp -R "${src}" "${dst}"
}

echo "==> Copying docs (offline triage on the stick)"
copy "${PROJECT_DIR}/docs/TRIAGE.md"              "${TARGET}/docs/TRIAGE.md"
copy "${PROJECT_DIR}/docs/BACKUP-AND-ROLLBACK.md" "${TARGET}/docs/BACKUP-AND-ROLLBACK.md"
copy "${PROJECT_DIR}/docs/SETUP-PLAN.md"          "${TARGET}/docs/SETUP-PLAN.md"
copy "${PROJECT_DIR}/docs/NETWORK.md"             "${TARGET}/docs/NETWORK.md"

echo "==> Copying configs"
copy "${PROJECT_DIR}/config/netplan.example.yaml"        "${TARGET}/config/netplan.example.yaml"
copy "${PROJECT_DIR}/config/netplan-vlan2-fallback.yaml" "${TARGET}/config/netplan-vlan2-fallback.yaml"
copy "${PROJECT_DIR}/config/firewall.example.yaml"       "${TARGET}/config/firewall.example.yaml"

echo "==> Copying minifw source"
copy "${PROJECT_DIR}/src"         "${TARGET}/minifw/src"
copy "${PROJECT_DIR}/pyproject.toml" "${TARGET}/minifw/pyproject.toml"
copy "${PROJECT_DIR}/tests"       "${TARGET}/minifw/tests"

echo "==> Copying scripts"
for f in setup.sh preflight.sh rollback-to-network-box.sh detect-interfaces.sh; do
  copy "${PROJECT_DIR}/scripts/${f}" "${TARGET}/${f}"
done
chmod +x "${TARGET}/setup.sh" "${TARGET}/preflight.sh" \
         "${TARGET}/rollback-to-network-box.sh" "${TARGET}/detect-interfaces.sh"

echo "==> Writing START-HERE.txt"
copy "${PROJECT_DIR}/usb/START-HERE.txt" "${TARGET}/START-HERE.txt"
copy "${PROJECT_DIR}/usb/EMERGENCY-CARD.txt" "${TARGET}/EMERGENCY-CARD.txt"

# Marker file so udev auto-run can identify this stick
echo "minifw-setup-usb-v1" > "${TARGET}/.minifw-usb"

echo
echo "==> Done. USB is ready."
echo
echo "  Volume label:  MINIFW-SETUP (recommended)"
echo "  On Mac Mini:   sudo ./setup.sh"
echo
echo "  Full instructions: docs/USB-SETUP.md"
du -sh "${TARGET}" 2>/dev/null || true

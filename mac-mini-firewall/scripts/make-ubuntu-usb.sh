#!/usr/bin/env bash
# Flash Ubuntu Server 24.04 to a USB — one command on your Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/make-ubuntu-usb.sh | bash
#
set -euo pipefail

ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
ISO_FILE="${TMPDIR:-/tmp}/ubuntu-24.04-server.iso"
MIN_GB=4

say()  { echo "==> $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only. On Linux: use dd or balenaEtcher manually."

# ── Find external USB ─────────────────────────────────────────────────────────
say "Looking for USB drives..."
echo

mapfile -t USBS < <(diskutil list external physical 2>/dev/null | awk '/^\/dev\/disk[0-9]+/ {print $1}')

if [[ ${#USBS[@]} -eq 0 ]]; then
  die "No USB drive found. Plug it in and run again."
fi

DISK=""
if [[ ${#USBS[@]} -eq 1 ]]; then
  DISK="${USBS[0]}"
  diskutil info "${DISK}" | grep -E "Device Node|Total Size|Volume Name|Mounted"
  echo
else
  echo "Multiple USB drives:"
  i=1
  for d in "${USBS[@]}"; do
    name=$(diskutil info "${d}" 2>/dev/null | awk -F': ' '/Volume Name/ {print $2; exit}')
    size=$(diskutil info "${d}" 2>/dev/null | awk -F': ' '/Disk Size/ {print $2; exit}')
    echo "  ${i}) ${d}  ${name:-unknown}  ${size:-}"
    ((i++)) || true
  done
  echo -n "Which one? [1-${#USBS[@]}]: "
  read -r pick
  [[ "${pick}" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#USBS[@]} )) || die "Invalid choice"
  DISK="${USBS[$((pick-1))]}"
fi

# Don't flash MINIFWSETUP by accident
vol=$(diskutil info "${DISK}" 2>/dev/null | awk -F': ' '/Volume Name/ {print $2; exit}' | tr -d ' ')
if [[ "${vol}" == "MINIFWSETUP" ]]; then
  die "That's your MINIFWSETUP stick. Plug in the OTHER USB."
fi

rdisk="/dev/r${DISK#/dev/}"

# ── Download ISO ─────────────────────────────────────────────────────────────
if [[ -f "${ISO_FILE}" ]]; then
  say "Using cached ISO: ${ISO_FILE}"
else
  say "Downloading Ubuntu Server 24.04 (~2.6 GB) — grab your USB, this takes a few min..."
  curl -L --progress-bar "${ISO_URL}" -o "${ISO_FILE}"
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  This ERASES the USB and writes Ubuntu Server 24.04      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "  Target: ${DISK} (${vol:-no name})"
echo
read -r -p "Type YES to continue: " confirm
[[ "${confirm}" == "YES" ]] || die "Aborted."

# ── Flash ─────────────────────────────────────────────────────────────────────
say "Unmounting ${DISK}..."
diskutil unmountDisk force "${DISK}"

say "Writing Ubuntu (5-10 min, looks frozen — it's not)..."
sudo dd if="${ISO_FILE}" of="${rdisk}" bs=4m status=progress conv=sync
sync

say "Ejecting..."
diskutil eject "${DISK}"

echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  DONE — Ubuntu USB ready                                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "  Mac Mini:  plug in → hold Option → pick Ubuntu → install"
echo "  After:     plug MINIFWSETUP → sudo ./setup.sh"
echo

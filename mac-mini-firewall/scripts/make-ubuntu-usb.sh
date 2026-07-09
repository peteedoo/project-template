#!/usr/bin/env bash
# Flash Ubuntu Server 24.04 to a USB — one command on your Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/make-ubuntu-usb.sh | bash
#
# Optional: pick disk number if asked — MINIFW_DISK=1 curl ... | bash
#
set -euo pipefail

ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
ISO_FILE="${TMPDIR:-/tmp}/ubuntu-24.04-server.iso"
MAX_USB_GB=128   # skip huge externals (e.g. 2TB Music drive)

say()  { echo "==> $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

ask() {
  local prompt="$1"
  local reply=""
  printf '%s' "${prompt}" >/dev/tty
  read -r reply </dev/tty || true
  echo "${reply}"
}

disk_label() {
  diskutil info "$1" 2>/dev/null | awk -F': ' '/Volume Name/ {gsub(/^ +| +$/,"",$2); print $2; exit}'
}

disk_bytes() {
  diskutil info "$1" 2>/dev/null | awk -F': ' '/Disk Size/ {gsub(/[^0-9].*/,"",$2); print $2; exit}'
}

disk_size_human() {
  diskutil info "$1" 2>/dev/null | awk -F': ' '/Disk Size/ {print $2; exit}'
}

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only."

# ── Find USB sticks (not 2TB drives) ───────────────────────────────────────────
say "Looking for USB drives..."
echo

ALL=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && ALL[${#ALL[@]}]="${line}"
done <<EOF
$(diskutil list external physical 2>/dev/null | awk '/^\/dev\/disk[0-9]+/ {print $1}')
EOF

USBS=()
for d in "${ALL[@]:-}"; do
  label="$(disk_label "${d}")"
  bytes="$(disk_bytes "${d}")"
  gb=$(( bytes / 1000000000 ))

  if [[ "${label}" == "MINIFWSETUP" ]]; then
    say "Skipping ${d} (MINIFWSETUP)"
    continue
  fi
  if [[ "${gb}" -gt "${MAX_USB_GB}" ]]; then
    say "Skipping ${d} (${gb} GB — too big, not a flash drive)"
    continue
  fi
  USBS[${#USBS[@]}]="${d}"
done

if [[ ${#USBS[@]} -eq 0 ]]; then
  die "No USB flash drive found. Plug in an 8–128 GB stick (not MINIFWSETUP, not your 2TB drive)."
fi

DISK=""
if [[ -n "${MINIFW_DISK:-}" ]]; then
  pick="${MINIFW_DISK}"
  [[ "${pick}" =~ ^[0-9]+$ ]] && [[ "${pick}" -ge 1 && "${pick}" -le ${#USBS[@]} ]] \
    || die "MINIFW_DISK must be 1-${#USBS[@]}"
  DISK="${USBS[$((pick - 1))]}"
  say "Using disk ${pick} from MINIFW_DISK"
elif [[ ${#USBS[@]} -eq 1 ]]; then
  DISK="${USBS[0]}"
  say "Auto-selected ${DISK} ($(disk_size_human "${DISK}"))"
else
  echo "Pick the Ubuntu installer stick (usually the empty ~32 GB one):"
  i=1
  for d in "${USBS[@]}"; do
    echo "  ${i}) ${d}  $(disk_label "${d}"): $(disk_size_human "${d}")"
    i=$((i + 1))
  done
  while true; do
    pick="$(ask "Type 1 or 2: ")"
    if [[ "${pick}" =~ ^[0-9]+$ ]] && [[ "${pick}" -ge 1 && "${pick}" -le ${#USBS[@]} ]]; then
      DISK="${USBS[$((pick - 1))]}"
      break
    fi
    echo "Please type 1 or ${#USBS[@]} and press Enter." >/dev/tty
  done
fi

vol="$(disk_label "${DISK}")"
rdisk="/dev/r${DISK#/dev/}"

# ── Download ISO ─────────────────────────────────────────────────────────────
if [[ -f "${ISO_FILE}" ]]; then
  say "Using cached ISO: ${ISO_FILE}"
else
  say "Downloading Ubuntu Server 24.04 (~2.6 GB)..."
  curl -L --progress-bar "${ISO_URL}" -o "${ISO_FILE}"
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  This ERASES the USB and writes Ubuntu Server 24.04      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "  Target: ${DISK} (${vol:-unnamed}) — $(disk_size_human "${DISK}")"
echo
confirm="$(ask "Type YES to continue: ")"
[[ "${confirm}" == "YES" ]] || die "Aborted."

# ── Flash ─────────────────────────────────────────────────────────────────────
say "Unmounting ${DISK}..."
diskutil unmountDisk force "${DISK}"

say "Writing Ubuntu (5-10 min)..."
sudo dd if="${ISO_FILE}" of="${rdisk}" bs=4m status=progress conv=sync
sync

say "Ejecting..."
diskutil eject "${DISK}"

echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  DONE — Ubuntu USB ready                                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "  Mac Mini: plug in → hold Option → pick Ubuntu → install"
echo "  Then:     MINIFWSETUP → sudo ./setup.sh"
echo

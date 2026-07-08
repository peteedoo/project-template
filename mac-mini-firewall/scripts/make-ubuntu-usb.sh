#!/usr/bin/env bash
# Flash Ubuntu Server 24.04 to a USB — one command on your Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/make-ubuntu-usb.sh | bash
#
set -euo pipefail

ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
ISO_FILE="${TMPDIR:-/tmp}/ubuntu-24.04-server.iso"

say()  { echo "==> $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# curl | bash steals stdin — read prompts from the real terminal
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

disk_size() {
  diskutil info "$1" 2>/dev/null | awk -F': ' '/Disk Size/ {print $2; exit}'
}

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only."

# ── Find external USBs (skip MINIFWSETUP) ────────────────────────────────────
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
  if [[ "${label}" == "MINIFWSETUP" ]]; then
    say "Skipping ${d} (MINIFWSETUP — use the other stick)"
    continue
  fi
  USBS[${#USBS[@]}]="${d}"
done

if [[ ${#USBS[@]} -eq 0 ]]; then
  die "No USB found. Plug in the Ubuntu stick (not MINIFWSETUP) and run again."
fi

DISK=""
if [[ ${#USBS[@]} -eq 1 ]]; then
  DISK="${USBS[0]}"
  say "Auto-selected ${DISK} ($(disk_label "${DISK}"): $(disk_size "${DISK}"))"
else
  echo "Multiple USB drives — pick the one for Ubuntu:"
  i=1
  for d in "${USBS[@]}"; do
    echo "  ${i}) ${d}  $(disk_label "${d}"): $(disk_size "${d}")"
    i=$((i + 1))
  done
  pick="$(ask "Which one? [1-${#USBS[@]}]: ")"
  [[ "${pick}" =~ ^[0-9]+$ ]] && [[ "${pick}" -ge 1 && "${pick}" -le ${#USBS[@]} ]] \
    || die "Invalid choice"
  DISK="${USBS[$((pick - 1))]}"
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
echo "  Target: ${DISK} (${vol:-unnamed})"
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

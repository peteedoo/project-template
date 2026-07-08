#!/usr/bin/env bash
# Populate MINIFWSETUP USB — one command, minimal input.
# Run on your Mac with the USB stick plugged in:
#
#   curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/make-usb.sh | bash
#
set -euo pipefail

REPO="https://github.com/peteedoo/project-template.git"
BRANCH="cursor/mac-mini-firewall-2baf"
WORK="/tmp/minifw-usb-build-$$"

say()  { echo "==> $*"; }
done_msg() {
  echo
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  DONE — USB is ready                                     ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo
  echo "  Stick:     ${TARGET}"
  echo "  Next:      Plug into firewall Mac Mini (auto-runs if watcher installed)"
  echo "  One-time:  sudo bash install-usb-watcher.sh  on the firewall Mac Mini"
  echo "  Obsidian:  open ${TARGET}/obsidian in Obsidian app"
  echo "  Emergency: ${TARGET}/EMERGENCY-CARD.txt"
  echo
  echo "  Eject when ready:  diskutil eject \"${TARGET}\""
  echo
}

# ── macOS only ───────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS. On Linux run:"
  echo "  git clone -b ${BRANCH} ${REPO} && cd project-template/mac-mini-firewall"
  echo "  ./scripts/build-setup-usb.sh /media/\$USER/MINIFWSETUP"
  exit 1
fi

# ── Find USB ─────────────────────────────────────────────────────────────────
find_usb() {
  local preferred=("$@")
  local vol

  for vol in "${preferred[@]}"; do
    if [[ -d "/Volumes/${vol}" ]]; then
      echo "/Volumes/${vol}"
      return 0
    fi
  done

  # Any removable volume that isn't a system disk
  local -a candidates=()
  while IFS= read -r vol; do
    [[ -z "${vol}" ]] && continue
    [[ "${vol}" == "Macintosh HD" ]] && continue
    [[ "${vol}" == "Macintosh HD - Data" ]] && continue
    [[ "${vol}" == "Preboot" ]] && continue
    [[ "${vol}" == "Recovery" ]] && continue
    [[ "${vol}" == "Update" ]] && continue
    [[ "${vol}" == "VM" ]] && continue
    candidates+=("${vol}")
  done < <(ls /Volumes 2>/dev/null)

  if [[ ${#candidates[@]} -eq 1 ]]; then
    echo "/Volumes/${candidates[0]}"
    return 0
  fi

  if [[ ${#candidates[@]} -gt 1 ]]; then
    echo "Multiple USB drives found:" >&2
    local i=1
    for vol in "${candidates[@]}"; do
      echo "  ${i}) /Volumes/${vol}" >&2
      ((i++)) || true
    done
    echo -n "Which one? [1-${#candidates[@]}]: " >&2
    read -r pick
    if [[ "${pick}" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#candidates[@]} )); then
      echo "/Volumes/${candidates[$((pick-1))]}"
      return 0
    fi
  fi

  return 1
}

say "Looking for USB stick..."
TARGET=""
if TARGET=$(find_usb MINIFWSETUP MINIFW-SETUP MINIFW); then
  say "Found: ${TARGET}"
else
  echo
  echo "Could not find USB. Make sure:"
  echo "  1. USB is plugged in"
  echo "  2. It shows up in Finder sidebar"
  echo "  3. Ideally named MINIFWSETUP (Disk Utility → Erase → ExFAT)"
  echo
  echo "Then run this script again."
  exit 1
fi

# ── Writable? ────────────────────────────────────────────────────────────────
if ! touch "${TARGET}/.minifw-write-test" 2>/dev/null; then
  echo "Cannot write to ${TARGET}. Check USB is not read-only."
  exit 1
fi
rm -f "${TARGET}/.minifw-write-test"

# ── Get source ───────────────────────────────────────────────────────────────
say "Downloading MiniFW (branch ${BRANCH})..."
rm -rf "${WORK}"
git clone --depth 1 --branch "${BRANCH}" "${REPO}" "${WORK}" 2>/dev/null || {
  say "Git failed — trying curl fallback..."
  mkdir -p "${WORK}/mac-mini-firewall"
  curl -fsSL "https://github.com/peteedoo/project-template/archive/refs/heads/${BRANCH}.tar.gz" \
    | tar xz --strip-components=2 -C "${WORK}/mac-mini-firewall" \
      "project-template-${BRANCH}/mac-mini-firewall" 2>/dev/null || {
    echo "Download failed. Check internet connection."
    exit 1
  }
  WORK="${WORK}/mac-mini-firewall"
  PROJECT_DIR="${WORK}"
}

if [[ -z "${PROJECT_DIR:-}" ]]; then
  PROJECT_DIR="${WORK}/mac-mini-firewall"
fi

if [[ ! -f "${PROJECT_DIR}/scripts/build-setup-usb.sh" ]]; then
  echo "Build script not found at ${PROJECT_DIR}/scripts/build-setup-usb.sh"
  exit 1
fi

# ── Build ────────────────────────────────────────────────────────────────────
say "Writing files to USB (takes ~10 seconds)..."
chmod +x "${PROJECT_DIR}/scripts/build-setup-usb.sh"
bash "${PROJECT_DIR}/scripts/build-setup-usb.sh" "${TARGET}"

# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf "${WORK}"

done_msg

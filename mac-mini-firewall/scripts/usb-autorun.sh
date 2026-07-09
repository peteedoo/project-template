#!/usr/bin/env bash
# Triggered by systemd when MINIFWSETUP USB is plugged in.
# Installed to /usr/local/lib/minifw/usb-autorun.sh by install-usb-watcher.sh
set -euo pipefail

LOG_TAG="minifw-usb"
DEVICE="${1:-}"
MOUNT="/mnt/minifwsetup"
LOCK="/run/minifw-usb.lock"
LABEL="MINIFWSETUP"

log() { logger -t "${LOG_TAG}" "$*"; echo "[${LOG_TAG}] $*"; }

have_tty() {
  [[ -e /dev/tty1 ]] && [[ "$(tty 2>/dev/null)" == "/dev/tty1" ]] && return 0
  [[ -t 0 ]] && return 0
  return 1
}

prompt_yes() {
  local msg="$1" default="${2:-y}"
  if [[ "${MINIFW_NO_PROMPT:-}" == "1" ]]; then
    [[ "${default}" == "y" ]]
    return
  fi
  if have_tty; then
    local ans
    read -r -p "${msg} " ans </dev/tty 2>/dev/null || ans=""
    ans="${ans:-$default}"
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
    return
  fi
  # Headless: default after short delay
  log "No keyboard attached — auto-yes in 15s (set MINIFW_NO_PROMPT=0 to wait forever)"
  sleep 15
  [[ "${default}" == "y" ]]
}

acquire_lock() {
  exec 9>"${LOCK}"
  if ! flock -n 9; then
    log "Another MiniFW USB job is running — skipping"
    exit 0
  fi
}

find_device() {
  if [[ -n "${DEVICE}" && -b "/dev/${DEVICE}" ]]; then
    echo "/dev/${DEVICE}"
    return 0
  fi
  local by_label="/dev/disk/by-label/${LABEL}"
  if [[ -e "${by_label}" ]]; then
    readlink -f "${by_label}"
    return 0
  fi
  return 1
}

mount_usb() {
  local dev="$1"
  mkdir -p "${MOUNT}"
  if mountpoint -q "${MOUNT}"; then
    if [[ -f "${MOUNT}/.minifw-usb" ]]; then
      return 0
    fi
    umount "${MOUNT}" || true
  fi
  mount -o ro "${dev}" "${MOUNT}" 2>/dev/null || mount "${dev}" "${MOUNT}"
  log "Mounted ${dev} at ${MOUNT}"
}

unmount_usb() {
  if mountpoint -q "${MOUNT}"; then
    umount "${MOUNT}" || true
    log "Unmounted ${MOUNT}"
  fi
}

wall_msg() {
  local msg="$1"
  log "${msg}"
  echo "${msg}" | wall 2>/dev/null || true
}

main() {
  acquire_lock

  local dev
  dev="$(find_device)" || { log "MINIFWSETUP device not found"; exit 1; }

  wall_msg "MiniFW USB detected — starting in 10 seconds (plug in keyboard on console to interact)"

  if ! mount_usb "${dev}"; then
    log "Mount failed for ${dev}"
    exit 1
  fi

  if [[ ! -f "${MOUNT}/.minifw-usb" ]]; then
    log "Not a MiniFW USB (missing .minifw-usb) — ignoring"
    unmount_usb
    exit 0
  fi

  local mode="setup"
  if [[ -f /etc/minifw/firewall.yaml ]]; then
    mode="update"
  fi

  if ! prompt_yes "Run MiniFW ${mode} from USB? [Y/n]" "y"; then
    log "Skipped by user"
    unmount_usb
    exit 0
  fi

  # Remount read-write if we need to run scripts from stick (setup copies from USB)
  mount -o remount,rw "${MOUNT}" 2>/dev/null || mount -o rw "${dev}" "${MOUNT}"

  export MINIFW_USB_AUTORUN=1
  if [[ "${mode}" == "update" ]]; then
    log "Running update mode"
    bash "${MOUNT}/setup.sh" --update
  else
    log "Running full setup"
    bash "${MOUNT}/setup.sh"
  fi

  unmount_usb
  wall_msg "MiniFW USB ${mode} complete"
}

main "$@"

#!/usr/bin/env bash
# Refuse to start the stack unless NAS paths are mounted and writable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${ROOT_DIR}/.env"
  set +a
fi

NAS_ROOT="${NAS_ROOT:-/mnt/nas}"
NAS_APPDATA="${NAS_APPDATA:-/mnt/nas/appdata}"
NAS_DOWNLOADS="${NAS_DOWNLOADS:-/mnt/nas/downloads}"
NAS_MEDIA="${NAS_MEDIA:-/mnt/nas/media}"
NAS_TV="${NAS_TV:-${NAS_MEDIA}/tv}"
NAS_MOVIES="${NAS_MOVIES:-${NAS_MEDIA}/movies}"

fail=0

check_path() {
  local label="$1"
  local path="$2"
  local require_mount="${3:-0}"

  if [[ ! -d "${path}" ]]; then
    echo "FAIL: ${label} missing — ${path}"
    fail=1
    return
  fi

  if [[ "${require_mount}" -eq 1 ]]; then
    if ! mountpoint -q "${path}" 2>/dev/null; then
      echo "FAIL: ${label} not mounted — ${path}"
      fail=1
      return
    fi
  elif ! mountpoint -q "${path}" 2>/dev/null; then
    echo "      (${label} is under NAS share — OK if ${NAS_ROOT} is mounted)"
  fi

  if [[ ! -w "${path}" ]]; then
    echo "FAIL: ${label} not writable — ${path}"
    fail=1
    return
  fi

  echo "OK:   ${label} — ${path}"
}

echo "Checking NAS paths before starting *arr stack..."
check_path "NAS root" "${NAS_ROOT}" 1
check_path "appdata"   "${NAS_APPDATA}"
check_path "downloads" "${NAS_DOWNLOADS}"
check_path "TV"        "${NAS_TV}"
check_path "movies"    "${NAS_MOVIES}"

if [[ "${fail}" -ne 0 ]]; then
  echo
  echo "Fix mounts first. See:"
  echo "  ${ROOT_DIR}/config/fstab.example"
  echo "  ${ROOT_DIR}/docs/MORNING-CHECKLIST.md"
  exit 1
fi

echo "NAS checks passed."

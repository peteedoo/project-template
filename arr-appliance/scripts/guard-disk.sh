#!/usr/bin/env bash
# Stop the stack if the local root disk fills past LOCAL_DISK_MAX_PCT.
# Sacrificial disk policy: protect your main Mac, not this box.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_TAG="arr-disk-guard"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${ROOT_DIR}/.env"
  set +a
fi

MAX_PCT="${LOCAL_DISK_MAX_PCT:-85}"
USED_PCT="$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"

if [[ -z "${USED_PCT}" ]]; then
  echo "${LOG_TAG}: could not read disk usage for /"
  exit 1
fi

if (( USED_PCT < MAX_PCT )); then
  echo "${LOG_TAG}: root disk ${USED_PCT}% — under ${MAX_PCT}% limit"
  exit 0
fi

echo "${LOG_TAG}: root disk ${USED_PCT}% >= ${MAX_PCT}% — stopping containers"

cd "${ROOT_DIR}"
if command -v docker >/dev/null 2>&1; then
  docker compose down 2>/dev/null || true
  docker image prune -f 2>/dev/null || true
fi

logger -t "${LOG_TAG}" "Stopped *arr stack: root disk at ${USED_PCT}% (limit ${MAX_PCT}%)"
echo "${LOG_TAG}: stack stopped. Free space on / then run: ${ROOT_DIR}/scripts/arr-up.sh"

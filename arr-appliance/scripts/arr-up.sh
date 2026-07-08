#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example and edit NAS paths:"
  echo "  cp .env.example .env && nano .env"
  exit 1
fi

"${SCRIPT_DIR}/check-nas.sh"
"${SCRIPT_DIR}/guard-disk.sh"

docker compose up -d
docker compose ps

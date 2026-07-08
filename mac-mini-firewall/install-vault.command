#!/usr/bin/env bash
# Double-click to open the MiniFW vault in Obsidian.
# Vault lives at: ~/Documents/MiniFW
set -euo pipefail

VAULT="${HOME}/Documents/MiniFW"
OBSIDIAN="/Applications/Obsidian.app"

find_vault() {
  if [[ -f "${VAULT}/Home.md" ]]; then
    echo "${VAULT}"
    return 0
  fi
  # Legacy / alternate locations
  for path in \
    "${HOME}/Documents/obsidian" \
    "${HOME}/Documents/mac-mini-firewall/obsidian" \
    "${HOME}/Desktop/MiniFW" \
    "${HOME}/Desktop/obsidian"; do
    if [[ -f "${path}/Home.md" ]]; then
      echo "${path}"
      return 0
    fi
  done
  return 1
}

VAULT_PATH="$(find_vault)" || {
  osascript -e 'display dialog "MiniFW vault not found.\n\nExpected: Documents/MiniFW/Home.md" buttons {"OK"} default button 1 with icon caution'
  exit 1
}

# If vault is somewhere else, move it to Documents/MiniFW
if [[ "${VAULT_PATH}" != "${VAULT}" ]]; then
  mkdir -p "$(dirname "${VAULT}")"
  if [[ -d "${VAULT}" ]]; then
    rsync -a "${VAULT_PATH}/" "${VAULT}/"
    rm -rf "${VAULT_PATH}"
  else
    mv "${VAULT_PATH}" "${VAULT}"
  fi
  VAULT_PATH="${VAULT}"
fi

if [[ -d "${OBSIDIAN}" ]]; then
  open -a Obsidian "${VAULT_PATH}"
else
  osascript -e "display dialog \"Open Obsidian, then:\nOpen folder as vault →\n${VAULT_PATH}\" buttons {\"OK\"} default button 1"
  open "${VAULT_PATH}"
fi

osascript -e 'display notification "MiniFW vault opened" with title "Obsidian"'

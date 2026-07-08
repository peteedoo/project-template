#!/usr/bin/env bash
# Double-click this file on your Mac. It moves the vault off Desktop and opens Obsidian.
set -euo pipefail

DEST="${HOME}/Documents/MiniFW"
OBSIDIAN="/Applications/Obsidian.app"

# Find vault on Desktop (common names)
SRC=""
for name in MiniFW obsidian mac-mini-firewall; do
  if [[ -d "${HOME}/Desktop/${name}" && -f "${HOME}/Desktop/${name}/Home.md" ]]; then
    SRC="${HOME}/Desktop/${name}"
    break
  fi
  if [[ -d "${HOME}/Desktop/${name}/obsidian" && -f "${HOME}/Desktop/${name}/obsidian/Home.md" ]]; then
    SRC="${HOME}/Desktop/${name}/obsidian"
    break
  fi
done

if [[ -z "${SRC}" ]]; then
  osascript -e 'display dialog "Could not find MiniFW vault on Desktop.\n\nLook for a folder with Home.md inside." buttons {"OK"} default button 1 with icon caution'
  exit 1
fi

# Already in the right place?
if [[ "$(cd "${SRC}" && pwd)" == "$(cd "${DEST}" 2>/dev/null && pwd)" ]]; then
  :
elif [[ -d "${DEST}" ]]; then
  # Merge/update — Desktop copy wins for newer files
  rsync -a "${SRC}/" "${DEST}/"
  rm -rf "${SRC}"
else
  mkdir -p "$(dirname "${DEST}")"
  mv "${SRC}" "${DEST}"
fi

# Open Obsidian
if [[ -d "${OBSIDIAN}" ]]; then
  open -a Obsidian "${DEST}"
else
  osascript -e "display dialog \"Vault moved to:\n${DEST}\n\nInstall Obsidian from obsidian.md, then Open folder as vault.\" buttons {\"OK\"} default button 1"
  open "${DEST}"
fi

osascript -e "display notification \"Vault is in Documents/MiniFW\" with title \"MiniFW\""

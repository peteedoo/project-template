#!/usr/bin/env bash
# Double-click helper — opens Terminal and runs make-usb.sh
# Save as: make-usb.command (macOS runs .command files in Terminal)
DIR="$(cd "$(dirname "$0")" && pwd)"
osascript -e "tell application \"Terminal\" to do script \"cd '${DIR}' && bash scripts/make-usb.sh; echo; echo 'Press Enter to close...'; read\""
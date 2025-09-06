#!/usr/bin/env bash
# Bootstrap installer: pulls the latest function-based script and forwards args
set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/RyanTheTide/LinuxConfigurations/refs/heads/main/scripts"
SCRIPT_NAME="install_v2.sh"

# Support both: sh -c "$(curl .../install.sh)" nowindows
# and:          sh -c "$(curl .../install.sh)" -- --no-windows
ARGS=("$@")
# If invoked via: sh -c "$(curl .../install.sh)" nowindows
# then $0 == "nowindows" and $@ is empty. Detect and forward it.
case "${0-}" in
	nowin|--no-windows)
		ARGS+=("${0}")
		;;
esac

tmp=$(mktemp)
curl -fsSL "${RAW_BASE}/${SCRIPT_NAME}" -o "$tmp"
chmod +x "$tmp"
exec "$tmp" "${ARGS[@]}"

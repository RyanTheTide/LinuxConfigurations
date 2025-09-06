#!/usr/bin/env bash
set -euo pipefail

uri=https://github.com/RyanTheTide/LinuxConfigurations/archive/refs/heads/main.tar.gz

bootstrap() {
	clear
	echo "Bootstrapping installer..."
	cd /tmp
	curl -fsSL "${uri}" | tar -xz
	cd LinuxConfigurations-main/scripts/archinstaller
	chmod +x main.sh
	exec ./main.sh "$@"
}

bootstrap "$@"

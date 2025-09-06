#!/usr/bin/env bash
set -euo pipefail

# sh -c "curl -sL https://github.com/RyanTheTide/LinuxConfigurations/archive/refs/heads/main.tar.gz | tar -xz && cd LinuxConfigurations-main/scripts/newinstall && chmod +x main.sh && ./main.sh"

uri=https://github.com/RyanTheTide/LinuxConfigurations/archive/refs/heads/main.tar.gz

bootstrap() {
	cd /tmp
	curl -SL "${uri}" | tar -xz
	cd LinuxConfigurations-main/scripts/newinstall
	chmod +x main.sh
	exec ./main.sh "$@"
}

bootstrap "$@"

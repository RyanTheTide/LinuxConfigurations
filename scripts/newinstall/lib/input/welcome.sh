#!/usr/bin/env bash

input_welcome() {
  clear
  cat <<EOF
Welcome to ArchInstaller by RyanTheTide!

This script will install a Arch Linux system
with a guided, interactive process. Offering
sensible defaults while allowing customization.

The base system will be installed with the following:
- btrfs filesystem (@,@home,@snapshots,@cache,@log)
- rEFInd bootmanager (with custom rounddark theme)
- additional packages (developement, networking, etc)
- microcode (if detected intel or amd)
- pacman mirrors (organised by speed, set by country)

Thanks for using my script & follow the folowing prompts!
EOF
}

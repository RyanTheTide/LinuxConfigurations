#!/usr/bin/env bash

input_welcome() {
  cat <<EOF
====================================================
  Welcome to ArchInstaller by RyanTheTide!

  This script will install a Arch Linux system
  with a guided, interactive process. Offering
  sensible defaults while allowing customization.

  The base system will be installed with:
  - btrfs filesystem
  - rEFInd bootmanager
  - 

  Please follow the prompts to complete the setup.
====================================================
EOF
}
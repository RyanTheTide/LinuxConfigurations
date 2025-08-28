# RTT's Linux Configurations

A collection of my personal Linux configurations, scripts, and dotfiles.
This repository is primarily designed for Arch Linux installations, but many of the scripts and configuration files can be adapted to other distributions.

## Repository Structure

```
LinuxConfigurations/
├── dotfiles/     # User configuration files (.zshrc, .config/, etc.)
├── refind/       # rEFInd boot manager themes and configuration
└── scripts/      # Installation and setup helper scripts
```

## Features
* Pre-configured dotfiles for shell, includes:
  * Oh My Posh theme for beautiful terminal usage.
  * Custom commands.
  * Simplified Zsh run commands file.
* rEFInd themes for clean boot experience, includes:
  * RoundDark theme.
* Automated setup script for Arch Linux, including:
  * Disk partitioning and filesystem layout. With a focus on dual-booting Windows.
  * rEFInd boot manager. With aformentioned theme.
  * Zsh shell environment including Oh My Zsh & Oh My Posh. With aformentioned theme.
  * System defaults (locales, keymaps, etc.). Note these are **hardcoded to Australia**, edit as necessary.

## Notes
* These configurations are opinionated and tailored for my systems.
* You may need to adjust scripts or configs for your hardware (e.g. timezone, locales, etc).
* Back up your data before running any installation scripts — they will completely wipe the target disk.

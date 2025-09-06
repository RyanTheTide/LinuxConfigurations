#!/usr/bin/env bash

detect_cpu_manufacturer() {
    local __var
    __var=$(lscpu | awk -F: '/Vendor ID/ {gsub(/^[ \t]+/, "", $2); print $2}')
    if [[ $__var == "GenuineIntel" ]]; then
        cpu_manufacturer="intel"
    elif [[ $__var == "AuthenticAMD" ]]; then
        # shellcheck disable=SC2034
        cpu_manufacturer="amd"
    else
        # shellcheck disable=SC2034
        cpu_manufacturer="unknown"
    fi
}
#!/usr/bin/env bash

# Prompt helper script provides functions to interact with the user:
# - ask: Prompt user for input and store in variable
# - asks: Prompt user for silent input and store in variable
# - confirm: Prompt user for yes/no confirmation, defaults to yes
# - say: Print message

# Usage examples:
# - ask - `ask var "prompt" "default"`
# - asks - `asks var "prompt"`
# - confirm - `confirm "prompt"`
# - say - `say "message"`

ask() {
    local var_name="$1"
    local __prompt="$2" 
    local __default="${3:-}"
    local __input
    if [[ -n "$__default" ]]; then
        read -rp "${__prompt} [${__default}]: " __input
        __input="${__input:-$__default}"
    else
        read -rp "${__prompt}: " __input
    fi
    echo
    echo "DEBUG: Setting variable '$var_name' to value '$__input'"
    eval "$var_name='$__input'"
    echo "DEBUG: Variable $var_name now contains: ${!var_name}"
}
}
asks() {
    local __var="$1"
    local __prompt="$2"
    local __input
    read -rsp "${__prompt}: " __input
    echo
    printf -v "$__var" '%s' "$__input"
}

confirm() {
    local __prompt="$1"
    local __response
    while true; do
        read -rp "${__prompt} [Y/n]: " __response
        if [[ -z "$__response" ]]; then
            return 0
        fi
        case "$__response" in
            [Yy] | [Yy][Ee][Ss] ) return 0 ;;
            [Nn] | [Nn][Oo] ) return 1 ;;
            * ) echo "Please answer yes (y) or no (n)." ;;
        esac
    done
}

say() {
    printf '%s\n' "$*"
}

#!/usr/bin/env bash

# User input script gets various user details:
# - newuser : new user (including password and description/full name)
# - rootpassword : root account password

input_user() {
# New user
    local __var1 __var2 __var3 __var4
    while true; do
        ask newusername "Enter your username (e.g. user)" "user"
        # shellcheck disable=SC2154
        if [[ "$newusername" =~ [[:space:]] ]]; then
            log_warn "Username cannot contain spaces."
            continue
        fi
        if [[ "$newusername" =~ ^[a-z_][a-z0-9_-]*$ && ${#newusername} -le 32 ]]; then
            while true; do
                asks __var1 "Enter new password for $newusername"
                asks __var2 "Confirm new password for $newusername"
                if [[ "$__var1" == "$__var2" ]]; then
                    # shellcheck disable=SC2034
                    newuserpassword="$__var1"
                    break
                else
                    log_warn "Passwords do not match. Please try again."
                fi
            done
            echo
            ask newuserdescription "Enter your full name for $newusername" "$newusername"
            break
        else
            log_warn "$newusername is invalid. Please try again."
        fi
    done
# Root password
    while true; do
        asks __var3 "Enter new password for root"
        asks __var4 "Confirm new password for root"
        if [[ "$__var3" == "$__var4" ]]; then
            # shellcheck disable=SC2034
            rootpassword="$__var3"
            break
        else
            log_warn "Passwords do not match. Please try again."
        fi
    done
}
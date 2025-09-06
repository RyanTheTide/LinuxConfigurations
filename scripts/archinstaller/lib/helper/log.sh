#!/usr/bin/env bash

# Log helper script provides logging functions with different severity levels:
# - log_info: Informational messages
# - log_success: Success messages
# - log_warn: Warning messages
# - log_error: Error messages
# - log_fatal: Fatal error messages and exits the script

# Usage examples:
# - log_info "message"
# - log_success "message"
# - log_warn "message"
# - log_error "message"
# - log_fatal "message"

log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

log_fatal() {
    log_error "$1"
    exit 1
}
#!/usr/bin/env bash

install_gui() {
    if [[ $(set_gui) == "gnome" ]]; then
        install_de_gnome
    elif [[ $(set_gui) == "kde" ]]; then
        install_de_kde
    fi
}
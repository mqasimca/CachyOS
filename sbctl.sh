#!/bin/bash

sudo pacman -S sbctl --needed --noconfirm sbctl

# Check if secureboot is enabled
if sbctl status | grep -q "Secure Boot:        ✓ Enabled"
then
    echo "Secure Boot is enabled."
else
    echo "Secure Boot is not enabled."
    echo "Setting up Secure Boot..."
    echo "https://wiki.cachyos.org/configuration/secure_boot_setup/"
    sudo sbctl create-keys # Create your custom secure boot keys
    sudo sbctl enroll-keys -m # Enroll your custom secure boot keys
fi

if ! command -v sbctl-batch-sign &> /dev/null
then
    echo "sbctl-batch-sign is not installed."
else
    echo "sbctl-batch-sign is already installed."
    echo "Signing the kernel..."
    sudo sbctl-batch-sign
    sudo sbctl verify
    echo "Reboot your system & check if Secure Boot is enabled."
fi

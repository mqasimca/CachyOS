#!/bin/bash

# Define constants
JOURNAL_DIR="/var/log/journal"
LOGIND_CONF="/etc/systemd/logind.conf"
HANDLE_LID_SWITCH="HandleLidSwitch=ignore"
RFKILL_SERVICE="rfkill-unblock@all"
COPILOT_DIR="$HOME/.vim/pack/github/start/copilot.vim"
PACMAN_PACKAGES="neovim nodejs npm fwupd cachyos-gaming-meta appmenu-gtk-module libdbusmenu-glib qt5ct wget unzip realtime-privileges libvoikko hspell nuspell hunspell aspell ttf-fantasque-nerd ttf-font-awesome otf-font-awesome awesome-terminal-fonts noto-fonts noto-fonts-emoji ttf-fira-sans ttf-hack cachyos-nord-gtk-theme-git capitaine-cursors cachyos-alacritty-config papirus-icon-theme gnome-shell-extension-dash-to-dock gnome-shell-extension-weather-oclock neofetch"
AUR_PACKAGES="visual-studio-code-bin ryzenadj-git ryzen_smu-dkms-git"

# Function to rsync etc files
rsync_etc_files() {
    echo "Copying etc files..."
    sudo rsync -av --chown=root:root sync/etc/ /etc/ || {
        echo "Failed to copy etc files. Exiting."
        exit 1
    }
    echo "etc files copied successfully."
}

# Function to rsync home files
rsync_home_files() {
    echo "Copying home files..."
    rsync -av sync/home/ ~ || {
        echo "Failed to copy home files. Exiting."
        exit 1
    }
    echo "home files copied successfully."
}

# Function to check which shell is being used
check_shell() {
    case "$SHELL" in
        */bash)
            echo "$HOME/.bashrc"
            ;;
        */zsh)
            echo "$HOME/.zshrc"
            ;;
        *)
            echo "$HOME/.dummyrc"
            ;;
    esac
}

# Function to check $HOME/bin is in PATH
home_bin_in_path() {
    if [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
        echo "$HOME/bin is already in PATH."
    else
        echo "Adding $HOME/bin to PATH..."
        echo "export PATH=\$PATH:\$HOME/bin" >>  "$(check_shell)" || {
            echo "Failed to add $HOME/bin to PATH. Exiting."
            exit 1
        }
        echo "$HOME/bin added to PATH."
        echo "Please source $(check_shell) to apply changes."
        exit 1
    fi
}

# Function to remove the journal directory
remove_journal_dir() {
    if [ -d "$JOURNAL_DIR" ]; then
        echo "Directory $JOURNAL_DIR exists. Removing it..."
        sudo rm -rf "$JOURNAL_DIR" || {
            echo "Failed to remove $JOURNAL_DIR. Exiting."
            exit 1
        }
        echo "Restarting systemd-journald service to apply changes..."
        sudo systemctl restart systemd-journald || {
            echo "Failed to restart systemd-journald. Exiting."
            exit 1
        }
    else
        echo "Directory $JOURNAL_DIR does not exist. Logging is already in /run/log/journal (in-memory)."
    fi
}

# Function to update HandleLidSwitch in logind.conf
update_logind_conf() {
    if grep -q "^$HANDLE_LID_SWITCH" "$LOGIND_CONF"; then
        echo "HandleLidSwitch is already set to ignore."
    else
        echo "Updating HandleLidSwitch to ignore in $LOGIND_CONF..."
        sudo sed -i "s/^#HandleLidSwitch=.*/$HANDLE_LID_SWITCH/" "$LOGIND_CONF" || {
            echo "Failed to update $LOGIND_CONF. Exiting."
            exit 1
        }
        # Ensure the line is added if it doesn't exist
        if ! grep -q "^$HANDLE_LID_SWITCH" "$LOGIND_CONF"; then
            echo "$HANDLE_LID_SWITCH" | sudo tee -a "$LOGIND_CONF" >/dev/null || {
                echo "Failed to append $HANDLE_LID_SWITCH to $LOGIND_CONF. Exiting."
                exit 1
            }
        fi
        echo "HandleLidSwitch is now set to ignore."
    fi
}

# Function to enable rfkill-unblock@all service
enable_rfkill_service() {
    if systemctl is-enabled --quiet "$RFKILL_SERVICE"; then
        echo "$RFKILL_SERVICE is already active."
    else
        echo "Enabling $RFKILL_SERVICE..."
        sudo systemctl enable --now "$RFKILL_SERVICE" || {
            echo "Failed to enable and start $RFKILL_SERVICE. Exiting."
            exit 1
        }
        echo "$RFKILL_SERVICE started and enabled."
    fi
}

# Function to install GitHub Copilot plugin for Vim
install_copilot_plugin() {
    if [ -d "$COPILOT_DIR" ]; then
        echo "GitHub Copilot is already installed in $COPILOT_DIR."
    else
        echo "Installing GitHub Copilot..."
        git clone https://github.com/github/copilot.vim.git "$COPILOT_DIR" || {
            echo "Failed to clone GitHub Copilot repository. Exiting."
            exit 1
        }
        echo "GitHub Copilot installed successfully."
        echo "Start Vim/Neovim and invoke :Copilot setup"
    fi
}

# Function to optimize Nvidia GPU power usage
optimize_nvidia_gpu() {
    echo "Optimizing Nvidia GPU power usage..."
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA driver is not installed. Please install it first."
        return
    fi
    
    if systemctl is-active --quiet nvidia-persistenced.service; then
        echo "nvidia-persistenced.service is already active."
    else
        echo "Starting nvidia-persistenced.service..."
        sudo systemctl enable --now nvidia-persistenced.service || {
            echo "Failed to start nvidia-persistenced.service. Exiting."
            exit 1
        }
        echo "nvidia-persistenced.service started."
    fi 

    sudo pacman -S --needed acpi_call-dkms

    if nvidia-smi -L | grep -q 2060; then
	    if systemctl is-enabled nvidia-powerd.service | grep masked; then
	        echo "nvidia-powerd.service is already masked."
	    else
      		sudo systemctl disable --now nvidia-powerd.service || {
          	echo "Failed to disable nvidia-powerd.service. Exiting."
          	exit 1
      		}
      		sudo systemctl mask nvidia-powerd.service || {
          	echo "Failed to mask nvidia-powerd.service. Exiting."
          	exit 1
      		}
      		echo "nvidia-powerd.service disabled and masked."
	    fi 
   fi
}

# Function to ensure apcid package is install and enabled
pacman_installed_acpid() {
  sudo pacman -S --needed acpid
  if systemctl is-active --quiet acpid.service; then
      echo "acpid.service is already active."
  else
      echo "Starting acpid.service..."
      sudo systemctl enable --now acpid.service || {
          echo "Failed to start acpid.service. Exiting."
          exit 1
      }
      echo "acpid.service started."
  fi
}

# Function to ensure pacman packages are installed
pacman_install() {
  echo "Installing pacman packages..."
  sudo pacman -S --needed $PACMAN_PACKAGES
}

# Function to ensure AUR packages are installed
aur_install() {
  echo "Installing AUR packages..."
  paru -S --needed $AUR_PACKAGES
}

# Function to ensure KVM is install
kvm() {
  echo "Installing KVM"
  sudo pacman -S --needed qemu-full qemu-img libvirt virt-install virt-manager virt-viewer edk2-ovmf dnsmasq swtpm guestfs-tools libosinfo tuned spice spice-vdagent qemu-guest-agent
  wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.240-1/virtio-win-0.1.240.iso -P ~/Downloads
  for drv in qemu interface network nodedev nwfilter secret storage; do
    sudo systemctl enable virt${drv}d.service;
    sudo systemctl enable virt${drv}d{,-ro,-admin}.socket;
  done
  sudo virsh net-start default
  sudo virsh net-autostart default
  echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> "$(check_shell)"
  sudo ufw allow in on virbr0
  sudo ufw allow out on virbr0
}

gsettings_set() {
    gsettings set org.gnome.mutter check-alive-timeout 60000 || {
        echo "Failed to set check-alive-timeout. Exiting."
    }
    gsettings set org.gnome.desktop.screensaver lock-enabled false || {
        echo "Failed to disable screensaver lock. Exiting."
    }
}

# Main execution
main() {
    echo "Starting setup..."
    rsync_etc_files
    rsync_home_files
    home_bin_in_path
    remove_journal_dir
    update_logind_conf
    install_copilot_plugin
    pacman_install
    aur_install
    gsettings_set
    echo "Setup completed successfully."
}

# Trap to handle unexpected interruptions
trap 'echo "Script interrupted."; exit 1' INT TERM

# Run the main function
main

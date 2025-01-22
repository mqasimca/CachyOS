#!/bin/bash
# https://forums.lenovo.com/t5/Ubuntu/Ubuntu-and-legion-pro-7-16IRX8H-audio-issues/m-p/5210709?page=32
# cat /sys/class/sound/hwC1D0/subsystem_id
# 16ARX8H

# Check if file exists /etc/modprobe.d/60-hda.conf
if [ -f /etc/modprobe.d/60-hda.conf ]; then
    echo "File /etc/modprobe.d/60-hda.conf exists."
else
    echo "File /etc/modprobe.d/60-hda.conf does not exist. Creating it..."
    echo "options snd-hda-intel model=,17aa:38a8" | sudo tee /etc/modprobe.d/60-hda.conf
fi

# Check if file exists ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
if [ -f ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf ]; then
    echo "File ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf exists."
else
    echo "File ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf does not exist. Creating it..."
    cp -a /usr/share/wireplumber ~/.config/
    # EOF config file ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
    cat <<EOF > ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
monitor.alsa.rules = [
  {
    matches = [
      {
        # Matches all sources
        node.name = "~alsa_input.*"
      },
      {
        # Matches all sinks
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        session.suspend-timeout-seconds = 0
      }
    }
  }
]
# bluetooth devices
monitor.bluez.rules = [
  {
    matches = [
      {
        # Matches all sources
        node.name = "~bluez_input.*"
      },
      {
        # Matches all sinks
        node.name = "~bluez_output.*"
      }
    ]
    actions = {
      update-props = {
        session.suspend-timeout-seconds = 0
      }
    }
  }
]
EOF
fi

sudo mkinitcpio -P 

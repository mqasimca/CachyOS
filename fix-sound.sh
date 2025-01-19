#!/bin/bash
# https://forums.lenovo.com/t5/Ubuntu/Ubuntu-and-legion-pro-7-16IRX8H-audio-issues/m-p/5210709?page=32


echo "options snd-hda-intel model=,17aa:38a8" | sudo tee /etc/modprobe.d/60-hda.conf
echo "options snd_hda_intel power_save=0" | sudo tee /etc/modprobe.d/audio_disable_powersave.conf
echo "options snd_hda_intel power_save_controller=N" | sudo tee -a /etc/modprobe.d/audio_disable_powersave.conf

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

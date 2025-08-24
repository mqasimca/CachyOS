#!/usr/bin/env bash
set -euo pipefail

# Check if ryzenadj is installed
ryzenadj_path=$(command -v ryzenadj)
if [[ -z "$ryzenadj_path" ]]; then
    echo "ryzenadj is not installed. Please install ryzenadj-git from AUR."
    exit 1
fi

default_tctl="--tctl-temp=93"

# Create script for max performance profile (AC)
sudo tee /usr/local/bin/ryzenadj-ac-perf.sh > /dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
${ryzenadj_path} --max-performance ${default_tctl}
EOF
sudo chmod 755 /usr/local/bin/ryzenadj-ac-perf.sh

# Create script for power saving profile (Battery)
sudo tee /usr/local/bin/ryzenadj-bat-save.sh > /dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
${ryzenadj_path} --power-saving ${default_tctl}
EOF
sudo chmod 755 /usr/local/bin/ryzenadj-bat-save.sh

# Create systemd service for max performance profile (AC)
sudo tee /etc/systemd/system/ryzenadj-ac-perf.service > /dev/null <<EOF
[Unit]
Description=RyzenAdj: max-performance on AC
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj-ac-perf.sh

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for power saving profile (Battery)
sudo tee /etc/systemd/system/ryzenadj-bat-save.service > /dev/null <<EOF
[Unit]
Description=RyzenAdj: power-saving on battery
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj-bat-save.sh

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new/changed services
sudo systemctl daemon-reload

# Create udev rule to trigger AC performance profile when AC is plugged in
sudo tee /etc/udev/rules.d/91-ryzenadj-ac.rules >/dev/null <<'EOF'
# AC plugged in -> start AC performance profile
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", ACTION=="change", \
  RUN+="/usr/bin/systemctl start ryzenadj-ac-perf.service"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", ACTION=="add", \
  RUN+="/usr/bin/systemctl start ryzenadj-ac-perf.service"
EOF

# Create udev rule to trigger battery saving profile when AC is unplugged
sudo tee /etc/udev/rules.d/92-ryzenadj-bat.rules >/dev/null <<'EOF'
# AC unplugged -> start Battery power-saving profile
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", ACTION=="change", \
  RUN+="/usr/bin/systemctl start ryzenadj-bat-save.service"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", ACTION=="add", \
  RUN+="/usr/bin/systemctl start ryzenadj-bat-save.service"
EOF

# Reload udev rules and trigger power_supply events
sudo udevadm control --reload
sudo udevadm trigger -s power_supply
echo "udevadm rules reloaded and power_supply events triggered."
echo "sudo journalctl -u ryzenadj-ac-perf.service -u ryzenadj-bat-save.service -f"
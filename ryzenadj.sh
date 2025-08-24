#!/usr/bin/env bash
set -euo pipefail

# Check if ryzenadj is installed
ryzenadj_path=$(command -v ryzenadj)
if [[ -z "$ryzenadj_path" ]]; then
    echo "ryzenadj is not installed. Please install ryzenadj-git from AUR."
    exit 1
fi

default_tctl="--tctl-temp=93"

# Create script to set tctl-temp
sudo tee /usr/local/bin/ryzenadj-temp.sh > /dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
${ryzenadj_path} ${default_tctl}
EOF
sudo chmod 755 /usr/local/bin/ryzenadj-temp.sh

# Create systemd service to set tctl-temp at boot
sudo tee /etc/systemd/system/ryzenadj-temp.service > /dev/null <<EOF
[Unit]
Description=Set RyzenAdj tctl-temp at boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj-temp.sh

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new/changed services
sudo systemctl daemon-reload
# Enable and start the tctl-temp service at boot
sudo systemctl enable ryzenadj-temp.service
sudo systemctl start ryzenadj-temp.service
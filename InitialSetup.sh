#!/bin/bash

# InitialSetup.sh

# Create ServiceSetup.service file
cat <<EOF | sudo tee /etc/systemd/system/ServiceSetup.service
[Unit]
Description=ServiceSetup Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/rj-project/scripts/ServiceSetup.sh
#RemainAfterExit=yes # Remove this line
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create CustomSetup.service file
cat <<EOF | sudo tee /etc/systemd/system/CustomSetup.service
[Unit]
Description=CustomSetup Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/rj-project/scripts/CustomSetup.sh
#RemainAfterExit=yes  # Remove this line
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Make the scripts executable
sudo chmod +x /opt/rj-project/scripts/ServiceSetup.sh
sudo chmod +x /opt/rj-project/scripts/CustomSetup.sh

# Reload systemd
sudo systemctl daemon-reload

# Enable the services
sudo systemctl enable ServiceSetup.service
sudo systemctl enable CustomSetup.service

# Start the services
sudo systemctl start ServiceSetup.service
sudo systemctl start CustomSetup.service


## Enables SSH! ((Testing Only!!))
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
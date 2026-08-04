#! /bin/bash

#Set Minecraft version to install yo
MINECRAFT_VERSION="1.26.36.1"

sudo apt update
sudo apt install -y awscli unzip
sudo mkdir -p /usr/games/minecraft
sudo mkdir -p /usr/games/minecraft_backup
sudo mkdir -p /usr/games/minecraft_downloads

# Download and install server
cd /usr/games/minecraft
sudo wget https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${MINECRAFT_VERSION}.zip
sudo unzip -o bedrock-server-${MINECRAFT_VERSION}.zip

# Create systemd service
sudo cat > /etc/systemd/system/minecraft.service << __EOF__
[Unit]
Description=Minecraft Bedrock Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/usr/games/minecraft
ExecStart=/bin/sh -c "LD_LIBRARY_PATH=. ./bedrock_server"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
__EOF__

sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft

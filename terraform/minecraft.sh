#! /bin/bash
sudo apt update
sudo apt install unzip
sudo mkdir /usr/games/minecraft

cd /usr/games/minecraft
sudo wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.20.15.01.zip
sudo unzip bedrock-server-1.20.15.01.zip

cd /lib/systemd/system
touch minecraft.service

sudo cat > minecraft.service << __EOF__
#!/bin/bash -x
[Unit]
Description=Minecraft Service
After=network.target

[Service]
Type=Simple
WorkingDirectory=/usr/games/minecraft
ExecStart=/bin/sh -c "LD_LIBRARY_PATH=. ./bedrock_server"
Restart=on-failure

[Install]
WantedBy=multi-user.target
__EOF__

sudo systemctl enable minecraft
sudo systemctl start minecraft
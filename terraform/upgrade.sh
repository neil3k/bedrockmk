#! /bin/bash

#Shutdown Server
sudo systemctl stop minecraft.service

sleep 10

#Empty Existing Download Directory
rm -rf /usr/games/downloads/*

echo "Please type in the version you wish to update to"

read MINECRAFT_VERSION

echo "This Instance will be updated to version $MINECRAFT_VERSION"

#Commence Backup of World - use your own s3 bucket here
aws s3 cp --recursive /usr/games/minecraft/worlds s3://bedrock-minecraft-backups/"$(date +"%F")"

sleep 10

#Download new version
cd /usr/games/downloads
sudo wget https://minecraft.azureedge.net/bin-linux/bedrock-server-${MINECRAFT_VERSION}.zip

sudo unzip bedrock-server-${MINECRAFT_VERSION}.zip

cp bedrock_server_symbols.debug /usr/games/minecraft
cp bedrock_server /usr/games/minecraft

sleep 5

systemctl start minecraft.service
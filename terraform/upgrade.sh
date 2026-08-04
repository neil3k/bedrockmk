#! /bin/bash
set -e

# Minecraft Bedrock Server Upgrade Script
# Backs up worlds to S3, downloads new server version, and restarts the service.

INSTALL_DIR="/usr/games/minecraft"
DOWNLOAD_DIR="/usr/games/minecraft_downloads"
BACKUP_BUCKET="bedrock-minecraft-backups"

# Stop the server
echo "Stopping Minecraft server..."
sudo systemctl stop minecraft.service
sleep 5

# Clean download directory
rm -rf ${DOWNLOAD_DIR}/*

# Get version from argument or prompt
if [ -z "$1" ]; then
  echo "Please type in the version you wish to update to (e.g. 1.26.36.1)"
  read MINECRAFT_VERSION
else
  MINECRAFT_VERSION="$1"
fi

echo "Upgrading to version ${MINECRAFT_VERSION}..."

# Backup worlds to S3
echo "Backing up worlds to S3..."
aws s3 cp --recursive ${INSTALL_DIR}/worlds s3://${BACKUP_BUCKET}/"$(date +"%F")"

# Download new version
echo "Downloading server ${MINECRAFT_VERSION}..."
cd ${DOWNLOAD_DIR}
wget -q https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${MINECRAFT_VERSION}.zip
unzip -o bedrock-server-${MINECRAFT_VERSION}.zip

# Copy new binaries (preserves worlds, server.properties, allowlist.json, permissions.json)
echo "Installing new binaries..."
cp bedrock_server ${INSTALL_DIR}/
cp bedrock_server_symbols.debug ${INSTALL_DIR}/
cp -r resource_packs ${INSTALL_DIR}/
cp -r definitions ${INSTALL_DIR}/

# Start the server
echo "Starting Minecraft server..."
sudo systemctl start minecraft.service
sleep 3
sudo systemctl status minecraft.service --no-pager

echo "Upgrade to ${MINECRAFT_VERSION} complete!"

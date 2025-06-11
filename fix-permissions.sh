#!/bin/bash

# Quick fix for permission issues
echo "🔧 Fixing permissions for /opt/iptv..."

# Fix ownership for current user (to write docker-compose.yml)
sudo chown -R $USER:$USER /opt/iptv
sudo chmod -R 755 /opt/iptv

echo "✅ Permissions fixed!"
echo
echo "You can now run the setup script again:"
echo "  ./setup-saltbox.sh"
echo
echo "Or manually continue from where it left off:"
echo "  cd /opt/iptv"
echo "  cp ../iptv-proxy/docker-compose.saltbox.yml docker-compose.yml"
echo "  # Edit the docker-compose.yml with your settings"
echo "  nano docker-compose.yml"
echo "  # Set proper Docker permissions"
echo "  sudo chown -R 1000:1000 config playlists logs"
echo "  # Start the container"
echo "  docker compose up -d"
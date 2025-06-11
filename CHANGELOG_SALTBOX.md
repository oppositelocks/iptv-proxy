# Saltbox Deployment - Updated to use "iptv" naming

## Changes Made

### Directory Structure
- **Changed from**: `/opt/iptv-proxy/`
- **Changed to**: `/opt/iptv/`

### Container Naming
- **Changed from**: `container_name: iptv-proxy`
- **Changed to**: `container_name: iptv`

### Service Naming
- **Changed from**: `services: iptv-proxy:`
- **Changed to**: `services: iptv:`

### Domain/Subdomain
- **Changed from**: `iptv-proxy.yourdomain.com`
- **Changed to**: `iptv.yourdomain.com`

### Traefik Router Names
- **Changed from**: `traefik.http.routers.iptv-proxy`
- **Changed to**: `traefik.http.routers.iptv`

## File Updates

### 1. docker-compose.saltbox.yml
- Updated all service names and container names
- Updated volume mount paths
- Updated Traefik labels
- Added Xtream configuration as default (commented M3U_URL)

### 2. setup-saltbox.sh
- Updated APP_NAME variable from "iptv-proxy" to "iptv"
- Updated directory paths throughout script
- Updated domain display messages
- Updated Traefik URL generation

### 3. SALTBOX_DEPLOYMENT.md
- Updated all directory references
- Updated DNS setup instructions
- Updated container management commands
- Updated access URLs

### 4. QUICK_DEPLOY.md
- Updated directory paths
- Updated container names in commands
- Updated access URLs
- Updated management commands

## New Default Configuration

The updated configuration now:
- Uses cleaner "iptv" naming throughout
- Defaults to Xtream API configuration (more common)
- Provides M3U URL as alternative option
- Uses shorter, cleaner domain name (iptv.domain.com vs iptv-proxy.domain.com)

## Migration from Old Setup

If you have an existing deployment with "iptv-proxy" naming:

```bash
# Stop existing container
cd /opt/iptv-proxy
docker compose down

# Copy data to new location
sudo cp -r /opt/iptv-proxy /opt/iptv

# Update docker-compose.yml
cd /opt/iptv
# Update container name and service name in docker-compose.yml

# Restart with new configuration
docker compose up -d

# Optional: Remove old directory after confirming everything works
# sudo rm -rf /opt/iptv-proxy
```

## DNS Update Required

If using Traefik, update your DNS record:
- **Old**: `iptv-proxy.yourdomain.com → server-ip`
- **New**: `iptv.yourdomain.com → server-ip`

## Benefits of the Update

1. **Cleaner naming** - "iptv" is shorter and more intuitive
2. **Simplified URLs** - Easier to remember and type
3. **Better defaults** - Xtream API configuration is more common
4. **Consistent structure** - Follows Saltbox app naming conventions
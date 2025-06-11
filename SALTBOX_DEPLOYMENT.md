# IPTV Proxy Deployment Guide for Saltbox

This guide covers deploying the IPTV Proxy on a Saltbox server following Saltbox best practices and requirements.

## Prerequisites

1. **Saltbox Server**: Fully configured Saltbox installation
2. **DNS Setup**: Create subdomain `iptv.yourdomain.com` at your DNS provider (Cloudflare recommended)
3. **IPTV Provider**: Active IPTV subscription with M3U/Xtream API access

## Quick Deployment

### Step 1: Build the Docker Image

```bash
# Clone and build the IPTV Proxy
git clone https://github.com/incmve/iptv-proxy.git
cd iptv-proxy

# Build the Docker image
docker build -t iptv-proxy:latest .
```

### Step 2: Create Application Directory

```bash
# Create the Saltbox standard directory structure
sudo mkdir -p /opt/iptv/{config,playlists,logs}
sudo chown -R 1000:1000 /opt/iptv
```

### Step 3: Configure the Application

```bash
# Copy the Saltbox docker-compose file
cp docker-compose.saltbox.yml /opt/iptv/docker-compose.yml
cd /opt/iptv

# Edit configuration
nano docker-compose.yml
```

**Required Configuration Changes:**
- Replace `M3U_URL` with your IPTV provider's URL
- Change `USER` and `PASSWORD` to secure credentials
- Update Traefik labels with your domain (if using Traefik)

### Step 4: Deploy the Container

```bash
# Navigate to application directory
cd /opt/iptv

# Start the container
docker compose up -d

# Check status
docker compose logs -f iptv
```

## Configuration Options

### Basic Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `M3U_URL` | IPTV provider M3U URL | - | Yes |
| `USER` | Proxy authentication username | - | Yes |
| `PASSWORD` | Proxy authentication password | - | Yes |
| `PORT` | Internal container port | 8080 | No |
| `HOSTNAME` | Service hostname | iptv-proxy | No |

### Buffer Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `BUFFER_ENABLED` | Enable 5-second buffering | true | No |
| `BUFFER_DURATION` | Buffer duration in seconds | 5 | No |
| `BUFFER_MAX_MEMORY` | Max memory per buffer (MB) | 10 | No |

### Xtream API Configuration (Optional)

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `XTREAM_USER` | Xtream API username | - | No |
| `XTREAM_PASSWORD` | Xtream API password | - | No |
| `XTREAM_BASE_URL` | Xtream API base URL | - | No |
| `XTREAM_API_GET` | Generate M3U from API | false | No |

## Traefik Integration

### Step 1: Enable Traefik Labels

Uncomment and configure the Traefik labels in `docker-compose.yml`:

```yaml
labels:
  - "com.github.saltbox.saltbox_managed=true"
  - "traefik.enable=true"
  - "traefik.http.routers.iptv.rule=Host(\`iptv.yourdomain.com\`)"
  - "traefik.http.routers.iptv.tls=true"
  - "traefik.http.routers.iptv.tls.certresolver=cfdns"
  - "traefik.http.services.iptv.loadbalancer.server.port=8080"
  - "traefik.http.routers.iptv.middlewares=secureHeaders@file,authelia@file"
```

### Step 2: Remove Port Exposure

Comment out the ports section when using Traefik:

```yaml
# ports:
#   - "8080:8080"
```

### Step 3: Restart Container

```bash
docker compose down
docker compose up -d
```

## Access URLs

### Direct Access (without Traefik)
- **M3U Playlist**: `http://your-server-ip:8080/iptv.m3u?username=USER&password=PASSWORD`
- **Buffer Stats**: `http://your-server-ip:8080/buffer-stats?username=USER&password=PASSWORD`
- **Xtream API**: `http://your-server-ip:8080/player_api.php?username=USER&password=PASSWORD&action=get_live_categories`

### Traefik Access
- **M3U Playlist**: `https://iptv.yourdomain.com/iptv.m3u?username=USER&password=PASSWORD`
- **Buffer Stats**: `https://iptv.yourdomain.com/buffer-stats?username=USER&password=PASSWORD`
- **Xtream API**: `https://iptv.yourdomain.com/player_api.php?username=USER&password=PASSWORD&action=get_live_categories`

## VPN Integration (Optional)

To route IPTV traffic through a VPN (like the original gluetun setup):

### Step 1: Deploy Gluetun

```bash
# Create gluetun directory
sudo mkdir -p /opt/gluetun
sudo chown -R 1000:1000 /opt/gluetun

# Add gluetun service to docker-compose.yml in /opt/iptv/
```

### Step 2: Update Compose File

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun-iptv
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=your_provider
      - OPENVPN_USER=your_vpn_user
      - OPENVPN_PASSWORD=your_vpn_password
      - SERVER_COUNTRIES=Netherlands
      - TZ=Etc/UTC
    volumes:
      - /opt/gluetun:/gluetun
    networks:
      - saltbox
    labels:
      - "com.github.saltbox.saltbox_managed=true"

  iptv:
    # ... existing config ...
    network_mode: "service:gluetun-iptv"
    depends_on:
      - gluetun
```

## Monitoring & Maintenance

### Check Container Status
```bash
cd /opt/iptv
docker compose ps
docker compose logs -f iptv
```

### View Buffer Statistics
```bash
curl -u "USER:PASSWORD" "http://localhost:8080/buffer-stats"
```

### Update Container
```bash
cd /opt/iptv
docker compose pull
docker compose up -d
```

### Backup Configuration
The `/opt/iptv` directory is automatically included in Saltbox backups due to the `com.github.saltbox.saltbox_managed=true` label.

## Troubleshooting

### Common Issues

1. **Container won't start**
   ```bash
   docker compose logs iptv
   ```

2. **Can't access streams**
   - Check firewall settings
   - Verify IPTV provider URL
   - Check authentication credentials

3. **Buffering issues**
   - Monitor memory usage: `docker stats iptv`
   - Check buffer stats endpoint
   - Adjust `BUFFER_MAX_MEMORY` if needed

4. **Traefik routing issues**
   - Verify DNS resolution
   - Check Traefik dashboard
   - Ensure SSL certificate is valid

### Logs Location
- Container logs: `docker compose logs iptv`
- Application logs: `/opt/iptv/logs/` (if mounted)

## Security Considerations

1. **Change Default Credentials**: Always change the default `USER` and `PASSWORD`
2. **Use Strong Passwords**: Generate secure passwords for authentication
3. **Limit Access**: Use Authelia or IP restrictions in Traefik
4. **Regular Updates**: Keep the container image updated
5. **Monitor Access**: Review logs regularly for suspicious activity

## Support

For issues specific to:
- **IPTV Proxy**: [GitHub Issues](https://github.com/incmve/iptv-proxy/issues)
- **Saltbox**: [Saltbox Discord](https://discord.gg/ugfKXpFND8)
- **Traefik**: [Traefik Documentation](https://doc.traefik.io/traefik/)
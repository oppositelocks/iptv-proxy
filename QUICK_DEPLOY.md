# Quick Saltbox Deployment

## 🚀 Automated Installation

```bash
# Clone repository
git clone https://github.com/incmve/iptv-proxy.git
cd iptv-proxy

# Run automated setup
./setup-saltbox.sh
```

The script will guide you through configuration and automatically:
- **Choose M3U URL or Xtream Codes setup**
- Auto-detect Xtream credentials from M3U URLs
- Create required directories
- Build the Docker image  
- Generate proper docker-compose.yml
- Deploy the container
- Show access URLs

### **Configuration Options**:
1. **M3U URL** - Direct playlist URL (auto-detects Xtream)
2. **Xtream Codes** - Username/password API setup

## 📋 Manual Installation (Alternative)

### 1. Prerequisites
```bash
# Verify Saltbox network exists
docker network ls | grep saltbox

# Create subdomain DNS record (if using Traefik)
# iptv.yourdomain.com → your-server-ip
```

### 2. Build & Deploy
```bash
# Clone and build
git clone https://github.com/incmve/iptv-proxy.git
cd iptv-proxy
docker build -t iptv-proxy:latest .

# Create directories
sudo mkdir -p /opt/iptv/{config,playlists,logs}
sudo chown -R 1000:1000 /opt/iptv

# Copy and edit compose file
cp docker-compose.saltbox.yml /opt/iptv/docker-compose.yml
cd /opt/iptv
nano docker-compose.yml  # Edit configuration

# Deploy
docker compose up -d
```

### 3. Configuration Required
Edit `/opt/iptv/docker-compose.yml` - **Choose ONE method**:

**Option A: M3U URL**
```yaml
environment:
  M3U_URL: "http://your-provider.com/playlist.m3u"  # Your IPTV URL
  USER: "your_username"                              # Change this!
  PASSWORD: "your_secure_password"                   # Change this!
```

**Option B: Xtream Codes**
```yaml
environment:
  XTREAM_USER: "your_xtream_username"                # Provider username
  XTREAM_PASSWORD: "your_xtream_password"            # Provider password  
  XTREAM_BASE_URL: "http://provider.com:8000"        # Provider URL
  XTREAM_API_GET: true                               # Generate from API
  USER: "your_username"                              # Proxy username
  PASSWORD: "your_secure_password"                   # Proxy password
```

## 🌐 Access URLs

**Without Traefik (Direct IP):**
- M3U: `http://YOUR-SERVER-IP:8080/iptv.m3u?username=USER&password=PASSWORD`
- Stats: `http://YOUR-SERVER-IP:8080/buffer-stats?username=USER&password=PASSWORD`

**With Traefik (Domain):**
- M3U: `https://iptv.yourdomain.com/iptv.m3u?username=USER&password=PASSWORD`
- Stats: `https://iptv.yourdomain.com/buffer-stats?username=USER&password=PASSWORD`

## 🔧 Key Features Enabled

✅ **5-Second Buffering** - Smooths live streams  
✅ **Saltbox Integration** - Proper network & backup labels  
✅ **Traefik Ready** - SSL & reverse proxy support  
✅ **VPN Compatible** - Works with gluetun containers  
✅ **Multiple Formats** - M3U and Xtream API support  

## 🛠️ Management Commands

```bash
cd /opt/iptv

# View logs
docker compose logs -f iptv

# Restart service
docker compose restart iptv

# Update image
docker compose pull && docker compose up -d

# Stop service
docker compose down
```

## ⚠️ Security Notes

1. **Change default credentials** in docker-compose.yml
2. **Use strong passwords** for authentication
3. **Configure Authelia** for additional protection (Traefik setup)
4. **Monitor access logs** regularly

## 🆘 Troubleshooting

**Container won't start:**
```bash
docker compose logs iptv
```

**Can't access streams:**
- Check firewall (port 8080)
- Verify IPTV provider URL
- Test credentials

**Traefik issues:**
- Verify DNS record
- Check Traefik dashboard
- Ensure SSL certificate issued
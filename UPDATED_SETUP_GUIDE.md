# Updated Setup Script - M3U vs Xtream Configuration

## 🚀 **Enhanced Setup Script**

The `setup-saltbox.sh` script has been updated to provide a choice between M3U URL and Xtream Codes configuration methods.

### **New Configuration Flow**

When you run `./setup-saltbox.sh`, you'll now see:

```
╔══════════════════════════════════════════════════════════════════╗
║                    IPTV Proxy Saltbox Installer                 ║
║                                                                  ║
║  This script will install and configure IPTV Proxy for Saltbox  ║
║                                                                  ║
║  Supports:                                                       ║
║  • M3U URL Configuration                                         ║
║  • Xtream Codes API                                              ║
║  • 5-Second Stream Buffering                                     ║
║  • Traefik Integration                                           ║
╚══════════════════════════════════════════════════════════════════╝

=== IPTV Proxy Configuration ===

How do you want to configure your IPTV source?
1) M3U URL (Direct playlist URL)
2) Xtream Codes (Username/Password API)

Choose option [1-2]:
```

## **🎯 Configuration Methods**

### **Option 1: M3U URL Configuration**

**When to use**: You have a direct playlist URL from your provider.

**What it asks for**:
- M3U playlist URL
- Auto-detects Xtream credentials if present in URL
- Offers to enable Xtream API features

**Smart Detection**:
```
Enter your IPTV M3U URL: http://provider.com:8000/get.php?username=john&password=secret&type=m3u_plus

Detected Xtream credentials in M3U URL:
  Username: john
  Password: secret

Do you want to enable Xtream API features with these credentials? [Y/n]:
```

### **Option 2: Xtream Codes Configuration**

**When to use**: You have Xtream username/password credentials.

**What it asks for**:
- Xtream username
- Xtream password  
- Xtream base URL (e.g., `http://provider.com:8000`)
- Automatically sets `XTREAM_API_GET=true`

## **🔧 Generated Configuration Examples**

### **M3U URL Method** (Direct URL)
```yaml
environment:
  # M3U configuration
  M3U_URL: "http://provider.com:8000/get.php?username=john&password=secret&type=m3u_plus"
  
  # Proxy authentication
  USER: "my_proxy_user"
  PASSWORD: "my_proxy_password"
  
  # Buffer settings
  BUFFER_ENABLED: true
  BUFFER_DURATION: 5
```

### **M3U URL Method** (with Xtream API enabled)
```yaml
environment:
  # M3U configuration
  M3U_URL: "http://provider.com:8000/get.php?username=john&password=secret&type=m3u_plus"
  
  # Xtream API configuration (extracted from M3U URL)
  XTREAM_USER: "john"
  XTREAM_PASSWORD: "secret"
  XTREAM_BASE_URL: "http://provider.com:8000"
  XTREAM_API_GET: false
  
  # Proxy authentication
  USER: "my_proxy_user"
  PASSWORD: "my_proxy_password"
```

### **Xtream Codes Method** (API Generated)
```yaml
environment:
  # Xtream API configuration
  XTREAM_USER: "john"
  XTREAM_PASSWORD: "secret"
  XTREAM_BASE_URL: "http://provider.com:8000"
  XTREAM_API_GET: true
  
  # Proxy authentication
  USER: "my_proxy_user"
  PASSWORD: "my_proxy_password"
```

## **🎬 Benefits by Method**

### **M3U URL Benefits**:
- ✅ Simple setup with just a URL
- ✅ Works with any M3U provider
- ✅ Fallback option if API doesn't work
- ✅ Auto-detection of Xtream credentials

### **Xtream Codes Benefits**:
- ✅ Full API access (categories, VOD, series)
- ✅ Dynamic playlist generation
- ✅ Better metadata and organization
- ✅ EPG and additional features
- ✅ More efficient than M3U parsing

## **📋 Complete Setup Example**

```bash
# Clone and run setup
git clone https://github.com/incmve/iptv-proxy.git
cd iptv-proxy
chmod +x setup-saltbox.sh
./setup-saltbox.sh
```

**Sample interaction**:
```
Choose option [1-2]: 2

--- Xtream Codes Configuration ---
Xtream username: myuser123
Xtream password: [hidden]
Xtream base URL (e.g., http://provider.com:8000): http://myprovider.tv:8000

--- General Configuration ---
Enter proxy username [iptv_user]: admin
Enter proxy password [randomly generated]: [hidden]
Enter your domain (leave empty if using IP access): mydomain.com
Enable 5-second buffering? [Y/n]: Y
Use Traefik reverse proxy? [Y/n]: Y
```

## **🌐 Access URLs**

After setup, you'll get URLs like:

**M3U Playlist**:
- Direct: `http://server-ip:8080/iptv.m3u?username=admin&password=***`
- Traefik: `https://iptv.mydomain.com/iptv.m3u?username=admin&password=***`

**Xtream API** (if configured):
- Categories: `https://iptv.mydomain.com/player_api.php?username=admin&password=***&action=get_live_categories`
- Streams: `https://iptv.mydomain.com/player_api.php?username=admin&password=***&action=get_live_streams`
- VOD: `https://iptv.mydomain.com/player_api.php?username=admin&password=***&action=get_vod_categories`

## **🔄 Migration Guide**

If you have an existing M3U setup and want to switch to Xtream API:

1. Stop the container: `docker compose down`
2. Edit `/opt/iptv/docker-compose.yml`
3. Add Xtream configuration, set `XTREAM_API_GET: true`
4. Comment out or remove `M3U_URL`
5. Restart: `docker compose up -d`

## **🆘 Troubleshooting**

**Script fails with "Invalid selection"**:
- Make sure to enter `1` or `2` exactly

**M3U URL not detected properly**:
- Ensure URL contains `username=` and `password=` parameters
- Check URL encoding/special characters

**Xtream API not working**:
- Verify base URL format (no trailing slash)
- Test credentials with your provider first
- Check container logs: `docker compose logs -f iptv`

The updated script makes setup much more intuitive and provides better configuration options for different provider types!
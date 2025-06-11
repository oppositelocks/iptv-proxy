#!/bin/bash

# IPTV Proxy Saltbox Setup Script
# This script automates the deployment of IPTV Proxy on Saltbox

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="iptv"
APP_DIR="/opt/${APP_NAME}"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons."
        print_status "Please run as a regular user with sudo access."
        exit 1
    fi
}

# Check if Saltbox is installed
check_saltbox() {
    if ! docker network ls | grep -q saltbox; then
        print_error "Saltbox network not found. Please ensure Saltbox is properly installed."
        exit 1
    fi
    print_success "Saltbox network detected"
}

# Prompt for configuration
get_configuration() {
    print_status "=== IPTV Proxy Configuration ==="
    echo
    
    # Ask for configuration method first
    print_status "How do you want to configure your IPTV source?"
    echo "1) M3U URL (Direct playlist URL)"
    echo "2) Xtream Codes (Username/Password API)"
    echo
    read -p "Choose option [1-2]: " CONFIG_METHOD
    
    case $CONFIG_METHOD in
        1)
            print_status "Selected: M3U URL Configuration"
            setup_m3u_config
            ;;
        2)
            print_status "Selected: Xtream Codes Configuration"
            setup_xtream_config
            ;;
        *)
            print_error "Invalid selection. Please choose 1 or 2."
            exit 1
            ;;
    esac
    
    # Common configuration
    setup_common_config
}

# M3U URL configuration
setup_m3u_config() {
    echo
    print_status "--- M3U URL Configuration ---"
    
    # M3U URL
    read -p "Enter your IPTV M3U URL: " M3U_URL
    if [[ -z "$M3U_URL" ]]; then
        print_error "M3U URL is required"
        exit 1
    fi
    
    # Check if URL contains Xtream parameters and offer to extract them
    if [[ "$M3U_URL" =~ username=([^&]+).*password=([^&]+) ]]; then
        DETECTED_USERNAME="${BASH_REMATCH[1]}"
        DETECTED_PASSWORD="${BASH_REMATCH[2]}"
        
        print_status "Detected Xtream credentials in M3U URL:"
        echo "  Username: $DETECTED_USERNAME"
        echo "  Password: $DETECTED_PASSWORD"
        echo
        
        read -p "Do you want to enable Xtream API features with these credentials? [Y/n]: " ENABLE_XTREAM_FROM_M3U
        if [[ "$ENABLE_XTREAM_FROM_M3U" =~ ^[Yy]?$ ]]; then
            XTREAM_USER="$DETECTED_USERNAME"
            XTREAM_PASSWORD="$DETECTED_PASSWORD"
            
            # Extract base URL from M3U URL
            if [[ "$M3U_URL" =~ (https?://[^/]+) ]]; then
                DETECTED_BASE_URL="${BASH_REMATCH[1]}"
                read -p "Xtream base URL [$DETECTED_BASE_URL]: " XTREAM_BASE_URL
                XTREAM_BASE_URL=${XTREAM_BASE_URL:-$DETECTED_BASE_URL}
                
                read -p "Generate M3U from Xtream API instead of direct URL? [y/N]: " XTREAM_API_GET
                if [[ "$XTREAM_API_GET" =~ ^[Yy]$ ]]; then
                    XTREAM_API_GET="true"
                    M3U_URL=""  # Clear M3U URL since we'll use API
                    print_status "Will generate M3U playlist from Xtream API"
                else
                    XTREAM_API_GET="false"
                fi
            fi
        fi
    fi
}

# Xtream Codes configuration
setup_xtream_config() {
    echo
    print_status "--- Xtream Codes Configuration ---"
    
    # Xtream credentials
    read -p "Xtream username: " XTREAM_USER
    if [[ -z "$XTREAM_USER" ]]; then
        print_error "Xtream username is required"
        exit 1
    fi
    
    read -s -p "Xtream password: " XTREAM_PASSWORD
    echo
    if [[ -z "$XTREAM_PASSWORD" ]]; then
        print_error "Xtream password is required"
        exit 1
    fi
    
    read -p "Xtream base URL (e.g., http://provider.com:8000): " XTREAM_BASE_URL
    if [[ -z "$XTREAM_BASE_URL" ]]; then
        print_error "Xtream base URL is required"
        exit 1
    fi
    
    # Default to API generation for Xtream setup
    XTREAM_API_GET="true"
    M3U_URL=""  # No direct M3U URL needed
    
    print_success "Xtream API configuration complete"
}

# Common configuration for both methods
setup_common_config() {
    echo
    print_status "--- General Configuration ---"
    
    # Authentication
    read -p "Enter proxy username [iptv_user]: " PROXY_USER
    PROXY_USER=${PROXY_USER:-iptv_user}
    
    read -s -p "Enter proxy password [randomly generated]: " PROXY_PASSWORD
    echo
    if [[ -z "$PROXY_PASSWORD" ]]; then
        PROXY_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        print_status "Generated password: $PROXY_PASSWORD"
    fi
    
    # Domain (optional)
    read -p "Enter your domain (leave empty if using IP access): " DOMAIN
    if [[ -n "$DOMAIN" ]]; then
        print_status "Will use subdomain: iptv.${DOMAIN}"
    fi
    
    # Buffer settings
    read -p "Enable buffering? [Y/n]: " ENABLE_BUFFER
    ENABLE_BUFFER=${ENABLE_BUFFER:-Y}
    if [[ "$ENABLE_BUFFER" =~ ^[Yy]$ ]]; then
        BUFFER_ENABLED="true"
        read -p "Buffer duration in seconds [10]: " BUFFER_DURATION
        BUFFER_DURATION=${BUFFER_DURATION:-10}
        read -p "Pre-buffer seconds before playback [3]: " BUFFER_PRELOAD
        BUFFER_PRELOAD=${BUFFER_PRELOAD:-3}
        read -p "Max buffer memory per stream in MB [100]: " BUFFER_MAX_MEMORY
        BUFFER_MAX_MEMORY=${BUFFER_MAX_MEMORY:-100}
    else
        BUFFER_ENABLED="false"
        BUFFER_DURATION="0"
        BUFFER_PRELOAD="0"
        BUFFER_MAX_MEMORY="0"
    fi
    
    # Traefik
    if [[ -n "$DOMAIN" ]]; then
        read -p "Use Traefik reverse proxy? [Y/n]: " USE_TRAEFIK
        USE_TRAEFIK=${USE_TRAEFIK:-Y}
    else
        USE_TRAEFIK="n"
    fi
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    sudo mkdir -p "${APP_DIR}"/{config,playlists,logs}
    
    # Set proper permissions for the current user to write files
    sudo chown -R $USER:$USER "${APP_DIR}"
    sudo chmod -R 755 "${APP_DIR}"
    
    print_success "Directories created: ${APP_DIR}"
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    if [[ ! -f "Dockerfile" ]]; then
        print_error "Dockerfile not found. Please run this script from the iptv-proxy repository."
        exit 1
    fi
    
    docker build -t iptv-proxy:latest . || {
        print_error "Failed to build Docker image"
        exit 1
    }
    
    print_success "Docker image built successfully"
}

# Generate docker-compose.yml
generate_compose() {
    print_status "Generating docker-compose.yml..."
    
    cat > "${COMPOSE_FILE}" << EOF
version: "3.8"

services:
  ${APP_NAME}:
    image: iptv-proxy:latest
    container_name: ${APP_NAME}
    restart: unless-stopped
    
    networks:
      - saltbox
    
    environment:
      # Saltbox required environment variables
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
      
      # Port and hostname
      PORT: 8080
      HOSTNAME: ${APP_NAME}
      
      # Authentication
      USER: "${PROXY_USER}"
      PASSWORD: "${PROXY_PASSWORD}"
      
      # Buffer configuration
      BUFFER_ENABLED: ${BUFFER_ENABLED}
      BUFFER_DURATION: ${BUFFER_DURATION}
      BUFFER_PRELOAD: ${BUFFER_PRELOAD}
      BUFFER_MAX_MEMORY: ${BUFFER_MAX_MEMORY}
      
      # Additional settings
      GIN_MODE: release
      M3U_CACHE_EXPIRATION: 1
      M3U_FILE_NAME: "iptv.m3u"
EOF

    # Add M3U URL if provided (M3U method or fallback)
    if [[ -n "${M3U_URL:-}" ]]; then
        cat >> "${COMPOSE_FILE}" << EOF
      
      # M3U configuration
      M3U_URL: "${M3U_URL}"
EOF
    fi

    # Add Xtream configuration if provided
    if [[ -n "${XTREAM_USER:-}" ]]; then
        cat >> "${COMPOSE_FILE}" << EOF
      
      # Xtream API configuration
      XTREAM_USER: "${XTREAM_USER}"
      XTREAM_PASSWORD: "${XTREAM_PASSWORD}"
      XTREAM_BASE_URL: "${XTREAM_BASE_URL}"
      XTREAM_API_GET: ${XTREAM_API_GET:-false}
EOF
    fi

    # Add volumes
    cat >> "${COMPOSE_FILE}" << EOF
    
    volumes:
      - "${APP_DIR}/config:/config"
      - "/etc/localtime:/etc/localtime:ro"
      - "${APP_DIR}/playlists:/playlists:ro"
EOF

    # Add ports if not using Traefik
    if [[ ! "$USE_TRAEFIK" =~ ^[Yy]$ ]]; then
        cat >> "${COMPOSE_FILE}" << EOF
    
    ports:
      - "8080:8080"
EOF
    fi

    # Add labels
    cat >> "${COMPOSE_FILE}" << EOF
    
    labels:
      - "com.github.saltbox.saltbox_managed=true"
EOF

    # Add Traefik labels if using Traefik
    if [[ "$USE_TRAEFIK" =~ ^[Yy]$ ]] && [[ -n "$DOMAIN" ]]; then
        cat >> "${COMPOSE_FILE}" << EOF
      - "traefik.enable=true"
      - "traefik.http.routers.${APP_NAME}.rule=Host(\`iptv.${DOMAIN}\`)"
      - "traefik.http.routers.${APP_NAME}.tls=true"
      - "traefik.http.routers.${APP_NAME}.tls.certresolver=cfdns"
      - "traefik.http.services.${APP_NAME}.loadbalancer.server.port=8080"
      - "traefik.http.routers.${APP_NAME}.middlewares=secureHeaders@file"
EOF
    fi

    # Add networks
    cat >> "${COMPOSE_FILE}" << EOF

networks:
  saltbox:
    external: true
EOF

    print_success "docker-compose.yml generated"
}

# Deploy container
deploy_container() {
    print_status "Deploying container..."
    
    cd "${APP_DIR}"
    
    # Set proper permissions for Docker volumes (PUID=1000, PGID=1000)
    sudo chown -R 1000:1000 "${APP_DIR}/config" "${APP_DIR}/playlists" "${APP_DIR}/logs" 2>/dev/null || true
    
    # Start the container
    docker compose up -d || {
        print_error "Failed to start container"
        exit 1
    }
    
    # Wait a moment for container to start
    sleep 5
    
    # Check if container is running
    if docker compose ps | grep -q "Up"; then
        print_success "Container deployed successfully"
    else
        print_error "Container failed to start. Check logs:"
        docker compose logs ${APP_NAME}
        exit 1
    fi
}

# Display access information
show_access_info() {
    print_success "=== Deployment Complete ==="
    
    if [[ "$USE_TRAEFIK" =~ ^[Yy]$ ]] && [[ -n "$DOMAIN" ]]; then
        BASE_URL="https://iptv.${DOMAIN}"
    else
        SERVER_IP=$(hostname -I | awk '{print $1}')
        BASE_URL="http://${SERVER_IP}:8080"
    fi
    
    echo
    print_status "Configuration Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show configuration method
    if [[ "$CONFIG_METHOD" == "1" ]]; then
        echo "📋 Configuration: M3U URL"
        if [[ -n "${M3U_URL:-}" ]]; then
            echo "   Source: Direct M3U URL"
        else
            echo "   Source: Generated from Xtream API"
        fi
    elif [[ "$CONFIG_METHOD" == "2" ]]; then
        echo "📋 Configuration: Xtream Codes API"
        echo "   Source: Generated from Xtream API"
    fi
    
    echo "🔐 Proxy Username: ${PROXY_USER}"
    echo "🔑 Proxy Password: ${PROXY_PASSWORD}"
    
    if [[ -n "${XTREAM_USER:-}" ]]; then
        echo "👤 Xtream Username: ${XTREAM_USER}"
        echo "🏠 Xtream Base URL: ${XTREAM_BASE_URL}"
    fi
    
    echo
    print_status "Access URLs:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📺 M3U Playlist:"
    echo "   ${BASE_URL}/iptv.m3u?username=${PROXY_USER}&password=${PROXY_PASSWORD}"
    echo
    echo "📊 Buffer Statistics:"
    echo "   ${BASE_URL}/buffer-stats?username=${PROXY_USER}&password=${PROXY_PASSWORD}"
    
    if [[ -n "${XTREAM_USER:-}" ]]; then
        echo
        echo "🎬 Xtream API Endpoints:"
        echo "   ${BASE_URL}/player_api.php?username=${PROXY_USER}&password=${PROXY_PASSWORD}&action=get_live_categories"
        echo "   ${BASE_URL}/player_api.php?username=${PROXY_USER}&password=${PROXY_PASSWORD}&action=get_live_streams"
        echo "   ${BASE_URL}/player_api.php?username=${PROXY_USER}&password=${PROXY_PASSWORD}&action=get_vod_categories"
        echo "   ${BASE_URL}/player_api.php?username=${PROXY_USER}&password=${PROXY_PASSWORD}&action=get_series"
    fi
    
    echo
    print_status "Container Management:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   cd ${APP_DIR}"
    echo "   docker compose logs -f ${APP_NAME}    # View logs"
    echo "   docker compose restart ${APP_NAME}    # Restart container"
    echo "   docker compose down                   # Stop container"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    if [[ "$USE_TRAEFIK" =~ ^[Yy]$ ]]; then
        print_warning "Make sure your DNS record for iptv.${DOMAIN} points to your server!"
    fi
    
    print_status "Save this information securely!"
}

# Main installation flow
main() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    IPTV Proxy Saltbox Installer                 ║"
    echo "║                                                                  ║"
    echo "║  This script will install and configure IPTV Proxy for Saltbox  ║"
    echo "║                                                                  ║"
    echo "║  Supports:                                                       ║"
    echo "║  • M3U URL Configuration                                         ║"
    echo "║  • Xtream Codes API                                              ║"
    echo "║  • 5-Second Stream Buffering                                     ║"
    echo "║  • Traefik Integration                                           ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo
    
    # Run installation steps
    check_root
    check_saltbox
    get_configuration
    create_directories
    build_image
    generate_compose
    deploy_container
    show_access_info
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"
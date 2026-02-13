#!/bin/bash

################################################################################
# OpenClaw VM - Environment Setup Script (Openbox)
# 
# This script provisions a lightweight Ubuntu VM with:
# - Openbox desktop environment
# - OpenClaw AI agent and gateway
# - Essential desktop applications
# - Auto-login configuration
#
# Usage: sudo bash provision.sh
################################################################################

set -euo pipefail

# Configuration
export DEBIAN_FRONTEND=noninteractive
OPENCLAW_USER="${OPENCLAW_USER:-vagrant}"
OPENCLAW_HOME="/home/${OPENCLAW_USER}"
OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"
NODE_VERSION="22"

# Color output helpers
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $*"
}

print_header() {
    echo ""
    echo "=========================================="
    echo " $*"
    echo "=========================================="
}

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Verify user exists
if ! id "${OPENCLAW_USER}" &>/dev/null; then
    log_error "User '${OPENCLAW_USER}' does not exist"
    exit 1
fi

################################################################################
# Utility Functions
################################################################################

# Clean package cache to ensure fresh downloads
clean_package_cache() {
    log_info "Cleaning package cache to ensure fresh downloads..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

################################################################################
# Main Setup Steps
################################################################################

print_header "OpenClaw VM - Environment Setup (Openbox)"

# 0. Initial cleanup
log_step "[0/8] Preparing system..."
clean_package_cache

# 1. System update - ALWAYS update to latest
log_step "[1/8] Updating system packages to latest versions..."
log_info "Updating package lists..."
apt-get update -qq

log_info "Upgrading installed packages..."
apt-get upgrade -y

log_info "Performing distribution upgrade..."
apt-get dist-upgrade -y

log_info "Removing unnecessary packages..."
apt-get autoremove -y
apt-get autoclean -y

log_info "✓ System packages updated to latest versions"

# 2. Desktop environment - ALWAYS install/update
log_step "[2/8] Installing Openbox desktop environment..."
log_info "Installing Openbox and panel components..."

apt-get install -y \
    openbox \
    tint2 \
    pcmanfm \
    nitrogen \
    obconf \
    lxappearance \
    lightdm \
    lightdm-gtk-greeter \
    xorg \
    dbus-x11 \
    xfce4-terminal \
    x11-xserver-utils \
    xinit

log_info "✓ Openbox desktop environment installed"

# 3. VirtualBox Guest Additions - ALWAYS try to get latest
log_step "[3/8] Installing VirtualBox Guest Additions..."
if apt-get install -y virtualbox-guest-utils virtualbox-guest-x11 2>/dev/null; then
    log_info "✓ VirtualBox Guest Additions installed"
else
    log_warn "VirtualBox Guest Additions not available (not running in VirtualBox?)"
fi

# 4. Common desktop applications - ALWAYS update
log_step "[4/8] Installing common applications..."
log_info "Installing utilities and applications..."

apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    vim \
    nano \
    htop \
    net-tools \
    ca-certificates \
    gnupg \
    software-properties-common \
    apt-transport-https \
    libreoffice \
    vlc \
    thunar-archive-plugin \
    xarchiver \
    p7zip-full \
    mousepad \
    xfce4-screenshooter \
    evince \
    ristretto \
    gnome-system-monitor

log_info "✓ Common applications installed"

# 5. Google Chrome - ALWAYS download latest version
log_step "[5/8] Installing Google Chrome (latest version)..."
CHROME_DEB="/tmp/google-chrome-stable_current_amd64.deb"

# Remove old version if exists
if dpkg -l google-chrome-stable &>/dev/null; then
    log_info "Removing old Chrome version..."
    apt-get remove -y google-chrome-stable 2>/dev/null || true
fi

log_info "Downloading latest Google Chrome..."
if wget -q --show-progress -O "${CHROME_DEB}" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"; then
    log_info "Installing Google Chrome..."
    if dpkg -i "${CHROME_DEB}" 2>/dev/null || apt-get install -f -y; then
        CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null || echo "unknown")
        log_info "✓ Google Chrome installed: ${CHROME_VERSION}"
    else
        log_warn "Google Chrome installation had issues but continued"
    fi
    rm -f "${CHROME_DEB}"
else
    log_warn "Could not download Google Chrome"
fi

# 6. Snapd - ALWAYS update
log_step "[6/8] Installing snapd..."
apt-get install -y snapd
systemctl enable snapd 2>/dev/null || true
systemctl start snapd 2>/dev/null || true

# Wait for snapd to be ready
log_info "Waiting for snapd to initialize..."
sleep 5

log_info "✓ Snapd installed"

# 7. Node.js and OpenClaw - ALWAYS install latest versions
log_step "[7/8] Installing Node.js ${NODE_VERSION} LTS and OpenClaw..."

# Remove old Node.js versions if present
log_info "Checking Node.js installation..."
if command -v node &>/dev/null; then
    CURRENT_NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
    log_info "Current Node.js version: ${CURRENT_NODE_VERSION}"
    log_info "Ensuring latest Node.js ${NODE_VERSION}.x is installed..."
fi

# Install/update Node.js from NodeSource
log_info "Adding NodeSource repository..."
curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -

log_info "Installing Node.js..."
apt-get install -y nodejs

NODE_INSTALLED_VERSION=$(node --version)
NPM_INSTALLED_VERSION=$(npm --version)
log_info "✓ Node.js installed: ${NODE_INSTALLED_VERSION}"
log_info "✓ npm version: ${NPM_INSTALLED_VERSION}"

# Install/update pnpm - ALWAYS get latest
log_info "Installing/updating pnpm (latest version)..."
npm install -g pnpm@latest

PNPM_VERSION=$(pnpm --version 2>/dev/null || echo "unknown")
log_info "✓ pnpm installed: ${PNPM_VERSION}"

# Install/update OpenClaw - ALWAYS get latest
log_info "Installing/updating OpenClaw (latest version)..."
npm install -g openclaw@latest --force

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "version check failed")
log_info "✓ OpenClaw installed: ${OPENCLAW_VERSION}"

# Create OpenClaw gateway systemd service
log_info "Creating OpenClaw gateway systemd service..."
cat > /etc/systemd/system/openclaw-gateway.service <<SYSTEMD
[Unit]
Description=OpenClaw Gateway Daemon
Documentation=https://openclaw.ai
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${OPENCLAW_USER}
Group=${OPENCLAW_USER}
Environment=HOME=${OPENCLAW_HOME}
Environment=NODE_ENV=production
WorkingDirectory=${OPENCLAW_HOME}
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${OPENCLAW_HOME}

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable openclaw-gateway.service
log_info "✓ OpenClaw gateway service configured"

# 8. Desktop configuration
log_step "[8/8] Configuring desktop environment..."

# Configure LightDM autologin
log_info "Configuring LightDM autologin..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<EOF
[Seat:*]
autologin-user=${OPENCLAW_USER}
autologin-user-timeout=0
user-session=openbox
EOF
log_info "✓ LightDM autologin configured"

# Set up Openbox configuration
log_info "Setting up Openbox configuration for user '${OPENCLAW_USER}'..."
sudo -u "${OPENCLAW_USER}" mkdir -p "${OPENCLAW_HOME}/.config/openbox"

# Copy default config if not exists or force update
if [[ -d /etc/xdg/openbox ]]; then
    cp -r /etc/xdg/openbox/* "${OPENCLAW_HOME}/.config/openbox/" 2>/dev/null || true
fi

# Create autostart script
cat > "${OPENCLAW_HOME}/.config/openbox/autostart" <<'AUTOSTART'
#!/bin/bash
# OpenClaw VM Openbox autostart
# Panel with taskbar, clock, and system tray
tint2 &
# Desktop manager (icons, background, file handling)
pcmanfm --desktop &
# Optional: Start OpenClaw gateway automatically
# systemctl --user start openclaw-gateway &
AUTOSTART

chmod +x "${OPENCLAW_HOME}/.config/openbox/autostart"
chown -R "${OPENCLAW_USER}:${OPENCLAW_USER}" "${OPENCLAW_HOME}/.config/openbox"

# Create desktop shortcuts directory
sudo -u "${OPENCLAW_USER}" mkdir -p "${OPENCLAW_HOME}/Desktop"

# Configure PCManFM to execute desktop files on click
log_info "Configuring PCManFM for desktop file execution..."
sudo -u "${OPENCLAW_USER}" mkdir -p "${OPENCLAW_HOME}/.config/pcmanfm/default"
cat > "${OPENCLAW_HOME}/.config/pcmanfm/default/pcmanfm.conf" <<'PCMANFM_CONF'
[config]
bm_open_method=0

[volume]
mount_on_startup=1
mount_removable=1
autorun=1

[ui]
always_show_tabs=0
max_tab_chars=32
win_width=640
win_height=480
splitter_pos=150
media_in_new_tab=0
desktop_folder_new_win=0
change_tab_on_drop=1
close_on_unmount=1
focus_previous=0
side_pane_mode=places
view_mode=icon
show_hidden=0
sort=name;ascending;
toolbar=newtab;navigation;home;
show_statusbar=1
pathbar_mode_buttons=0

[desktop]
wallpaper_mode=stretch
wallpaper_common=1
desktop_bg=#000000
desktop_fg=#ffffff
desktop_shadow=#000000
show_wm_menu=0
sort=mtime;ascending;
show_documents=0
show_trash=1
show_mounts=1

[desktop-ui]
always_show_tabs=0
max_tab_chars=32
win_width=640
win_height=480
splitter_pos=150
media_in_new_tab=0
desktop_folder_new_win=0
change_tab_on_drop=1
close_on_unmount=1
focus_previous=0
side_pane_mode=places
view_mode=icon
show_hidden=0
sort=name;ascending;
toolbar=newtab;navigation;home;
show_statusbar=1
pathbar_mode_buttons=0
PCMANFM_CONF
chown -R "${OPENCLAW_USER}:${OPENCLAW_USER}" "${OPENCLAW_HOME}/.config/pcmanfm"

# OpenClaw Setup launcher
log_info "Creating desktop shortcuts..."
cat > "${OPENCLAW_HOME}/Desktop/openclaw-setup.desktop" <<'LAUNCHER'
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenClaw Setup
Comment=Run OpenClaw onboarding wizard
Exec=xfce4-terminal --maximize --title="OpenClaw Setup" --command="bash -c 'echo \"========================================\"; echo \" OpenClaw Onboarding Wizard\"; echo \"========================================\"; echo \"\"; openclaw onboard --install-daemon; echo \"\"; echo \"Setup complete! Press Enter to close...\"; read'"
Icon=utilities-terminal
Terminal=false
Categories=Development;System;
StartupNotify=true
LAUNCHER
chmod +x "${OPENCLAW_HOME}/Desktop/openclaw-setup.desktop"

# OpenClaw Dashboard launcher
cat > "${OPENCLAW_HOME}/Desktop/openclaw-dashboard.desktop" <<LAUNCHER
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenClaw Dashboard
Comment=Open OpenClaw Gateway Dashboard in browser
Exec=google-chrome-stable --new-window http://127.0.0.1:${OPENCLAW_PORT}/
Icon=web-browser
Terminal=false
Categories=Network;Development;
StartupNotify=true
LAUNCHER
chmod +x "${OPENCLAW_HOME}/Desktop/openclaw-dashboard.desktop"

# OpenClaw TUI launcher
cat > "${OPENCLAW_HOME}/Desktop/openclaw-tui.desktop" <<'LAUNCHER'
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenClaw TUI
Comment=Launch OpenClaw Terminal User Interface
Exec=xfce4-terminal --maximize --title="OpenClaw TUI" --command="bash -c 'openclaw || bash'"
Icon=utilities-terminal
Terminal=false
Categories=Development;System;
StartupNotify=true
LAUNCHER
chmod +x "${OPENCLAW_HOME}/Desktop/openclaw-tui.desktop"

# Gateway Control launcher
cat > "${OPENCLAW_HOME}/Desktop/openclaw-gateway-control.desktop" <<'LAUNCHER'
[Desktop Entry]
Version=1.0
Type=Application
Name=Gateway Control
Comment=Start/Stop/Restart OpenClaw Gateway service
Exec=xfce4-terminal --title="OpenClaw Gateway Control" --command="bash -c 'echo \"========================================\"; echo \" OpenClaw Gateway Control\"; echo \"========================================\"; echo \"\"; echo \"1) Start gateway\"; echo \"2) Stop gateway\"; echo \"3) Restart gateway\"; echo \"4) Check status\"; echo \"5) View logs\"; echo \"\"; read -p \"Choose option (1-5): \" opt; case $opt in 1) sudo systemctl start openclaw-gateway && echo \"Gateway started\";; 2) sudo systemctl stop openclaw-gateway && echo \"Gateway stopped\";; 3) sudo systemctl restart openclaw-gateway && echo \"Gateway restarted\";; 4) sudo systemctl status openclaw-gateway;; 5) sudo journalctl -u openclaw-gateway -f;; *) echo \"Invalid option\";; esac; echo \"\"; read -p \"Press Enter to close...\"'"
Icon=system-run
Terminal=false
Categories=System;
StartupNotify=true
LAUNCHER
chmod +x "${OPENCLAW_HOME}/Desktop/openclaw-gateway-control.desktop"

# Update Check launcher
cat > "${OPENCLAW_HOME}/Desktop/openclaw-update.desktop" <<'LAUNCHER'
[Desktop Entry]
Version=1.0
Type=Application
Name=Update OpenClaw
Comment=Check for and install OpenClaw updates
Exec=xfce4-terminal --title="OpenClaw Update" --command="bash -c 'echo \"===========================================\"; echo \" OpenClaw Update Tool\"; echo \"===========================================\"; echo \"\"; echo \"Current version:\"; openclaw --version; echo \"\"; echo \"Checking for updates...\"; echo \"\"; npm update -g openclaw@latest; echo \"\"; echo \"New version:\"; openclaw --version; echo \"\"; echo \"===========================================\"; echo \" Update complete!\"; echo \"===========================================\"; echo \"\"; read -p \"Press Enter to close...\"'"
Icon=system-software-update
Terminal=false
Categories=System;
StartupNotify=true
LAUNCHER
chmod +x "${OPENCLAW_HOME}/Desktop/openclaw-update.desktop"

# README file
cat > "${OPENCLAW_HOME}/Desktop/README.txt" <<'README'
================================================================================
                    OpenClaw VM - Safe Testing Environment
================================================================================

Welcome! This VM provides an isolated environment for running and testing
OpenClaw (https://openclaw.ai), the open-source AI agent framework.

┌─────────────────────────────────────────────────────────────────────────────┐
│ GETTING STARTED                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

1. **Initial Setup**
   → Double-click "OpenClaw Setup" to run the onboarding wizard
   → Follow the prompts to configure your API keys and settings

2. **Start the Gateway**
   → Use "Gateway Control" launcher to manage the service
   → Or run: sudo systemctl start openclaw-gateway

3. **Access the Dashboard**
   → Double-click "OpenClaw Dashboard" to open in browser
   → Or visit: http://127.0.0.1:18789/

4. **Use the Terminal Interface**
   → Double-click "OpenClaw TUI" for the terminal interface
   → Or run: openclaw

5. **Keep OpenClaw Updated**
   → Double-click "Update OpenClaw" to get the latest version
   → Or run: sudo npm install -g openclaw@latest

┌─────────────────────────────────────────────────────────────────────────────┐
│ DESKTOP ENVIRONMENT                                                         │
└─────────────────────────────────────────────────────────────────────────────┘

This VM uses Openbox, a lightweight window manager:
  • Right-click anywhere on desktop to open the application menu
  • Desktop icons are managed by PCManFM
  • Panel (tint2) shows taskbar, clock, and system tray
  • If icons aren't clickable, run: bash ~/Desktop/fix-desktop-files.sh

┌─────────────────────────────────────────────────────────────────────────────┐
│ USEFUL COMMANDS                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Service Management:
  sudo systemctl start openclaw-gateway      # Start gateway
  sudo systemctl stop openclaw-gateway       # Stop gateway
  sudo systemctl restart openclaw-gateway    # Restart gateway
  sudo systemctl status openclaw-gateway     # Check status
  sudo journalctl -u openclaw-gateway -f     # View live logs

OpenClaw CLI:
  openclaw --version                         # Check version
  openclaw --help                            # Show help
  openclaw onboard                           # Run setup wizard
  openclaw                                   # Launch TUI

Update Software:
  sudo npm install -g openclaw@latest        # Update OpenClaw
  sudo apt update && sudo apt upgrade -y     # Update system

┌─────────────────────────────────────────────────────────────────────────────┐
│ SYSTEM INFORMATION                                                          │
└─────────────────────────────────────────────────────────────────────────────┘

Credentials: vagrant / vagrant (auto-login enabled)
Gateway Port: 18789
Dashboard URL: http://127.0.0.1:18789/

Installed Software:
  • Node.js 22 LTS
  • OpenClaw (latest)
  • Google Chrome
  • LibreOffice
  • VLC Media Player
  • Various utilities

┌─────────────────────────────────────────────────────────────────────────────┐
│ TROUBLESHOOTING                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Gateway won't start:
  • Check logs: sudo journalctl -u openclaw-gateway -n 50
  • Verify OpenClaw is installed: openclaw --version
  • Try reinstalling: sudo npm install -g openclaw@latest

Can't access dashboard:
  • Ensure gateway is running: sudo systemctl status openclaw-gateway
  • Check if port is in use: sudo netstat -tlnp | grep 18789
  • Try restarting: sudo systemctl restart openclaw-gateway

Desktop icons not working:
  • Check file permissions: ls -la ~/Desktop/
  • Run fix script: bash ~/Desktop/fix-desktop-files.sh
  • Or manually: chmod +x ~/Desktop/*.desktop
  • Restart desktop: pkill pcmanfm && pcmanfm --desktop &

Need help:
  • Visit: https://openclaw.ai
  • Check documentation
  • Join community support channels

================================================================================
                              Enjoy using OpenClaw!
================================================================================
README

chmod 644 "${OPENCLAW_HOME}/Desktop/README.txt"

# Set ownership for all desktop files
chown -R "${OPENCLAW_USER}:${OPENCLAW_USER}" "${OPENCLAW_HOME}/Desktop"

# Mark all desktop files as trusted/executable for PCManFM
log_info "Marking desktop files as trusted..."
for desktop_file in "${OPENCLAW_HOME}/Desktop"/*.desktop; do
    if [[ -f "$desktop_file" ]]; then
        # Set executable permission
        chmod +x "$desktop_file"
        # Mark as trusted (prevents "untrusted application" warning)
        sudo -u "${OPENCLAW_USER}" gio set "$desktop_file" metadata::trusted true 2>/dev/null || true
    fi
done

log_info "✓ Desktop shortcuts created"

# Set graphical target
log_info "Setting graphical target..."
systemctl set-default graphical.target
systemctl enable lightdm

log_info "✓ Desktop environment configured"

# Final cleanup
log_info "Performing final cleanup..."
apt-get autoremove -y
apt-get autoclean -y
clean_package_cache

################################################################################
# Summary
################################################################################

print_header "Setup Complete!"

echo ""
log_info "Installation Summary:"
echo "  • System:          Updated to latest packages"
echo "  • Desktop:         Openbox with Tint2 panel"
echo "  • Node.js:         ${NODE_INSTALLED_VERSION}"
echo "  • npm:             ${NPM_INSTALLED_VERSION}"
echo "  • pnpm:            ${PNPM_VERSION}"
echo "  • OpenClaw:        ${OPENCLAW_VERSION}"
echo "  • Chrome:          $(google-chrome-stable --version 2>/dev/null || echo 'Installed')"
echo ""
log_info "The VM will start in graphical mode on next boot."
log_info "Auto-login is configured for user: ${OPENCLAW_USER}"
echo ""
log_info "Desktop shortcuts available:"
echo "  • OpenClaw Setup         - Initial configuration wizard"
echo "  • OpenClaw Dashboard     - Web interface"
echo "  • OpenClaw TUI           - Terminal interface"
echo "  • Gateway Control        - Service management"
echo "  • Update OpenClaw        - Get latest version"
echo "  • README.txt             - Detailed documentation"
echo ""
log_info "Gateway service: ${OPENCLAW_USER} can start with 'sudo systemctl start openclaw-gateway'"
echo ""

print_header "Ready to use OpenClaw!"
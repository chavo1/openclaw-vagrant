# OpenClaw VM - Safe Testing Environment

> An isolated environment for running and testing [OpenClaw](https://openclaw.ai), the open-source AI agent framework.

## 🚀 Quick Start

### First Time Setup

1. **Run Initial Setup**
   - Double-click `OpenClaw Setup` icon on desktop
   - Follow the onboarding wizard to configure API keys and settings

2. **Start the Gateway**
   ```bash
   sudo systemctl start openclaw-gateway
   ```
   Or use the `Gateway Control` desktop launcher

3. **Access the Dashboard**
   - Double-click `OpenClaw Dashboard` icon
   - Or visit: http://127.0.0.1:18789/

4. **Launch Terminal Interface**
   - Double-click `OpenClaw TUI` icon
   - Or run: `openclaw`

## 📦 What's Included

### System Components
- **OS**: Ubuntu 24.04 LTS
- **Desktop**: Openbox (lightweight window manager)
- **Panel**: Tint2 with taskbar, clock, and system tray
- **File Manager**: PCManFM

### Pre-installed Software
- **Node.js 22 LTS** with npm and pnpm
- **OpenClaw** (latest version)
- **Google Chrome**
- **LibreOffice** (full office suite)
- **VLC Media Player**
- **Development Tools**: git, vim, nano, htop
- **Archive Tools**: xarchiver, p7zip, unzip

## 🖥️ Desktop Environment

### Openbox Features
- **Right-click** anywhere on desktop to open application menu
- **Desktop icons** managed by PCManFM
- **Panel** (tint2) shows running applications, clock, and system tray
- **Lightweight** and fast performance

### Desktop Shortcuts

| Icon | Purpose |
|------|---------|
| 🔧 OpenClaw Setup | Initial configuration wizard |
| 🌐 OpenClaw Dashboard | Web interface (http://127.0.0.1:18789/) |
| 💻 OpenClaw TUI | Terminal user interface |
| ⚙️ Gateway Control | Start/stop/restart service manager |
| 🔄 Update OpenClaw | Get latest OpenClaw version |
| 📄 README.txt | This documentation |

## 🛠️ Common Commands

### Service Management

```bash
# Start the gateway
sudo systemctl start openclaw-gateway

# Stop the gateway
sudo systemctl stop openclaw-gateway

# Restart the gateway
sudo systemctl restart openclaw-gateway

# Check service status
sudo systemctl status openclaw-gateway

# View live logs
sudo journalctl -u openclaw-gateway -f

# Enable auto-start on boot
sudo systemctl enable openclaw-gateway

# Disable auto-start on boot
sudo systemctl disable openclaw-gateway
```

### OpenClaw CLI

```bash
# Check installed version
openclaw --version

# Show help and available commands
openclaw --help

# Run onboarding wizard
openclaw onboard

# Launch terminal interface
openclaw

# Run specific tasks
openclaw run <task-name>
```

### System Updates

```bash
# Update OpenClaw to latest version
sudo npm install -g openclaw@latest --force

# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js (if needed)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
```

## 🔐 System Information

| Setting | Value |
|---------|-------|
| **Username** | vagrant |
| **Password** | vagrant |
| **Auto-login** | Enabled |
| **Gateway Port** | 18789 |
| **Dashboard URL** | http://127.0.0.1:18789/ |
| **OpenClaw Config** | `~/.openclaw/` |

## 🐛 Troubleshooting

### Gateway Won't Start

**Problem**: Service fails to start or crashes immediately

**Solutions**:
```bash
# Check detailed error logs
sudo journalctl -u openclaw-gateway -n 50 --no-pager

# Verify OpenClaw is properly installed
openclaw --version

# Reinstall OpenClaw
sudo npm install -g openclaw@latest --force

# Check if port 18789 is already in use
sudo netstat -tlnp | grep 18789

# Try starting manually to see errors
openclaw gateway
```

### Can't Access Dashboard

**Problem**: Browser shows "Connection refused" or timeout

**Solutions**:
```bash
# Ensure gateway is running
sudo systemctl status openclaw-gateway

# Check if service is listening on port
sudo netstat -tlnp | grep 18789

# Restart the service
sudo systemctl restart openclaw-gateway

# Check firewall (if configured)
sudo ufw status
```

### Desktop Icons Not Working

**Problem**: Double-clicking icons does nothing

**Solutions**:
```bash
# Make desktop files executable
chmod +x ~/Desktop/*.desktop

# Restart PCManFM desktop manager
pkill pcmanfm
pcmanfm --desktop &

# Check file permissions
ls -la ~/Desktop/
```

### OpenClaw Command Not Found

**Problem**: Terminal shows "command not found: openclaw"

**Solutions**:
```bash
# Check if npm global bin is in PATH
echo $PATH | grep npm

# Add to PATH temporarily
export PATH=$PATH:/usr/bin

# Reinstall OpenClaw
sudo npm install -g openclaw@latest

# Verify installation location
which openclaw
npm list -g openclaw
```

### Node.js Version Issues

**Problem**: Wrong Node.js version or compatibility errors

**Solutions**:
```bash
# Check current version
node --version

# Update to Node.js 22 LTS
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt update
sudo apt install -y nodejs

# Verify npm version
npm --version
```

## 📚 Configuration Files

### Important Locations

```
~/.openclaw/              # OpenClaw configuration and data
~/.config/openbox/        # Openbox window manager config
  ├── autostart           # Programs to run on desktop start
  ├── menu.xml            # Right-click menu configuration
  └── rc.xml              # Openbox settings
~/Desktop/                # Desktop shortcuts and files
/etc/systemd/system/      # System services
  └── openclaw-gateway.service
```

### Customizing Autostart

Edit `~/.config/openbox/autostart` to add programs that run on login:

```bash
nano ~/.config/openbox/autostart

# Example additions:
# google-chrome-stable &    # Auto-start Chrome
# xfce4-terminal &          # Auto-start terminal
```

### Customizing the Panel

Edit tint2 panel configuration:

```bash
# Edit panel config
nano ~/.config/tint2/tint2rc

# Restart panel to apply changes
pkill tint2
tint2 &
```

## 🔄 Keeping Software Updated

### Automatic Updates

The provision script already installs the latest versions. For ongoing updates:

```bash
# Quick update script (create as ~/update-all.sh)
#!/bin/bash
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Updating OpenClaw..."
sudo npm install -g openclaw@latest --force

echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean

echo "All updates complete!"
openclaw --version
```

Make it executable:
```bash
chmod +x ~/update-all.sh
./update-all.sh
```

## 🌐 Network Configuration

### Port Forwarding (VirtualBox)

If you need to access the gateway from your host machine:

1. Open VirtualBox Manager
2. Select the VM → Settings → Network
3. Adapter 1 → Advanced → Port Forwarding
4. Add rule:
   - Name: `OpenClaw Gateway`
   - Protocol: `TCP`
   - Host Port: `18789`
   - Guest Port: `18789`

Then access from host: http://localhost:18789/

## 🔒 Security Notes

### Default Security Settings

The VM is configured with basic security:
- Service runs as non-root user (`vagrant`)
- systemd security hardening enabled
- Private tmp directory
- Read-only system protection
- No new privileges flag set

### Recommended Security Practices

```bash
# Change default password
passwd

# Enable firewall (optional, but recommended)
sudo apt install -y ufw
sudo ufw allow 18789/tcp  # OpenClaw gateway
sudo ufw allow 22/tcp     # SSH (if needed)
sudo ufw enable

# Review active services
systemctl list-units --type=service --state=running
```

## 🆘 Getting Help

- **Official Documentation**: https://openclaw.ai/docs
- **GitHub Issues**: https://github.com/openclaw/openclaw
- **Community Support**: Join OpenClaw community channels

## 📝 Tips & Best Practices

### Performance Optimization

```bash
# Check resource usage
htop

# Monitor OpenClaw process
ps aux | grep openclaw

# Check disk space
df -h
du -sh ~/.openclaw/
```

### Backup Your Configuration

```bash
# Backup OpenClaw config
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw/

# Restore from backup
tar -xzf openclaw-backup-YYYYMMDD.tar.gz -C ~/
```

### Development Workflow

```bash
# Create a project directory
mkdir -p ~/openclaw-projects
cd ~/openclaw-projects

# Initialize a new project
openclaw init my-project

# Work with git
git init
git add .
git commit -m "Initial commit"
```

## 🎯 Next Steps

1. **Configure API Keys**: Run `openclaw onboard` to set up your AI provider credentials
2. **Explore Examples**: Check OpenClaw documentation for example workflows
3. **Create Custom Tasks**: Define your own automation tasks
4. **Join Community**: Connect with other OpenClaw users for tips and support

---

**Version**: 1.0.0  
**Last Updated**: 2024  
**Maintained By**: OpenClaw VM Team

Enjoy using OpenClaw! 🚀
# Installation Guide - Dynamic Theming Dotfiles

## Overview

This guide covers the complete installation process for the Dynamic Theming Dotfiles system on Arch Linux. The system provides AI-powered theme generation using local LLaVA models with comprehensive desktop environment integration.

## Prerequisites

### System Requirements
- **Operating System**: Minimal Arch Linux installation
- **Internet Connection**: Required for package downloads and initial setup
- **User Account**: Non-root user with sudo privileges
- **Storage Space**: ~2GB for dependencies and AI models
- **RAM**: Minimum 4GB recommended for LLaVA processing

### Before Installation
1. **Complete Base Arch Installation**: Ensure you have a working Arch Linux system
2. **Enable Network**: Verify internet connectivity with `ping google.com`
3. **Update System**: Run `sudo pacman -Syu` to ensure latest packages
4. **Install Git**: `sudo pacman -S git` (if not already installed)

## Installation Methods

### Method 1: One-Command Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/cursordots.git
cd cursordots

# Run the post-install script
./post-install.sh
```

**What This Does:**
- Installs all required packages and dependencies
- Configures Wayland/Hyprland environment
- Sets up LLaVA AI system for theme generation
- Installs and configures all dotfiles
- Creates directory structure and symlinks
- Configures system services (audio, networking, etc.)
- Sets fish as default shell
- Generates initial theme

### Method 2: Manual Installation

If you prefer to understand each step or need to customize the installation:

#### Step 1: System Update
```bash
sudo pacman -Syu
```

#### Step 2: Install Base Packages
```bash
sudo pacman -S --needed base-devel git wget curl unzip tar fish \
    hyprland hyprland-protocols xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland wayland wayland-protocols wlroots \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    pavucontrol playerctl networkmanager nm-connection-editor \
    bluez bluez-utils blueman thunar thunar-volman gvfs \
    kitty foot btop imv mpv brightnessctl grim slurp swappy \
    wl-clipboard cliphist polkit-gnome ttf-jetbrains-mono-nerd \
    noto-fonts noto-fonts-emoji jq file-roller unrar p7zip
```

#### Step 3: Install Wayland Applications
```bash
sudo pacman -S --needed waybar dunst fuzzel swww swaylock-effects \
    swayidle xdg-desktop-portal-wlr imv
```

#### Step 4: Install Ollama and LLaVA
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Enable and start Ollama service
sudo systemctl enable ollama
sudo systemctl start ollama

# Install LLaVA model
ollama pull llava-llama3:8b
```

#### Step 5: Configure Services
```bash
# Enable NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Enable Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Add fish to shells and set as default
echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s "$(which fish)"
```

#### Step 6: Install Dotfiles
```bash
# Run the symlink manager
./scripts/management/symlink-manager.sh --install

# Install fonts and icons
./scripts/install/fonts-icons.sh

# Make scripts executable and add to PATH
find theme-engine -name "*.sh" -exec chmod +x {} \;
mkdir -p ~/.local/bin
ln -sf "$PWD/theme-engine/wallpaper-picker.sh" ~/.local/bin/wallpaper-picker
ln -sf "$PWD/theme-engine/theme-applier.sh" ~/.local/bin/theme-applier
```

## Post-Installation Configuration

### 1. Reboot System
```bash
sudo reboot
```
This ensures all services and shell changes take effect.

### 2. Start Hyprland
After logging in, start Hyprland from your login manager or TTY:
```bash
Hyprland
```

### 3. Initial Theme Setup
1. Press `Super+W` to open wallpaper picker
2. Add wallpapers to `~/Pictures/Wallpapers/` if none exist
3. Select a wallpaper to generate your first theme
4. The system will automatically apply the theme across all applications

### 4. Verify Installation
Test that all components are working:
```bash
# Check if all tools are available
command -v yay
command -v pacui
command -v ollama
command -v wallpaper-picker
command -v theme-applier

# Test theme generation
theme-applier --fallback

# Check services
systemctl status ollama
systemctl status NetworkManager
systemctl status bluetooth
```

## Package Management Tools

The system includes two package management tools:

### yay (AUR Helper)
```bash
# Install AUR packages
yay package-name

# Update all packages (system + AUR)
yay -Syu

# Search packages
yay -Ss search-term
```

### pacui (Package Manager UI)
```bash
# Launch interactive package manager
pacui

# Or use the alias
pui
```

## Directory Structure

After installation, your home directory will include:

```
~/
├── .config/
│   ├── hyprland/           # Hyprland configuration
│   ├── waybar/             # Status bar configurations
│   ├── kitty/              # Kitty terminal config
│   ├── foot/               # Foot terminal config
│   ├── fish/               # Fish shell configuration
│   ├── dunst/              # Notification configuration
│   ├── fuzzel/             # Launcher configuration
│   ├── gtk-3.0/            # GTK theming
│   └── btop/               # System monitor config
├── .cache/
│   ├── themes/             # Generated theme files
│   ├── wallpapers/         # Wallpaper analysis cache
│   ├── thumbnails/         # Wallpaper thumbnails
│   └── logs/               # System logs
├── .local/bin/             # Theme scripts in PATH
└── Pictures/
    ├── Wallpapers/         # Your wallpaper collection
    └── Screenshots/        # Screenshot directory
```

## Troubleshooting Installation Issues

### Common Issues

#### 1. Ollama Connection Failed
```bash
# Check Ollama service
sudo systemctl status ollama

# Restart if needed
sudo systemctl restart ollama

# Test connection
curl http://localhost:11434/api/tags
```

#### 2. LLaVA Model Not Found
```bash
# List available models
ollama list

# Install backup model
ollama pull llava:7b

# Test model
ollama run llava:7b "describe this image" < /path/to/test/image.jpg
```

#### 3. Fish Shell Not Default
```bash
# Check current shell
echo $SHELL

# Verify fish in shells file
grep fish /etc/shells

# Change shell manually
chsh -s $(which fish)
```

#### 4. Symlinks Not Working
```bash
# Check symlink status
ls -la ~/.config/hyprland

# Re-run symlink manager
./scripts/management/symlink-manager.sh --install --force
```

#### 5. Missing Dependencies
```bash
# Check for missing packages
pacman -Qi package-name

# Reinstall if needed
sudo pacman -S --needed package-name
```

### Re-running Installation

The installation script is designed to be run multiple times safely:

```bash
# Safe to re-run for updates or fixes
./post-install.sh
```

The script will:
- ✅ Skip already installed packages
- ✅ Only configure unconfigured services
- ✅ Preserve existing configurations
- ✅ Fix broken symlinks
- ✅ Update outdated components

### Getting Help

If you encounter issues:

1. **Check Logs**: Review logs in `~/.cache/logs/`
2. **Verify Dependencies**: Ensure all required packages are installed
3. **Test Components**: Use individual commands to isolate issues
4. **Re-run Script**: The post-install script can fix many issues
5. **Reset Configuration**: Use backup system to restore working state

### Backup and Recovery

The system automatically creates backups:

```bash
# List available backups
ls ~/.cache/backups/

# Restore from backup
./scripts/management/symlink-manager.sh --restore backup-timestamp

# Manual backup
./scripts/management/symlink-manager.sh --backup
```

## Next Steps

After successful installation:

1. **Customize Hyprland**: Edit `~/.config/hyprland/modules/` files
2. **Add Wallpapers**: Place images in `~/Pictures/Wallpapers/`
3. **Explore Theming**: Try different wallpapers and themes
4. **Configure Applications**: Customize individual app settings
5. **Learn Keybindings**: Familiarize yourself with the key shortcuts

For detailed information about the theming system, see [Theming System Flow](THEMING-SYSTEM-FLOW.md).

## System Requirements Check

Before installation, verify your system meets the requirements:

```bash
# Check available RAM
free -h

# Check disk space
df -h

# Verify internet connectivity
ping -c 3 google.com

# Check Arch Linux version
cat /etc/arch-release
```

The installation should complete successfully on any properly configured minimal Arch Linux system with the above prerequisites met. 
# Dynamic Theming Dotfiles Suite for Arch Linux

A comprehensive, production-ready dynamic theming system for Arch Linux using Hyprland with MaterialYou-style theming powered by local LLaVA AI.

## 🌟 Features

### 🎨 **Dynamic AI Theming**
- MaterialYou color palette extraction from wallpapers using local LLaVA/Ollama
- Atomic theme application across all applications
- Intelligent color harmony and contrast optimization
- Caching system for performance

### 🖥️ **Complete Desktop Environment**
- **Hyprland**: Modular configuration with Swedish keyboard layout
- **Dual Waybar Setup**: Primary (top) and secondary (bottom) status bars
- **Smart Wallpaper Picker**: Fuzzel-based with thumbnail preview
- **Comprehensive App Coverage**: All applications themed consistently

### 🎯 **Supported Applications**
- **Terminals**: Kitty, Foot
- **Shell**: Fish with dynamic prompt theming
- **System Monitor**: btop with custom themes
- **Notifications**: Dunst with contextual colors
- **Launcher**: Fuzzel with adaptive styling
- **GTK Applications**: GTK2/3/4 theming support
- **Status Bars**: Dual Waybar configuration

### 🏗️ **Architecture**
- **Modular Design**: DRY configuration with template system
- **Atomic Updates**: No half-themed states during transitions
- **Backup System**: Automatic configuration backups with restore
- **Error Handling**: Comprehensive validation and fallbacks

## 🚀 Quick Start

### Prerequisites
- Minimal Arch Linux installation
- Working internet connection
- Root access for package installation

### One-Command Installation

```bash
git clone https://github.com/yourusername/cursordots.git
cd cursordots
./post-install.sh
```

**The script is idempotent and safe to run multiple times!** It will:
1. Update system and install all dependencies (using `--needed` flags)
2. Configure Wayland/Hyprland environment
3. Install and configure LLaVA AI system
4. Set up audio (PipeWire) and networking
5. Install all dotfiles and configurations
6. Configure system services
7. Generate initial theme

### Re-running the Script
The installation script intelligently detects existing installations:
- ✅ **First Run**: Full installation
- ✅ **Re-runs**: Only updates/fixes what's needed
- ✅ **Safe**: Won't break existing configurations
- ✅ **Smart**: Skips already completed operations

### After Installation
1. Reboot your system
2. Log in and start Hyprland
3. Press `Super+W` to select wallpaper and generate theme
4. Enjoy your dynamically themed desktop!

## 🎮 Key Bindings

### Application Launchers
- `Super+Return` - Terminal (Kitty)
- `Super+Shift+Return` - Terminal (Foot)
- `Super+D` / `Super+Space` - Application launcher (Fuzzel)
- `Super+E` - File manager (Thunar)
- `Super+B` - Web browser (Firefox)
- `Super+I` - System monitor (btop)

### Window Management
- `Super+Q` - Close window
- `Super+V` - Toggle floating
- `Super+F` - Fullscreen
- `Super+H/J/K/L` - Move focus (Vim-style)
- `Super+Shift+H/J/K/L` - Move windows

### Theming Controls
- `Super+W` - Wallpaper picker and theme generation
- `Super+Shift+W` - Random theme
- `Super+R` - Reload current theme

### System Controls
- `Super+X` - Lock screen
- `Super+Shift+X` - Logout
- `Super+Delete` - Power off
- `Super+Shift+Delete` - Reboot

## 🛠️ System Architecture

### Directory Structure
```
cursordots/
├── theme-engine/           # Core theming scripts
│   ├── wallpaper-picker.sh
│   ├── color-extractor.sh
│   ├── theme-renderer.sh
│   └── theme-applier.sh
├── templates/              # Minimal theming templates
│   ├── terminals/
│   ├── waybar/
│   ├── hyprland/
│   ├── fish/
│   ├── gtk/
│   ├── dunst/
│   ├── fuzzel/
│   └── btop/
├── dotfiles/               # Main configurations
│   ├── hyprland/
│   ├── waybar/
│   ├── fish/
│   ├── foot/
│   ├── dunst/
│   ├── fuzzel/
│   ├── gtk-3.0/
│   └── btop/
├── scripts/
│   ├── install/            # Installation scripts
│   └── management/         # Configuration management
└── docs/                   # Documentation
```

### Theming Workflow
1. **Wallpaper Selection**: User chooses wallpaper via fuzzel with thumbnails
2. **Color Extraction**: LLaVA analyzes image and generates MaterialYou palette
3. **Template Processing**: Theme renderer processes all templates with new colors
4. **Atomic Application**: Theme applier updates all configurations simultaneously
5. **Service Reload**: All applications reload configurations with new theme

## 🎨 Customization

### Adding New Applications
1. Create minimal template in `templates/app-name/`
2. Add main configuration in `dotfiles/app-name/`
3. Update `theme-renderer.sh` to process new template
4. Update `theme-applier.sh` to reload the application

### Color Palette Variables
All templates use these standardized variables:
- `{{PRIMARY_COLOR}}`, `{{SECONDARY_COLOR}}`, `{{TERTIARY_COLOR}}`
- `{{ACCENT_COLOR}}`, `{{SURFACE_COLOR}}`
- `{{TEXT_PRIMARY}}`, `{{TEXT_SECONDARY}}`, `{{TEXT_DISABLED}}`
- `{{BACKGROUND_PRIMARY}}`, `{{BACKGROUND_SECONDARY}}`
- `{{SUCCESS_COLOR}}`, `{{WARNING_COLOR}}`, `{{ERROR_COLOR}}`
- `{{BORDER_COLOR}}`, `{{SHADOW_COLOR}}`, `{{CURSOR_COLOR}}`

### Monitor Configuration
Edit `dotfiles/hyprland/modules/monitors.conf` for your specific setup:
```bash
# Single monitor
monitor = eDP-1,1920x1080@60,0x0,1

# Dual monitor
monitor = eDP-1,1920x1080@60,0x0,1
monitor = HDMI-A-1,1920x1080@60,1920x0,1
```

## 🤖 AI System

### LLaVA Integration
- **Local Processing**: No cloud dependencies, complete privacy
- **Model Selection**: Automatic fallback between llava-llama3:8b and llava:7b
- **Intelligent Prompting**: Optimized prompts for MaterialYou color extraction
- **Caching System**: Hash-based caching for performance optimization

### Color Processing
- **Harmony Analysis**: Ensures color combinations work well together
- **Accessibility**: Maintains sufficient contrast ratios
- **Context Awareness**: Different color roles for different UI elements

## 📦 Dependencies

### System Packages
- **Wayland Environment**: hyprland, waybar, dunst, fuzzel, swww
- **Terminals**: kitty, foot
- **Audio**: pipewire, pipewire-pulse, pavucontrol
- **Utilities**: grim, slurp, wl-clipboard, brightnessctl
- **Development**: git, jq, curl, fish
- **Package Management**: yay (AUR helper), pacui (package manager UI)

### AI Dependencies
- **Ollama**: Local LLM runtime
- **LLaVA Models**: llava-llama3:8b (primary) or llava:7b (fallback)

## 🔧 Commands

### Theme Management
```bash
wallpaper-picker          # Interactive wallpaper selection
theme-applier            # Apply current theme
theme-applier --reload   # Reload current theme
theme-applier --random   # Apply random theme
theme-applier --fallback # Use fallback colors
```

### System Management
```bash
# Package management
yay                         # Interactive AUR helper
yay -Syu                   # Update system and AUR packages
pacui                      # User-friendly package manager interface
sudo pacman -Syu           # Update official packages only

# Symlink management
symlink-manager --install    # Install dotfiles
symlink-manager --backup    # Backup current configs
symlink-manager --restore   # Restore from backup

# Font and icon installation
fonts-icons.sh              # Install required fonts and icons
```

## 🎯 Performance

### Optimizations
- **Parallel Processing**: Simultaneous template rendering and application reloading
- **Caching Strategy**: Smart caching for wallpaper analysis and thumbnails
- **Atomic Updates**: Prevents visual inconsistencies during theme changes
- **Resource Management**: Efficient memory usage and cleanup

### Benchmarks
- **Theme Generation**: ~2-5 seconds (depending on LLaVA model)
- **Application Reload**: ~1-2 seconds for all applications
- **Memory Usage**: <100MB additional overhead
- **Storage**: ~50MB for cache and backups

## 🛡️ Error Handling

### Robust Fallbacks
- **Network Issues**: Graceful handling of Ollama connection failures
- **Model Availability**: Automatic fallback between LLaVA models
- **Color Validation**: Ensures all generated colors are valid
- **Configuration Backup**: Automatic backup before applying changes

### Logging System
- **Comprehensive Logs**: All operations logged with timestamps
- **Debug Mode**: Detailed logging for troubleshooting
- **Error Recovery**: Automatic restoration on critical failures

## 📚 Documentation

### 📋 **Process Documentation**
- [Post-Install Flow](docs/POST-INSTALL-FLOW.md) - Detailed installation process
- [Theming System Flow](docs/THEMING-SYSTEM-FLOW.md) - Complete theming workflow
- [Development Log](DEVLOG.md) - Project development history

### 🔧 **Technical Documentation**  
- [Installation Guide](docs/INSTALLATION.md) - Setup instructions
- [Theming System](docs/THEMING.md) - Color system and AI integration
- [Configuration Reference](docs/CONFIGURATION.md) - Config file details
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

### 📊 **System Flowcharts**
The documentation includes detailed Mermaid flowcharts showing:
- **Post-Install Process**: Every step from start to finish with decision points
- **Theming System**: Complete AI-powered color extraction and application workflow

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with detailed description

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Hyprland**: Amazing Wayland compositor
- **Ollama**: Local LLM runtime
- **LLaVA**: Vision-language model for color analysis
- **MaterialYou**: Google's dynamic theming inspiration
- **Arch Linux**: The distribution that makes this possible

---

**Made with ❤️ for the Arch Linux and ricing community** 
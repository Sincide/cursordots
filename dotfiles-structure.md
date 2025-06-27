# Dotfiles Directory Structure

## Complete Repository Layout

```
cursordots/
├── README.md                           # Main project documentation
├── DEVLOG.md                          # Development log and status
├── install.sh                         # Main installation script
├── setup-arch.sh                      # Arch Linux package installation
│
├── dotfiles/                          # Actual configuration files
│   ├── hyprland/                      # Hyprland window manager configs
│   │   ├── hyprland.conf             # Main config with includes
│   │   ├── modules/                   # Modular config components
│   │   │   ├── general.conf          # General settings
│   │   │   ├── input.conf            # Input/keyboard settings
│   │   │   ├── monitors.conf         # Monitor configuration
│   │   │   ├── keybinds.conf         # Key bindings
│   │   │   ├── windowrules.conf      # Window rules
│   │   │   └── animations.conf       # Animation settings
│   │   └── themes/                    # Theme-specific overrides
│   │       └── colors.conf           # Dynamic color variables
│   │
│   ├── waybar/                        # Waybar configurations
│   │   ├── config-primary.json       # Primary bar config
│   │   ├── config-secondary.json     # Secondary bar config
│   │   ├── style-primary.css         # Primary bar styles
│   │   ├── style-secondary.css       # Secondary bar styles
│   │   └── modules/                   # Shared module configs
│   │       ├── cpu.json              # CPU module
│   │       ├── memory.json           # Memory module
│   │       └── network.json          # Network module
│   │
│   ├── terminals/                     # Terminal configurations
│   │   ├── kitty/                    # Kitty terminal
│   │   │   ├── kitty.conf           # Main kitty config
│   │   │   └── themes/              # Color schemes
│   │   │       └── dynamic.conf     # Dynamic theme file
│   │   ├── foot/                     # Foot terminal
│   │   │   └── foot.ini             # Foot config
│   │   └── fish/                     # Fish shell
│   │       ├── config.fish          # Fish configuration
│   │       ├── functions/            # Custom functions
│   │       └── themes/              # Shell themes
│   │           └── dynamic.fish     # Dynamic theme
│   │
│   ├── applications/                  # Application configs
│   │   ├── dunst/                    # Notification daemon
│   │   │   └── dunstrc              # Dunst configuration
│   │   ├── fuzzel/                   # Application launcher
│   │   │   └── fuzzel.ini           # Fuzzel config
│   │   ├── btop/                     # System monitor
│   │   │   └── btop.conf            # Btop configuration
│   │   └── rofi/                     # Rofi (fallback launcher)
│   │       ├── config.rasi          # Rofi config
│   │       └── themes/              # Rofi themes
│   │           └── dynamic.rasi     # Dynamic theme
│   │
│   ├── gtk/                          # GTK theming
│   │   ├── gtk-2.0/                 # GTK2 config
│   │   │   └── gtkrc-2.0           # GTK2 theme file
│   │   ├── gtk-3.0/                 # GTK3 config
│   │   │   ├── settings.ini        # GTK3 settings
│   │   │   └── gtk.css             # Custom GTK3 styles
│   │   └── gtk-4.0/                 # GTK4 config
│   │       ├── settings.ini        # GTK4 settings
│   │       └── gtk.css             # Custom GTK4 styles
│   │
│   └── fonts/                        # Font configurations
│       ├── fontconfig/               # Fontconfig settings
│       │   └── fonts.conf           # Font configuration
│       └── .fonts/                   # Custom fonts directory
│
├── templates/                         # Template files for theming
│   ├── hyprland/                     # Hyprland templates
│   │   └── colors.conf.template     # Color variables template
│   ├── waybar/                       # Waybar templates
│   │   ├── style-primary.css.template
│   │   └── style-secondary.css.template
│   ├── terminals/                    # Terminal templates
│   │   ├── kitty.conf.template      # Kitty theme template
│   │   ├── foot.ini.template        # Foot theme template
│   │   └── fish-theme.fish.template # Fish theme template
│   ├── applications/                 # Application templates
│   │   ├── dunstrc.template         # Dunst template
│   │   ├── fuzzel.ini.template      # Fuzzel template
│   │   ├── btop.conf.template       # Btop template
│   │   └── rofi-theme.rasi.template # Rofi template
│   └── gtk/                         # GTK templates
│       ├── gtk2-gtkrc.template      # GTK2 template
│       ├── gtk3-settings.ini.template # GTK3 template
│       └── gtk4-settings.ini.template # GTK4 template
│
├── theme-engine/                     # Dynamic theming system
│   ├── wallpaper-picker.sh          # Wallpaper selection script
│   ├── color-extractor.sh           # LLaVA color extraction
│   ├── theme-renderer.sh            # Template rendering engine
│   ├── theme-applier.sh             # Theme application script
│   ├── ollama-interface.sh          # Ollama API interface
│   └── utils/                        # Utility functions
│       ├── color-utils.sh           # Color manipulation
│       ├── template-utils.sh        # Template processing
│       └── validation.sh            # Config validation
│
├── wallpapers/                       # Wallpaper collection
│   ├── nature/                       # Nature wallpapers
│   ├── abstract/                     # Abstract wallpapers
│   ├── minimal/                      # Minimal wallpapers
│   └── current.jpg                   # Current wallpaper symlink
│
├── scripts/                          # Utility and setup scripts
│   ├── install/                      # Installation scripts
│   │   ├── arch-packages.sh         # Arch package installation
│   │   ├── ollama-setup.sh          # Ollama and LLaVA setup
│   │   └── fonts-icons.sh           # Font and icon installation
│   ├── management/                   # Dotfiles management
│   │   ├── symlink-manager.sh       # Symlink creation/management
│   │   ├── backup-configs.sh        # Backup existing configs
│   │   └── restore-configs.sh       # Restore from backup
│   └── maintenance/                  # Maintenance scripts
│       ├── update-templates.sh      # Update template files
│       ├── validate-configs.sh      # Validate configurations
│       └── cleanup.sh               # Clean temporary files
│
├── assets/                           # Static assets
│   ├── fonts/                        # Custom fonts
│   │   ├── JetBrainsMono/           # JetBrains Mono font
│   │   └── NerdFonts/               # Nerd Fonts collection
│   ├── icons/                        # Custom icons
│   │   ├── Papirus/                 # Papirus icon theme
│   │   └── custom/                  # Custom icon overrides
│   └── cursors/                      # Custom cursor themes
│       └── Bibata/                  # Bibata cursor theme
│
├── cache/                            # Runtime cache and data
│   ├── themes/                       # Generated theme data
│   │   ├── current-theme.json       # Current theme colors
│   │   └── theme-history.json       # Theme history
│   ├── thumbnails/                   # Wallpaper thumbnails
│   └── temp/                         # Temporary files
│
├── docs/                             # Documentation
│   ├── INSTALLATION.md              # Installation guide
│   ├── CONFIGURATION.md             # Configuration guide
│   ├── THEMING.md                   # Theming system docs
│   ├── TROUBLESHOOTING.md           # Common issues and fixes
│   └── API.md                       # API documentation
│
└── tests/                           # Test scripts and configs
    ├── test-theme-engine.sh         # Theme engine tests
    ├── test-ollama-integration.sh   # Ollama integration tests
    ├── validate-templates.sh        # Template validation
    └── sample-configs/              # Sample configuration files
```

## Directory Explanations

### `/dotfiles/`
Contains the actual configuration files that will be symlinked to their respective locations in `~/.config/` and other system directories. Each subdirectory represents a different application or component.

### `/templates/`
Template files with placeholder variables that get replaced with dynamic theme values. These are the source files that generate the actual configs in `/dotfiles/`.

### `/theme-engine/`
Core theming system scripts responsible for wallpaper selection, color extraction via LLaVA, template rendering, and theme application.

### `/wallpapers/`
Organized wallpaper collection with current wallpaper symlink for easy reference by the theming system.

### `/scripts/`
Utility scripts for installation, management, and maintenance of the dotfiles system.

### `/assets/`
Static assets like fonts, icons, and cursors that are part of the theming system.

### `/cache/`
Runtime data and generated files, including current theme information and wallpaper thumbnails.

### `/docs/`
Comprehensive documentation for installation, configuration, and usage.

### `/tests/`
Test scripts and validation tools to ensure the system works correctly.

## Key Design Principles

1. **Modularity**: Each component is separated and can be modified independently
2. **Template-driven**: All theming uses templates to avoid duplication
3. **Atomic updates**: Theme changes are applied atomically across all components
4. **Extensibility**: Easy to add new applications and components
5. **Version control friendly**: Clear structure for tracking changes
6. **Cache efficiency**: Thumbnails and generated data are cached appropriately 
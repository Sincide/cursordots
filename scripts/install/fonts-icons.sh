#!/usr/bin/env fish

# =============================================================================
# Fonts & Icons Installation Script - Dynamic Theming System
# =============================================================================
# Description: Install and configure fonts and icon themes for the system
# Dependencies: pacman, wget, tar, unzip
# Author: Dotfiles Dynamic Theming System
# Usage: ./fonts-icons.sh [--install] [--configure] [--update] [--remove]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname (dirname $SCRIPT_DIR))
set ASSETS_DIR "$DOTFILES_ROOT/assets"
set FONTS_DIR "$ASSETS_DIR/fonts"
set ICONS_DIR "$ASSETS_DIR/icons"
set CURSORS_DIR "$ASSETS_DIR/cursors"
set CACHE_DIR "$DOTFILES_ROOT/cache"
set LOGS_DIR "$CACHE_DIR/logs"

# System directories
set SYSTEM_FONTS_DIR "/usr/share/fonts"
set USER_FONTS_DIR "$HOME/.local/share/fonts"
set SYSTEM_ICONS_DIR "/usr/share/icons"
set USER_ICONS_DIR "$HOME/.local/share/icons"
set SYSTEM_CURSORS_DIR "/usr/share/icons"
set USER_CURSORS_DIR "$HOME/.local/share/icons"

# Font and theme configurations
set NERD_FONTS_VERSION "v3.1.1"
set JETBRAINS_MONO_VERSION "2.304"
set PAPIRUS_ICONS_VERSION "20231101"
set BIBATA_CURSORS_VERSION "v2.0.3"

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/fonts-icons.log"
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/fonts-icons.log"
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/fonts-icons.log"
    end
end

function log_success
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/fonts-icons.log"
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_dependencies
    set required_tools pacman wget tar unzip fc-cache gtk-update-icon-cache
    set missing_tools
    
    for tool in $required_tools
        if not command -v $tool > /dev/null 2>&1
            set missing_tools $missing_tools $tool
        end
    end
    
    if test (count $missing_tools) -gt 0
        log_error "Missing required tools: $missing_tools"
        log_error "Please install missing dependencies:"
        for tool in $missing_tools
            switch $tool
                case pacman
                    echo "  This script requires Arch Linux"
                case wget
                    echo "  pacman -S wget"
                case tar
                    echo "  pacman -S tar"
                case unzip
                    echo "  pacman -S unzip"
                case fc-cache
                    echo "  pacman -S fontconfig"
                case gtk-update-icon-cache
                    echo "  pacman -S gtk3"
            end
        end
        return 1
    end
    
    log_debug "All dependencies satisfied"
    return 0
end

# =============================================================================
# Font Installation
# =============================================================================

function install_system_fonts
    log_info "Installing system fonts via pacman"
    
    set font_packages \
        ttf-jetbrains-mono \
        ttf-jetbrains-mono-nerd \
        ttf-fira-code \
        ttf-fira-sans \
        ttf-roboto \
        ttf-roboto-mono \
        ttf-opensans \
        ttf-liberation \
        noto-fonts \
        noto-fonts-emoji \
        noto-fonts-cjk \
        ttf-dejavu \
        ttf-cascadia-code
    
    set failed_packages
    
    for package in $font_packages
        log_debug "Installing font package: $package"
        
        if pacman -S --noconfirm $package 2>/dev/null
            log_debug "Successfully installed: $package"
        else
            log_error "Failed to install: $package"
            set failed_packages $failed_packages $package
        end
    end
    
    if test (count $failed_packages) -gt 0
        log_error "Failed to install font packages: $failed_packages"
        return 1
    end
    
    log_success "System fonts installation completed"
    return 0
end

function download_nerd_fonts
    log_info "Downloading additional Nerd Fonts"
    
    set nerd_fonts \
        JetBrainsMono \
        FiraCode \
        Hack \
        SourceCodePro \
        RobotoMono
    
    mkdir -p "$FONTS_DIR/NerdFonts"
    cd "$FONTS_DIR/NerdFonts"
    
    for font in $nerd_fonts
        set download_url "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_VERSION/$font.zip"
        set font_zip "$font.zip"
        set font_dir "$font"
        
        if test -d "$font_dir"
            log_debug "Nerd Font already exists: $font"
            continue
        end
        
        log_debug "Downloading Nerd Font: $font"
        
        if wget -q "$download_url" -O "$font_zip"
            mkdir -p "$font_dir"
            if unzip -q "$font_zip" -d "$font_dir"
                rm "$font_zip"
                log_debug "Successfully downloaded and extracted: $font"
            else
                log_error "Failed to extract Nerd Font: $font"
                rm -f "$font_zip"
            end
        else
            log_error "Failed to download Nerd Font: $font"
        end
    end
    
    cd "$SCRIPT_DIR"
    log_success "Nerd Fonts download completed"
end

function install_user_fonts
    log_info "Installing user fonts"
    
    mkdir -p "$USER_FONTS_DIR"
    
    # Install downloaded Nerd Fonts
    if test -d "$FONTS_DIR/NerdFonts"
        for font_dir in "$FONTS_DIR/NerdFonts"/*
            if test -d "$font_dir"
                set font_name (basename "$font_dir")
                set target_dir "$USER_FONTS_DIR/$font_name"
                
                if not test -d "$target_dir"
                    cp -r "$font_dir" "$target_dir"
                    log_debug "Installed user font: $font_name"
                end
            end
        end
    end
    
    # Install custom fonts from assets
    if test -d "$FONTS_DIR/custom"
        cp -r "$FONTS_DIR/custom"/* "$USER_FONTS_DIR/" 2>/dev/null
        log_debug "Installed custom fonts"
    end
    
    log_success "User fonts installation completed"
end

function update_font_cache
    log_info "Updating font cache"
    
    if fc-cache -fv 2>/dev/null
        log_success "Font cache updated successfully"
        return 0
    else
        log_error "Failed to update font cache"
        return 1
    end
end

# =============================================================================
# Icon Theme Installation
# =============================================================================

function install_system_icons
    log_info "Installing system icon themes via pacman"
    
    set icon_packages \
        papirus-icon-theme \
        breeze-icons \
        adwaita-icon-theme \
        hicolor-icon-theme \
        gnome-icon-theme
    
    set failed_packages
    
    for package in $icon_packages
        log_debug "Installing icon package: $package"
        
        if pacman -S --noconfirm $package 2>/dev/null
            log_debug "Successfully installed: $package"
        else
            log_error "Failed to install: $package"
            set failed_packages $failed_packages $package
        end
    end
    
    if test (count $failed_packages) -gt 0
        log_error "Failed to install icon packages: $failed_packages"
        return 1
    end
    
    log_success "System icon themes installation completed"
    return 0
end

function download_papirus_icons
    log_info "Downloading latest Papirus icon theme"
    
    set download_url "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/heads/master.zip"
    set papirus_zip "$ICONS_DIR/papirus.zip"
    set papirus_dir "$ICONS_DIR/Papirus"
    
    mkdir -p "$ICONS_DIR"
    
    if test -d "$papirus_dir"
        log_debug "Papirus icons already exist"
        return 0
    end
    
    cd "$ICONS_DIR"
    
    if wget -q "$download_url" -O "$papirus_zip"
        if unzip -q "$papirus_zip"
            mv papirus-icon-theme-master "$papirus_dir"
            rm "$papirus_zip"
            log_success "Papirus icons downloaded successfully"
        else
            log_error "Failed to extract Papirus icons"
            rm -f "$papirus_zip"
            return 1
        end
    else
        log_error "Failed to download Papirus icons"
        return 1
    end
    
    cd "$SCRIPT_DIR"
end

function install_user_icons
    log_info "Installing user icon themes"
    
    mkdir -p "$USER_ICONS_DIR"
    
    # Install downloaded Papirus icons
    if test -d "$ICONS_DIR/Papirus"
        set target_dir "$USER_ICONS_DIR/Papirus"
        
        if not test -d "$target_dir"
            cp -r "$ICONS_DIR/Papirus" "$target_dir"
            log_debug "Installed Papirus icon theme"
        end
    end
    
    # Install custom icons from assets
    if test -d "$ICONS_DIR/custom"
        cp -r "$ICONS_DIR/custom"/* "$USER_ICONS_DIR/" 2>/dev/null
        log_debug "Installed custom icon themes"
    end
    
    log_success "User icon themes installation completed"
end

function update_icon_cache
    log_info "Updating icon cache"
    
    # Update system icon cache
    if test -d "$SYSTEM_ICONS_DIR"
        for theme_dir in "$SYSTEM_ICONS_DIR"/*
            if test -d "$theme_dir"
                gtk-update-icon-cache -f -t "$theme_dir" 2>/dev/null
            end
        end
    end
    
    # Update user icon cache
    if test -d "$USER_ICONS_DIR"
        for theme_dir in "$USER_ICONS_DIR"/*
            if test -d "$theme_dir"
                gtk-update-icon-cache -f -t "$theme_dir" 2>/dev/null
            end
        end
    end
    
    log_success "Icon cache updated successfully"
end

# =============================================================================
# Cursor Theme Installation
# =============================================================================

function install_system_cursors
    log_info "Installing system cursor themes via pacman"
    
    set cursor_packages \
        bibata-cursor-theme \
        xcursor-themes \
        adwaita-cursors
    
    set failed_packages
    
    for package in $cursor_packages
        log_debug "Installing cursor package: $package"
        
        if pacman -S --noconfirm $package 2>/dev/null
            log_debug "Successfully installed: $package"
        else
            log_error "Failed to install: $package"
            set failed_packages $failed_packages $package
        end
    end
    
    if test (count $failed_packages) -gt 0
        log_error "Failed to install cursor packages: $failed_packages"
        return 1
    end
    
    log_success "System cursor themes installation completed"
    return 0
end

function download_bibata_cursors
    log_info "Downloading Bibata cursor theme"
    
    set download_url "https://github.com/ful1e5/Bibata_Cursor/releases/download/$BIBATA_CURSORS_VERSION/Bibata-Modern-Classic.tar.gz"
    set bibata_tar "$CURSORS_DIR/bibata.tar.gz"
    set bibata_dir "$CURSORS_DIR/Bibata"
    
    mkdir -p "$CURSORS_DIR"
    
    if test -d "$bibata_dir"
        log_debug "Bibata cursors already exist"
        return 0
    end
    
    cd "$CURSORS_DIR"
    
    if wget -q "$download_url" -O "$bibata_tar"
        if tar -xzf "$bibata_tar"
            mv Bibata-Modern-Classic "$bibata_dir"
            rm "$bibata_tar"
            log_success "Bibata cursors downloaded successfully"
        else
            log_error "Failed to extract Bibata cursors"
            rm -f "$bibata_tar"
            return 1
        end
    else
        log_error "Failed to download Bibata cursors"
        return 1
    end
    
    cd "$SCRIPT_DIR"
end

function install_user_cursors
    log_info "Installing user cursor themes"
    
    mkdir -p "$USER_CURSORS_DIR"
    
    # Install downloaded Bibata cursors
    if test -d "$CURSORS_DIR/Bibata"
        set target_dir "$USER_CURSORS_DIR/Bibata-Modern-Classic"
        
        if not test -d "$target_dir"
            cp -r "$CURSORS_DIR/Bibata" "$target_dir"
            log_debug "Installed Bibata cursor theme"
        end
    end
    
    # Install custom cursors from assets
    if test -d "$CURSORS_DIR/custom"
        cp -r "$CURSORS_DIR/custom"/* "$USER_CURSORS_DIR/" 2>/dev/null
        log_debug "Installed custom cursor themes"
    end
    
    log_success "User cursor themes installation completed"
end

# =============================================================================
# Configuration Management
# =============================================================================

function configure_system_themes
    log_info "Configuring system-wide font and theme settings"
    
    # Configure fontconfig
    set fontconfig_dir ~/.config/fontconfig
    mkdir -p "$fontconfig_dir"
    
    # Create fontconfig configuration
    cat > "$fontconfig_dir/fonts.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Default fonts -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Liberation Serif</family>
      <family>DejaVu Serif</family>
    </prefer>
  </alias>
  
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Liberation Sans</family>
      <family>DejaVu Sans</family>
    </prefer>
  </alias>
  
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrainsMono Nerd Font</family>
      <family>JetBrains Mono</family>
      <family>Fira Code</family>
      <family>Liberation Mono</family>
    </prefer>
  </alias>
  
  <!-- Emoji fonts -->
  <alias>
    <family>emoji</family>
    <prefer>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>
  
  <!-- Font rendering settings -->
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>
EOF
    
    # Configure GTK settings via gsettings
    if command -v gsettings > /dev/null 2>&1
        gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
        gsettings set org.gnome.desktop.interface document-font-name "Noto Sans 11"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 10"
        gsettings set org.gnome.desktop.wm.preferences titlebar-font "Noto Sans Bold 11"
        
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
        gsettings set org.gnome.desktop.interface cursor-size 24
        
        log_debug "GTK settings configured via gsettings"
    end
    
    log_success "System themes configuration completed"
end

function create_theme_scripts
    log_info "Creating theme management scripts"
    
    set scripts_dir "$DOTFILES_ROOT/scripts/themes"
    mkdir -p "$scripts_dir"
    
    # Create font switching script
    cat > "$scripts_dir/switch-font.sh" << 'EOF'
#!/usr/bin/env fish

# Font switching script
set fonts \
    "JetBrainsMono Nerd Font" \
    "Fira Code" \
    "Hack Nerd Font" \
    "Source Code Pro" \
    "Roboto Mono"

if test (count $argv) -eq 0
    echo "Available fonts:"
    for i in (seq (count $fonts))
        echo "  $i. $fonts[$i]"
    end
    echo ""
    echo "Usage: $argv[0] <font_number>"
    exit 1
end

set selected_font $fonts[$argv[1]]

if test -z "$selected_font"
    echo "Invalid font selection"
    exit 1
end

echo "Switching to font: $selected_font"

# Update gsettings
gsettings set org.gnome.desktop.interface monospace-font-name "$selected_font 10"

# Update terminal configs if they exist
if test -f ~/.config/kitty/kitty.conf
    sed -i "s/^font_family.*/font_family $selected_font/" ~/.config/kitty/kitty.conf
end

if test -f ~/.config/foot/foot.ini
    sed -i "s/^font=.*/font=$selected_font:size=10/" ~/.config/foot/foot.ini
end

echo "Font switched successfully"
EOF
    
    chmod +x "$scripts_dir/switch-font.sh"
    
    # Create icon theme switching script
    cat > "$scripts_dir/switch-icons.sh" << 'EOF'
#!/usr/bin/env fish

# Icon theme switching script
set icon_themes \
    "Papirus" \
    "Papirus-Dark" \
    "Papirus-Light" \
    "Adwaita" \
    "breeze" \
    "hicolor"

if test (count $argv) -eq 0
    echo "Available icon themes:"
    for i in (seq (count $icon_themes))
        echo "  $i. $icon_themes[$i]"
    end
    echo ""
    echo "Usage: $argv[0] <theme_number>"
    exit 1
end

set selected_theme $icon_themes[$argv[1]]

if test -z "$selected_theme"
    echo "Invalid theme selection"
    exit 1
end

echo "Switching to icon theme: $selected_theme"

# Update gsettings
gsettings set org.gnome.desktop.interface icon-theme "$selected_theme"

echo "Icon theme switched successfully"
EOF
    
    chmod +x "$scripts_dir/switch-icons.sh"
    
    log_success "Theme management scripts created"
end

# =============================================================================
# Main Operations
# =============================================================================

function install_all
    log_info "Installing all fonts, icons, and cursors"
    
    set failed_operations
    
    # Install fonts
    if not install_system_fonts
        set failed_operations $failed_operations "system fonts"
    end
    
    download_nerd_fonts
    
    if not install_user_fonts
        set failed_operations $failed_operations "user fonts"
    end
    
    if not update_font_cache
        set failed_operations $failed_operations "font cache"
    end
    
    # Install icons
    if not install_system_icons
        set failed_operations $failed_operations "system icons"
    end
    
    download_papirus_icons
    
    if not install_user_icons
        set failed_operations $failed_operations "user icons"
    end
    
    if not update_icon_cache
        set failed_operations $failed_operations "icon cache"
    end
    
    # Install cursors
    if not install_system_cursors
        set failed_operations $failed_operations "system cursors"
    end
    
    download_bibata_cursors
    
    if not install_user_cursors
        set failed_operations $failed_operations "user cursors"
    end
    
    if test (count $failed_operations) -gt 0
        log_error "Some operations failed: $failed_operations"
        return 1
    end
    
    log_success "All fonts, icons, and cursors installed successfully"
    return 0
end

function configure_all
    log_info "Configuring all themes"
    
    configure_system_themes
    create_theme_scripts
    
    log_success "All themes configured successfully"
end

function update_all
    log_info "Updating all fonts, icons, and cursors"
    
    # Remove existing downloads and reinstall
    rm -rf "$FONTS_DIR/NerdFonts"
    rm -rf "$ICONS_DIR/Papirus"
    rm -rf "$CURSORS_DIR/Bibata"
    
    install_all
    configure_all
    
    log_success "All themes updated successfully"
end

function remove_all
    log_info "Removing user-installed fonts, icons, and cursors"
    
    # Remove user fonts
    rm -rf "$USER_FONTS_DIR/JetBrainsMono"*
    rm -rf "$USER_FONTS_DIR/FiraCode"*
    rm -rf "$USER_FONTS_DIR/Hack"*
    rm -rf "$USER_FONTS_DIR/SourceCodePro"*
    rm -rf "$USER_FONTS_DIR/RobotoMono"*
    
    # Remove user icons
    rm -rf "$USER_ICONS_DIR/Papirus"*
    
    # Remove user cursors
    rm -rf "$USER_CURSORS_DIR/Bibata"*
    
    # Update caches
    update_font_cache
    update_icon_cache
    
    log_success "User themes removed successfully"
end

# =============================================================================
# Setup and Main Function
# =============================================================================

function setup_directories
    mkdir -p $LOGS_DIR
    mkdir -p $FONTS_DIR
    mkdir -p $ICONS_DIR
    mkdir -p $CURSORS_DIR
    touch "$LOGS_DIR/fonts-icons.log"
end

function main
    set operation "install"
    
    # Parse command line arguments
    for arg in $argv
        switch $arg
            case --install
                set operation "install"
            case --configure
                set operation "configure"
            case --update
                set operation "update"
            case --remove
                set operation "remove"
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] [--install] [--configure] [--update] [--remove] [--debug] [--help]"
                echo ""
                echo "Install and configure fonts, icons, and cursors for the theming system"
                echo ""
                echo "Options:"
                echo "  --install            Install all fonts, icons, and cursors (default)"
                echo "  --configure          Configure system themes and create management scripts"
                echo "  --update             Update all themes by re-downloading"
                echo "  --remove             Remove user-installed themes"
                echo "  --debug              Enable debug logging"
                echo "  --help               Show this help message"
                return 0
            case -*
                log_error "Unknown option: $arg"
                return 1
        end
    end
    
    # Check dependencies
    if not check_dependencies
        return 1
    end
    
    # Setup directories
    setup_directories
    
    # Execute operation
    switch $operation
        case install
            install_all
            configure_all
        case configure
            configure_all
        case update
            update_all
        case remove
            remove_all
        case '*'
            log_error "Unknown operation: $operation"
            return 1
    end
    
    return $status
end

# Execute main function with all arguments
main $argv 
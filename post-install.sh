#!/usr/bin/env bash

# =============================================================================
# Dynamic Theming Dotfiles - Post-Install Script for Minimal Arch Linux
# =============================================================================
# Description: Complete setup script for minimal Arch Linux installation
# Author: Dotfiles Dynamic Theming System
# Usage: ./post-install.sh
# Requirements: Minimal Arch Linux with working internet connection
# =============================================================================

set -uo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"
LOCAL_BIN="$USER_HOME/.local/bin"
WALLPAPERS_DIR="$USER_HOME/Pictures/Wallpapers"
SCREENSHOTS_DIR="$USER_HOME/Pictures/Screenshots"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        exit 1
    fi
}

check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection detected. Please check your network."
        exit 1
    fi
    log_success "Internet connection verified"
}

# =============================================================================
# AUR Helper Installation (First Priority)
# =============================================================================

install_yay_first() {
    log_header "Installing AUR Helper (yay)"
    
    # Check if yay is already installed
    if command -v yay &> /dev/null; then
        log_info "yay is already installed"
        return 0
    fi
    
    log_info "Installing yay AUR helper..."
    
    # Install base-devel and git first with pacman (essential for building)
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay
    local temp_dir="/tmp/yay-install"
    rm -rf "$temp_dir"
    git clone https://aur.archlinux.org/yay.git "$temp_dir"
    cd "$temp_dir"
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_success "yay installed successfully"
}

# =============================================================================
# System Update
# =============================================================================

update_system() {
    log_header "Updating System"
    
    log_info "Updating package databases and system..."
    sudo pacman -Syu --noconfirm
    
    log_success "System updated successfully"
}

# =============================================================================
# Package Installation Functions with Error Handling
# =============================================================================

install_package_safe() {
    local package="$1"
    local description="$2"
    
    # Check if package is already installed
    if yay -Q "$package" &>/dev/null; then
        log_info "$package is already installed"
        return 0
    fi
    
    # Try to install the package
    log_info "Installing $package ($description)..."
    if yay -S --needed --noconfirm "$package" 2>/dev/null; then
        log_success "$package installed successfully"
        return 0
    else
        log_warning "Failed to install $package - continuing anyway"
        return 1
    fi
}

install_packages_batch() {
    local category="$1"
    shift
    local packages=("$@")
    
    log_header "Installing $category"
    
    local failed_packages=()
    local success_count=0
    
    for package in "${packages[@]}"; do
        if install_package_safe "$package" "$category"; then
            success_count=$((success_count + 1))
        else
            failed_packages+=("$package")
        fi
    done
    
    log_info "$category: $success_count/${#packages[@]} packages installed successfully"
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "Failed packages in $category: ${failed_packages[*]}"
    fi
    
    log_success "$category installation completed"
}

# =============================================================================
# System Packages Installation
# =============================================================================

install_essential_packages() {
    local essential_packages=(
        # System essentials
        wget
        curl
        unzip
        tar
        fish
        
        # Wayland and Hyprland
        hyprland
        hyprland-protocols
        xdg-desktop-portal-hyprland
        qt5-wayland
        qt6-wayland
        
        # Display and graphics
        wayland
        wayland-protocols
        
        # AMD GPU support
        mesa
        lib32-mesa
        vulkan-radeon
        lib32-vulkan-radeon
        xf86-video-amdgpu
        
        # Audio
        pipewire
        pipewire-alsa
        pipewire-pulse
        pipewire-jack
        wireplumber
        pavucontrol
        playerctl
        
        # Networking
        networkmanager
        nm-connection-editor
        
        # Bluetooth
        bluez
        bluez-utils
        blueman
        
        # File management
        thunar
        thunar-volman
        gvfs
        
        # Terminal applications
        kitty
        foot
        btop
        
        # Media
        imv
        mpv
        
        # System utilities
        brightnessctl
        grim
        slurp
        swappy
        wl-clipboard
        cliphist
        
        # Authentication
        polkit-gnome
        
        # Fonts
        ttf-jetbrains-mono-nerd
        noto-fonts
        noto-fonts-emoji
        
        # Development tools
        jq
        
        # Archive tools
        file-roller
        unrar
        p7zip
    )
    
    install_packages_batch "Essential Packages" "${essential_packages[@]}"
}

# =============================================================================
# Wayland Applications Installation
# =============================================================================

install_wayland_apps() {
    local wayland_apps=(
        # Status bar
        waybar
        
        # Notifications
        dunst
        
        # Launcher
        fuzzel
        
        # Wallpaper
        swww
        
        # Lock screen (AUR package)
        swaylock-effects
        
        # Idle management  
        swayidle
        
        # Screen sharing
        xdg-desktop-portal-wlr
        
        # Image viewer
        imv
    )
    
    install_packages_batch "Wayland Applications" "${wayland_apps[@]}"
}

# =============================================================================
# AI/LLaVA Dependencies
# =============================================================================

install_ai_dependencies() {
    log_header "Installing AI Dependencies for LLaVA"
    
    # Install ROCm for AMD GPU support first
    log_info "Installing ROCm for AMD GPU acceleration..."
    local rocm_packages=(
        "rocm-opencl-runtime"
        "rocm-clinfo" 
        "rocm-cmake"
        "rocm-device-libs"
        "hip"
    )
    
    install_packages_batch "ROCm AMD GPU Support" "${rocm_packages[@]}"
    
    # Add user to render and video groups for GPU access
    log_info "Adding user to GPU access groups..."
    sudo usermod -a -G render,video "$USER"
    
    # Check if ollama is already installed
    if command -v ollama &> /dev/null; then
        log_info "Ollama already installed"
        # Restart ollama to detect GPU
        log_info "Restarting Ollama to detect AMD GPU..."
        sudo systemctl restart ollama 2>/dev/null || true
    else
        log_info "Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
        
        # Enable and start ollama service
        sudo systemctl enable ollama
        sudo systemctl start ollama
        
        log_success "Ollama installed and started"
    fi
    
    # Verify GPU detection
    log_info "Checking GPU detection..."
    if command -v rocm-smi &>/dev/null; then
        rocm-smi --showproductname || log_warning "ROCm not detecting GPU - may need reboot"
    fi
    
    # Install LLaVA model
    log_info "Installing LLaVA model (this may take a while)..."
    ollama pull llava-llama3:8b || ollama pull llava:7b
    
    log_success "LLaVA model installed successfully"
}

# =============================================================================
# System Services Configuration
# =============================================================================

configure_services() {
    log_header "Configuring System Services"
    
    # Enable NetworkManager (check if already enabled)
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        sudo systemctl enable NetworkManager
        log_info "NetworkManager enabled"
    else
        log_info "NetworkManager already enabled"
    fi
    
    if ! systemctl is-active NetworkManager &>/dev/null; then
        sudo systemctl start NetworkManager
        log_info "NetworkManager started"
    else
        log_info "NetworkManager already running"
    fi
    
    # Enable Bluetooth (check if already enabled)
    if ! systemctl is-enabled bluetooth &>/dev/null; then
        sudo systemctl enable bluetooth
        log_info "Bluetooth enabled"
    else
        log_info "Bluetooth already enabled"
    fi
    
    if ! systemctl is-active bluetooth &>/dev/null; then
        sudo systemctl start bluetooth
        log_info "Bluetooth started"
    else
        log_info "Bluetooth already running"
    fi
    
    # Configure fish shell as default (check if already configured)
    if ! grep -q "$(which fish)" /etc/shells; then
        echo "$(which fish)" | sudo tee -a /etc/shells
        log_info "Fish shell added to /etc/shells"
    else
        log_info "Fish shell already in /etc/shells"
    fi
    
    # Check if fish is already the default shell
    if [[ "$SHELL" != "$(which fish)" ]]; then
        log_info "Changing default shell to fish..."
        chsh -s "$(which fish)"
        log_info "Default shell changed to fish (will take effect on next login)"
    else
        log_info "Fish is already the default shell"
    fi
    
    log_success "System services configured successfully"
}

# =============================================================================
# Directory Structure Creation
# =============================================================================

create_directories() {
    log_header "Creating Directory Structure"
    
    local directories=(
        "$CONFIG_DIR"
        "$LOCAL_BIN"
        "$WALLPAPERS_DIR"
        "$SCREENSHOTS_DIR"
        "$USER_HOME/.local/share"
        "$USER_HOME/.cache"
        "$USER_HOME/.cache/themes"
        "$USER_HOME/.cache/wallpapers"
        "$USER_HOME/.cache/thumbnails"
        "$USER_HOME/.cache/logs"
    )
    
    # Create directories if they don't exist
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    log_success "Directory structure verified/created successfully"
}

# =============================================================================
# Dotfiles Installation
# =============================================================================

install_dotfiles() {
    log_header "Installing Dotfiles"
    
    # Install fonts and icons first
    log_info "Installing fonts and icons..."
    if [[ -f "$SCRIPT_DIR/scripts/install/fonts-icons.sh" ]]; then
        bash "$SCRIPT_DIR/scripts/install/fonts-icons.sh"
    else
        log_warning "Fonts and icons script not found, skipping..."
    fi
    
    # Install dotfiles using symlink manager
    log_info "Installing dotfiles configuration..."
    if [[ -f "$SCRIPT_DIR/scripts/management/symlink-manager.sh" ]]; then
        bash "$SCRIPT_DIR/scripts/management/symlink-manager.sh" install --force
    else
        log_warning "Symlink manager script not found, skipping..."
    fi
    
    # Make scripts executable
    if [[ -d "$SCRIPT_DIR/theme-engine" ]]; then
        find "$SCRIPT_DIR/theme-engine" -name "*.sh" -exec chmod +x {} \;
        log_info "Made theme engine scripts executable"
    fi
    
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
        log_info "Made management scripts executable"
    fi
    
    # Add theme scripts to PATH (check if already linked)
    if [[ -d "$LOCAL_BIN" ]]; then
        local scripts=(
            "wallpaper-picker:theme-engine/wallpaper-picker.sh"
            "theme-applier:theme-engine/theme-applier.sh"
            "color-extractor:theme-engine/color-extractor.sh"
            "theme-renderer:theme-engine/theme-renderer.sh"
        )
        
        for script_entry in "${scripts[@]}"; do
            local name="${script_entry%:*}"
            local path="${script_entry#*:}"
            local target_link="$LOCAL_BIN/$name"
            local source_script="$SCRIPT_DIR/$path"
            
            if [[ -f "$source_script" ]]; then
                if [[ ! -L "$target_link" ]] || [[ "$(readlink "$target_link")" != "$source_script" ]]; then
                    ln -sf "$source_script" "$target_link"
                    log_info "Linked $name to PATH"
                else
                    log_info "$name already linked to PATH"
                fi
            else
                log_warning "Source script not found: $source_script"
            fi
        done
    fi
    
    log_success "Dotfiles installation completed"
}

# =============================================================================
# Default Wallpapers
# =============================================================================

install_default_wallpapers() {
    log_header "Installing Default Wallpapers"
    
    # Ensure wallpapers directory exists
    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        mkdir -p "$WALLPAPERS_DIR"
        log_info "Created wallpapers directory: $WALLPAPERS_DIR"
    else
        log_info "Wallpapers directory already exists"
    fi
    
    # Check if wallpapers exist
    if [[ -z "$(find "$WALLPAPERS_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" 2>/dev/null)" ]]; then
        log_info "No wallpapers found, creating default wallpaper..."
        
        # Create a basic default wallpaper if ImageMagick is available
        if command -v convert &>/dev/null; then
            convert -size 2560x1440 xc:'#1e1e2e' "$WALLPAPERS_DIR/default-dark.png" 2>/dev/null && {
                log_info "Created default wallpaper: default-dark.png"
            }
        else
            log_warning "ImageMagick not available for wallpaper generation"
            log_info "Please add wallpapers manually to $WALLPAPERS_DIR"
        fi
    else
        log_info "Wallpapers already exist in $WALLPAPERS_DIR"
    fi
    
    log_success "Wallpaper setup completed"
}

# =============================================================================
# Additional AUR Packages and Package UI Installation
# =============================================================================

install_additional_packages() {
    log_header "Installing Additional Packages and Package UI"
    
    # Install some useful AUR packages
    local aur_packages=(
        "starship"  # Better shell prompt
    )
    
    install_packages_batch "Additional AUR Packages" "${aur_packages[@]}"
    
    # Install pacui (package manager UI) from source
    if command -v pacui &> /dev/null; then
        log_info "pacui already installed"
    else
        log_info "Installing pacui from source..."
        
        # Clone pacui repository
        local temp_dir="/tmp/pacui-install"
        rm -rf "$temp_dir"
        git clone https://github.com/excalibur1234/pacui.git "$temp_dir"
        cd "$temp_dir"
        
        # Install pacui
        sudo install -Dm755 pacui /usr/bin/pacui
        sudo install -Dm644 pacui.desktop /usr/share/applications/pacui.desktop
        sudo install -Dm644 README.md /usr/share/doc/pacui/README.md
        
        cd - > /dev/null
        rm -rf "$temp_dir"
        
        log_success "pacui installed successfully"
    fi
}

# =============================================================================
# Firefox Installation and Configuration
# =============================================================================

install_firefox() {
    log_header "Installing and Configuring Firefox"
    
    install_package_safe "firefox" "Web Browser"
    
    # Set Firefox as default browser (check if already set)
    current_browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "")
    if [[ "$current_browser" != "firefox.desktop" ]]; then
        xdg-settings set default-web-browser firefox.desktop
        log_info "Set Firefox as default browser"
    else
        log_info "Firefox is already the default browser"
    fi
    
    log_success "Firefox installation and configuration completed"
}

# =============================================================================
# Final Configuration
# =============================================================================

final_configuration() {
    log_header "Final Configuration"
    
    # Set environment variables for Wayland (check if already configured)
    if [[ ! -f "$USER_HOME/.profile" ]]; then
        log_info "Creating ~/.profile with Wayland environment variables..."
        cat > "$USER_HOME/.profile" << 'EOF'
# Wayland environment
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
    else
        log_info "~/.profile already exists, checking for required variables..."
        
        # Check and add missing environment variables
        local vars_to_check=(
            "MOZ_ENABLE_WAYLAND=1"
            "QT_QPA_PLATFORM=wayland"
            "XDG_CURRENT_DESKTOP=Hyprland"
            "XDG_SESSION_TYPE=wayland"
            "XDG_SESSION_DESKTOP=Hyprland"
        )
        
        for var in "${vars_to_check[@]}"; do
            if ! grep -q "$var" "$USER_HOME/.profile"; then
                echo "export $var" >> "$USER_HOME/.profile"
                log_info "Added missing environment variable: $var"
            fi
        done
        
        # Check PATH addition
        if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$USER_HOME/.profile"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.profile"
            log_info "Added ~/.local/bin to PATH"
        fi
    fi
    
    # Configure git if not already configured
    if ! git config --global user.name &> /dev/null; then
        echo
        log_info "Configuring Git..."
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        
        log_success "Git configured successfully"
    fi
    
    # Generate initial theme (only if not already exists)
    if [[ ! -f "$USER_HOME/.cache/themes/current_theme.json" ]]; then
        log_info "Generating initial theme..."
        if [[ -f "$LOCAL_BIN/theme-applier" ]]; then
            "$LOCAL_BIN/theme-applier" --fallback 2>/dev/null || log_warning "Initial theme generation failed, will use defaults"
        else
            log_warning "Theme applier not found, skipping initial theme generation"
        fi
    else
        log_info "Theme already exists, skipping initial generation"
    fi
    
    log_success "Final configuration completed"
}

# =============================================================================
# Post-Installation Summary
# =============================================================================

show_summary() {
    log_header "Installation Summary"
    
    echo -e "${GREEN}✓ System updated and base packages installed${NC}"
    echo -e "${GREEN}✓ Wayland and Hyprland environment configured${NC}"
    echo -e "${GREEN}✓ Audio system (PipeWire) configured${NC}"
    echo -e "${GREEN}✓ LLaVA AI system installed for dynamic theming${NC}"
    echo -e "${GREEN}✓ Dotfiles and configurations installed${NC}"
    echo -e "${GREEN}✓ System services configured${NC}"
    echo -e "${GREEN}✓ Fish shell set as default${NC}"
    echo -e "${GREEN}✓ yay AUR helper installed${NC}"
    echo -e "${GREEN}✓ pacui package manager UI installed${NC}"
    
    echo -e "\n${CYAN}Next Steps:${NC}"
    echo -e "1. Reboot your system: ${YELLOW}sudo reboot${NC}"
    echo -e "2. Log in and start Hyprland"
    echo -e "3. Press ${YELLOW}Super+W${NC} to select a wallpaper and generate theme"
    echo -e "4. Press ${YELLOW}Super+Return${NC} to open terminal"
    echo -e "5. Press ${YELLOW}Super+D${NC} to open application launcher"
    
    echo -e "\n${CYAN}Theming Commands:${NC}"
    echo -e "• ${YELLOW}wallpaper-picker${NC} - Select wallpaper and generate theme"
    echo -e "• ${YELLOW}theme-applier${NC} - Apply current theme"
    echo -e "• ${YELLOW}theme-applier --reload${NC} - Reload current theme"
    echo -e "• ${YELLOW}theme-applier --random${NC} - Apply random theme"
    
    echo -e "\n${CYAN}Package Management:${NC}"
    echo -e "• ${YELLOW}yay${NC} - AUR helper for installing AUR packages"
    echo -e "• ${YELLOW}pacui${NC} - User-friendly package manager interface"
    echo -e "• ${YELLOW}sudo pacman -Syu${NC} - Update system packages"
    echo -e "• ${YELLOW}yay -Syu${NC} - Update system and AUR packages"
    
    echo -e "\n${CYAN}Key Bindings:${NC}"
    echo -e "• ${YELLOW}Super+Return${NC} - Terminal (Kitty)"
    echo -e "• ${YELLOW}Super+Shift+Return${NC} - Terminal (Foot)"
    echo -e "• ${YELLOW}Super+D${NC} - Application launcher"
    echo -e "• ${YELLOW}Super+E${NC} - File manager"
    echo -e "• ${YELLOW}Super+B${NC} - Web browser"
    echo -e "• ${YELLOW}Super+W${NC} - Wallpaper picker"
    echo -e "• ${YELLOW}Super+Q${NC} - Close window"
    echo -e "• ${YELLOW}Super+Shift+X${NC} - Logout"
    
    echo -e "\n${GREEN}Installation completed successfully!${NC}"
    echo -e "${YELLOW}Please reboot to start using your new dynamic theming system.${NC}"
}

# =============================================================================
# Error Handling
# =============================================================================

cleanup_on_error() {
    log_error "Installation encountered errors but will continue..."
    # Add any cleanup commands here if needed
    return 1
}

# Note: No error trap - we want to continue even if some packages fail

# =============================================================================
# Main Installation Process
# =============================================================================

main() {
    log_header "Dynamic Theming Dotfiles - Post-Install Script"
    echo -e "${CYAN}This script will install all dependencies and configure your system${NC}"
    echo -e "${CYAN}for the dynamic theming Hyprland environment.${NC}"
    echo -e "${YELLOW}This script is safe to run multiple times.${NC}\n"
    
    # Check if this is a re-run
    if command -v yay &>/dev/null && command -v pacui &>/dev/null && [[ -d "$CONFIG_DIR/hyprland" ]]; then
        echo -e "${GREEN}Previous installation detected!${NC}"
        read -p "Do you want to re-run the installation/update? (y/N): " -n 1 -r
    else
        read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    fi
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Run installation steps
    check_root
    check_internet
    
    update_system
    install_yay_first
    install_essential_packages
    install_wayland_apps
    install_ai_dependencies
    configure_services
    create_directories
    install_dotfiles
    install_default_wallpapers
    install_firefox
    install_additional_packages
    final_configuration
    
    show_summary
}

# Run main function
main "$@" 
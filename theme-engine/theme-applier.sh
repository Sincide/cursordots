#!/usr/bin/env fish

# =============================================================================
# Theme Applier - Dynamic Theming System
# =============================================================================
# Description: Main theme application script for atomic theme updates
# Dependencies: All theme engine components
# Author: Dotfiles Dynamic Theming System
# Usage: ./theme-applier.sh <wallpaper_path> [--force] [--dry-run]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname $SCRIPT_DIR)
set CACHE_DIR "$DOTFILES_ROOT/cache"
set THEMES_DIR "$CACHE_DIR/themes"
set LOGS_DIR "$CACHE_DIR/logs"
set BACKUP_DIR "$CACHE_DIR/backups"

# Theme engine scripts
set WALLPAPER_PICKER "$SCRIPT_DIR/wallpaper-picker.sh"
set COLOR_EXTRACTOR "$SCRIPT_DIR/color-extractor.sh"
set THEME_RENDERER "$SCRIPT_DIR/theme-renderer.sh"

# Configuration
set THEME_BACKUP_RETENTION 7  # days
set PARALLEL_RELOADS true

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-applier.log"
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-applier.log"
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-applier.log"
    end
end

function log_success
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-applier.log"
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_theme_engine_dependencies
    set required_scripts $WALLPAPER_PICKER $COLOR_EXTRACTOR $THEME_RENDERER
    set missing_scripts
    
    for script in $required_scripts
        if not test -x "$script"
            set missing_scripts $missing_scripts $script
        end
    end
    
    if test (count $missing_scripts) -gt 0
        log_error "Missing or non-executable theme engine scripts:"
        for script in $missing_scripts
            log_error "  $script"
        end
        return 1
    end
    
    log_debug "All theme engine scripts available"
    return 0
end

function check_system_dependencies
    set required_tools hyprctl waybar dunst swww gsettings
    set missing_tools
    
    for tool in $required_tools
        if not command -v $tool > /dev/null 2>&1
            set missing_tools $missing_tools $tool
        end
    end
    
    if test (count $missing_tools) -gt 0
        log_error "Missing system tools: $missing_tools"
        return 1
    end
    
    log_debug "All system dependencies satisfied"
    return 0
end

# =============================================================================
# Backup Management
# =============================================================================

function create_backup_timestamp
    date '+%Y%m%d_%H%M%S'
end

function create_theme_backup
    set backup_timestamp (create_backup_timestamp)
    set backup_path "$BACKUP_DIR/$backup_timestamp"
    
    log_info "Creating theme backup: $backup_path"
    
    mkdir -p "$backup_path"
    
    # Backup current configurations
    set config_paths \
        ~/.config/hyprland \
        ~/.config/waybar \
        ~/.config/dunst \
        ~/.config/kitty \
        ~/.config/foot \
        ~/.config/fish \
        ~/.config/btop \
        ~/.config/fuzzel \
        ~/.config/gtk-2.0 \
        ~/.config/gtk-3.0 \
        ~/.config/gtk-4.0
    
    for config_path in $config_paths
        if test -e "$config_path"
            set backup_target "$backup_path/"(basename $config_path)
            cp -r "$config_path" "$backup_target" 2>/dev/null
            log_debug "Backed up: $config_path -> $backup_target"
        end
    end
    
    # Backup current theme information
    if test -f "$THEMES_DIR/current-theme.json"
        cp "$THEMES_DIR/current-theme.json" "$backup_path/theme.json"
    end
    
    # Save wallpaper information
    if test -L "$DOTFILES_ROOT/wallpapers/current.jpg"
        set current_wallpaper (readlink "$DOTFILES_ROOT/wallpapers/current.jpg")
        echo $current_wallpaper > "$backup_path/wallpaper.txt"
    end
    
    log_success "Backup created successfully: $backup_path"
    echo $backup_path
end

function cleanup_old_backups
    log_info "Cleaning up old backups (retention: $THEME_BACKUP_RETENTION days)"
    
    if not test -d "$BACKUP_DIR"
        return 0
    end
    
    # Find backups older than retention period
    find "$BACKUP_DIR" -maxdepth 1 -type d -name "20??????_??????" -mtime +$THEME_BACKUP_RETENTION -exec rm -rf {} \; 2>/dev/null
    
    log_debug "Old backup cleanup completed"
end

function restore_from_backup
    set backup_path $argv[1]
    
    if not test -d "$backup_path"
        log_error "Backup path not found: $backup_path"
        return 1
    end
    
    log_info "Restoring from backup: $backup_path"
    
    # Restore configurations
    for backup_item in $backup_path/*
        if test -d "$backup_item"
            set config_name (basename $backup_item)
            set restore_target ~/.config/$config_name
            
            if test -e "$restore_target"
                rm -rf "$restore_target"
            end
            
            cp -r "$backup_item" "$restore_target"
            log_debug "Restored: $backup_item -> $restore_target"
        end
    end
    
    # Restore wallpaper if available
    if test -f "$backup_path/wallpaper.txt"
        set wallpaper_path (cat "$backup_path/wallpaper.txt")
        if test -f "$wallpaper_path"
            ln -sf "$wallpaper_path" "$DOTFILES_ROOT/wallpapers/current.jpg"
            swww img "$wallpaper_path" 2>/dev/null
        end
    end
    
    log_success "Restore completed from: $backup_path"
end

# =============================================================================
# Theme Generation
# =============================================================================

function extract_wallpaper_colors
    set wallpaper_path $argv[1]
    set output_file "$THEMES_DIR/current-theme.json"
    
    log_info "Extracting colors from wallpaper: $wallpaper_path"
    
    # Call color extractor
    if "$COLOR_EXTRACTOR" "$wallpaper_path" --output-file "$output_file"
        log_success "Color extraction completed"
        return 0
    else
        log_error "Color extraction failed"
        return 1
    end
end

function render_theme_templates
    set theme_file "$THEMES_DIR/current-theme.json"
    
    log_info "Rendering theme templates"
    
    # Call theme renderer
    if "$THEME_RENDERER" --theme-file "$theme_file"
        log_success "Theme template rendering completed"
        return 0
    else
        log_error "Theme template rendering failed"
        return 1
    end
end

# =============================================================================
# Application Reloading
# =============================================================================

function reload_hyprland
    log_info "Reloading Hyprland configuration"
    
    if hyprctl reload 2>/dev/null
        log_debug "Hyprland reloaded successfully"
        return 0
    else
        log_error "Failed to reload Hyprland"
        return 1
    end
end

function reload_waybar
    log_info "Reloading Waybar"
    
    # Kill existing waybar instances
    pkill waybar 2>/dev/null
    sleep 1
    
    # Start new waybar instances
    waybar -c ~/.config/waybar/config-primary.json -s ~/.config/waybar/style-primary.css &
    waybar -c ~/.config/waybar/config-secondary.json -s ~/.config/waybar/style-secondary.css &
    
    sleep 2
    
    if pgrep waybar > /dev/null
        log_debug "Waybar reloaded successfully"
        return 0
    else
        log_error "Failed to reload Waybar"
        return 1
    end
end

function reload_dunst
    log_info "Reloading Dunst"
    
    pkill dunst 2>/dev/null
    sleep 1
    dunst &
    
    sleep 1
    
    if pgrep dunst > /dev/null
        log_debug "Dunst reloaded successfully"
        return 0
    else
        log_error "Failed to reload Dunst"
        return 1
    end
end

function update_gtk_themes
    log_info "Updating GTK themes"
    
    # Read current theme colors
    set theme_file "$THEMES_DIR/current-theme.json"
    
    if not test -f "$theme_file"
        log_error "Theme file not found: $theme_file"
        return 1
    end
    
    # Update GTK settings using gsettings
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark" 2>/dev/null
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null
    gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 11" 2>/dev/null
    gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 10" 2>/dev/null
    
    log_debug "GTK themes updated"
    return 0
end

function set_wallpaper
    set wallpaper_path $argv[1]
    
    log_info "Setting wallpaper: $wallpaper_path"
    
    # Check if swww daemon is running
    if not pgrep swww-daemon > /dev/null
        log_info "Starting swww daemon"
        swww init &
        sleep 2
    end
    
    # Set wallpaper with transition
    if swww img "$wallpaper_path" --transition-type wipe --transition-duration 1
        log_debug "Wallpaper set successfully"
        return 0
    else
        log_error "Failed to set wallpaper"
        return 1
    end
end

function send_notification
    set title $argv[1]
    set message $argv[2]
    set urgency $argv[3]
    
    if test -z "$urgency"
        set urgency normal
    end
    
    if command -v notify-send > /dev/null 2>&1
        notify-send --urgency=$urgency "$title" "$message" 2>/dev/null
    end
end

# =============================================================================
# Parallel Application Reloading
# =============================================================================

function reload_applications_parallel
    log_info "Reloading applications in parallel"
    
    set reload_functions reload_hyprland reload_waybar reload_dunst update_gtk_themes
    set background_pids
    
    # Start reload functions in background
    for reload_func in $reload_functions
        $reload_func &
        set background_pids $background_pids $last_pid
    end
    
    # Wait for all background processes
    set success_count 0
    set failed_count 0
    
    for pid in $background_pids
        if wait $pid
            set success_count (math $success_count + 1)
        else
            set failed_count (math $failed_count + 1)
        end
    end
    
    log_info "Application reload completed: $success_count successful, $failed_count failed"
    
    if test $failed_count -gt 0
        return 1
    end
    
    return 0
end

function reload_applications_sequential
    log_info "Reloading applications sequentially"
    
    set success_count 0
    set failed_count 0
    
    # Reload each application sequentially
    if reload_hyprland
        set success_count (math $success_count + 1)
    else
        set failed_count (math $failed_count + 1)
    end
    
    if reload_waybar
        set success_count (math $success_count + 1)
    else
        set failed_count (math $failed_count + 1)
    end
    
    if reload_dunst
        set success_count (math $success_count + 1)
    else
        set failed_count (math $failed_count + 1)
    end
    
    if update_gtk_themes
        set success_count (math $success_count + 1)
    else
        set failed_count (math $failed_count + 1)
    end
    
    log_info "Application reload completed: $success_count successful, $failed_count failed"
    
    if test $failed_count -gt 0
        return 1
    end
    
    return 0
end

# =============================================================================
# Main Theme Application Process
# =============================================================================

function apply_theme
    set wallpaper_path $argv[1]
    set force_apply $argv[2]
    set dry_run $argv[3]
    
    log_info "Starting theme application process"
    log_info "Wallpaper: $wallpaper_path"
    log_info "Force apply: $force_apply"
    log_info "Dry run: $dry_run"
    
    # Validate wallpaper path
    if not test -f "$wallpaper_path"
        log_error "Wallpaper file not found: $wallpaper_path"
        return 1
    end
    
    # Check if theme is already applied for this wallpaper
    if test "$force_apply" != true
        set image_hash (sha256sum "$wallpaper_path" | cut -d' ' -f1)
        set cache_file "$THEMES_DIR/cache_$image_hash.json"
        
        if test -f "$cache_file" -a -f "$THEMES_DIR/current-theme.json"
            set current_hash (sha256sum "$THEMES_DIR/current-theme.json" | cut -d' ' -f1)
            set cached_hash (sha256sum "$cache_file" | cut -d' ' -f1)
            
            if test "$current_hash" = "$cached_hash"
                log_info "Theme already applied for this wallpaper"
                return 0
            end
        end
    end
    
    # Create backup before making changes
    if test "$dry_run" != true
        set backup_path (create_theme_backup)
        if test $status -ne 0
            log_error "Failed to create backup"
            return 1
        end
    end
    
    # Extract colors from wallpaper
    if not extract_wallpaper_colors "$wallpaper_path"
        if test "$dry_run" != true
            log_error "Theme application failed at color extraction"
            restore_from_backup $backup_path
        end
        return 1
    end
    
    if test "$dry_run" = true
        log_info "DRY RUN: Would render theme templates"
    else
        # Render theme templates
        if not render_theme_templates
            log_error "Theme application failed at template rendering"
            restore_from_backup $backup_path
            return 1
        end
    end
    
    if test "$dry_run" = true
        log_info "DRY RUN: Would set wallpaper and reload applications"
    else
        # Set wallpaper
        if not set_wallpaper "$wallpaper_path"
            log_error "Failed to set wallpaper"
            # Continue anyway as theme configs are already applied
        end
        
        # Reload applications
        if test "$PARALLEL_RELOADS" = true
            reload_applications_parallel
        else
            reload_applications_sequential
        end
        
        if test $status -ne 0
            log_error "Some applications failed to reload"
            send_notification "Theme Applied" "Theme applied but some applications failed to reload" "normal"
        else
            log_success "Theme application completed successfully"
            send_notification "Theme Applied" "Dynamic theme applied successfully" "normal"
        end
    end
    
    # Clean up old backups
    if test "$dry_run" != true
        cleanup_old_backups
    end
    
    return 0
end

# =============================================================================
# Setup and Main Function
# =============================================================================

function setup_directories
    mkdir -p $THEMES_DIR
    mkdir -p $LOGS_DIR
    mkdir -p $BACKUP_DIR
    touch "$LOGS_DIR/theme-applier.log"
end

function main
    set wallpaper_path ""
    set force_apply false
    set dry_run false
    
    # Parse command line arguments
    for arg in $argv
        switch $arg
            case --force -f
                set force_apply true
            case --dry-run -n
                set dry_run true
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] <wallpaper_path> [--force] [--dry-run] [--debug] [--help]"
                echo ""
                echo "Apply dynamic theme based on wallpaper colors"
                echo ""
                echo "Arguments:"
                echo "  wallpaper_path       Path to wallpaper image file"
                echo ""
                echo "Options:"
                echo "  --force              Force apply even if theme is cached"
                echo "  --dry-run            Show what would be done without applying"
                echo "  --debug              Enable debug logging"
                echo "  --help               Show this help message"
                return 0
            case -*
                log_error "Unknown option: $arg"
                return 1
            case '*'
                if test -z "$wallpaper_path"
                    set wallpaper_path $arg
                else
                    log_error "Too many arguments. Expected one wallpaper path."
                    return 1
                end
        end
    end
    
    # Validate required arguments
    if test -z "$wallpaper_path"
        log_error "Wallpaper path is required"
        echo "Usage: $argv[0] <wallpaper_path> [options]"
        return 1
    end
    
    # Check dependencies
    if not check_theme_engine_dependencies
        return 1
    end
    
    if not check_system_dependencies
        return 1
    end
    
    # Setup directories
    setup_directories
    
    # Apply theme
    apply_theme "$wallpaper_path" $force_apply $dry_run
    return $status
end

# Execute main function with all arguments
main $argv 
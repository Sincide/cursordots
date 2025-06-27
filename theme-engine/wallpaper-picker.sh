#!/usr/bin/env fish

# =============================================================================
# Wallpaper Picker Script - Dynamic Theming System
# =============================================================================
# Description: Interactive wallpaper selection with thumbnail previews
# Dependencies: fuzzel, rofi-wayland (fallback), swww, imagemagick
# Author: Dotfiles Dynamic Theming System
# Usage: ./wallpaper-picker.sh [--theme-mode]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname $SCRIPT_DIR)
set WALLPAPERS_DIR "$HOME/Pictures/Wallpapers"
set THUMBNAILS_DIR "$DOTFILES_ROOT/cache/thumbnails"
set CACHE_DIR "$DOTFILES_ROOT/cache"
set CURRENT_WALLPAPER "$WALLPAPERS_DIR/current.jpg"

# Configuration
set THUMBNAIL_SIZE "200x150"
set FUZZEL_WIDTH 50
set FUZZEL_HEIGHT 20

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    end
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_dependencies
    set required_tools fuzzel convert swww
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
                case fuzzel
                    echo "  pacman -S fuzzel"
                case convert
                    echo "  pacman -S imagemagick"
                case swww
                    echo "  pacman -S swww"
            end
        end
        return 1
    end
    
    log_debug "All dependencies satisfied"
    return 0
end

# =============================================================================
# Directory Setup
# =============================================================================

function setup_directories
    log_debug "Setting up required directories"
    
    # Create cache directories if they don't exist
    mkdir -p $THUMBNAILS_DIR
    mkdir -p $CACHE_DIR/temp
    mkdir -p $CACHE_DIR/logs
    
    # Ensure wallpapers directory exists
    if not test -d $WALLPAPERS_DIR
        log_error "Wallpapers directory not found: $WALLPAPERS_DIR"
        return 1
    end
    
    log_debug "Directory setup completed"
    return 0
end

# =============================================================================
# Thumbnail Generation
# =============================================================================

function generate_thumbnail
    set wallpaper_path $argv[1]
    set thumbnail_path $argv[2]
    
    log_debug "Generating thumbnail: $wallpaper_path -> $thumbnail_path"
    
    # Skip if thumbnail already exists and is newer than original
    if test -f $thumbnail_path
        if test $thumbnail_path -nt $wallpaper_path
            log_debug "Thumbnail already exists and is current: $thumbnail_path"
            return 0
        end
    end
    
    # Generate thumbnail using ImageMagick
    if convert "$wallpaper_path" -resize $THUMBNAIL_SIZE^ -gravity center -extent $THUMBNAIL_SIZE "$thumbnail_path" 2>/dev/null
        log_debug "Thumbnail generated successfully: $thumbnail_path"
        return 0
    else
        log_error "Failed to generate thumbnail for: $wallpaper_path"
        return 1
    end
end

function generate_all_thumbnails
    log_info "Generating thumbnails for wallpapers..."
    
    set total_wallpapers 0
    set generated_thumbnails 0
    
    # Find all image files in wallpapers directory
    for wallpaper in $WALLPAPERS_DIR/**/*.{jpg,jpeg,png,webp,bmp,tiff}
        # Skip if file doesn't exist (glob expansion failed)
        if not test -f $wallpaper
            continue
        end
        
        set total_wallpapers (math $total_wallpapers + 1)
        
        # Generate thumbnail filename
        set relative_path (string replace $WALLPAPERS_DIR/ "" $wallpaper)
        set thumbnail_name (string replace -a "/" "_" $relative_path)
        set thumbnail_path "$THUMBNAILS_DIR/$thumbnail_name"
        
        # Generate thumbnail
        if generate_thumbnail $wallpaper $thumbnail_path
            set generated_thumbnails (math $generated_thumbnails + 1)
        end
    end
    
    log_info "Thumbnail generation complete: $generated_thumbnails/$total_wallpapers"
    return 0
end

# =============================================================================
# Wallpaper Discovery
# =============================================================================

function find_wallpapers
    set wallpaper_list
    
    # Find all supported image files
    for wallpaper in $WALLPAPERS_DIR/**/*.{jpg,jpeg,png,webp,bmp,tiff}
        if test -f $wallpaper
            set wallpaper_list $wallpaper_list $wallpaper
        end
    end
    
    if test (count $wallpaper_list) -eq 0
        log_error "No wallpapers found in $WALLPAPERS_DIR"
        return 1
    end
    
    log_debug "Found "(count $wallpaper_list)" wallpapers"
    
    # Sort wallpapers by name
    for wallpaper in (printf "%s\n" $wallpaper_list | sort)
        echo $wallpaper
    end
    
    return 0
end

# =============================================================================
# Fuzzel Interface
# =============================================================================

function create_fuzzel_entries
    set entries_file "$CACHE_DIR/temp/fuzzel_wallpaper_entries.txt"
    
    log_debug "Creating fuzzel entries file: $entries_file"
    
    # Clear existing entries
    truncate -s 0 $entries_file
    
    # Create entries with thumbnails
    for wallpaper in (find_wallpapers)
        # Generate display name
        set basename_name (basename $wallpaper)
        set display_name (string replace -r '\.[^.]*$' '' $basename_name)
        
        # Generate thumbnail path
        set relative_path (string replace $WALLPAPERS_DIR/ "" $wallpaper)
        set thumbnail_name (string replace -a "/" "_" $relative_path)
        set thumbnail_path "$THUMBNAILS_DIR/$thumbnail_name"
        
        # Create fuzzel entry with thumbnail (if available)
        if test -f $thumbnail_path
            echo "$display_name\0icon\x1f$thumbnail_path\x1finfo\x1f$wallpaper" >> $entries_file
        else
            echo "$display_name\0info\x1f$wallpaper" >> $entries_file
        end
    end
    
    echo $entries_file
end

function launch_fuzzel
    set entries_file (create_fuzzel_entries)
    
    log_info "Launching fuzzel wallpaper picker..."
    
    # Launch fuzzel with custom configuration
    set selected (cat $entries_file | fuzzel \
        --dmenu \
        --width $FUZZEL_WIDTH \
        --lines $FUZZEL_HEIGHT \
        --prompt "Select wallpaper: " \
        --placeholder "Type to search wallpapers..." \
        --tab-accepts \
        --anchor center \
        --font "JetBrainsMono Nerd Font:size=12" \
        --background-color 282828ee \
        --text-color ebdbb2ff \
        --match-color fabd2fff \
        --selection-color 458588ff \
        --selection-text-color ebdbb2ff \
        --border-width 2 \
        --border-color 458588ff \
        --border-radius 8)
    
    # Clean up temporary file
    rm -f $entries_file
    
    if test -z "$selected"
        log_info "No wallpaper selected"
        return 1
    end
    
    # Extract wallpaper path from selection
    set wallpaper_path (echo $selected | grep -o '/.*')
    
    if test -z "$wallpaper_path" -o ! -f "$wallpaper_path"
        log_error "Invalid wallpaper selection: $selected"
        return 1
    end
    
    log_info "Selected wallpaper: $wallpaper_path"
    echo $wallpaper_path
    return 0
end

# =============================================================================
# Rofi Fallback Interface
# =============================================================================

function launch_rofi_fallback
    log_info "Fuzzel unavailable, falling back to rofi..."
    
    # Check if rofi is available
    if not command -v rofi > /dev/null 2>&1
        log_error "Rofi fallback not available"
        return 1
    end
    
    set wallpaper_list (find_wallpapers)
    
    # Create display entries for rofi
    set display_entries
    for wallpaper in $wallpaper_list
        set basename_name (basename $wallpaper)
        set display_name (string replace -r '\.[^.]*$' '' $basename_name)
        set display_entries $display_entries $display_name
    end
    
    # Launch rofi
    set selected_index (printf "%s\n" $display_entries | rofi \
        -dmenu \
        -i \
        -p "Select wallpaper" \
        -theme-str 'window {width: 50%; height: 60%;}' \
        -format d)
    
    if test -z "$selected_index"
        log_info "No wallpaper selected"
        return 1
    end
    
    # Get wallpaper path by index
    set wallpaper_path $wallpaper_list[$selected_index]
    
    if test -z "$wallpaper_path" -o ! -f "$wallpaper_path"
        log_error "Invalid wallpaper selection index: $selected_index"
        return 1
    end
    
    log_info "Selected wallpaper: $wallpaper_path"
    echo $wallpaper_path
    return 0
end

# =============================================================================
# Current Wallpaper Management
# =============================================================================

function set_current_wallpaper
    set wallpaper_path $argv[1]
    
    log_info "Setting current wallpaper: $wallpaper_path"
    
    # Update current wallpaper symlink
    if test -L $CURRENT_WALLPAPER
        rm $CURRENT_WALLPAPER
    end
    
    ln -s $wallpaper_path $CURRENT_WALLPAPER
    
    # Apply wallpaper using swww
    if command -v swww > /dev/null 2>&1
        # Check if swww daemon is running
        if not pgrep -x swww-daemon > /dev/null
            log_info "Starting swww daemon..."
            swww init &
            sleep 2
        end
        
        # Set wallpaper with transition
        swww img "$wallpaper_path" \
            --transition-type wipe \
            --transition-duration 1 \
            --transition-fps 60
        
        log_info "Wallpaper applied successfully"
    else
        log_error "swww not available for wallpaper setting"
        return 1
    end
    
    return 0
end

# =============================================================================
# Main Function
# =============================================================================

function main
    set theme_mode false
    
    # Parse command line arguments
    for arg in $argv
        switch $arg
            case --theme-mode
                set theme_mode true
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] [--theme-mode] [--debug] [--help]"
                echo ""
                echo "Options:"
                echo "  --theme-mode    Apply theme after wallpaper selection"
                echo "  --debug         Enable debug logging"
                echo "  --help          Show this help message"
                return 0
        end
    end
    
    log_info "Starting wallpaper picker..."
    
    # Check dependencies
    if not check_dependencies
        return 1
    end
    
    # Setup directories
    if not setup_directories
        return 1
    end
    
    # Generate thumbnails
    generate_all_thumbnails
    
    # Launch wallpaper picker interface
    set selected_wallpaper
    if command -v fuzzel > /dev/null 2>&1
        set selected_wallpaper (launch_fuzzel)
    else
        set selected_wallpaper (launch_rofi_fallback)
    end
    
    # Check if wallpaper was selected
    if test $status -ne 0 -o -z "$selected_wallpaper"
        log_info "Wallpaper selection cancelled"
        return 1
    end
    
    # Set the selected wallpaper
    if not set_current_wallpaper $selected_wallpaper
        return 1
    end
    
    # Apply theme if requested
    if test $theme_mode = true
        log_info "Applying theme based on selected wallpaper..."
        if test -x "$SCRIPT_DIR/theme-applier.sh"
            exec "$SCRIPT_DIR/theme-applier.sh" $selected_wallpaper
        else
            log_error "Theme applier script not found or not executable"
            return 1
        end
    end
    
    log_info "Wallpaper picker completed successfully"
    echo $selected_wallpaper
    return 0
end

# Execute main function with all arguments
main $argv 
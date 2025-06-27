#!/usr/bin/env fish

# =============================================================================
# Symlink Manager - Dynamic Theming System
# =============================================================================
# Description: Comprehensive symlink management for dotfiles deployment
# Dependencies: stow (optional), find, ln
# Author: Dotfiles Dynamic Theming System
# Usage: ./symlink-manager.sh [install|uninstall|status|update] [--force] [--dry-run]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname (dirname $SCRIPT_DIR))
set SOURCE_DIR "$DOTFILES_ROOT/dotfiles"
set TARGET_HOME $HOME
set CACHE_DIR "$DOTFILES_ROOT/cache"
set LOGS_DIR "$CACHE_DIR/logs"
set BACKUP_DIR "$CACHE_DIR/backups/symlinks"

# Symlink mapping configuration
set SYMLINK_MAPPINGS \
    "hyprland:.config/hyprland" \
    "waybar:.config/waybar" \
    "foot:.config/foot" \
    "fish:.config/fish" \
    "dunst:.config/dunst" \
    "fuzzel:.config/fuzzel" \
    "btop:.config/btop" \
    "gtk-3.0:.config/gtk-3.0" \
    "fonts/.fonts:.fonts"

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/symlink-manager.log"
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/symlink-manager.log"
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/symlink-manager.log"
    end
end

function log_success
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/symlink-manager.log"
end

function log_warning
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/symlink-manager.log"
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_dependencies
    set required_tools find ln readlink dirname basename
    set missing_tools
    
    for tool in $required_tools
        if not command -v $tool > /dev/null 2>&1
            set missing_tools $missing_tools $tool
        end
    end
    
    if test (count $missing_tools) -gt 0
        log_error "Missing required tools: $missing_tools"
        return 1
    end
    
    # Check for optional stow
    if command -v stow > /dev/null 2>&1
        log_debug "GNU Stow is available"
        set -g STOW_AVAILABLE true
    else
        log_debug "GNU Stow not available, using manual symlink management"
        set -g STOW_AVAILABLE false
    end
    
    log_debug "All dependencies satisfied"
    return 0
end

# =============================================================================
# Backup Management
# =============================================================================

function create_backup_timestamp
    date '+%Y%m%d_%H%M%S'
end

function backup_existing_file
    set target_path $argv[1]
    set backup_timestamp $argv[2]
    
    if not test -e "$target_path"
        return 0
    end
    
    set backup_dir "$BACKUP_DIR/$backup_timestamp"
    mkdir -p "$backup_dir"
    
    # Create relative path structure in backup
    set relative_path (string replace "$TARGET_HOME/" "" "$target_path")
    set backup_target "$backup_dir/$relative_path"
    set backup_parent (dirname "$backup_target")
    
    mkdir -p "$backup_parent"
    
    if test -L "$target_path"
        # Backup symlink information
        set link_target (readlink "$target_path")
        echo "$link_target" > "$backup_target.symlink"
        log_debug "Backed up symlink: $target_path -> $link_target"
    else
        # Backup actual file/directory
        cp -r "$target_path" "$backup_target" 2>/dev/null
        log_debug "Backed up file: $target_path -> $backup_target"
    end
end

function restore_from_backup
    set backup_timestamp $argv[1]
    set backup_dir "$BACKUP_DIR/$backup_timestamp"
    
    if not test -d "$backup_dir"
        log_error "Backup directory not found: $backup_dir"
        return 1
    end
    
    log_info "Restoring from backup: $backup_timestamp"
    
    # Find all backed up items
    for backup_item in (find "$backup_dir" -type f -o -type d | grep -v '\.symlink$')
        set relative_path (string replace "$backup_dir/" "" "$backup_item")
        set restore_target "$TARGET_HOME/$relative_path"
        
        # Remove current symlink/file if exists
        if test -e "$restore_target" -o -L "$restore_target"
            rm -rf "$restore_target"
        end
        
        # Create parent directory
        set restore_parent (dirname "$restore_target")
        mkdir -p "$restore_parent"
        
        # Restore file/directory
        cp -r "$backup_item" "$restore_target"
        log_debug "Restored: $backup_item -> $restore_target"
    end
    
    # Restore symlinks
    for symlink_file in (find "$backup_dir" -name "*.symlink")
        set relative_path (string replace "$backup_dir/" "" "$symlink_file")
        set relative_path (string replace ".symlink" "" "$relative_path")
        set target_path "$TARGET_HOME/$relative_path"
        set link_target (cat "$symlink_file")
        
        # Remove current file if exists
        if test -e "$target_path" -o -L "$target_path"
            rm -rf "$target_path"
        end
        
        # Create parent directory
        set target_parent (dirname "$target_path")
        mkdir -p "$target_parent"
        
        # Restore symlink
        ln -s "$link_target" "$target_path"
        log_debug "Restored symlink: $target_path -> $link_target"
    end
    
    log_success "Restore completed from backup: $backup_timestamp"
end

# =============================================================================
# Symlink Operations
# =============================================================================

function create_symlink
    set source_path $argv[1]
    set target_path $argv[2]
    set force $argv[3]
    set dry_run $argv[4]
    
    log_debug "Creating symlink: $source_path -> $target_path"
    
    # Check if source exists
    if not test -e "$source_path"
        log_error "Source path does not exist: $source_path"
        return 1
    end
    
    # Create target directory
    set target_dir (dirname "$target_path")
    if test "$dry_run" != true
        mkdir -p "$target_dir"
    else
        log_info "DRY RUN: Would create directory: $target_dir"
    end
    
    # Handle existing target
    if test -e "$target_path" -o -L "$target_path"
        if test -L "$target_path"
            set existing_target (readlink "$target_path")
            if test "$existing_target" = "$source_path"
                log_debug "Symlink already exists and points to correct target: $target_path"
                return 0
            end
        end
        
        if test "$force" != true
            log_warning "Target already exists: $target_path"
            return 1
        else
            if test "$dry_run" != true
                rm -rf "$target_path"
                log_debug "Removed existing target: $target_path"
            else
                log_info "DRY RUN: Would remove existing target: $target_path"
            end
        end
    end
    
    # Create symlink
    if test "$dry_run" != true
        if ln -s "$source_path" "$target_path"
            log_debug "Created symlink: $target_path -> $source_path"
            return 0
        else
            log_error "Failed to create symlink: $target_path -> $source_path"
            return 1
        end
    else
        log_info "DRY RUN: Would create symlink: $target_path -> $source_path"
        return 0
    end
end

function remove_symlink
    set target_path $argv[1]
    set dry_run $argv[2]
    
    if not test -L "$target_path"
        log_debug "Target is not a symlink: $target_path"
        return 0
    end
    
    if test "$dry_run" != true
        if rm "$target_path"
            log_debug "Removed symlink: $target_path"
            return 0
        else
            log_error "Failed to remove symlink: $target_path"
            return 1
        end
    else
        log_info "DRY RUN: Would remove symlink: $target_path"
        return 0
    end
end

# =============================================================================
# Stow Integration
# =============================================================================

function install_with_stow
    set force $argv[1]
    set dry_run $argv[2]
    
    log_info "Installing dotfiles using GNU Stow"
    
    set stow_args --target="$TARGET_HOME" --dir="$DOTFILES_ROOT"
    
    if test "$force" = true
        set stow_args $stow_args --restow
    end
    
    if test "$dry_run" = true
        set stow_args $stow_args --simulate
    end
    
    if test "$DEBUG" = "1"
        set stow_args $stow_args --verbose
    end
    
    # Stow the dotfiles directory
    if stow $stow_args dotfiles
        log_success "Stow installation completed"
        return 0
    else
        log_error "Stow installation failed"
        return 1
    end
end

function uninstall_with_stow
    set dry_run $argv[1]
    
    log_info "Uninstalling dotfiles using GNU Stow"
    
    set stow_args --target="$TARGET_HOME" --dir="$DOTFILES_ROOT" --delete
    
    if test "$dry_run" = true
        set stow_args $stow_args --simulate
    end
    
    if test "$DEBUG" = "1"
        set stow_args $stow_args --verbose
    end
    
    # Unstow the dotfiles directory
    if stow $stow_args dotfiles
        log_success "Stow uninstallation completed"
        return 0
    else
        log_error "Stow uninstallation failed"
        return 1
    end
end

# =============================================================================
# Manual Symlink Management
# =============================================================================

function install_symlinks_manual
    set force $argv[1]
    set dry_run $argv[2]
    set backup_timestamp $argv[3]
    
    log_info "Installing symlinks manually"
    
    set success_count 0
    set failed_count 0
    
    for mapping in $SYMLINK_MAPPINGS
        set source_rel (echo $mapping | cut -d':' -f1)
        set target_rel (echo $mapping | cut -d':' -f2)
        
        set source_path "$SOURCE_DIR/$source_rel"
        set target_path "$TARGET_HOME/$target_rel"
        
        # Backup existing file if needed
        if test "$dry_run" != true -a "$force" = true
            backup_existing_file "$target_path" $backup_timestamp
        end
        
        # Create symlink
        if create_symlink "$source_path" "$target_path" $force $dry_run
            set success_count (math $success_count + 1)
        else
            set failed_count (math $failed_count + 1)
        end
    end
    
    log_info "Manual symlink installation: $success_count successful, $failed_count failed"
    
    if test $failed_count -gt 0
        return 1
    end
    
    return 0
end

function uninstall_symlinks_manual
    set dry_run $argv[1]
    
    log_info "Uninstalling symlinks manually"
    
    set success_count 0
    set failed_count 0
    
    for mapping in $SYMLINK_MAPPINGS
        set target_rel (echo $mapping | cut -d':' -f2)
        set target_path "$TARGET_HOME/$target_rel"
        
        if remove_symlink "$target_path" $dry_run
            set success_count (math $success_count + 1)
        else
            set failed_count (math $failed_count + 1)
        end
    end
    
    log_info "Manual symlink uninstallation: $success_count successful, $failed_count failed"
    
    if test $failed_count -gt 0
        return 1
    end
    
    return 0
end

# =============================================================================
# Status Checking
# =============================================================================

function check_symlink_status
    log_info "Checking symlink status"
    
    set installed_count 0
    set broken_count 0
    set missing_count 0
    set conflict_count 0
    
    for mapping in $SYMLINK_MAPPINGS
        set source_rel (echo $mapping | cut -d':' -f1)
        set target_rel (echo $mapping | cut -d':' -f2)
        
        set source_path "$SOURCE_DIR/$source_rel"
        set target_path "$TARGET_HOME/$target_rel"
        
        if test -L "$target_path"
            set link_target (readlink "$target_path")
            if test "$link_target" = "$source_path"
                echo "✓ $target_rel -> $source_rel"
                set installed_count (math $installed_count + 1)
            else
                echo "✗ $target_rel -> $link_target (expected: $source_rel)"
                set broken_count (math $broken_count + 1)
            end
        else if test -e "$target_path"
            echo "! $target_rel exists but is not a symlink"
            set conflict_count (math $conflict_count + 1)
        else
            echo "- $target_rel not installed"
            set missing_count (math $missing_count + 1)
        end
    end
    
    echo ""
    echo "Status Summary:"
    echo "  Installed: $installed_count"
    echo "  Missing: $missing_count"
    echo "  Broken: $broken_count"
    echo "  Conflicts: $conflict_count"
    
    if test $broken_count -gt 0 -o $conflict_count -gt 0
        return 1
    end
    
    return 0
end

# =============================================================================
# Main Operations
# =============================================================================

function install_dotfiles
    set force $argv[1]
    set dry_run $argv[2]
    
    log_info "Installing dotfiles"
    
    # Create backup timestamp for manual method
    set backup_timestamp (create_backup_timestamp)
    
    # Use Stow if available, otherwise manual
    if test "$STOW_AVAILABLE" = true
        install_with_stow $force $dry_run
    else
        install_symlinks_manual $force $dry_run $backup_timestamp
    end
    
    return $status
end

function uninstall_dotfiles
    set dry_run $argv[1]
    
    log_info "Uninstalling dotfiles"
    
    # Use Stow if available, otherwise manual
    if test "$STOW_AVAILABLE" = true
        uninstall_with_stow $dry_run
    else
        uninstall_symlinks_manual $dry_run
    end
    
    return $status
end

function update_dotfiles
    set force $argv[1]
    set dry_run $argv[2]
    
    log_info "Updating dotfiles (reinstalling)"
    
    # Uninstall first, then install
    if uninstall_dotfiles $dry_run
        install_dotfiles $force $dry_run
        return $status
    else
        log_error "Failed to uninstall before update"
        return 1
    end
end

# =============================================================================
# Setup and Main Function
# =============================================================================

function setup_directories
    mkdir -p $LOGS_DIR
    mkdir -p $BACKUP_DIR
    touch "$LOGS_DIR/symlink-manager.log"
end

function main
    set operation ""
    set force false
    set dry_run false
    
    # Parse command line arguments
    for arg in $argv
        switch $arg
            case install uninstall status update
                if test -z "$operation"
                    set operation $arg
                else
                    log_error "Multiple operations specified"
                    return 1
                end
            case --force -f
                set force true
            case --dry-run -n
                set dry_run true
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] <operation> [--force] [--dry-run] [--debug] [--help]"
                echo ""
                echo "Manage symlinks for dotfiles deployment"
                echo ""
                echo "Operations:"
                echo "  install              Install dotfiles symlinks"
                echo "  uninstall            Remove dotfiles symlinks"
                echo "  status               Check symlink status"
                echo "  update               Update (reinstall) dotfiles symlinks"
                echo ""
                echo "Options:"
                echo "  --force              Force operation, overwrite existing files"
                echo "  --dry-run            Show what would be done without applying"
                echo "  --debug              Enable debug logging"
                echo "  --help               Show this help message"
                return 0
            case -*
                log_error "Unknown option: $arg"
                return 1
            case '*'
                if test -z "$operation"
                    set operation $arg
                else
                    log_error "Extra argument: $arg"
                    return 1
                end
        end
    end
    
    # Validate operation
    if test -z "$operation"
        log_error "No operation specified"
        echo "Usage: $argv[0] <operation> [options]"
        echo "Use --help for more information"
        return 1
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
            install_dotfiles $force $dry_run
        case uninstall
            uninstall_dotfiles $dry_run
        case status
            check_symlink_status
        case update
            update_dotfiles $force $dry_run
        case '*'
            log_error "Unknown operation: $operation"
            return 1
    end
    
    return $status
end

# Execute main function with all arguments
main $argv 
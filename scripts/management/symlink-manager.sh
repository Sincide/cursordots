#!/usr/bin/env bash

# =============================================================================
# Symlink Manager - Dynamic Theming System
# =============================================================================
# Description: Comprehensive symlink management for dotfiles deployment
# Dependencies: stow (optional), find, ln
# Author: Dotfiles Dynamic Theming System
# Usage: ./symlink-manager.sh [install|uninstall|status|update] [--force] [--dry-run]
# =============================================================================

# Set script directory and configuration paths
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DOTFILES_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SOURCE_DIR="$DOTFILES_ROOT/dotfiles"
TARGET_HOME="$HOME"
CACHE_DIR="$DOTFILES_ROOT/cache"
LOGS_DIR="$CACHE_DIR/logs"
BACKUP_DIR="$CACHE_DIR/backups/symlinks"

# Symlink mapping configuration
SYMLINK_MAPPINGS=(
    "hyprland:.config/hypr"
    "waybar:.config/waybar"
    "foot:.config/foot"
    "fish:.config/fish"
    "dunst:.config/dunst"
    "fuzzel:.config/fuzzel"
    "btop:.config/btop"
    "gtk-3.0:.config/gtk-3.0"
    "fonts/.fonts:.fonts"
)

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGS_DIR/symlink-manager.log"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGS_DIR/symlink-manager.log"
}

log_debug() {
    if [[ "$DEBUG" == "1" ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGS_DIR/symlink-manager.log"
    fi
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGS_DIR/symlink-manager.log"
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGS_DIR/symlink-manager.log"
}

# =============================================================================
# Dependency Checking
# =============================================================================

check_dependencies() {
    local required_tools=(find ln readlink dirname basename)
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    # Check for optional stow
    if command -v stow > /dev/null 2>&1; then
        log_debug "GNU Stow is available"
        STOW_AVAILABLE=true
    else
        log_debug "GNU Stow not available, using manual symlink management"
        STOW_AVAILABLE=false
    fi
    
    log_debug "All dependencies satisfied"
    return 0
}

# =============================================================================
# Backup Management
# =============================================================================

create_backup_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

backup_existing_file() {
    local target_path="$1"
    local backup_timestamp="$2"
    
    if [[ ! -e "$target_path" ]]; then
        return 0
    fi
    
    local backup_dir="$BACKUP_DIR/$backup_timestamp"
    mkdir -p "$backup_dir"
    
    # Create relative path structure in backup
    local relative_path="${target_path#$TARGET_HOME/}"
    local backup_target="$backup_dir/$relative_path"
    local backup_parent="$(dirname "$backup_target")"
    
    mkdir -p "$backup_parent"
    
    if [[ -L "$target_path" ]]; then
        # Backup symlink information
        local link_target="$(readlink "$target_path")"
        echo "$link_target" > "$backup_target.symlink"
        log_debug "Backed up symlink: $target_path -> $link_target"
    else
        # Backup actual file/directory
        cp -r "$target_path" "$backup_target" 2>/dev/null
        log_debug "Backed up file: $target_path -> $backup_target"
    fi
}

restore_from_backup() {
    local backup_timestamp="$1"
    local backup_dir="$BACKUP_DIR/$backup_timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "Restoring from backup: $backup_timestamp"
    
    # Find all backed up items
    while IFS= read -r -d '' backup_item; do
        [[ "$backup_item" == *.symlink ]] && continue
        
        local relative_path="${backup_item#$backup_dir/}"
        local restore_target="$TARGET_HOME/$relative_path"
        
        # Remove current symlink/file if exists
        if [[ -e "$restore_target" || -L "$restore_target" ]]; then
            rm -rf "$restore_target"
        fi
        
        # Create parent directory
        local restore_parent="$(dirname "$restore_target")"
        mkdir -p "$restore_parent"
        
        # Restore file/directory
        cp -r "$backup_item" "$restore_target"
        log_debug "Restored: $backup_item -> $restore_target"
    done < <(find "$backup_dir" \( -type f -o -type d \) -print0)
    
    # Restore symlinks
    while IFS= read -r -d '' symlink_file; do
        local relative_path="${symlink_file#$backup_dir/}"
        relative_path="${relative_path%.symlink}"
        local target_path="$TARGET_HOME/$relative_path"
        local link_target="$(cat "$symlink_file")"
        
        # Remove current file if exists
        if [[ -e "$target_path" || -L "$target_path" ]]; then
            rm -rf "$target_path"
        fi
        
        # Create parent directory
        local target_parent="$(dirname "$target_path")"
        mkdir -p "$target_parent"
        
        # Restore symlink
        ln -s "$link_target" "$target_path"
        log_debug "Restored symlink: $target_path -> $link_target"
    done < <(find "$backup_dir" -name "*.symlink" -print0)
    
    log_success "Restore completed from backup: $backup_timestamp"
}

# =============================================================================
# Symlink Operations
# =============================================================================

create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local force="$3"
    local dry_run="$4"
    
    log_debug "Creating symlink: $source_path -> $target_path"
    
    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
        log_error "Source does not exist: $source_path"
        return 1
    fi
    
    # Create parent directory for target
    local target_parent="$(dirname "$target_path")"
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$target_parent"
    else
        log_debug "[DRY-RUN] Would create directory: $target_parent"
    fi
    
    # Handle existing target
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        if [[ "$force" == "true" ]]; then
            log_debug "Forcing removal of existing target: $target_path"
            if [[ "$dry_run" != "true" ]]; then
                rm -rf "$target_path"
            else
                log_debug "[DRY-RUN] Would remove: $target_path"
            fi
        else
            log_error "Target already exists: $target_path (use --force to overwrite)"
            return 1
        fi
    fi
    
    # Create symlink
    if [[ "$dry_run" != "true" ]]; then
        if ln -s "$source_path" "$target_path"; then
            log_success "Created symlink: $target_path -> $source_path"
            return 0
        else
            log_error "Failed to create symlink: $target_path -> $source_path"
            return 1
        fi
    else
        log_debug "[DRY-RUN] Would create symlink: $target_path -> $source_path"
        return 0
    fi
}

remove_symlink() {
    local target_path="$1"
    local dry_run="$2"
    
    log_debug "Removing symlink: $target_path"
    
    if [[ ! -L "$target_path" ]]; then
        if [[ -e "$target_path" ]]; then
            log_warning "Target exists but is not a symlink: $target_path"
            return 1
        else
            log_debug "Target does not exist: $target_path"
            return 0
        fi
    fi
    
    if [[ "$dry_run" != "true" ]]; then
        if rm "$target_path"; then
            log_success "Removed symlink: $target_path"
            return 0
        else
            log_error "Failed to remove symlink: $target_path"
            return 1
        fi
    else
        log_debug "[DRY-RUN] Would remove symlink: $target_path"
        return 0
    fi
}

# =============================================================================
# Stow Integration
# =============================================================================

install_with_stow() {
    local force="$1"
    local dry_run="$2"
    
    log_info "Installing dotfiles with GNU Stow"
    
    local stow_args=()
    [[ "$force" == "true" ]] && stow_args+=("--restow")
    [[ "$dry_run" == "true" ]] && stow_args+=("--simulate")
    
    cd "$DOTFILES_ROOT" || {
        log_error "Failed to change to dotfiles directory: $DOTFILES_ROOT"
        return 1
    }
    
    if stow "${stow_args[@]}" --target="$TARGET_HOME" dotfiles; then
        log_success "Successfully installed dotfiles with Stow"
        return 0
    else
        log_error "Failed to install dotfiles with Stow"
        return 1
    fi
}

uninstall_with_stow() {
    local dry_run="$1"
    
    log_info "Uninstalling dotfiles with GNU Stow"
    
    local stow_args=("--delete")
    [[ "$dry_run" == "true" ]] && stow_args+=("--simulate")
    
    cd "$DOTFILES_ROOT" || {
        log_error "Failed to change to dotfiles directory: $DOTFILES_ROOT"
        return 1
    }
    
    if stow "${stow_args[@]}" --target="$TARGET_HOME" dotfiles; then
        log_success "Successfully uninstalled dotfiles with Stow"
        return 0
    else
        log_error "Failed to uninstall dotfiles with Stow"
        return 1
    fi
}

# =============================================================================
# Manual Symlink Management
# =============================================================================

install_symlinks_manual() {
    local force="$1"
    local dry_run="$2"
    local backup_timestamp="$3"
    
    log_info "Installing dotfiles with manual symlink management"
    
    local success_count=0
    local error_count=0
    
    for mapping in "${SYMLINK_MAPPINGS[@]}"; do
        local source_rel="${mapping%%:*}"
        local target_rel="${mapping##*:}"
        
        local source_path="$SOURCE_DIR/$source_rel"
        local target_path="$TARGET_HOME/$target_rel"
        
        log_debug "Processing mapping: $source_rel -> $target_rel"
        
        # Backup existing file if not dry run
        if [[ "$dry_run" != "true" ]]; then
            backup_existing_file "$target_path" "$backup_timestamp"
        fi
        
        if create_symlink "$source_path" "$target_path" "$force" "$dry_run"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done
    
    log_info "Installation completed: $success_count successful, $error_count failed"
    
    if [[ $error_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

uninstall_symlinks_manual() {
    local dry_run="$1"
    
    log_info "Uninstalling dotfiles with manual symlink management"
    
    local success_count=0
    local error_count=0
    
    for mapping in "${SYMLINK_MAPPINGS[@]}"; do
        local source_rel="${mapping%%:*}"
        local target_rel="${mapping##*:}"
        
        local target_path="$TARGET_HOME/$target_rel"
        
        log_debug "Processing removal: $target_rel"
        
        if remove_symlink "$target_path" "$dry_run"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done
    
    log_info "Uninstallation completed: $success_count successful, $error_count failed"
    
    if [[ $error_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# =============================================================================
# Status Checking
# =============================================================================

check_symlink_status() {
    log_info "Checking symlink status"
    
    local installed_count=0
    local broken_count=0
    local missing_count=0
    local conflict_count=0
    
    for mapping in "${SYMLINK_MAPPINGS[@]}"; do
        local source_rel="${mapping%%:*}"
        local target_rel="${mapping##*:}"
        
        local source_path="$SOURCE_DIR/$source_rel"
        local target_path="$TARGET_HOME/$target_rel"
        
        if [[ -L "$target_path" ]]; then
            local link_target="$(readlink "$target_path")"
            if [[ "$link_target" == "$source_path" ]]; then
                echo "✓ $target_rel -> $source_rel"
                ((installed_count++))
            else
                echo "✗ $target_rel -> $link_target (expected: $source_rel)"
                ((broken_count++))
            fi
        elif [[ -e "$target_path" ]]; then
            echo "! $target_rel exists but is not a symlink"
            ((conflict_count++))
        else
            echo "- $target_rel not installed"
            ((missing_count++))
        fi
    done
    
    echo ""
    echo "Status Summary:"
    echo "  Installed: $installed_count"
    echo "  Missing: $missing_count"
    echo "  Broken: $broken_count"
    echo "  Conflicts: $conflict_count"
    
    if [[ $broken_count -gt 0 || $conflict_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# =============================================================================
# Main Operations
# =============================================================================

install_dotfiles() {
    local force="$1"
    local dry_run="$2"
    
    log_info "Installing dotfiles"
    
    # Create backup timestamp for manual method
    local backup_timestamp="$(create_backup_timestamp)"
    
    # Use Stow if available, otherwise manual
    if [[ "$STOW_AVAILABLE" == "true" ]]; then
        install_with_stow "$force" "$dry_run"
    else
        install_symlinks_manual "$force" "$dry_run" "$backup_timestamp"
    fi
    
    return $?
}

uninstall_dotfiles() {
    local dry_run="$1"
    
    log_info "Uninstalling dotfiles"
    
    # Use Stow if available, otherwise manual
    if [[ "$STOW_AVAILABLE" == "true" ]]; then
        uninstall_with_stow "$dry_run"
    else
        uninstall_symlinks_manual "$dry_run"
    fi
    
    return $?
}

update_dotfiles() {
    local force="$1"
    local dry_run="$2"
    
    log_info "Updating dotfiles (reinstalling)"
    
    # Uninstall first, then install
    if uninstall_dotfiles "$dry_run"; then
        install_dotfiles "$force" "$dry_run"
        return $?
    else
        log_error "Failed to uninstall before update"
        return 1
    fi
}

# =============================================================================
# Setup and Main Function
# =============================================================================

setup_directories() {
    mkdir -p "$LOGS_DIR"
    mkdir -p "$BACKUP_DIR"
    touch "$LOGS_DIR/symlink-manager.log"
}

main() {
    local operation=""
    local force=false
    local dry_run=false
    
    # Parse command line arguments
    for arg in "$@"; do
        case "$arg" in
            install|uninstall|status|update)
                if [[ -z "$operation" ]]; then
                    operation="$arg"
                else
                    log_error "Multiple operations specified"
                    return 1
                fi
                ;;
            --force|-f)
                force=true
                ;;
            --dry-run|-n)
                dry_run=true
                ;;
            --debug)
                DEBUG=1
                ;;
            --help|-h)
                echo "Usage: $(basename "$0") <operation> [--force] [--dry-run] [--debug] [--help]"
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
                ;;
            -*)
                log_error "Unknown option: $arg"
                return 1
                ;;
            *)
                if [[ -z "$operation" ]]; then
                    operation="$arg"
                else
                    log_error "Extra argument: $arg"
                    return 1
                fi
                ;;
        esac
    done
    
    # Validate operation
    if [[ -z "$operation" ]]; then
        log_error "No operation specified"
        echo "Usage: $(basename "$0") <operation> [options]"
        echo "Use --help for more information"
        return 1
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Setup directories
    setup_directories
    
    # Execute operation
    case "$operation" in
        install)
            install_dotfiles "$force" "$dry_run"
            ;;
        uninstall)
            uninstall_dotfiles "$dry_run"
            ;;
        status)
            check_symlink_status
            ;;
        update)
            update_dotfiles "$force" "$dry_run"
            ;;
        *)
            log_error "Unknown operation: $operation"
            return 1
            ;;
    esac
    
    return $?
}

# Execute main function with all arguments
main "$@" 
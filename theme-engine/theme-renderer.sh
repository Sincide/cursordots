#!/usr/bin/env fish

# =============================================================================
# Theme Renderer - Dynamic Theming System
# =============================================================================
# Description: Process template files and generate themed configurations
# Dependencies: jq, sed, find
# Author: Dotfiles Dynamic Theming System
# Usage: ./theme-renderer.sh [--theme-file] [--template-dir] [--output-dir]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname $SCRIPT_DIR)
set TEMPLATES_DIR "$DOTFILES_ROOT/templates"
set OUTPUT_DIR "$DOTFILES_ROOT/dotfiles"
set CACHE_DIR "$DOTFILES_ROOT/cache"
set THEMES_DIR "$CACHE_DIR/themes"
set LOGS_DIR "$CACHE_DIR/logs"

# Default theme file
set DEFAULT_THEME_FILE "$THEMES_DIR/current-theme.json"

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-renderer.log"
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-renderer.log"
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/theme-renderer.log"
    end
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_dependencies
    set required_tools jq sed find
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
                case jq
                    echo "  pacman -S jq"
                case sed
                    echo "  pacman -S sed"
                case find
                    echo "  pacman -S findutils"
            end
        end
        return 1
    end
    
    log_debug "All dependencies satisfied"
    return 0
end

# =============================================================================
# Theme Loading and Validation
# =============================================================================

function load_theme_colors
    set theme_file $argv[1]
    
    log_debug "Loading theme colors from: $theme_file"
    
    if not test -f "$theme_file"
        log_error "Theme file not found: $theme_file"
        return 1
    end
    
    # Validate JSON syntax
    if not jq empty "$theme_file" 2>/dev/null
        log_error "Invalid JSON in theme file: $theme_file"
        return 1
    end
    
    # Required color keys
    set required_keys primary secondary tertiary surface background accent error warning success text_primary text_secondary text_disabled
    
    # Validate all required keys exist
    for key in $required_keys
        set color_value (jq -r ".$key // empty" "$theme_file")
        
        if test -z "$color_value" -o "$color_value" = "null"
            log_error "Missing required color key: $key"
            return 1
        end
        
        log_debug "Loaded $key: $color_value"
    end
    
    log_info "Theme colors loaded successfully"
    return 0
end

function extract_color_variables
    set theme_file $argv[1]
    
    # Extract all colors and create variable assignments
    set color_vars
    
    # Primary colors
    set primary (jq -r '.primary' "$theme_file")
    set secondary (jq -r '.secondary' "$theme_file")
    set tertiary (jq -r '.tertiary' "$theme_file")
    set surface (jq -r '.surface' "$theme_file")
    set background (jq -r '.background' "$theme_file")
    set accent (jq -r '.accent' "$theme_file")
    
    # Status colors
    set error (jq -r '.error' "$theme_file")
    set warning (jq -r '.warning' "$theme_file")
    set success (jq -r '.success' "$theme_file")
    
    # Text colors
    set text_primary (jq -r '.text_primary' "$theme_file")
    set text_secondary (jq -r '.text_secondary' "$theme_file")
    set text_disabled (jq -r '.text_disabled' "$theme_file")
    
    # Additional derived colors
    set primary_light (lighten_color $primary 20)
    set primary_dark (darken_color $primary 20)
    set secondary_light (lighten_color $secondary 20)
    set secondary_dark (darken_color $secondary 20)
    
    # Border colors
    set border (mix_colors $text_disabled $surface 50)
    set border_focus $accent
    
    # Store all variables in associative array format
    echo "PRIMARY_COLOR=$primary"
    echo "SECONDARY_COLOR=$secondary"
    echo "TERTIARY_COLOR=$tertiary"
    echo "SURFACE_COLOR=$surface"
    echo "BACKGROUND_COLOR=$background"
    echo "ACCENT_COLOR=$accent"
    echo "ERROR_COLOR=$error"
    echo "WARNING_COLOR=$warning"
    echo "SUCCESS_COLOR=$success"
    echo "TEXT_PRIMARY=$text_primary"
    echo "TEXT_SECONDARY=$text_secondary"
    echo "TEXT_DISABLED=$text_disabled"
    echo "PRIMARY_LIGHT=$primary_light"
    echo "PRIMARY_DARK=$primary_dark"
    echo "SECONDARY_LIGHT=$secondary_light"
    echo "SECONDARY_DARK=$secondary_dark"
    echo "BORDER_COLOR=$border"
    echo "BORDER_FOCUS_COLOR=$border_focus"
    
    log_debug "Extracted color variables"
end

# =============================================================================
# Color Manipulation Functions
# =============================================================================

function hex_to_rgb
    set hex_color (string replace '#' '' $argv[1])
    
    set r (string sub -s 1 -l 2 $hex_color)
    set g (string sub -s 3 -l 2 $hex_color)
    set b (string sub -s 5 -l 2 $hex_color)
    
    set r_dec (math "0x$r")
    set g_dec (math "0x$g")
    set b_dec (math "0x$b")
    
    echo "$r_dec $g_dec $b_dec"
end

function rgb_to_hex
    set r $argv[1]
    set g $argv[2]
    set b $argv[3]
    
    # Clamp values to 0-255 range
    set r (math "max(0, min(255, $r))")
    set g (math "max(0, min(255, $g))")
    set b (math "max(0, min(255, $b))")
    
    printf "#%02x%02x%02x" $r $g $b
end

function lighten_color
    set color $argv[1]
    set percentage $argv[2]
    
    set rgb (hex_to_rgb $color)
    set r (echo $rgb | cut -d' ' -f1)
    set g (echo $rgb | cut -d' ' -f2)
    set b (echo $rgb | cut -d' ' -f3)
    
    set factor (math "1 + ($percentage / 100)")
    
    set new_r (math "round($r * $factor)")
    set new_g (math "round($g * $factor)")
    set new_b (math "round($b * $factor)")
    
    rgb_to_hex $new_r $new_g $new_b
end

function darken_color
    set color $argv[1]
    set percentage $argv[2]
    
    set rgb (hex_to_rgb $color)
    set r (echo $rgb | cut -d' ' -f1)
    set g (echo $rgb | cut -d' ' -f2)
    set b (echo $rgb | cut -d' ' -f3)
    
    set factor (math "1 - ($percentage / 100)")
    
    set new_r (math "round($r * $factor)")
    set new_g (math "round($g * $factor)")
    set new_b (math "round($b * $factor)")
    
    rgb_to_hex $new_r $new_g $new_b
end

function mix_colors
    set color1 $argv[1]
    set color2 $argv[2]
    set ratio $argv[3]  # 0-100, where 0 is all color1, 100 is all color2
    
    set rgb1 (hex_to_rgb $color1)
    set rgb2 (hex_to_rgb $color2)
    
    set r1 (echo $rgb1 | cut -d' ' -f1)
    set g1 (echo $rgb1 | cut -d' ' -f2)
    set b1 (echo $rgb1 | cut -d' ' -f3)
    
    set r2 (echo $rgb2 | cut -d' ' -f1)
    set g2 (echo $rgb2 | cut -d' ' -f2)
    set b2 (echo $rgb2 | cut -d' ' -f3)
    
    set factor (math "$ratio / 100")
    
    set new_r (math "round($r1 * (1 - $factor) + $r2 * $factor)")
    set new_g (math "round($g1 * (1 - $factor) + $g2 * $factor)")
    set new_b (math "round($b1 * (1 - $factor) + $b2 * $factor)")
    
    rgb_to_hex $new_r $new_g $new_b
end

# =============================================================================
# Template Discovery and Processing
# =============================================================================

function find_template_files
    set template_dir $argv[1]
    
    log_debug "Finding template files in: $template_dir"
    
    if not test -d "$template_dir"
        log_error "Template directory not found: $template_dir"
        return 1
    end
    
    # Find all .template files recursively
    find "$template_dir" -name "*.template" -type f | sort
end

function get_output_path
    set template_path $argv[1]
    set template_dir $argv[2]
    set output_dir $argv[3]
    
    # Convert template path to output path
    set relative_path (string replace "$template_dir/" "" "$template_path")
    set relative_path (string replace ".template" "" "$relative_path")
    set output_path "$output_dir/$relative_path"
    
    echo $output_path
end

function create_output_directory
    set output_path $argv[1]
    
    set output_dir (dirname "$output_path")
    
    if not test -d "$output_dir"
        mkdir -p "$output_dir"
        log_debug "Created output directory: $output_dir"
    end
end

# =============================================================================
# Template Variable Substitution
# =============================================================================

function substitute_template_variables
    set template_file $argv[1]
    set output_file $argv[2]
    set -l color_vars $argv[3..-1]
    
    log_debug "Processing template: $template_file -> $output_file"
    
    # Start with the template content
    cat "$template_file" > "$output_file.tmp"
    
    # Apply each color variable substitution
    for var_assignment in $color_vars
        set var_name (echo $var_assignment | cut -d'=' -f1)
        set var_value (echo $var_assignment | cut -d'=' -f2)
        
        # Substitute {{VARIABLE}} patterns
        sed -i "s/{{$var_name}}/$var_value/g" "$output_file.tmp"
        
        log_debug "Substituted $var_name with $var_value"
    end
    
    # Additional template functions
    substitute_template_functions "$output_file.tmp"
    
    # Move temp file to final location
    mv "$output_file.tmp" "$output_file"
    
    log_debug "Template processing completed: $output_file"
end

function substitute_template_functions
    set file $argv[1]
    
    # Process color format conversion functions
    # Convert hex to RGB: {{RGB:PRIMARY_COLOR}} -> r,g,b format
    sed -i -E 's/\{\{RGB:([^}]+)\}\}/$(hex_to_rgb_sed \1)/g' "$file"
    
    # Convert hex to RGBA: {{RGBA:PRIMARY_COLOR:0.8}} -> r,g,b,a format
    sed -i -E 's/\{\{RGBA:([^:}]+):([^}]+)\}\}/$(hex_to_rgba_sed \1 \2)/g' "$file"
    
    # Lighten color: {{LIGHTEN:PRIMARY_COLOR:20}} -> lighter hex color
    sed -i -E 's/\{\{LIGHTEN:([^:}]+):([^}]+)\}\}/$(lighten_color_sed \1 \2)/g' "$file"
    
    # Darken color: {{DARKEN:PRIMARY_COLOR:20}} -> darker hex color
    sed -i -E 's/\{\{DARKEN:([^:}]+):([^}]+)\}\}/$(darken_color_sed \1 \2)/g' "$file"
end

# =============================================================================
# Template Validation
# =============================================================================

function validate_template_output
    set output_file $argv[1]
    set template_type $argv[2]
    
    log_debug "Validating template output: $output_file ($template_type)"
    
    # Check if file was created
    if not test -f "$output_file"
        log_error "Template output file not created: $output_file"
        return 1
    end
    
    # Check for unresolved template variables
    set unresolved (grep -o '{{[^}]*}}' "$output_file" 2>/dev/null)
    
    if test -n "$unresolved"
        log_error "Unresolved template variables in $output_file:"
        echo "$unresolved" | sed 's/^/  /'
        return 1
    end
    
    # Application-specific validation
    switch $template_type
        case "*.css"
            # Validate CSS syntax (basic check)
            if grep -q '^[[:space:]]*[^{]*{[^}]*}' "$output_file"
                log_debug "CSS syntax appears valid"
            else
                log_error "CSS syntax validation failed"
                return 1
            end
            
        case "*.json"
            # Validate JSON syntax
            if jq empty "$output_file" 2>/dev/null
                log_debug "JSON syntax is valid"
            else
                log_error "JSON syntax validation failed"
                return 1
            end
            
        case "*.conf" "*.ini"
            # Basic config file validation
            if test -s "$output_file"
                log_debug "Config file appears valid"
            else
                log_error "Config file is empty"
                return 1
            end
    end
    
    log_debug "Template output validation passed"
    return 0
end

# =============================================================================
# Main Template Processing
# =============================================================================

function process_templates
    set theme_file $argv[1]
    set template_dir $argv[2]
    set output_dir $argv[3]
    
    log_info "Processing templates from $template_dir to $output_dir"
    
    # Load and validate theme
    if not load_theme_colors "$theme_file"
        return 1
    end
    
    # Extract color variables
    set color_vars (extract_color_variables "$theme_file")
    
    # Find all template files
    set template_files (find_template_files "$template_dir")
    
    if test (count $template_files) -eq 0
        log_error "No template files found in $template_dir"
        return 1
    end
    
    log_info "Found "(count $template_files)" template files to process"
    
    set processed_count 0
    set failed_count 0
    
    # Process each template file
    for template_file in $template_files
        log_debug "Processing template: $template_file"
        
        # Determine output path
        set output_path (get_output_path "$template_file" "$template_dir" "$output_dir")
        
        # Create output directory if needed
        create_output_directory "$output_path"
        
        # Process template
        if substitute_template_variables "$template_file" "$output_path" $color_vars
            # Validate output
            set template_type (string replace -r '.*\.' '.' "$output_path")
            
            if validate_template_output "$output_path" "$template_type"
                set processed_count (math $processed_count + 1)
                log_debug "Successfully processed: $template_file -> $output_path"
            else
                set failed_count (math $failed_count + 1)
                log_error "Validation failed for: $output_path"
            end
        else
            set failed_count (math $failed_count + 1)
            log_error "Failed to process template: $template_file"
        end
    end
    
    log_info "Template processing completed: $processed_count successful, $failed_count failed"
    
    if test $failed_count -gt 0
        return 1
    end
    
    return 0
end

# =============================================================================
# Setup and Main Function
# =============================================================================

function setup_directories
    mkdir -p $THEMES_DIR
    mkdir -p $LOGS_DIR
    mkdir -p $OUTPUT_DIR
    touch "$LOGS_DIR/theme-renderer.log"
end

function main
    set theme_file $DEFAULT_THEME_FILE
    set template_dir $TEMPLATES_DIR
    set output_dir $OUTPUT_DIR
    
    # Parse command line arguments
    set parsing_theme false
    set parsing_template false
    set parsing_output false
    
    for arg in $argv
        if test $parsing_theme = true
            set theme_file $arg
            set parsing_theme false
            continue
        end
        
        if test $parsing_template = true
            set template_dir $arg
            set parsing_template false
            continue
        end
        
        if test $parsing_output = true
            set output_dir $arg
            set parsing_output false
            continue
        end
        
        switch $arg
            case --theme-file -t
                set parsing_theme true
            case --template-dir
                set parsing_template true
            case --output-dir -o
                set parsing_output true
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] [--theme-file <file>] [--template-dir <dir>] [--output-dir <dir>] [--debug] [--help]"
                echo ""
                echo "Process template files and generate themed configurations"
                echo ""
                echo "Options:"
                echo "  --theme-file <file>    Theme JSON file (default: $DEFAULT_THEME_FILE)"
                echo "  --template-dir <dir>   Template directory (default: $TEMPLATES_DIR)"
                echo "  --output-dir <dir>     Output directory (default: $OUTPUT_DIR)"
                echo "  --debug                Enable debug logging"
                echo "  --help                 Show this help message"
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
    
    # Process templates
    process_templates "$theme_file" "$template_dir" "$output_dir"
    return $status
end

# Execute main function with all arguments
main $argv 
#!/usr/bin/env fish

# =============================================================================
# Color Extraction Engine - Dynamic Theming System
# =============================================================================
# Description: Extract MaterialYou color palette from wallpapers using LLaVA
# Dependencies: curl, jq, ollama (with llava model)
# Author: Dotfiles Dynamic Theming System
# Usage: ./color-extractor.sh <wallpaper_path> [--output-file]
# =============================================================================

# Set script directory and configuration paths
set SCRIPT_DIR (dirname (realpath (status --current-filename)))
set DOTFILES_ROOT (dirname $SCRIPT_DIR)
set CACHE_DIR "$DOTFILES_ROOT/cache"
set THEMES_DIR "$CACHE_DIR/themes"
set LOGS_DIR "$CACHE_DIR/logs"

# Ollama configuration
set OLLAMA_HOST "http://localhost:11434"
set LLAVA_MODEL "llava-llama3:8b"
set BACKUP_MODEL "llava:7b"
set CONNECTION_TIMEOUT 30
set MAX_RETRIES 3
set RETRY_DELAY 5

# =============================================================================
# Utility Functions
# =============================================================================

function log_info
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/color-extractor.log"
end

function log_error
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/color-extractor.log"
end

function log_debug
    if test "$DEBUG" = "1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >&2
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $argv" >> "$LOGS_DIR/color-extractor.log"
    end
end

# =============================================================================
# Dependency Checking
# =============================================================================

function check_dependencies
    set required_tools curl jq base64
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
                case curl
                    echo "  pacman -S curl"
                case jq
                    echo "  pacman -S jq"
                case base64
                    echo "  pacman -S coreutils"
            end
        end
        return 1
    end
    
    log_debug "All dependencies satisfied"
    return 0
end

# =============================================================================
# Ollama Connection and Model Management
# =============================================================================

function check_ollama_connection
    log_debug "Checking Ollama connection at $OLLAMA_HOST"
    
    set response (curl -s --connect-timeout $CONNECTION_TIMEOUT "$OLLAMA_HOST/api/tags" 2>/dev/null)
    
    if test $status -eq 0 -a -n "$response"
        log_debug "Ollama server is reachable"
        return 0
    else
        log_error "Cannot connect to Ollama server at $OLLAMA_HOST"
        return 1
    end
end

function check_model_availability
    set model_name $argv[1]
    
    log_debug "Checking availability of model: $model_name"
    
    set models_response (curl -s --connect-timeout $CONNECTION_TIMEOUT "$OLLAMA_HOST/api/tags" 2>/dev/null)
    
    if test $status -ne 0 -o -z "$models_response"
        log_error "Failed to get model list from Ollama"
        return 1
    end
    
    # Parse model list and check if our model exists
    set model_exists (echo $models_response | jq -r --arg model "$model_name" '.models[]? | select(.name == $model) | .name')
    
    if test -n "$model_exists"
        log_debug "Model $model_name is available"
        return 0
    else
        log_debug "Model $model_name is not available"
        return 1
    end
end

function select_available_model
    log_info "Selecting available LLaVA model..."
    
    # Try primary model first
    if check_model_availability $LLAVA_MODEL
        echo $LLAVA_MODEL
        return 0
    end
    
    # Try backup model
    if check_model_availability $BACKUP_MODEL
        log_info "Primary model unavailable, using backup: $BACKUP_MODEL"
        echo $BACKUP_MODEL
        return 0
    end
    
    # Try any available llava model
    set models_response (curl -s --connect-timeout $CONNECTION_TIMEOUT "$OLLAMA_HOST/api/tags" 2>/dev/null)
    set available_llava (echo $models_response | jq -r '.models[]? | select(.name | contains("llava")) | .name' | head -1)
    
    if test -n "$available_llava"
        log_info "Using available LLaVA model: $available_llava"
        echo $available_llava
        return 0
    end
    
    log_error "No LLaVA models available. Please install with: ollama pull $LLAVA_MODEL"
    return 1
end

# =============================================================================
# Image Processing
# =============================================================================

function encode_image_base64
    set image_path $argv[1]
    
    log_debug "Encoding image to base64: $image_path"
    
    if not test -f "$image_path"
        log_error "Image file not found: $image_path"
        return 1
    end
    
    # Check if file is a supported image format
    set file_type (file -b --mime-type "$image_path")
    if not echo $file_type | grep -q "^image/"
        log_error "File is not a valid image: $image_path ($file_type)"
        return 1
    end
    
    # Encode to base64
    set encoded (base64 -w 0 "$image_path" 2>/dev/null)
    
    if test $status -eq 0 -a -n "$encoded"
        echo $encoded
        return 0
    else
        log_error "Failed to encode image to base64"
        return 1
    end
end

# =============================================================================
# LLaVA Prompt Generation
# =============================================================================

function generate_color_analysis_prompt
    cat << 'EOF'
Analyze this wallpaper image and extract a MaterialYou color palette. Focus on the most prominent and harmonious colors that would work well as a cohesive theme across desktop applications.

Return ONLY a valid JSON object with these exact keys and hex color values:
{
  "primary": "#hexcolor",
  "secondary": "#hexcolor",
  "tertiary": "#hexcolor",
  "surface": "#hexcolor",
  "background": "#hexcolor",
  "accent": "#hexcolor",
  "error": "#ff5449",
  "warning": "#ffb74d",
  "success": "#4caf50",
  "text_primary": "#hexcolor",
  "text_secondary": "#hexcolor",
  "text_disabled": "#hexcolor"
}

Guidelines:
- primary: The most dominant, characteristic color from the image
- secondary: A complementary color that pairs well with primary
- tertiary: An accent color for highlights and emphasis
- surface: A neutral color suitable for surfaces and cards
- background: The main background color (usually neutral/muted)
- accent: A vibrant color for interactive elements
- text_primary: High contrast color for primary text (usually dark or light)
- text_secondary: Medium contrast color for secondary text
- text_disabled: Low contrast color for disabled elements

Ensure all colors work together harmoniously and provide sufficient contrast for accessibility. Extract colors that capture the mood and aesthetic of the wallpaper.
EOF
end

# =============================================================================
# Color Extraction API Call
# =============================================================================

function call_llava_api
    set model_name $argv[1]
    set image_base64 $argv[2]
    set prompt $argv[3]
    
    log_debug "Calling LLaVA API with model: $model_name"
    
    # Prepare the API request payload
    set api_payload (jq -n \
        --arg model "$model_name" \
        --arg prompt "$prompt" \
        --arg image "$image_base64" \
        '{
            model: $model,
            prompt: $prompt,
            images: [$image],
            stream: false,
            options: {
                temperature: 0.1,
                top_p: 0.9,
                seed: 42
            }
        }')
    
    # Make the API call with retry logic
    set attempt 1
    while test $attempt -le $MAX_RETRIES
        log_debug "API call attempt $attempt/$MAX_RETRIES"
        
        set response (curl -s \
            --connect-timeout $CONNECTION_TIMEOUT \
            --max-time 120 \
            -H "Content-Type: application/json" \
            -d "$api_payload" \
            "$OLLAMA_HOST/api/generate" 2>/dev/null)
        
        if test $status -eq 0 -a -n "$response"
            # Check if response contains an error
            set error_msg (echo $response | jq -r '.error // empty')
            
            if test -n "$error_msg"
                log_error "API error: $error_msg"
                if test $attempt -lt $MAX_RETRIES
                    log_info "Retrying in $RETRY_DELAY seconds..."
                    sleep $RETRY_DELAY
                    set attempt (math $attempt + 1)
                    continue
                else
                    return 1
                end
            end
            
            # Extract the response text
            set response_text (echo $response | jq -r '.response // empty')
            
            if test -n "$response_text"
                log_debug "API call successful"
                echo $response_text
                return 0
            else
                log_error "Empty response from API"
            end
        else
            log_error "API call failed (attempt $attempt/$MAX_RETRIES)"
        end
        
        if test $attempt -lt $MAX_RETRIES
            log_info "Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
        end
        
        set attempt (math $attempt + 1)
    end
    
    log_error "All API call attempts failed"
    return 1
end

# =============================================================================
# Color Validation and Processing
# =============================================================================

function validate_hex_color
    set color $argv[1]
    
    # Check if color matches hex pattern
    if echo $color | grep -qE '^#[0-9a-fA-F]{6}$'
        return 0
    else
        return 1
    end
end

function parse_and_validate_colors
    set raw_response $argv[1]
    
    log_debug "Parsing and validating color response"
    
    # Try to extract JSON from the response
    set json_response (echo $raw_response | grep -o '{[^}]*}' | head -1)
    
    if test -z "$json_response"
        log_error "No JSON object found in response"
        return 1
    end
    
    # Validate JSON syntax
    if not echo $json_response | jq empty 2>/dev/null
        log_error "Invalid JSON in response"
        return 1
    end
    
    # Required color keys
    set required_keys primary secondary tertiary surface background accent error warning success text_primary text_secondary text_disabled
    
    # Validate all required keys exist and contain valid hex colors
    for key in $required_keys
        set color_value (echo $json_response | jq -r ".$key // empty")
        
        if test -z "$color_value"
            log_error "Missing required color key: $key"
            return 1
        end
        
        if not validate_hex_color $color_value
            log_error "Invalid hex color for $key: $color_value"
            return 1
        end
        
        log_debug "Validated $key: $color_value"
    end
    
    log_info "All colors validated successfully"
    echo $json_response
    return 0
end

# =============================================================================
# Fallback Color Generation
# =============================================================================

function generate_fallback_palette
    log_info "Generating fallback color palette"
    
    # Basic MaterialYou-inspired fallback palette
    cat << 'EOF'
{
  "primary": "#6750a4",
  "secondary": "#958da5",
  "tertiary": "#b58392",
  "surface": "#fef7ff",
  "background": "#fffbfe",
  "accent": "#7c4dff",
  "error": "#ff5449",
  "warning": "#ffb74d",
  "success": "#4caf50",
  "text_primary": "#1c1b1f",
  "text_secondary": "#49454f",
  "text_disabled": "#79747e"
}
EOF
end

# =============================================================================
# Color Caching
# =============================================================================

function get_image_hash
    set image_path $argv[1]
    
    # Generate SHA256 hash of the image file
    sha256sum "$image_path" | cut -d' ' -f1
end

function get_cached_colors
    set image_hash $argv[1]
    set cache_file "$THEMES_DIR/cache_$image_hash.json"
    
    if test -f "$cache_file"
        # Check if cache is not older than 30 days
        set cache_age (math (date +%s) - (stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file"))
        
        if test $cache_age -lt 2592000  # 30 days in seconds
            log_debug "Using cached colors for image hash: $image_hash"
            cat "$cache_file"
            return 0
        else
            log_debug "Cache expired for image hash: $image_hash"
            rm -f "$cache_file"
        end
    end
    
    return 1
end

function cache_colors
    set image_hash $argv[1]
    set colors_json $argv[2]
    set cache_file "$THEMES_DIR/cache_$image_hash.json"
    
    echo $colors_json > "$cache_file"
    log_debug "Cached colors for image hash: $image_hash"
end

# =============================================================================
# Main Color Extraction Function
# =============================================================================

function extract_colors_from_wallpaper
    set wallpaper_path $argv[1]
    set output_file $argv[2]
    
    log_info "Starting color extraction for: $wallpaper_path"
    
    # Validate input file
    if not test -f "$wallpaper_path"
        log_error "Wallpaper file not found: $wallpaper_path"
        return 1
    end
    
    # Check cache first
    set image_hash (get_image_hash "$wallpaper_path")
    set cached_colors (get_cached_colors $image_hash)
    
    if test $status -eq 0 -a -n "$cached_colors"
        log_info "Using cached color palette"
        
        if test -n "$output_file"
            echo $cached_colors > "$output_file"
        end
        
        echo $cached_colors
        return 0
    end
    
    # Check Ollama connection
    if not check_ollama_connection
        log_error "Ollama server not available, using fallback palette"
        set fallback_colors (generate_fallback_palette)
        
        if test -n "$output_file"
            echo $fallback_colors > "$output_file"
        end
        
        echo $fallback_colors
        return 0
    end
    
    # Select available model
    set selected_model (select_available_model)
    
    if test $status -ne 0
        log_error "No LLaVA model available, using fallback palette"
        set fallback_colors (generate_fallback_palette)
        
        if test -n "$output_file"
            echo $fallback_colors > "$output_file"
        end
        
        echo $fallback_colors
        return 0
    end
    
    # Encode image to base64
    set image_base64 (encode_image_base64 "$wallpaper_path")
    
    if test $status -ne 0
        log_error "Failed to encode image, using fallback palette"
        set fallback_colors (generate_fallback_palette)
        
        if test -n "$output_file"
            echo $fallback_colors > "$output_file"
        end
        
        echo $fallback_colors
        return 0
    end
    
    # Generate prompt
    set prompt (generate_color_analysis_prompt)
    
    # Call LLaVA API
    set raw_response (call_llava_api $selected_model $image_base64 $prompt)
    
    if test $status -ne 0 -o -z "$raw_response"
        log_error "LLaVA API call failed, using fallback palette"
        set fallback_colors (generate_fallback_palette)
        
        if test -n "$output_file"
            echo $fallback_colors > "$output_file"
        end
        
        echo $fallback_colors
        return 0
    end
    
    # Parse and validate colors
    set validated_colors (parse_and_validate_colors "$raw_response")
    
    if test $status -ne 0 -o -z "$validated_colors"
        log_error "Color validation failed, using fallback palette"
        set fallback_colors (generate_fallback_palette)
        
        if test -n "$output_file"
            echo $fallback_colors > "$output_file"
        end
        
        echo $fallback_colors
        return 0
    end
    
    # Cache the successful result
    cache_colors $image_hash $validated_colors
    
    # Save to output file if specified
    if test -n "$output_file"
        echo $validated_colors > "$output_file"
        log_info "Colors saved to: $output_file"
    end
    
    log_info "Color extraction completed successfully"
    echo $validated_colors
    return 0
end

# =============================================================================
# Setup and Main Function
# =============================================================================

function setup_directories
    mkdir -p $THEMES_DIR
    mkdir -p $LOGS_DIR
    touch "$LOGS_DIR/color-extractor.log"
end

function main
    set wallpaper_path ""
    set output_file ""
    
    # Parse command line arguments
    set parsing_output false
    
    for arg in $argv
        if test $parsing_output = true
            set output_file $arg
            set parsing_output false
            continue
        end
        
        switch $arg
            case --output-file -o
                set parsing_output true
            case --debug
                set DEBUG 1
            case --help -h
                echo "Usage: $argv[0] <wallpaper_path> [--output-file <file>] [--debug] [--help]"
                echo ""
                echo "Extract MaterialYou color palette from wallpaper using LLaVA"
                echo ""
                echo "Arguments:"
                echo "  wallpaper_path       Path to wallpaper image file"
                echo ""
                echo "Options:"
                echo "  --output-file <file> Save colors to specified file"
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
        echo "Usage: $argv[0] <wallpaper_path> [--output-file <file>]"
        return 1
    end
    
    # Check dependencies
    if not check_dependencies
        return 1
    end
    
    # Setup directories
    setup_directories
    
    # Default output file if not specified
    if test -z "$output_file"
        set output_file "$THEMES_DIR/current-theme.json"
    end
    
    # Extract colors
    extract_colors_from_wallpaper "$wallpaper_path" "$output_file"
    return $status
end

# Execute main function with all arguments
main $argv 
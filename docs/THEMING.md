# Dynamic Theming Workflow Documentation

## Overview

The dynamic theming system provides MaterialYou-style theming across all desktop components based on wallpaper analysis using local LLaVA model via Ollama. The system ensures atomic updates with no half-themed states.

## Workflow Process

### 1. Wallpaper Selection Phase
- **Tool**: `fuzzel` with thumbnail previews (fallback to `rofi-wayland`)
- **Location**: `theme-engine/wallpaper-picker.sh`
- **Process**: 
  - Scans `wallpapers/` directory recursively
  - Generates thumbnails (cached in `cache/thumbnails/`)
  - Displays selection interface with previews
  - Returns selected wallpaper path

### 2. Color Extraction Phase
- **Tool**: LLaVA model via Ollama API
- **Location**: `theme-engine/color-extractor.sh`
- **Process**:
  - Sends wallpaper image to local Ollama server
  - Uses specific prompt for MaterialYou palette extraction
  - Receives JSON response with color hierarchy
  - Validates and parses color data
  - Stores results in `cache/themes/current-theme.json`

### 3. Template Processing Phase
- **Tool**: Custom template renderer
- **Location**: `theme-engine/theme-renderer.sh`
- **Process**:
  - Reads current theme colors from JSON
  - Processes all template files in `templates/`
  - Performs variable substitution using color values
  - Generates final config files in `dotfiles/`
  - Validates output syntax for each application

### 4. Atomic Application Phase
- **Tool**: Theme applier with backup system
- **Location**: `theme-engine/theme-applier.sh`
- **Process**:
  - Creates backup of existing configurations
  - Deploys all new configs simultaneously
  - Updates symlinks atomically
  - Reloads/restarts all themed applications
  - Sets wallpaper using `swww`
  - Updates system theme settings

## Color Extraction Details

### LLaVA Prompt Strategy
```
Analyze this wallpaper image and extract a MaterialYou color palette. 
Return ONLY a JSON object with these exact keys:
{
  "primary": "#hexcolor",
  "secondary": "#hexcolor", 
  "tertiary": "#hexcolor",
  "surface": "#hexcolor",
  "background": "#hexcolor",
  "accent": "#hexcolor",
  "error": "#hexcolor",
  "warning": "#hexcolor",
  "success": "#hexcolor",
  "text_primary": "#hexcolor",
  "text_secondary": "#hexcolor",
  "text_disabled": "#hexcolor"
}
Extract the most dominant and harmonious colors from the image.
```

### Color Processing
- **Primary**: Most dominant color from image
- **Secondary**: Complementary to primary
- **Tertiary**: Accent color for highlights
- **Surface**: Background surface color
- **Background**: Main background color
- **Text Colors**: Calculated for optimal contrast

## Template System

### Template Variables
All templates use consistent variable naming:
- `{{PRIMARY_COLOR}}` - Main theme color
- `{{SECONDARY_COLOR}}` - Secondary theme color
- `{{BACKGROUND_COLOR}}` - Background color
- `{{TEXT_PRIMARY}}` - Primary text color
- `{{TEXT_SECONDARY}}` - Secondary text color
- `{{ACCENT_COLOR}}` - Accent/highlight color
- `{{SURFACE_COLOR}}` - Surface/card color
- `{{BORDER_COLOR}}` - Border color
- `{{ERROR_COLOR}}` - Error state color
- `{{WARNING_COLOR}}` - Warning state color
- `{{SUCCESS_COLOR}}` - Success state color

### Template Processing
1. **Variable Substitution**: Replace all `{{VARIABLE}}` patterns
2. **Color Validation**: Ensure all colors are valid hex codes
3. **Syntax Validation**: Check generated config syntax
4. **Backup Generation**: Create backups before deployment

## Application Reload Strategy

### Immediate Reload Applications
- **Hyprland**: `hyprctl reload`
- **Waybar**: `killall waybar && waybar &`
- **Dunst**: `killall dunst && dunst &`
- **Fuzzel**: No reload needed (config read on startup)

### Session Restart Applications
- **GTK Applications**: Update via gsettings
- **Terminals**: New instances pick up themes
- **Fish Shell**: Source new theme file

### System-wide Updates
- **GTK2/3/4**: Update theme files and reload settings
- **Icon Theme**: Update via gsettings
- **Font Config**: Update fontconfig and refresh cache
- **Cursor Theme**: Update via gsettings

## Error Handling

### Ollama Connection Failures
- **Fallback**: Use previous theme or default palette
- **Retry Logic**: Attempt reconnection with exponential backoff
- **User Notification**: Display error via dunst notification

### Template Processing Errors
- **Validation**: Check template syntax before processing
- **Rollback**: Restore from backup if generation fails
- **Logging**: Detailed error logs in `cache/logs/`

### Application Reload Failures
- **Graceful Degradation**: Continue with other applications
- **Manual Recovery**: Provide manual reload commands
- **Status Reporting**: Show which components succeeded/failed

## Performance Optimization

### Caching Strategy
- **Thumbnails**: Cache wallpaper previews indefinitely
- **Color Palettes**: Cache LLaVA responses by image hash
- **Templates**: Pre-compile template processors
- **Generated Configs**: Only regenerate if colors changed

### Parallel Processing
- **Template Rendering**: Process multiple templates simultaneously
- **Application Reloads**: Reload compatible applications in parallel
- **Thumbnail Generation**: Generate thumbnails asynchronously

### Resource Management
- **Ollama Connection**: Reuse persistent connections
- **Memory Usage**: Clean up temporary files after processing
- **CPU Usage**: Limit parallel operations based on system resources

## Customization Points

### Adding New Applications
1. Create template file in `templates/app-name/`
2. Add config generation to `theme-renderer.sh`
3. Add reload logic to `theme-applier.sh`
4. Update symlink mappings

### Custom Color Processing
- Modify color extraction prompt in `color-extractor.sh`
- Add custom color calculations in `utils/color-utils.sh`
- Extend template variables as needed

### Alternative Color Sources
- Replace LLaVA with different AI model
- Add manual color picker interface
- Support color palette files (JSON/YAML)
- Integration with external theming tools 
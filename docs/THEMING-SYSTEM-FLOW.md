# Dynamic Theming System Flow Documentation

## Overview

The dynamic theming system provides real-time, AI-powered theme generation based on wallpaper analysis. The system uses local LLaVA (Large Language and Vision Assistant) models to extract MaterialYou-style color palettes and applies them atomically across all desktop applications.

## Core Components

### 🎨 **Theme Engine Scripts**
1. **wallpaper-picker.sh** - Interactive wallpaper selection with thumbnails
2. **color-extractor.sh** - AI-powered color palette extraction using LLaVA
3. **theme-renderer.sh** - Template processing and color variable substitution
4. **theme-applier.sh** - Atomic theme application and service reloading

### 🔧 **Template System**
- **Minimal Templates**: Only contain color variables and theming elements
- **Main Configurations**: Complete app configs that source the templates
- **DRY Principle**: Avoid duplication while maintaining modularity

## Theming Workflow Stages

### 1. **Wallpaper Selection Phase**

#### **Trigger Methods**
- `Super+W` - Interactive wallpaper picker
- `Super+Shift+W` - Random wallpaper selection
- `wallpaper-picker` command - Manual invocation

#### **Selection Process**
```bash
1. Scan ~/Pictures/Wallpapers/ for images
2. Generate thumbnails (cached for performance)
3. Launch fuzzel with thumbnail grid
4. User selects wallpaper or cancels
5. Set wallpaper via swww daemon
```

#### **Supported Formats**
- PNG, JPEG, WebP image formats
- Automatic format detection
- Thumbnail generation with caching

#### **Error Handling**
- Missing wallpapers directory → Create and show warning
- No images found → Guide user to add wallpapers
- Thumbnail generation failure → Graceful fallback

### 2. **Color Extraction Phase**

#### **AI Analysis Pipeline**
```bash
wallpaper-picker.sh → color-extractor.sh → LLaVA Analysis
```

#### **Caching Strategy**
- **Hash-based Caching**: Image content hash determines cache key
- **Cache Hit**: Load existing palette instantly
- **Cache Miss**: Perform AI analysis and cache results

#### **LLaVA Integration**
```bash
1. Check Ollama connection status
2. Verify model availability (priority order):
   - llava-llama3:8b (primary)
   - llava:7b (backup)
   - Any available LLaVA model (fallback)
3. Encode image to base64
4. Send structured prompt for MaterialYou analysis
5. Parse and validate JSON response
```

#### **Prompt Engineering**
The system uses a carefully crafted prompt that instructs LLaVA to:
- Identify dominant and accent colors
- Consider color harmony principles
- Generate MaterialYou-compatible palettes
- Return structured JSON with specific color roles

#### **Fallback Mechanisms**
- **Connection Failure**: Use cached palette or defaults
- **Model Unavailable**: Automatic model fallback
- **Invalid Response**: Retry up to 3 times, then use defaults
- **Color Validation**: Ensure all colors are valid hex values

### 3. **Color Processing and Enhancement**

#### **Palette Expansion**
The base LLaVA palette is expanded to include:
```json
{
  "primary": "#color",     // Main brand color
  "secondary": "#color",   // Secondary accent
  "tertiary": "#color",    // Additional accent
  "accent": "#color",      // Highlight color
  "surface": "#color",     // Card/surface backgrounds
  "background_primary": "#color",    // Main background
  "background_secondary": "#color",  // Secondary background
  "text_primary": "#color",     // Main text
  "text_secondary": "#color",   // Secondary text
  "text_disabled": "#color",    // Disabled text
  "border": "#color",       // Border elements
  "shadow": "#color",       // Shadow effects
  "success": "#color",      // Success states
  "warning": "#color",      // Warning states
  "error": "#color",        // Error states
  "cursor": "#color"        // Cursor color
}
```

#### **Color Harmony Functions**
- **Lightening/Darkening**: Automatic shade generation
- **Contrast Adjustment**: Ensure accessibility standards
- **Color Mixing**: Generate intermediate shades
- **Validation**: Verify all colors meet requirements

### 4. **Template Rendering Phase**

#### **Template Discovery**
```bash
1. Scan templates/ directory recursively
2. Find all *.template files
3. Identify target applications and configs
4. Prepare rendering pipeline
```

#### **Variable Substitution**
```bash
# Template format
{{PRIMARY_COLOR}} → #1a73e8
{{TEXT_PRIMARY}} → #e8eaed
{{BACKGROUND_PRIMARY}} → #202124
```

#### **Advanced Processing**
- **Color Functions**: Apply mathematical color operations
- **Conditional Logic**: Template-specific adaptations
- **Format Validation**: Ensure output meets application requirements

#### **Supported Applications**
- **Hyprland**: Window manager theming
- **Waybar**: Status bar styling (dual setup)
- **Kitty/Foot**: Terminal color schemes
- **Fish**: Shell prompt and syntax highlighting
- **Dunst**: Notification appearance
- **Fuzzel**: Launcher styling
- **GTK**: Application framework theming
- **btop**: System monitor colors

### 5. **Atomic Application Phase**

#### **Backup Strategy**
```bash
1. Create timestamped backup of current configs
2. Verify backup integrity
3. Maintain 7-day backup retention
4. Enable quick rollback on failure
```

#### **Configuration Deployment**
```bash
1. Copy all generated configs to target locations
2. Verify file integrity and permissions
3. Update symlinks atomically
4. Signal applications for reload
```

#### **Service Reloading**
Parallel reloading of all themed applications:
- **Hyprland**: `hyprctl reload`
- **Waybar**: `killall waybar && waybar &`
- **Dunst**: `killall dunst && dunst &`
- **Terminals**: Signal for config reload
- **GTK Apps**: Automatic theme detection

#### **Failure Recovery**
- **Partial Failure**: Continue with working components
- **Critical Failure**: Automatic rollback to previous theme
- **Service Restart**: Restart failed services automatically

## Performance Optimizations

### **Caching Mechanisms**
1. **Image Analysis Cache**: Store LLaVA results by image hash
2. **Thumbnail Cache**: Reuse generated thumbnails
3. **Template Cache**: Cache processed templates for speed
4. **Color Calculation Cache**: Store computed color variations

### **Parallel Processing**
- **Template Rendering**: Process multiple templates simultaneously
- **Service Reloading**: Reload applications in parallel
- **File Operations**: Batch file operations for efficiency

### **Resource Management**
- **Memory Optimization**: Efficient color calculations
- **CPU Usage**: Balanced AI processing with system responsiveness
- **Storage**: Smart cache cleanup and rotation

## Error Handling and Recovery

### **Graceful Degradation**
- **AI Unavailable**: Fall back to previous theme or defaults
- **Template Errors**: Skip problematic templates, continue with others
- **Service Failures**: Continue theming other applications

### **User Feedback**
- **Progress Indicators**: Real-time status updates
- **Success Notifications**: Visual confirmation of theme changes
- **Error Messages**: Clear explanations of any issues
- **Recovery Suggestions**: Guidance for resolving problems

### **Logging System**
```bash
~/.cache/logs/
├── color-extractor.log    # AI analysis logs
├── theme-renderer.log     # Template processing logs
├── theme-applier.log      # Application logs
└── wallpaper-picker.log   # Selection logs
```

## Advanced Features

### **Theme Persistence**
- **Current Theme Tracking**: Remember active theme
- **Theme History**: Maintain recent theme history
- **Favorite Themes**: Mark and quickly apply favorite combinations

### **Color Science Integration**
- **Color Space Conversion**: RGB ↔ HSL ↔ LAB conversions
- **Accessibility**: WCAG contrast ratio compliance
- **Harmony Rules**: Mathematical color harmony principles

### **Extensibility**
- **Plugin Architecture**: Easy addition of new applications
- **Custom Templates**: User-defined template creation
- **API Integration**: Extensible color extraction methods

## Usage Examples

### **Interactive Theming**
```bash
# Select wallpaper and generate theme
Super+W

# Quick random theme
Super+Shift+W

# Reload current theme
Super+R
```

### **Command Line Usage**
```bash
# Manual wallpaper selection
wallpaper-picker

# Apply specific theme
theme-applier --theme /path/to/theme.json

# Use fallback colors
theme-applier --fallback

# Debug mode
DEBUG=1 theme-applier --reload
```

### **Integration Examples**
```bash
# Script integration
wallpaper-picker && notify-send "Theme updated!"

# Automation
echo "Auto-theming at login"
theme-applier --random
```

This comprehensive theming system provides a sophisticated yet user-friendly way to maintain visual consistency across the entire desktop environment while leveraging cutting-edge AI technology for intelligent color palette generation. 
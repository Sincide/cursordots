# Post-Install Process Flow Documentation

## Overview

This document details the complete flow of the `post-install.sh` script, which is designed to be **idempotent** and **safe to run multiple times**. The script automatically handles existing installations and only performs necessary operations.

## Key Features

### 🔄 **Idempotency**
- **No Duplicate Installations**: Uses `--needed` flags and existence checks
- **Smart Detection**: Recognizes existing installations and configurations
- **Safe Re-runs**: Won't break existing setups when run multiple times
- **Selective Operations**: Only performs actions that are actually needed

### 🛡️ **Safety Mechanisms**
- **Root Prevention**: Prevents running as root user
- **Internet Verification**: Checks connectivity before proceeding
- **Graceful Failures**: Handles missing components without breaking
- **Comprehensive Logging**: Detailed status reporting for every operation

## Process Flow Stages

### 1. **Initial Validation**
```bash
# Safety checks
- Verify not running as root
- Check internet connectivity
- Detect previous installations
```

**Behaviors:**
- **First Run**: Shows standard installation prompt
- **Re-run Detected**: Shows "Previous installation detected!" message
- **User Choice**: Always asks for confirmation before proceeding

### 2. **System Package Installation**
```bash
# Base packages with --needed flag
sudo pacman -S --needed --noconfirm base-devel git curl fish hyprland...
```

**Idempotent Features:**
- `--needed` flag prevents reinstalling existing packages
- Package list includes all essential components
- Automatic dependency resolution

### 3. **AI System Setup**
```bash
# LLaVA/Ollama installation
- Check if ollama command exists
- Install only if missing
- Pull LLaVA models with fallback options
```

**Smart Detection:**
- Verifies existing Ollama installation
- Tests model availability before downloading
- Automatic model fallback (llava-llama3:8b → llava:7b)

### 4. **System Service Configuration**
```bash
# Service management with state checking
systemctl is-enabled NetworkManager  # Check before enabling
systemctl is-active NetworkManager   # Check before starting
```

**Safety Features:**
- Checks service state before modifying
- Only enables/starts services that need it
- Comprehensive status logging

### 5. **Shell Configuration**
```bash
# Fish shell setup with validation
- Check if fish in /etc/shells
- Verify current default shell
- Only change if needed
```

**Intelligent Handling:**
- Adds fish to `/etc/shells` only if missing
- Changes default shell only if not already fish
- Preserves existing shell preferences

### 6. **Directory Structure**
```bash
# Individual directory checking
for dir in directories; do
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
done
```

**Granular Control:**
- Checks each directory individually
- Only creates missing directories
- Detailed logging of what's created vs. existing

### 7. **Dotfiles Installation**
```bash
# Component verification and installation
- Check if scripts exist before running
- Verify symlinks before creating
- Only link missing or incorrect links
```

**Advanced Symlink Management:**
- Validates existing symlinks
- Updates broken or incorrect links
- Preserves working configurations

### 8. **Environment Configuration**
```bash
# ~/.profile management
- Check if file exists
- Parse existing variables
- Add only missing environment variables
```

**Smart Configuration:**
- Preserves existing environment settings
- Adds only missing Wayland variables
- PATH modifications only when needed

### 9. **Package Management Tools**
```bash
# AUR helper and UI installation
- yay: Build from source if missing
- pacui: Clone and install if missing
- AUR packages: Install useful defaults
```

**Robust Installation:**
- Checks tool availability before installation
- Handles build failures gracefully
- Installs essential AUR packages

### 10. **Final Setup**
```bash
# Theme and configuration finalization
- Generate initial theme only if none exists
- Configure Git only if not already set
- Update system configurations
```

**Preservation Features:**
- Respects existing themes
- Preserves Git configuration
- Maintains user preferences

## Error Handling

### **Graceful Degradation**
- Missing components don't halt installation
- Warnings logged for non-critical failures
- Fallback options for optional features

### **Recovery Mechanisms**
- Automatic retry for network operations
- Alternative installation methods
- Comprehensive error logging

## Re-run Scenarios

### **When to Re-run**
1. **Accidental Deletion**: Restore missing configurations
2. **Partial Installation**: Complete interrupted installations
3. **Updates**: Refresh components and dependencies
4. **Repairs**: Fix broken symlinks or configurations

### **What Happens on Re-run**
- **Packages**: Only install missing packages (--needed flag)
- **Services**: Only configure unconfigured services
- **Files**: Only create missing files and directories
- **Links**: Only fix broken or missing symlinks
- **Environment**: Only add missing variables

## Performance Optimizations

### **Skip Unnecessary Operations**
- Package installation skipped if already installed
- Service configuration skipped if already configured
- File operations skipped if files exist and are correct

### **Parallel Operations**
- Package installations use pacman's parallel downloading
- Service operations are batched efficiently
- File operations are optimized for speed

## Logging and Feedback

### **Color-Coded Output**
- 🔵 **INFO**: General information
- 🟢 **SUCCESS**: Completed operations
- 🟡 **WARNING**: Non-critical issues
- 🔴 **ERROR**: Critical failures

### **Detailed Status Reporting**
- "Already exists" vs "Created" messages
- "Already configured" vs "Configured" status
- Clear indication of what actions were taken

## Advanced Features

### **Previous Installation Detection**
The script intelligently detects previous installations by checking for:
- `yay` command availability
- `pacui` command availability
- Hyprland configuration directory

### **Selective Updates**
When re-running, the script:
- Updates existing packages to latest versions
- Refreshes configurations that may have changed
- Preserves user customizations
- Maintains system stability

This design ensures that users can confidently re-run the installation script whenever needed, without fear of breaking their existing setup or wasting time on unnecessary operations. 
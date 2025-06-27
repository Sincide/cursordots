#!/usr/bin/env bash

echo "🔧 Fixing Hyprland and Waybar configuration..."

# Remove old symlinks that point to wrong locations
echo "Removing old symlinks..."
rm -f ~/.config/hypr ~/.config/waybar ~/.config/fish ~/.config/dunst ~/.config/fuzzel ~/.config/gtk-3.0 ~/.config/foot ~/.config/btop

# Get the current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create new symlinks with correct paths
echo "Creating new symlinks..."
ln -sf "$SCRIPT_DIR/dotfiles/hyprland" ~/.config/hypr
ln -sf "$SCRIPT_DIR/dotfiles/waybar" ~/.config/waybar
ln -sf "$SCRIPT_DIR/dotfiles/fish" ~/.config/fish
ln -sf "$SCRIPT_DIR/dotfiles/dunst" ~/.config/dunst
ln -sf "$SCRIPT_DIR/dotfiles/fuzzel" ~/.config/fuzzel
ln -sf "$SCRIPT_DIR/dotfiles/gtk-3.0" ~/.config/gtk-3.0
ln -sf "$SCRIPT_DIR/dotfiles/foot" ~/.config/foot
ln -sf "$SCRIPT_DIR/dotfiles/btop" ~/.config/btop

# Verify symlinks
echo "Verifying symlinks..."
ls -la ~/.config/ | grep -E "(hypr|waybar|fish|dunst|fuzzel|gtk-3.0|foot|btop) ->"

echo "🎯 Reloading Hyprland configuration..."
hyprctl reload

echo "✅ Configuration fixed! Try:"
echo "  • Super+Return (terminal)"
echo "  • Super+D (launcher)"
echo "  • Super+Q (close window)"

echo "If Waybar doesn't appear, try: killall waybar && sleep 1 && hyprctl reload" 
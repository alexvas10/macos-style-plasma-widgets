#!/bin/bash
# Enable D-Bus global menu export for Electron apps.
# Electron v9+ supports D-Bus menus natively via --enable-features=GlobalMenuBar.

set -e

echo "==> Configuring Electron app global menu support..."

GLOBAL_MENU_FLAG="--enable-features=GlobalMenuBar"
OZONE_FLAG="--ozone-platform-hint=auto"

# Map of app name → flags file path
declare -A ELECTRON_APPS=(
    ["VS Code"]="$HOME/.config/code-flags.conf"
    ["VS Code Insiders"]="$HOME/.config/code-insiders-flags.conf"
    ["Discord"]="$HOME/.config/discord-flags.conf"
    ["Slack"]="$HOME/.config/slack-flags.conf"
    ["Obsidian"]="$HOME/.config/obsidian-flags.conf"
    ["Figma"]="$HOME/.config/figma-desktop-flags.conf"
    ["Notion"]="$HOME/.config/notion-app-flags.conf"
    ["1Password"]="$HOME/.config/1password-flags.conf"
    ["GitHub Desktop"]="$HOME/.config/github-desktop-flags.conf"
    ["Bitwarden"]="$HOME/.config/bitwarden-flags.conf"
)

for app in "${!ELECTRON_APPS[@]}"; do
    flagfile="${ELECTRON_APPS[$app]}"
    if [ -f "$flagfile" ]; then
        changed=false
        if ! grep -q "GlobalMenuBar" "$flagfile"; then
            echo "$GLOBAL_MENU_FLAG" >> "$flagfile"
            changed=true
        fi
        if ! grep -q "ozone-platform-hint" "$flagfile"; then
            echo "$OZONE_FLAG" >> "$flagfile"
            changed=true
        fi
        if $changed; then
            echo "    Updated: $flagfile ($app)"
        fi
    fi
done

# Set environment variables for Electron apps that check them at runtime
dbus-update-activation-environment --systemd \
    ELECTRON_OZONE_PLATFORM_HINT=auto 2>/dev/null || true

echo ""
echo "    NOTE: Flags files are only updated for apps that already have a config file."
echo "    For new apps, create the flags file manually:"
echo "      echo '--enable-features=GlobalMenuBar' > ~/.config/APP-flags.conf"
echo "    Restart the app after updating its flags file."
echo ""
echo "==> Electron setup complete."

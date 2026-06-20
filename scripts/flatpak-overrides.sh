#!/bin/bash
# Expose the D-Bus AppMenu Registrar to Flatpak sandboxes.
# This allows Flatpak apps whose runtimes include appmenu-gtk-module (GTK2/3)
# or native D-Bus menu support (Qt, Electron) to export their menus.
#
# Limitation: GTK4 Flatpak apps will still not export menus because the GTK4
# appmenu module is not included in GNOME or KDE Flatpak runtimes.

set -e

echo "==> Configuring Flatpak D-Bus global menu access..."

# Global overrides: allow all Flatpak apps to talk to the menu registrar
flatpak override --user --talk-name=com.canonical.AppMenu.Registrar
flatpak override --user --talk-name=org.kde.kappmenu
flatpak override --user --env=UBUNTU_MENUPROXY=1
flatpak override --user --env=APPMENU_DISPLAY_BOTH=1

echo "    Applied global Flatpak D-Bus overrides."

# Per-app overrides for common applications
declare -A FLATPAK_APPS=(
    ["Firefox"]="org.mozilla.firefox"
    ["Thunderbird"]="org.mozilla.Thunderbird"
    ["GIMP"]="org.gimp.GIMP"
    ["LibreOffice"]="org.libreoffice.LibreOffice"
    ["Inkscape"]="org.inkscape.Inkscape"
    ["Kdenlive"]="org.kde.kdenlive"
    ["VLC"]="org.videolan.VLC"
    ["Audacity"]="org.audacityteam.Audacity"
    ["VS Code"]="com.visualstudio.code"
    ["Flatseal"]="com.github.tchx84.Flatseal"
)

for app in "${!FLATPAK_APPS[@]}"; do
    app_id="${FLATPAK_APPS[$app]}"
    if flatpak list --user --app --columns=application 2>/dev/null | grep -q "^${app_id}$" || \
       flatpak list --system --app --columns=application 2>/dev/null | grep -q "^${app_id}$"; then
        flatpak override --user "$app_id" \
            --talk-name=com.canonical.AppMenu.Registrar \
            --talk-name=org.kde.kappmenu
        echo "    Configured: $app ($app_id)"
    fi
done

echo ""
echo "    NOTE: GTK4 Flatpak apps (Nautilus, GNOME apps) require the GTK4 appmenu"
echo "    module inside the Flatpak runtime, which is not currently available."
echo "    Qt and Electron Flatpak apps with native D-Bus menu support will work."
echo ""
echo "==> Flatpak setup complete."

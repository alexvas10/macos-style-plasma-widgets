#!/bin/bash
# GTK4 global menu integration for KDE Plasma.
#
# GTK4 removed appmenu-gtk-module support in 2017, so GTK4 GNOME apps (Nautilus,
# GNOME Text Editor, etc.) cannot export their menus via D-Bus natively.
# This script configures what IS possible and documents what requires the AUR package.

set -e

echo "==> Configuring GTK4 global menu support..."

# Tell GTK4 apps to hide their in-window menu bar and let the shell handle it.
# Note: this alone does NOT make them export via D-Bus — it just hides the in-app bar.
mkdir -p ~/.config/gtk-4.0
SETTINGS="$HOME/.config/gtk-4.0/settings.ini"
if [ ! -f "$SETTINGS" ]; then
    cat > "$SETTINGS" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=0
gtk-shell-shows-menubar=1
EOF
else
    if ! grep -q "gtk-shell-shows-menubar" "$SETTINGS"; then
        echo "gtk-shell-shows-menubar=1" >> "$SETTINGS"
        echo "    Updated $SETTINGS with gtk-shell-shows-menubar=1"
    fi
fi

# Propagate GTK2/3 appmenu-gtk-module environment variables to all D-Bus-activated apps
dbus-update-activation-environment --systemd \
    GTK_MODULES="${GTK_MODULES:+${GTK_MODULES}:}appmenu-gtk-module" \
    UBUNTU_MENUPROXY=1 \
    APPMENU_DISPLAY_BOTH=1 2>/dev/null || true

# Check if plasma-appmenu-gtk4 (AUR) is installed — this is needed for full GTK4 support
if [ -f /usr/lib/gtk-4.0/modules/libappmenu-gtk4-module.so ]; then
    echo "    plasma-appmenu-gtk4 is installed — full GTK4 menu export enabled."
    dbus-update-activation-environment --systemd \
        GTK4_MODULES=appmenu-gtk4-module 2>/dev/null || true
else
    echo ""
    echo "    NOTE: GTK4 apps (Nautilus, GNOME Text Editor, etc.) require the AUR package"
    echo "    'plasma-appmenu-gtk4' for menu export. Without it, GTK4 app menus will not"
    echo "    appear in the global menu bar — the Finder fallback bar will show instead."
    echo ""
    echo "    To install (requires an AUR helper):"
    echo "      yay -S plasma-appmenu-gtk4"
    echo "      # or: paru -S plasma-appmenu-gtk4"
fi

echo "==> GTK4 setup complete."

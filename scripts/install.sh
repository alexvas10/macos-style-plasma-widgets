#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_DIR="$SCRIPT_DIR/../io.macos.plasma.globalmenu"

echo "==> Installing io.macos.plasma.globalmenu..."

# Remove any previous installation first
kpackagetool6 --type Plasma/Applet --remove io.macos.plasma.globalmenu 2>/dev/null || true

kpackagetool6 --type Plasma/Applet --install "$PLASMOID_DIR"

echo "==> Rebuilding KDE service cache..."
kbuildsycoca6 --noincremental

echo "==> Ensuring kded appmenu module is loaded..."
qdbus6 org.kde.kded6 /kded loadModule appmenu 2>/dev/null || \
    dbus-send --session --print-reply --dest=org.kde.kded6 \
        /kded org.kde.kded6.loadModule string:appmenu 2>/dev/null || true

echo "==> Installing appmenu registrar systemd service..."
SERVICE_SRC="$SCRIPT_DIR/appmenu_registrar.py"
SERVICE_DST="$HOME/.config/systemd/user/appmenu-registrar.service"
mkdir -p "$HOME/.config/systemd/user"
cat > "$SERVICE_DST" << SVCEOF
[Unit]
Description=com.canonical.AppMenu.Registrar for KDE global menu
After=dbus.socket
PartOf=graphical-session.target

[Service]
ExecStart=$SERVICE_SRC
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
SVCEOF
systemctl --user daemon-reload
systemctl --user enable appmenu-registrar.service
systemctl --user restart appmenu-registrar.service
echo "    Registrar service started and enabled."

echo ""
echo "==> Running system integration scripts..."
bash "$SCRIPT_DIR/gtk4-appmenu-setup.sh"
bash "$SCRIPT_DIR/electron-flags.sh"
bash "$SCRIPT_DIR/flatpak-overrides.sh"

echo ""
echo "Done! To add the widget to your top panel:"
echo "  1. Right-click the panel → Edit Panel"
echo "  2. Add Widgets → search for 'macOS Global Menu'"
echo "  3. Place it between the Application Title Bar and the spacer"
echo ""
echo "To reload Plasma without logging out:"
echo "  plasmashell --replace &"

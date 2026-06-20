#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/.."

WIDGETS=(
    "io.macos.plasma.datetime"
    "io.macos.plasma.search"
    "io.macos.plasma.controlcenter"
)

for widget in "${WIDGETS[@]}"; do
    echo "==> Installing $widget..."
    kpackagetool6 --type Plasma/Applet --remove "$widget" 2>/dev/null || true
    kpackagetool6 --type Plasma/Applet --install "$ROOT/$widget"
done

echo "==> Rebuilding KDE service cache..."
kbuildsycoca6 --noincremental

echo "==> Restarting plasmashell..."
plasmashell --replace &
sleep 3

echo ""
echo "Done! Plasmashell restarted."
echo "Add the widgets via: Right-click panel → Edit Panel → Add Widgets"
echo "  Suggested right-to-left order: [Search] [Date & Time] [Control Center]"

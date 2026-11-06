#!/usr/bin/env sh
# Install or upgrade Dara Launcher for the current user (Plasma 6).
set -e
cd "$(dirname "$0")"
kpackagetool6 -t Plasma/Applet -u launcher 2>/dev/null || kpackagetool6 -t Plasma/Applet -i launcher
echo "Installed. Right-click the panel > Add Widgets > search 'Dara Launcher'."
echo "If it does not show up yet, restart the shell:  plasmashell --replace &"

#!/usr/bin/env bash
# AMakerLauncher entfernen. Über den Launcher installierte Apps bleiben erhalten,
# außer du startest das Skript mit --alles.
#
#   curl -fsSL https://raw.githubusercontent.com/AMakerSpace/AMakerLauncher/main/uninstall.sh | bash
set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS="$DATA/amakerlauncher/apps"

pkill -f "amakerlauncher/apps/amakerlauncher/amakerlauncher.py" 2>/dev/null || true
rm -f "$DATA/applications/de.amakerspace.AMakerLauncher.desktop" "$DATA/applications/de.amakerspace.AMakerLauncherDev.desktop"
rm -rf "$APPS/amakerlauncher" "$DATA/fonts/amakerlauncher/amakerlauncher"

if [ "${1:-}" = "--alles" ]; then
  # Menüeinträge der installierten Apps finden und mit entfernen
  grep -l "^X-AMakerLauncher-App=" "$DATA"/applications/*.desktop 2>/dev/null | xargs -r rm -f
  rm -rf "$DATA/amakerlauncher" "$DATA/fonts/amakerlauncher" "${XDG_CACHE_HOME:-$HOME/.cache}/amakerlauncher"
  echo "✓ AMakerLauncher und alle darüber installierten Apps wurden entfernt."
else
  echo "✓ AMakerLauncher wurde entfernt. Deine Apps sind noch da (alles entfernen: uninstall.sh --alles)."
fi
update-desktop-database "$DATA/applications" 2>/dev/null || true

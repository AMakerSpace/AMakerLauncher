#!/usr/bin/env bash
# AMakerLauncher installieren – für Ubuntu und Debian.
#
#   curl -fsSL https://raw.githubusercontent.com/AMakerSpace/AMakerLauncher/main/install.sh | bash
#
# Lädt die neueste Version aus dem Katalog (github.com/AMakerSpace/amakerlauncher-apps), prüft die
# SHA-256-Prüfsumme und installiert den Launcher für deinen Benutzer – mit Menüeintrag und Schrift.
# Root-Rechte braucht es nur, falls Systempakete (python3-gi, WebKit) fehlen.
set -euo pipefail

CATALOG_REPO="AMakerSpace/amakerlauncher-apps"
APP_ID="amakerlauncher"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\033[1m▸\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

bold "AMakerLauncher – Installation"

[ "$(uname -s)" = "Linux" ] || fail "Der AMakerLauncher läuft unter Linux (Ubuntu/Debian)."
command -v apt-get >/dev/null || fail "apt wurde nicht gefunden – gedacht für Ubuntu und Debian."
[ "$(id -u)" -ne 0 ] || fail "Bitte nicht mit sudo starten – der Launcher wird für deinen Benutzer installiert."

# 1. Abhängigkeiten
NEEDED=()
for pkg in python3 python3-gi gir1.2-webkit2-4.1 curl; do
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" || NEEDED+=("$pkg")
done
if [ ${#NEEDED[@]} -gt 0 ]; then
  step "Installiere fehlende Pakete: ${NEEDED[*]} (braucht dein Passwort)"
  sudo apt-get update -q
  sudo apt-get install -y -q "${NEEDED[@]}"
else
  step "Alle Abhängigkeiten sind schon da"
fi

# 2. Neueste Version aus dem Katalog
step "Frage den Katalog nach der neuesten Version"
CATALOG="$(curl -fsSL -H 'Accept: application/vnd.github.raw' "https://api.github.com/repos/$CATALOG_REPO/contents/catalog.json" \
  || curl -fsSL "https://raw.githubusercontent.com/$CATALOG_REPO/main/catalog.json")" || fail "Katalog nicht erreichbar – Internetverbindung prüfen."
read -r VERSION URL SHA < <(printf '%s' "$CATALOG" | python3 -c '
import json, sys
app = next(a for a in json.load(sys.stdin)["apps"] if a["id"] == sys.argv[1])
print(app["version"], app["url"], app["sha256"])' "$APP_ID") || fail "Der Launcher fehlt im Katalog."

# 3. Herunterladen und prüfen
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
step "Lade AMakerLauncher $VERSION"
curl -fsSL --retry 3 -o "$TMP/launcher.tar.gz" "$URL" || fail "Download fehlgeschlagen."
echo "$SHA  $TMP/launcher.tar.gz" | sha256sum -c --quiet - || fail "Prüfsumme stimmt nicht – Download beschädigt."
mkdir "$TMP/app"
tar -xzf "$TMP/launcher.tar.gz" -C "$TMP/app"

# 4. Installieren (kopiert sich nach ~/.local/share/amakerlauncher, legt Menüeintrag und Schrift an)
step "Installiere für $(whoami)"
python3 "$TMP/app/amakerlauncher.py" --install-local >/dev/null

bold "✓ Fertig! AMakerLauncher $VERSION ist installiert."
echo "  Starten: im App-Menü nach „AMakerLauncher“ suchen – oder jetzt mit:"
echo "  gtk-launch de.amakerspace.AMakerLauncher"
echo "  Updates installiert der Launcher ab jetzt selbst."

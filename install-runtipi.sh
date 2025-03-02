#!/usr/bin/env sh
set -e
set -u
set -o pipefail

# ANSI-Farben: Bold und Grün
BOLD_GREEN='\033[1;32m'
NC='\033[0m'  # Kein Farbcode

# Logging-Funktion
log() {
  printf "%s [INFO] ${BOLD_GREEN}%s${NC}\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

log "Starte install-runtipi.sh..."

# Architektur ermitteln
ARCHITECTURE="$(uname -m)"
case "$ARCHITECTURE" in
  armv7*|i686|i386)
    log "runtipi wird auf 32-Bit-Systemen nicht unterstützt."
    exit 1
    ;;
  arm64|aarch64)
    ASSET="runtipi-cli-linux-aarch64.tar.gz"
    ;;
  *)
    ASSET="runtipi-cli-linux-x86_64.tar.gz"
    ;;
esac

# Immer die neueste Version installieren
log "Hole die neueste runtipi-Version..."
LATEST_VERSION="$(curl -sL https://api.github.com/repos/runtipi/runtipi/releases/latest | grep '"tag_name":' | cut -d '"' -f4)"
if [ -z "$LATEST_VERSION" ]; then
  log "Fehler beim Abrufen der neuesten Version. Skript wird beendet."
  exit 1
fi
log "Die neueste Version ist ${LATEST_VERSION}"

URL="https://github.com/runtipi/runtipi/releases/download/${LATEST_VERSION}/${ASSET}"
INSTALL_DIR="/root/runtipi"

# Installationsverzeichnis vorbereiten
log "Erstelle das Installationsverzeichnis ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

log "Lade runtipi von ${URL} herunter..."
curl --location "$URL" -o runtipi-cli.tar.gz

log "Entpacke runtipi-cli.tar.gz..."
tar -xzf runtipi-cli.tar.gz

# Den extrahierten Ordner ermitteln (erster Eintrag im Tar-Archiv)
EXTRACTED_DIR="$(tar -tzf runtipi-cli.tar.gz | head -n 1 | cut -d "/" -f1)"
if [ -d "$EXTRACTED_DIR" ]; then
  mv "$EXTRACTED_DIR" runtipi-cli
else
  # Falls kein Verzeichnis, dann handelt es sich um die ausführbare Datei direkt
  mv runtipi-cli.tar.gz runtipi-cli
fi

rm -f runtipi-cli.tar.gz
chmod +x runtipi-cli

log "Starte runtipi..."
./runtipi-cli start

log "runtipi wurde erfolgreich installiert und gestartet."
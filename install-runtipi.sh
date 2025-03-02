#!/usr/bin/env sh
set -e
set -u
set -o pipefail

# Dieses Skript MUSS als Root ausgeführt werden
if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als Root ausgeführt werden." >&2
  exit 1
fi

# ANSI-Farben: Bold und Grün
BOLD_GREEN='\033[1;32m'
NC='\033[0m'  # Kein Farbcode

# Logging-Funktion
log() {
  printf "%s [INFO] ${BOLD_GREEN}%s${NC}\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

log "Starte install-runtipi.sh..."

# Architektur ermitteln und passendes Asset wählen
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

# Ermitteln des ersten Eintrags im Archiv (Name des extrahierten Ordners)
EXTRACTED_DIR="$(tar -tzf runtipi-cli.tar.gz | head -n 1 | cut -d "/" -f1)"
rm -f runtipi-cli.tar.gz

# Prüfen, ob der extrahierte Ordner existiert und ob darin die ausführbare Datei enthalten ist
if [ -d "$EXTRACTED_DIR" ]; then
  if [ -f "$EXTRACTED_DIR/runtipi-cli" ]; then
    log "Extrahierter Ordner '$EXTRACTED_DIR' enthält die erwartete ausführbare Datei."
  else
    log "Warnung: Im Ordner '$EXTRACTED_DIR' wurde keine Datei 'runtipi-cli' gefunden. Es wird versucht, die ausführbare Datei zu identifizieren."
  fi

  # Den extrahierten Ordner in "runtipi-cli" umbenennen
  log "Benenne '$EXTRACTED_DIR' in 'runtipi-cli' um..."
  mv "$EXTRACTED_DIR" runtipi-cli
  BIN_PATH="$INSTALL_DIR/runtipi-cli/runtipi-cli"
else
  # Falls direkt eine ausführbare Datei extrahiert wurde
  log "Direkt eine ausführbare Datei '$EXTRACTED_DIR' extrahiert."
  mv "$EXTRACTED_DIR" runtipi-cli
  BIN_PATH="$INSTALL_DIR/runtipi-cli"
fi

chmod +x "$BIN_PATH"

log "Starte runtipi..."
"$BIN_PATH" start

log "runtipi wurde erfolgreich installiert und gestartet."
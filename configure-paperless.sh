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

log "Starte script..."

# Verzeichnis für das Git-Repo erstellen und Repository klonen
INSTALL_DIR="/root/runtipi"
USER_CONFIG_DIR="${INSTALL_DIR}/user-config"
PAPERLESS_NGX_DIR="${USER_CONFIG_DIR}/paperless-ngx"

log "Klonen des Repositories 'runtipi-paperless-user-config' in ${USER_CONFIG_DIR}..."
git clone https://github.com/thueske/runtipi-paperless-user-config.git "$USER_CONFIG_DIR"

log "Repository wurde erfolgreich geklont."

# Erstelle das Verzeichnis für paperless-ngx, falls es noch nicht existiert
mkdir -p "$PAPERLESS_NGX_DIR"

# Die Datei app.env erstellen
APP_ENV_FILE="${PAPERLESS_NGX_DIR}/app.env"

log "Erstelle die Datei 'app.env' in ${PAPERLESS_NGX_DIR}..."

# Benutzer nach Passwort fragen
echo "Bitte geben Sie das Passwort für die Gehaltsabrechnung ein (mehrere Passwörter mit Leerzeichen getrennt):"
read -r PAPERLESS_PASSWORD

# Inhalt der app.env-Datei eintragen
echo "# Mehrere Passwörter mit Leerzeichen getrennt" > "$APP_ENV_FILE"
echo "PAPERLESS_DECRYPT_PASSWORD=\"$PAPERLESS_PASSWORD\"" >> "$APP_ENV_FILE"

log "Die Datei 'app.env' wurde erfolgreich erstellt und gespeichert."

# Benutzer darauf hinweisen, die App neu zu starten
log "Wichtig: Bitte starten Sie die Paperless-ngx-App über das UI neu, damit die Änderungen wirksam werden."

log "Script abgeschlossen."

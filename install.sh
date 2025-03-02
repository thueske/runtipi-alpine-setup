#!/usr/bin/env sh
set -e

# ANSI-Farben: Bold und Grün
BOLD_GREEN='\033[1;32m'
NC='\033[0m'  # Kein Farbcode

# Logging-Funktion mit farbiger und fetter Ausgabe
log() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ${BOLD_GREEN}$*${NC}"
}

# Aktualisiere /etc/apk/repositories (ersetze immer, da es idempotent ist)
log "Aktualisiere /etc/apk/repositories..."
cat > /etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/
EOF

log "Installiere Pakete..."
apk --update --no-cache add zip git zsh curl htop docker docker-cli-compose doas bash rsync iftop tailscale logrotate

# Lade das tun-Modul nur, wenn es noch nicht geladen ist
log "Lade das tun-Modul..."
if ! lsmod | grep -q "^tun"; then
  modprobe tun
else
  log "tun-Modul bereits geladen."
fi

# Stelle sicher, dass "tun" in /etc/modules-load.d/tun.conf steht
if [ ! -f /etc/modules-load.d/tun.conf ] || ! grep -q "^tun$" /etc/modules-load.d/tun.conf; then
  echo "tun" >> /etc/modules-load.d/tun.conf
  log "tun wurde zu /etc/modules-load.d/tun.conf hinzugefügt."
else
  log "tun ist bereits in /etc/modules-load.d/tun.conf."
fi

# Konfiguriere sysctl für Tailscale: Nur hinzufügen, wenn die Zeilen nicht existieren
log "Konfiguriere sysctl für Tailscale..."
TAILSCALE_CONF="/etc/sysctl.d/99-tailscale.conf"
if [ ! -f "$TAILSCALE_CONF" ]; then
  echo 'net.ipv4.ip_forward = 1' > "$TAILSCALE_CONF"
  echo 'net.ipv6.conf.all.forwarding = 1' >> "$TAILSCALE_CONF"
  log "Tailscale sysctl-Konfiguration erstellt."
else
  # Ergänze fehlende Einträge
  if ! grep -q "net.ipv4.ip_forward" "$TAILSCALE_CONF"; then
    echo 'net.ipv4.ip_forward = 1' >> "$TAILSCALE_CONF"
    log "IPv4 Forwarding zu Tailscale sysctl-Konfiguration hinzugefügt."
  fi
  if ! grep -q "net.ipv6.conf.all.forwarding" "$TAILSCALE_CONF"; then
    echo 'net.ipv6.conf.all.forwarding = 1' >> "$TAILSCALE_CONF"
    log "IPv6 Forwarding zu Tailscale sysctl-Konfiguration hinzugefügt."
  fi
fi
sysctl -p "$TAILSCALE_CONF"

# Konfiguriere sysctl für Caddy
log "Konfiguriere sysctl für Caddy..."
CADDY_CONF="/etc/sysctl.d/99-caddy.conf"
if [ ! -f "$CADDY_CONF" ]; then
  echo 'net.core.rmem_max=7500000' > "$CADDY_CONF"
  echo 'net.core.wmem_max=7500000' >> "$CADDY_CONF"
  log "Caddy sysctl-Konfiguration erstellt."
else
  if ! grep -q "net.core.rmem_max" "$CADDY_CONF"; then
    echo 'net.core.rmem_max=7500000' >> "$CADDY_CONF"
    log "rmem_max zu Caddy sysctl-Konfiguration hinzugefügt."
  fi
  if ! grep -q "net.core.wmem_max" "$CADDY_CONF"; then
    echo 'net.core.wmem_max=7500000' >> "$CADDY_CONF"
    log "wmem_max zu Caddy sysctl-Konfiguration hinzugefügt."
  fi
fi
sysctl -p "$CADDY_CONF"

# Tailscale-Dienst hinzufügen, falls nicht bereits vorhanden, und starten
log "Füge den Tailscale-Dienst hinzu..."
if ! rc-update show | grep -q "^tailscale"; then
  rc-update add tailscale
fi
rc-service tailscale restart

# Docker zum Boot-Prozess hinzufügen, falls noch nicht vorhanden
log "Füge Docker zum Boot-Prozess hinzu..."
if ! rc-update show | grep -q "^docker"; then
  rc-update add docker boot
fi

# Erstelle und konfiguriere die Docker-Daemon-Konfiguration
log "Erstelle und konfiguriere die Docker-Daemon-Konfiguration..."
DOCKER_CONF_DIR="/etc/docker"
DOCKER_CONF_FILE="${DOCKER_CONF_DIR}/daemon.json"
mkdir -p "$DOCKER_CONF_DIR"
# Überschreibe die Datei, da die Konfiguration konsistent sein soll.
cat > "$DOCKER_CONF_FILE" <<EOL
{
  "live-restore": true,
  "log-driver": "local",
  "log-opts": {
    "mode": "non-blocking",
    "max-buffer-size": "16m",
    "compress": "true",
    "max-file": "3",
    "max-size": "10m"
  },
  "default-address-pools": [
    {
      "base": "172.16.0.0/12",
      "size": 24
    }
  ],
  "dns": [
    "8.8.8.8",
    "8.8.4.4"
  ]
}
EOL

# Docker-Dienst starten oder neu starten, falls bereits aktiv
log "Starte oder starte den Docker-Dienst neu..."
if pgrep dockerd > /dev/null; then
  service docker restart
else
  service docker start
fi

# Oh My Zsh installieren, falls noch nicht vorhanden
log "Installiere Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh ist bereits installiert."
fi

# Aktivierung des docker-compose Plugins in der .zshrc
log "Aktiviere das docker-compose Plugin in der Zsh-Konfiguration..."
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  if grep -q "^plugins=(" "$ZSHRC"; then
    if ! grep -q "docker-compose" "$ZSHRC"; then
      sed -i '/^plugins=(/ s/)/ docker-compose)/' "$ZSHRC"
      log "docker-compose Plugin wurde zur .zshrc hinzugefügt."
    else
      log "docker-compose Plugin ist bereits in der .zshrc aktiviert."
    fi
  else
    log "Keine plugins-Zeile in der .zshrc gefunden. Füge eine neue ein."
    echo "plugins=(docker-compose)" >> "$ZSHRC"
  fi
else
  log ".zshrc nicht gefunden, überspringe Plugin-Aktivierung."
fi

# Cronjobs einrichten
log "Installiere Cronjobs..."
CRON_PATH="$PWD/cronjobs"
(
  crontab -l 2>/dev/null
  cat <<EOF
0 0 * * * $CRON_PATH/autoupgrade.sh
0 1 * * * $CRON_PATH/autorebootifnewkernel.sh
EOF
) | crontab -
log "Cronjobs wurden eingerichtet."

log "Setup abgeschlossen."

# Neustart-Abfrage
printf "\nMöchtest du das System neu starten? [Y/n] "
read answer
# Bei leerer Eingabe oder Y/y wird ein Neustart durchgeführt
if [ -z "$answer" ] || [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
  log "Neustart wird durchgeführt..."
  reboot
else
  log "Neustart abgebrochen."
fi
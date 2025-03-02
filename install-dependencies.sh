#!/usr/bin/env sh
set -e

# ANSI-Farben: Bold und Grün
BOLD_GREEN='\033[1;32m'
NC='\033[0m'  # Kein Farbcode

# Logging-Funktion mit farbiger und fetter Ausgabe
log() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ${BOLD_GREEN}$*${NC}"
}

log "Aktualisiere /etc/apk/repositories..."
cat > /etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/
EOF

log "Installiere Pakete..."
apk --update --no-cache add zip git zsh curl htop docker docker-cli-compose doas bash rsync iftop tailscale logrotate

log "Lade das tun-Modul..."
modprobe tun
echo "tun" >> /etc/modules-load.d/tun.conf

log "Konfiguriere sysctl für Tailscale..."
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf

log "Konfiguriere sysctl für Caddy..."
echo 'net.core.rmem_max=7500000' | tee -a /etc/sysctl.d/99-caddy.conf
echo 'net.core.wmem_max=7500000' | tee -a /etc/sysctl.d/99-caddy.conf
sysctl -p /etc/sysctl.d/99-caddy.conf

log "Füge den Tailscale-Dienst hinzu und starte ihn..."
rc-update add tailscale
rc-service tailscale start

log "Füge Docker zum Boot-Prozess hinzu..."
rc-update add docker boot

log "Erstelle und konfiguriere die Docker-Daemon-Konfiguration..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOL
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

log "Starte Docker-Dienst..."
service docker start

log "Installiere Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh ist bereits installiert."
fi

log "Aktiviere das docker-compose Plugin in der Zsh-Konfiguration..."
if [ -f "$HOME/.zshrc" ]; then
  if grep -q "plugins=(" "$HOME/.zshrc"; then
    if ! grep -q "docker-compose" "$HOME/.zshrc"; then
      sed -i '/^plugins=(/ s/)/ docker-compose)/' "$HOME/.zshrc"
      log "docker-compose Plugin wurde zur .zshrc hinzugefügt."
    else
      log "docker-compose Plugin ist bereits in der .zshrc aktiviert."
    fi
  else
    log "Keine plugins-Zeile in der .zshrc gefunden. Füge eine neue ein."
    echo "plugins=(docker-compose)" >> "$HOME/.zshrc"
  fi
else
  log ".zshrc nicht gefunden, überspringe Plugin-Aktivierung."
fi

log "Setup abgeschlossen."
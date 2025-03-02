# Homeserver mit [Alpine](https://alpinelinux.org/) und [Runtipi](https://runtipi.io/)

![Lenovo M720q Mini-PC](https://i.imgur.com/EzA5OuB.png)

Erstelle einen Homeserver mit Alpine Linux (inkl. automatische, tägliche Updates) und Runtipi für App-Installationen per 1-Klick. Die Backups des Servers werden per Restic (inkl. [Web-UI](https://github.com/garethgeorge/backrest)) auf einen SFTP-Server deiner Wahl gemacht und per [Healthchecks.io](https://healthchecks.io/) überwacht.

## Voraussetzungen

- (refurbished) [Mini-PC](https://www.mydealz.de/gruppe/mini-pc) mit min. 8GB Arbeitsspeicher und min. 128GB SSD
- USB-Stick mit min. 8GB Speicherplatz
- RJ45-Netzwerkkabel zum Anschluss am Router
- Account bei [Healthchecks.io](https://healthchecks.io/)
- SFTP-Server für Backups

## Boot-Medium erstellen

![Balena Etcher](https://i.imgur.com/RmoenZF.png)

- https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ aufrufen und dort die aktuellste Version der Datei `alpine-standard-*-x86_64.iso` herunterladen
- Mit dem Tool [BalenaEtcher](https://etcher.balena.io/) die zuvor heruntergeladene Datei auf den USB-Stick flashen
- Anschließend den bootfähigen USB-Stick an den Mini-PC, welcher per Netzwerkkabel an deinem Router angeschlossen ist, stecken und von diesem aus dem BIOS heraus booten

## Alpine Linux installieren

![Alpine Linux USB-Installer](https://linuxiac.b-cdn.net/wp-content/uploads/2023/05/alpine-install1.png)

- Login im zuvor gezeigten Screen mit dem Nutzernamen `root`
- Befehl `setup-alpine` ausführen, um den Installations-Wizard zu starten
- Folgende Einstellungen im Wizard setzen:
	- Keymap: `de`
	- Keymap-Variant: `de`
	- Hostname: `homeserver`
	- Interface: `eth0` / `DHCP` / `no` (Manual configuration)
	- Root-Passwort: Sicheres Passwort wählen und gut speichern
	- Timezone: `Europe/Berlin`
	- Proxy: `none`
	- Mirror: `1`
	- User: `no`
	- SSH-Server: `openssh` 
	- Root-SSH-Login: `yes`
	- SSH-Key-URL: `none`
	- Disk: `sda` (in den meisten Fällen passt der Vorschlag)
	- Type: `sys`
	- Erase & continue: `yes`
- USB-Stick entfernen
- `reboot`

## Grundsystem konfigurieren 

- Zuerst musst du die IP-Adresse deines Servers herausfinden, z. B. über die Fritz!Box
- SSH-Login ([iTerm2](https://iterm2.com/) auf macOS oder [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) auf Windows) auf die obige IP-Adresse, dem Benutzername `root` und deinem zuvor gesetzten Passwort
- `apk --update add git` nutzen, um die Software `git` zu installieren
- `git clone https://github.com/thueske/runtipi-alpine-setup.git` eingeben, um die Installationsskripte herunterzuladen
- In den neuen Ordner wechseln `cd runtipi-alpine-setup`, um anschließend mit `./install-system.sh` ([Quelle](https://github.com/thueske/runtipi-alpine-setup/blob/main/install-system.sh)) Abhängigkeiten (z. B. Docker) sowie Cronjobs (z. B. Automatische Updates) zu installieren
- Danach startet das System einmal neu

## Runtipi installieren

- Wieder, wie bereits bekannt, per SSH anmelden
- Erneut in den Ordner `cd runtipi-alpine-setup` wechseln und dort dann `./install-runtipi.sh` ([Quelle](https://github.com/thueske/runtipi-alpine-setup/blob/main/install-runtipi.sh)) ausführen, um Runtipi zu installieren
- Das Webinterface sollte nun per `http://<deineIP>` aufrufbar sein und dich auffordern, einen Nutzer anzulegen

## Backups einrichten

### SFTP-Server konfigurieren

- Halte die Verbindungsdaten (Hostname, Port, Benutzer, Passwort, Pfad) von deinem SFTP-Server (z. B. [Hetzner Storage-Box](https://www.hetzner.com/de/storage/storage-box/)) bereit
- Installiere in deiner Runtipi-Instanz die App `Backrest` und gib dort die Verbindungsdaten deines SFTP-Servers ein
	- Als `Notify-URL` (z. B. `https://hc-ping.com/f44d42e8-0534-1212-96e3-497de4asdasddas`) trägst du deine Check-URL von [Healthchecks.io](https://healthchecks.io/) ein
- Nach der Installation kannst du im Log den Public-Key deiner Backrest-Instanz sehen:
```
ssh-key-generator-1  | Public SSH key:  
ssh-key-generator-1  | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+Abj8mDZH90PbPimcC/JEbnov7U0PDTF8VlCruIZJj root@a7eb6221e118
```
- Diesen Key fügst du in die `~/.ssh/authorized_keys` deines SFTP-Servers ein
- Anschließend das Webinterface von Backrest unter `http://<deineIP>:9898` öffnen
- Konfiguriere auch hier einen Benutzer samt Passwort, damit die Backups nicht ohne Authentifizierung aufrufbar sind – als Instance-ID kannst du einfach `homeserver` eintragen

### Restic-Repository anlegen
- Klicke links im Backrest-Menü auf `Add Repo` und trage einen Namen (z. B. `Hetzner Storage-Box`) ein
- Bei `Repository URI` trägst du `sftp:backup:/your/path` ein, wobei `/your/path` das Zielverzeichnis deiner Backups ist – ein Passwort brauchst du nicht, weil das passwortlos über den SSH-Key funktioniert, den du im vorherigen Schritt eingerichtet hast
- Das `Passwort`, was du nun generierst, verschlüsselt deine Backups – speichere es sicher weg, denn auch zum Wiederherstellen von Dateien benötigst du dieses
- Wähle bei `Prune Policy` aus, an welchen Tagen es laufen soll (ca. 1x im Monat reicht)
- Bei `Check Policy` reicht ebenfalls 1x im Monat, wähle nur hier einen anderen Zeitpunkt als bei der vorherigen Einstellung
- Setze die Checkbox `Auto unlock`, teste und speichere das Repository

### Zeitplan anlegen
- Lege nun über das Hauptmenü einen Zeitplan mit Klick auf `Add Plan` an, den du `daily` nennst
- Als `Repository` wählst du das zuvor angelegte Repository aus
- Der `Path` ist in unseren Fall `/mnt`, da hier alle Docker-Volumes und der Benutzerordner sowie Runtipi gemounted sind
- Als `Backup Schedule` wählst du z. B. `Every day at 14:00` aus
- Bei `Retention Policy` nun noch konfigurieren wie viele alte Backups gespeichert werden sollen
- Zu guter letzt müssen noch die Hooks angelegt werden, sodass [Healthchecks.io](https://healthchecks.io/) deine Backups überwachen kann und im Falle eines ausbleibenden Backups eine Notification schicken kann – wähle jeweils `Add Hook` und `Command` aus und trage es wie folgt ein:

| HOOK                                                       | Command                                  |
|------------------------------------------------------------|------------------------------------------|
| `CONDITION_SNAPSHOT_START`                                 | `bash -x /scripts/stop-container.sh`     |
| `CONDITION_SNAPSHOT_END`                                   | `bash -x /scripts/start-container.sh`    |
| `CONDITION_SNAPSHOT_WARNING`<br>`CONDITION_SNAPSHOT_ERROR` | `bash -x /scripts/report-status.sh down` |
| `CONDITION_SNAPSHOT_SUCCESS`                               | `bash -x /scripts/report-status.sh up`   |
- Den Zeitplan nun abspeichern und mit Klick auf `Backup now` testen

## Bock, noch mehr zu lernen?

Natürlich ist das nur der Anfang und du kannst noch viel mehr machen. Ließ dich doch mal in folgende Themen ein:

- Installiere dir Apps aus dem App-Store - nicht das passende dabei? Nimm die App `Portainer` und starte eigene Docker-Container 
- SSH-Key statt Passwort-Authentifizierung per SSH
- Domain und HTTPS in Runtipi einrichten
- Tailscale für sicheren Remote-Zugriff nutzen (Agent bereits über [install-system.sh](https://github.com/thueske/runtipi-alpine-setup/blob/main/install-system.sh) auf dem Host installiert, allerdings nicht konfiguriert)

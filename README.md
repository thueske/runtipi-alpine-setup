# Homeserver mit [Alpine](https://alpinelinux.org/) und [Runtipi](https://runtipi.io/)

![Lenovo M720q Mini-PC](https://i.imgur.com/EzA5OuB.png)

## Voraussetzungen

- (refurbished) [Mini-PC](https://www.mydealz.de/gruppe/mini-pc) mit min. 8GB Arbeitsspeicher und min. 128GB SSD
- USB-Stick mit min. 8GB Speicherplatz
- RJ45-Netzwerkkabel zum Anschluss am Router

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
- In den neuen Ordner wechseln `cd runtipi-alpine-setup`, um anschließend mit `./install-system.sh` Abhängigkeiten (z. B. Docker) sowie Cronjobs (z. B. Automatische Updates) zu installieren
- Danach startet das System einmal neu

## Runtipi installieren

- Wieder, wie bereits bekannt, per SSH anmelden
- Erneut in den Ordner `cd runtipi-alpine-setup` wechseln und dort dann `./install-runtipi.sh` ausführen, um Runtipi zu installieren
- Das Webinterface sollte nun per `http://<deineIP>` aufrufbar sein und dich auffordern, einen Nutzer anzulegen

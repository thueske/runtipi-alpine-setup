# Homeserver mit [Alpine](https://alpinelinux.org/) und [Runtipi](https://runtipi.io/)

![Lenovo M720q Mini-PC](https://i.postimg.cc/BbS42s2p/header.png)

## Voraussetzungen

- (refurbished) [Mini-PC](https://www.mydealz.de/gruppe/mini-pc) mit min. 8GB Arbeitsspeicher und min. 128GB SSD
- USB-Stick mit min. 8GB Speicherplatz
- RJ45-Netzwerkkabel zum Anschluss am Router

## Boot-Medium erstellen

- https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ aufrufen und dort die aktuellste Version der Datei `alpine-standard-*-x86_64.iso` herunterladen
- Mit dem Tool [BalenaEtcher](https://etcher.balena.io/) die zuvor heruntergeladene Datei auf den USB-Stick flashen
- Anschließend den bootfähigen USB-Stick an den Mini-PC anschließen und von diesem (aus dem BIOS heraus) booten

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

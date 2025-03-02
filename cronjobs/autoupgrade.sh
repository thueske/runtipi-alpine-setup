#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
LOGFILE="/var/log/autoupgrade.log"
CONFIG_FILE="$SCRIPT_DIR/autoupgrade.logrotate"

logrotate --force "$CONFIG_FILE"

apk update && apk upgrade --available | sed "s/^/[`date`] /" >> "$LOGFILE"
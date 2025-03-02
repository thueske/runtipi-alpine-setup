#!/usr/bin/env sh

SCRIPT_DIR="$(dirname "$0")"
LOGFILE="/var/log/autoupgrade.log"
CONFIG_FILE="$SCRIPT_DIR/autoupgrade.logrotate"

logrotate -v "$CONFIG_FILE"

apk update && apk upgrade --available | sed "s/^/[`date`] /" >> "$LOGFILE"
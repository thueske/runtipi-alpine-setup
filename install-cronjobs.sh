#!/usr/bin/env sh

CRON_PATH="$PWD/cronjobs"

(
  crontab -l 2>/dev/null
  cat <<EOF
0 0 * * * $CRON_PATH/autoupgrade.sh
0 1 * * * $CRON_PATH/autorebootifnewkernel.sh
EOF
) | crontab -
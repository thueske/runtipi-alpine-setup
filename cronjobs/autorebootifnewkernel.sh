#!/usr/bin/env sh

CURRENT_KERNEL=$(uname -r)
INSTALLED_KERNEL=$(ls /lib/modules/ | sort -V | tail -n 1)

if [ "$CURRENT_KERNEL" != "$INSTALLED_KERNEL" ]; then
    echo "Ein Kernel-Update wurde installiert. Ein Neustart ist erforderlich."
    reboot
else
    echo "Kein Kernel-Update erforderlich."
fi

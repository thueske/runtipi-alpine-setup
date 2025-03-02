#!/usr/bin/env sh

# Lenovo M720q
# sudo crontab -e
# @reboot /home/thueske/scripts/powertop.sh

echo '0' > '/proc/sys/kernel/nmi_watchdog';
echo '1500' > '/proc/sys/vm/dirty_writeback_centisecs';
echo 'auto' > '/sys/bus/usb/devices/1-7/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.0/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:08.0/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.5/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:00.0/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:14.2/power/control';
echo 'auto' > '/sys/bus/pci/devices/0000:00:14.0/power/control';
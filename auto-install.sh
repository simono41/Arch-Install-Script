#!/bin/bash

set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0
    exit 0
fi

server="$1"
day="$2"

[[ -z "${day}" ]] && day="0"

echo "To use this script for the automation paste in the Crontab"
echo "0 0 * * ${day} /root/auto.sh voll > /root/auto_voll.log 2>&1" > /var/spool/cron/root
echo "0 3 * * ${day} /root/auto.sh cinnamon > /root/auto_cinnamon.log 2>&1" >> /var/spool/cron/root
echo "0 6 * * ${day} /root/auto.sh gnome > /root/auto_gnome.log 2>&1" >> /var/spool/cron/root
echo "0 9 * * ${day} /root/auto.sh kde > /root/auto_kde.log 2>&1" >> /var/spool/cron/root
echo "0 12 * * ${day} /root/auto.sh lxde > /root/auto_lxde.log 2>&1" >> /var/spool/cron/root
echo "0 15 * * ${day} /root/auto.sh lxqt > /root/auto_lxqt.log 2>&1" >> /var/spool/cron/root
echo "0 18 * * ${day} /root/auto.sh mate > /root/auto_mate.log 2>&1" >> /var/spool/cron/root
echo "0 21 * * ${day} /root/auto.sh xfce4 > /root/auto_xfce4.log 2>&1" >> /var/spool/cron/root
echo "0 0 * * $(($day + 1)) /root/auto.sh libre > /root/auto_libre.log 2>&1" >> /var/spool/cron/root

systemctl restart cronie.service

cp "./auto.sh" /root/
chmod 755 /root/auto.sh

echo "You use for the uplouding on your server ssh with certificates"
chmod 755 ssh-keygen-auto.sh
./ssh-keygen-auto.sh ${server}

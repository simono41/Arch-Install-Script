#!/bin/bash

set -ex

pfad="${2}"

if [ "make" == "$1" ]; then

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/${pfad}/SNAPSHOT
echo "${3}" >> /run/btrfs-root/__current/${pfad}/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/${pfad} /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`

rm /run/btrfs-root/__current/${pfad}/SNAPSHOT

elif [ "restore" == "$1" ]; then

echo "Heutiges datum $(date "+%Y%m%d-%H%M%S")"
ls /run/btrfs-root/__snapshot
read -p "Welches datum hat das Image? : " datum

mv /run/btrfs-root/__current/${pfad} /run/btrfs-root/__current/${pfad}.old
btrfs subvolume snapshot /run/btrfs-root/__snapshot/${pfad}@${datum} /run/btrfs-root/__current/${pfad}
reboot

else

echo "bash ./snapshot.sh PARAMETER PFAD BESCHREIBUNG"
echo "Parameters: make restore"

btrfs subvolume list -p /

fi

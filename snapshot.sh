#!/bin/bash

set -ex

pfad="${2}"

if [ "make" == "$1" ]; then

btrfs subvolume list -p /

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/${pfad}/SNAPSHOT
echo "${3}" >> /run/btrfs-root/${pfad}/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/${pfad} /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/${pfad}/SNAPSHOT`

rm /run/btrfs-root/${pfad}/SNAPSHOT

elif [ "restore" == "$1" ]; then

echo "Heutiges datum $(date "+%Y%m%d-%H%M%S")"
ls /run/btrfs-root/__snapshot
read -p "Welches datum hat das Image? : " datum

mv /run/btrfs-root/${pfad} /run/btrfs-root/${pfad}.old
btrfs subvolume snapshot /run/btrfs-root/${pfad}@${datum} /run/btrfs-root/${pfad}
reboot

else

echo "bash ./snapshot.sh PARAMETER PFAD BESCHREIBUNG"
echo "Parameters: make restore"

fi

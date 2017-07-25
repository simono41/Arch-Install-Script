#!/bin/bash

set -ex

if [ "make" == "$1" ]; then

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/ROOT/SNAPSHOT
echo "${2}" >> /run/btrfs-root/__current/ROOT/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/ROOT /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/ROOT/SNAPSHOT`

rm /run/btrfs-root/__current/ROOT/SNAPSHOT

elif [ "restore" == "$1" ]; then

echo "Heutiges datum $(date "+%Y%m%d-%H%M%S")"
ls /run/btrfs-root/__snapshot
read -p "Welches datum hat das Image? : " datum

mv /run/btrfs-root/__current/ROOT /run/btrfs-root/__current/ROOT.old
btrfs subvolume snapshot /run/btrfs-root/__snapshot/ROOT@${datum} /run/btrfs-root/__current/ROOT
reboot

else

echo "bash ./snapshot.sh PARAMETER BESCHREIBUNG"
echo "Parameters: make restore"

fi

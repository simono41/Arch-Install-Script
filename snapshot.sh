#!/bin/bash

set -ex

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
echo "Als root Angemeldet"

pfad="${2}"

if [ "make" == "$1" ]; then

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/${pfad}/SNAPSHOT
echo "${3}" >> /run/btrfs-root/__current/${pfad}/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/${pfad} /run/btrfs-root/__snapshot/${pfad}@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`

rm /run/btrfs-root/__current/${pfad}/SNAPSHOT

elif [ "restore" == "$1" ]; then

if [ "$3" == '' ]; then
  echo "Heutiges datum $(date "+%Y%m%d-%H%M%S")"
  ls /run/btrfs-root/__snapshot
  read -p "Welches datum hat das Image? : " datum
    else
  datum="$3"
fi

if [ -d /run/btrfs-root/__current/${pfad}.old ]; then
  btrfs subvolume delete /run/btrfs-root/__current/${pfad}.old
fi
mv /run/btrfs-root/__current/${pfad} /run/btrfs-root/__current/${pfad}.old
btrfs subvolume snapshot /run/btrfs-root/__snapshot/${pfad}@${datum} /run/btrfs-root/__current/${pfad}
reboot

else

echo "bash ./snapshot.sh PARAMETER PFAD BESCHREIBUNG"
echo "Parameters: make restore"
echo "make ROOT fix"
echo "restore ROOT 20170725-235544"

btrfs subvolume list -p /

fi

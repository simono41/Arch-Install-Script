#!/bin/bash

set -ex

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
echo "Als root Angemeldet"

if [ "make" == "$1" ]; then

while (( "$(expr $# - 1)" ))
do

pfad="${2}"

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/${pfad}/SNAPSHOT
echo "BACKUP" >> /run/btrfs-root/__current/${pfad}/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/${pfad} /run/btrfs-root/__snapshot/${pfad}@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`

rm /run/btrfs-root/__current/${pfad}/SNAPSHOT

shift

done

elif [ "restore" == "$1" ]; then

while (( "$(expr $# - 1)" ))
do

pfad="${2}"

if [ -d /run/btrfs-root/__current/${pfad/@*}.old ]; then
  btrfs subvolume delete /run/btrfs-root/__current/${pfad/@*}.old
fi
mv /run/btrfs-root/__current/${pfad/@*} /run/btrfs-root/__current/${pfad/@*}.old
btrfs subvolume snapshot /run/btrfs-root/__snapshot/${pfad} /run/btrfs-root/__current/${pfad/@*}

shift

done

#reboot

else

echo "bash ./snapshot.sh PARAMETER PFAD"
echo "Parameters: make restore"
echo "make ROOT home opt var"
echo "restore ROOT@20170725-235544 home@20170725-235544 opt@20170725-235544 var@20170725-235544"

btrfs subvolume list -p /

fi

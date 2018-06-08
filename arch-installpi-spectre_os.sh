#!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi
echo "Als root Angemeldet"

fdisk -l

read -p "Wo soll das Image aufgespielt werden?: /dev/sda : " device
[[ -z "${device}" ]] && device=/dev/sda

if [ -f arch-spectre_os-*-armV7.tar.gz ]
then
    image=$(find arch-spectre_os-*-armV7.tar.gz)
    echo $datei
else
    echo "ABGEBROCHEN"
    exit 1
fi

echo "device: ${device}"
echo "Image: ${image}"

read -p "Sind alle Angaben Richtig?: [Y/n] " sicherheitsabfrage

if [ "$sicherheitsabfrage" == "n" ]
then
    echo "ABGEBROCHEN"
    exit 1
fi

if [ -f /usr/bin/pacman ]
then
    pacman -S dosfstools wget --needed --noconfirm
else
    apt-get install bsdtar dosfstools -y
fi

if cat /proc/mounts | grep /dev/"$device"1 > /dev/null; then
    echo "gemountet"
    umount /dev/"$device"1
else
    echo "nicht gemountet"
fi

if cat /proc/mounts | grep /dev/"$device"2 > /dev/null; then
    echo "gemountet"
    umount /dev/"$device"2
else
    echo "nicht gemountet"
fi

fdisk -W always /dev/"$device" <<EOT
o
p
n
p
1

+100M
t
c
n
p
2


p
w
EOT

sleep 1

mkfs.vfat /dev/"$device"1
mkdir -p boot
mount /dev/"$device"1 boot


mkfs.ext4 /dev/"$device"2
mkdir -p root
mount /dev/"$device"2 root

tar -xpf arch-spectre_os-*-armV7.tar.gz -C root
sync

mv root/boot/* boot

umount boot root

echo "Fertig!!!"

#!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0
    exit 0
fi
echo "Als root Angemeldet"

fdisk -l

read -p "Wo soll das Image aufgespielt werden?: /dev/sda : " device
[[ -z "${device}" ]] && device=/dev/sda

read -p "Haben sie ein PI 2 oder 3?: [3/2] " version
[[ -z "${version}" ]] && version=2

echo "device: ${device}"
echo "Version: ${version}"

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

if cat /proc/mounts | grep "$device"1 > /dev/null; then
    echo "gemountet"
    umount "$device"1
else
    echo "nicht gemountet"
fi

if cat /proc/mounts | grep "$device"2 > /dev/null; then
    echo "gemountet"
    umount "$device"2
else
    echo "nicht gemountet"
fi

fdisk -W always "$device" <<EOT
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

mkfs.vfat "$device"1
mkdir -p boot
mount "$device"1 boot


mkfs.ext4 "$device"2
mkdir -p root
mount "$device"2 root

if [ "$version" == "2" ]; then
    if [ ! -f "ArchLinuxARM-rpi-2-latest.tar.gz" ]
    then
        wget -c -t 0 "http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz"
    fi
    tar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C root
fi
if [ "$version" == "3" ]; then
    if [ ! -f "ArchLinuxARM-rpi-3-latest.tar.gz" ]
    then
        wget -c -t 0 "http://archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz"
    fi
    tar -xpf ArchLinuxARM-rpi-3-latest.tar.gz -C root
fi

sync

mv root/boot/* boot

echo "hdmi_force_hotplug=1" > boot/config.txt
echo "hdmi_group=2" >> boot/config.txt
echo "hdmi_mode=82" >> boot/config.txt
echo "hdmi_drive=2" >> boot/config.txt
echo "dtparam=audio=on" >> boot/config.txt
echo "gpu_mem=256" >> boot/config.txt

umount boot root

echo "Fertig!!!"

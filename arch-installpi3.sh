#!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi
echo "Als root Angemeldet"

fdisk -l

read -p "Wo soll das Image aufgespielt werden?: sda,sdb,sdc : " device

read -p "Haben sie das Image schon gedownloaded?: [Y/n] " image

echo "device:" $device
echo "image vorhanden:" $image

read -p "Sind alle Angaben Richtig?: [Y/n] " sicherheitsabfrage

if [ "$sicherheitsabfrage" == "n" ]
then
    echo "ABGEBROCHEN"
    exit 1
fi

if [ -f /usr/bin/pacman ]
then
    pacman -S dosfstools wget
else
    apt-get install bsdtar dosfstools
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

if [ "$image" == "n" ]
then
    wget -c -t 0 "http://archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz"
fi

tar -xpf ArchLinuxARM-rpi-3-latest.tar.gz -C root
sync

wget https://github.com/simono41/Arch-Install-Script/raw/master/arch-graphical-install -t 0 --output-document=root/root/arch-graphical-install
chmod +x root/root/arch-graphical-install

mv root/boot/* boot
#cp config.txt boot

echo "hdmi_force_hotplug=1" >> boot/config.txt
echo "hdmi_group=2" >> boot/config.txt
echo "hdmi_mode=82" >> boot/config.txt
echo "hdmi_drive=2" >> boot/config.txt
echo "dtparam=audio=on" >> boot/config.txt
echo "gpu_mem=256" >> boot/config.txt

umount boot root

echo "Fertig!!!"

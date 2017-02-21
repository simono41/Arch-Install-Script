#!/bin/bash
#
set -ex
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
fdisk -l
read -p "Geben sie eine Festplatte an: sda,sdb,sdc: " device

name=simon_os
arch=armV7

mkdir -p boot
mkdir -p root

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

mount /dev/"$device"1 boot 
mount /dev/"$device"2 root 

cp -R boot/* root/boot/

cd root/
tar -cpf ../arch-${name}-$(date "+%y.%m.%d")-${arch}.tar.gz *
cd ..
echo "FERTIG!!!"
exit 0

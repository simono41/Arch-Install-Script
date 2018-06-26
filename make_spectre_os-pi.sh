#!/bin/bash
#
set -ex
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0
    exit 0
fi
fdisk -l
read -p "Geben sie eine Festplatte an: /dev/sda : " device
[[ -z "${device}" ]] && device=/dev/sda

if [ "${device}" == "/dev/mmcblk0" ]; then
  m2ssddevice=p
fi

name=spectre_os
arch=armV7
out_dir=out

mkdir -p boot
mkdir -p root

if cat /proc/mounts | grep ${device}${m2ssddevice}1 > /dev/null; then
    echo "gemountet"
    umount ${device}${m2ssddevice}1
else
    echo "nicht gemountet"
fi

if cat /proc/mounts | grep ${device}${m2ssddevice}2 > /dev/null; then
    echo "gemountet"
    umount ${device}${m2ssddevice}2
else
    echo "nicht gemountet"
fi

mount ${device}${m2ssddevice}1 boot
mount ${device}${m2ssddevice}2 root

cp -R boot/* root/boot/

cd root/
mkdir -p ../${out_dir}/
tar -Ipixz -cpf ../${out_dir}/arch-${name}-$(date "+%y.%m.%d")-${arch}.tar.pxz *
cd ..

umount boot root

sync

echo "FERTIG!!!"
exit 0

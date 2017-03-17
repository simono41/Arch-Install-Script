#!/bin/bash
#
set -ex
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

iso_name=siri-os
iso_label="SIRI_OS"
iso_version=$(date +%Y.%m.%d)
work_dir=work
out_dir=out
install_dir=arch

arch=$(uname -m)

read -p "Soll das System neu aufgebaut werden?: [Y/n] " system
if [ "$system" != "n" ]
  then
echo "Scripte werden heruntergeladen!"

pacman -S xorriso cdrtools squashfs-tools wget dosfstools

mkdir -p ${work_dir}/${arch}/airootfs

read -p "Soll die Packete neu aufgebaut werden? [Y/n] " pacstrap
if [ "$pacstrap" != "n" ]
  then
    ./pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs base base-devel syslinux efibootmgr efitools grub intel-ucode arch-install-scripts 
fi

cd install
cp archiso ../${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/archiso
cd ..
cd hooks
cp archiso ../${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/archiso
cd ..

echo "HOOKS=\"base udev block filesystems keyboard archiso\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
echo "COMPRESSION=\"cat\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

echo ${iso_name} > ${work_dir}/${arch}/airootfs/etc/hostname

cp make_mksquashfs.sh ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs

cp pacman.conf ${work_dir}/${arch}/airootfs/etc/

cp arch-graphical-install ${work_dir}/${arch}/airootfs/usr/bin/
cp arch-install ${work_dir}/${arch}/airootfs/usr/bin/
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-graphical-install
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-install

cp mirrorlist ${work_dir}/${arch}/airootfs/etc/pacman.d/mirrorlist

./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --init
./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --populate archlinux
./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --refresh-keys

./arch-chroot ${work_dir}/${arch}/airootfs pacman -Syu

./arch-chroot ${work_dir}/${arch}/airootfs mkinitcpio -p linux

read -p "Welches Passwort soll der Root erhalten?: " pass
./arch-chroot ${work_dir}/${arch}/airootfs /bin/bash <<EOT
passwd
$pass
$pass
EOT
  else
echo "Wird nicht neu aufgebaut!!!"
echo "Es muss aber vorhanden sein für ein reibenloser Ablauf!!!"
fi
echo "Jetzt können sie ihre eigenen Packete hinzufügen:D"
read -p "Wollen sie automatisch eigene Packete hinzufügen? [Y/n] " packete
if [ "$packete" != "n" ]
  then
    ./arch-chroot ${work_dir}/${arch}/airootfs /usr/bin/arch-graphical-install
fi

# System-image

read -p "Soll das System-Image neu aufgebaut werden?: [Y/n] " image
mkdir -p ${work_dir}/iso/isolinux
mkdir -p ${work_dir}/iso/${install_dir}/${arch}
mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
mkdir -p ${work_dir}/iso/EFI/archiso
mkdir -p ${work_dir}/iso/EFI/boot
mkdir -p ${work_dir}/iso/loader/entries

if [ "$image" != "n" ]
  then
./arch-chroot ${work_dir}/${arch}/airootfs/ pacman -Q > ${work_dir}/${arch}/airootfs/pkglist.txt
cp ${work_dir}/${arch}/airootfs/pkglist.txt ${work_dir}/iso/${install_dir}/${arch}/
./arch-chroot ${work_dir}/${arch}/airootfs pacman -Sc
./arch-chroot ${work_dir}/${arch}/airootfs pacman -Scc

if [ -f ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs ]
then
rm ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs
else
echo "airootfs.sfs nicht vorhanden!"
fi

mksquashfs ${work_dir}/${arch}/airootfs ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs -comp xz -b 1024K

md5sum ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs > ${work_dir}/iso/${install_dir}/${arch}/airootfs.md5

  else
echo "Image wird nicht neu aufgebaut!!!"
fi

# BIOS

read -p "Soll das BIOS installiert werden?: [Y/n] " bios
if [ "$bios" != "n" ]
  then
cp -R ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/* ${work_dir}/iso/${install_dir}/boot/syslinux/
cp ${work_dir}/${arch}/airootfs/boot/initramfs-linux.img ${work_dir}/iso/arch/boot/${arch}/archiso.img
cp ${work_dir}/${arch}/airootfs/boot/vmlinuz-linux ${work_dir}/iso/arch/boot/${arch}/vmlinuz
cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/

echo "DEFAULT menu.c32" > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "PROMPT 0" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU TITLE ${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "TIMEOUT 300" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# default
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} DEFAULT" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# gnome
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} GNOME" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=gnome" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# cinnamon
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} CINNAMON" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=cinnamon" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# mate
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} MATE" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=mate" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# lxde
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} LXDE" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=lxde" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# lxqt
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} LXQT" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=lxqt" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# default toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} DEFAULT TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# gnome toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} GNOME TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=gnome copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "ONTIMEOUT arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# cinnamon toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} CINNAMON TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=cinnamon copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# mate toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} MATE TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=mate copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# lxde toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} LXDE TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=lxde copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

# lxqt toram
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label} LXQT TORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} desktop=lxqt copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

echo "DEFAULT loadconfig" > ${work_dir}/iso/isolinux/isolinux.cfg
echo "" >> ${work_dir}/iso/isolinux/isolinux.cfg
echo "LABEL loadconfig" >> ${work_dir}/iso/isolinux/isolinux.cfg
echo "  CONFIG /arch/boot/syslinux/syslinux.cfg" >> ${work_dir}/iso/isolinux/isolinux.cfg
echo "  APPEND /arch/boot/syslinux/" >> ${work_dir}/iso/isolinux/isolinux.cfg
fi

# EFI

read -p "Soll das EFI installiert werden?: [Y/n] " efi
if [ "$efi" != "n" ]
  then
if [ -f ${work_dir}/iso/EFI/archiso/efiboot.img ]
then
rm ${work_dir}/iso/EFI/archiso/efiboot.img
else
echo "efiboot.img nicht vorhanden!"
fi
truncate -s 256M ${work_dir}/iso/EFI/archiso/efiboot.img
mkfs.fat -n ${iso_label}_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

mkdir -p ${work_dir}/efiboot/
mount ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot
mkdir -p ${work_dir}/efiboot/EFI/boot
mkdir -p ${work_dir}/efiboot/EFI/archiso
mkdir -p ${work_dir}/efiboot/loader/entries

cp ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
cp ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img ${work_dir}/efiboot/EFI/archiso/archiso.img

cp ${work_dir}/${arch}/airootfs/boot/intel-ucode.img ${work_dir}/iso/${install_dir}/boot/intel_ucode.img
cp ${work_dir}/iso/${install_dir}/boot/intel_ucode.img ${work_dir}/efiboot/EFI/archiso/intel_ucode.img

cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi ${work_dir}/efiboot/EFI/boot/bootx64.efi

cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi ${work_dir}/efiboot/EFI/boot/

cp ${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/efiboot/EFI/boot/loader.efi

cp loader.conf ${work_dir}/efiboot/loader/
cp uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
cp uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/

# default
echo "title   ${iso_label} x86_64 UEFI USB DEFAULT" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-default.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label}" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default.conf

# gnome
echo "title   ${iso_label} x86_64 UEFI USB GNOME" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=gnome" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome.conf

# cinnamon
echo "title   ${iso_label} x86_64 UEFI USB CINNAMON" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=cinnamon" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon.conf

# mate
echo "title   ${iso_label} x86_64 UEFI USB MATE" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=mate" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate.conf

# lxde
echo "title   ${iso_label} x86_64 UEFI USB LXDE" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=lxde" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde.conf

# lxqt
echo "title   ${iso_label} x86_64 UEFI USB LXQT" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=lxqt" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt.conf

# default toram
echo "title   ${iso_label} x86_64 UEFI USB DEFAULT TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-default-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-default-toram.conf

# gnome toram
echo "title   ${iso_label} x86_64 UEFI USB GNOME TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=gnome copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-gnome-toram.conf

# cinnamon toram
echo "title   ${iso_label} x86_64 UEFI USB CINNAMON TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=cinnamon copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-cinnamon-toram.conf

# mate toram
echo "title   ${iso_label} x86_64 UEFI USB MATE TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=mate copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-mate-toram.conf

# lxde toram
echo "title   ${iso_label} x86_64 UEFI USB LXDE TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=lxde copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxde-toram.conf

# lxqt toram
echo "title   ${iso_label} x86_64 UEFI USB LXQT TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} desktop=lxqt copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-lxqt-toram.conf

# EFI Shell 2.0 for UEFI 2.3+
if [ -f ${work_dir}/iso/EFI/shellx64_v2.efi ]
then
echo "Bereits Vorhanden!"
else
curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/master/ShellBinPkg/UefiShell/X64/Shell.efi
fi
# EFI Shell 1.0 for non UEFI 2.3+
if [ -f ${work_dir}/iso/EFI/shellx64_v1.efi ]
then
echo "Bereits Vorhanden!"
else
curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/master/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
fi

cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi ${work_dir}/iso/EFI/boot/

cp ${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

cp loader.conf ${work_dir}/iso/loader/loader.conf
cp uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v1-x86_64.conf
cp uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v2-x86_64.conf

echo "title   ${iso_label} x86_64 UEFI USB" > ${work_dir}/iso/loader/entries/archiso-x86_64.conf
echo "linux   /arch/boot/x86_64/vmlinuz" >> ${work_dir}/iso/loader/entries/archiso-x86_64.conf
echo "initrd  /arch/boot/intel_ucode.img" >> ${work_dir}/iso/loader/entries/archiso-x86_64.conf
echo "initrd  /arch/boot/x86_64/archiso.img" >> ${work_dir}/iso/loader/entries/archiso-x86_64.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label}" >> ${work_dir}/iso/loader/entries/archiso-x86_64.conf

echo "title   ${iso_label} x86_64 UEFI USB TORAM" > ${work_dir}/iso/loader/entries/archiso-x86_64-toram.conf
echo "linux   /arch/boot/x86_64/vmlinuz" >> ${work_dir}/iso/loader/entries/archiso-x86_64-toram.conf
echo "initrd  /arch/boot/intel_ucode.img" >> ${work_dir}/iso/loader/entries/archiso-x86_64-toram.conf
echo "initrd  /arch/boot/x86_64/archiso.img" >> ${work_dir}/iso/loader/entries/archiso-x86_64-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/loader/entries/archiso-x86_64-toram.conf

umount -d ${work_dir}/efiboot
fi

read -p "Soll das Image jetzt gemacht werden? [Y/n] " image
if [ "$image" != "n" ]
  then
mkdir -p ${out_dir}
xorriso -as mkisofs \
-iso-level 3 \
-full-iso9660-filenames \
-volid "${iso_label}" \
-eltorito-boot isolinux/isolinux.bin \
-eltorito\-catalog isolinux/boot.cat \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-isohybrid-mbr $(pwd)/${work_dir}/iso/isolinux/isohdpfx.bin \
-eltorito-alt-boot \
-e EFI/archiso/efiboot.img \
-no-emul-boot \
-isohybrid-gpt-basdat \
-output ${out_dir}/arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso ${work_dir}/iso/
fi
echo "Fertig!!!"

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
    ./pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs base base-devel syslinux efibootmgr efitools grub intel-ucode arch-install-scripts os-prober
fi

cd install
cp archiso ../${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/archiso
cd ..
cd hooks
cp archiso ../${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/archiso
cd ..

echo "HOOKS=\"base udev block filesystems keyboard archiso\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
echo "COMPRESSION=\"xz\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

echo ${iso_name} > ${work_dir}/${arch}/airootfs/etc/hostname

cp make_mksquashfs.sh ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs

cp pacman.conf ${work_dir}/${arch}/airootfs/etc/

cp arch-graphical-install ${work_dir}/${arch}/airootfs/usr/bin/
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-graphical-install

cp arch-install ${work_dir}/${arch}/airootfs/usr/bin/
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-install

cp arch-install-non_root ${work_dir}/${arch}/airootfs/usr/bin/
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-install-non_root

mkdir -p ${work_dir}/${arch}/airootfs/root/Schreibtisch/
cp arch-install.desktop ${work_dir}/${arch}/airootfs/root/Schreibtisch/
chmod +x ${work_dir}/${arch}/airootfs/root/Schreibtisch/arch-install.desktop

mkdir -p ${work_dir}/${arch}/airootfs/usr/share/applications/
cp arch-install.desktop ${work_dir}/${arch}/airootfs/usr/share/applications/ 
chmod +x ${work_dir}/${arch}/airootfs/usr/share/applications/arch-install.desktop

mkdir -p ${work_dir}/${arch}/airootfs/usr/share/pixmaps/
cp install.png ${work_dir}/${arch}/airootfs/usr/share/pixmaps/

cp mirrorlist ${work_dir}/${arch}/airootfs/etc/pacman.d/mirrorlist

read -p "Soll das System aktualisiert werden? [Y/n] " update
if [ "$update" != "n" ]
  then   
    ./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --init
    ./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --populate archlinux
    ./arch-chroot ${work_dir}/${arch}/airootfs pacman-key --refresh-keys

    ./arch-chroot ${work_dir}/${arch}/airootfs pacman -Syu

    ./arch-chroot ${work_dir}/${arch}/airootfs mkinitcpio -p linux
fi

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

read -p "Soll alle Bootoptionen verwendet werden? [Y/n] " bootoptionen

echo "DEFAULT menu.c32" > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "PROMPT 0" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU TITLE ${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "TIMEOUT 300" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

sed "s|%ISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g" syslinux.cfg >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

if [ "$bootoptionen" != "n" ]
  then
sed "s|%ISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g" syslinux_extra.cfg >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
fi

echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "ONTIMEOUT arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

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

mkdir -p ${work_dir}/efiboot

if [ -f ${work_dir}/iso/EFI/archiso/efiboot.img ]
then
rm ${work_dir}/iso/EFI/archiso/efiboot.img
else
echo "efiboot.img nicht vorhanden!"
fi
truncate -s 64M ${work_dir}/iso/EFI/archiso/efiboot.img
mkfs.fat -n ${iso_label}_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

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

cp uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
cp uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/
cp uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v1-x86_64.conf
cp uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v2-x86_64.conf

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

echo "timeout 3" > ${work_dir}/iso/loader/loader.conf
echo "default archiso-x86_64-usb-default" >> ${work_dir}/iso/loader/loader.conf
echo "timeout 3" > ${work_dir}/efiboot/loader/loader.conf
echo "default archiso-x86_64-cd-default" >> ${work_dir}/efiboot/loader/loader.conf

read -p "Soll alle Bootoptionen verwendet werden? [Y/n] " bootoptionen

if [ "$bootoptionen" != "n" ]
  then
         for _cfg in releng/archiso-x86_64-usb-*.conf; do
        sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/iso/loader/entries/${_cfg##*/}
    done

###

    for _cfg in releng/archiso-x86_64-cd-*.conf; do
        sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/efiboot/loader/entries/${_cfg##*/}
    done

    else

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-usb-default.conf > ${work_dir}/iso/loader/entries/archiso-x86_64-usb-default.conf

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-cd-default.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64-cd-default.conf

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-usb-default_nvidia.conf > ${work_dir}/iso/loader/entries/archiso-x86_64-usb-default_nvidia.conf

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-cd-default_nvidia.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64-cd-default_nvidia.conf

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-usb-default_toram.conf > ${work_dir}/iso/loader/entries/archiso-x86_64-usb-default_toram.conf

sed "s|%ISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" releng/archiso-x86_64-cd-default_toram.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64-cd-default_toram.conf

fi



read -p "efiboot jetzt trennen!"
umount -d ${work_dir}/efiboot
fi

read -p "Soll das Image jetzt gemacht werden? [Y/n] " image
if [ "$image" != "n" ]
  then
if [ -f ${out_dir}/arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso ]
then
rm ${out_dir}/arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso
fi
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

read -p "Soll das Image jetzt ausgeführt werden? [Y/n] " run
if [ "$run" != "n" ]
then
qemu-system-x86_64 -enable-kvm -cdrom out/arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso -boot d -m 8092
fi
read -p "Soll das Image jetzt geschrieben werden? [Y/n] " write
if [ "$write" != "n" ]
then
fdisk -l
read -p "Wo das Image jetzt geschrieben werden? [sda/sdb/sdc/sdd] " device
if [ "$device" != "n" ]
then
dd bs=4M if=out/arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso of=/dev/${device} status=progress && sync
fi
fi

fi
echo "Fertig!!!"

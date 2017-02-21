#!/bin/bash
#
set -ex
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

iso_name=simon_os
iso_label="SIMON_OS"
iso_version=$(date +%Y.%m.%d)
work_dir=work
out_dir=out
install_dir=arch

script_path=scripts

arch=$(uname -m)

read -p "Soll das System neu aufgebaut werden?: [Y/n] " system
if [ "$system" != "n" ]
  then
echo "Scripte werden heruntergeladen!"
pacman -Sy arch-install-scripts xorriso cdrtools squashfs-tools wget dosfstools
mkdir -p ${script_path}
mkdir -p ${work_dir}/${arch}/airootfs

pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs base base-devel syslinux efibootmgr efitools grub intel-ucode arch-install-scripts 

cd ${script_path}
mkdir -p install
cd install
wget -c https://raw.githubusercontent.com/simono41/archiso/master/archiso/initcpio/install/archiso
cp archiso ../../${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/archiso
cd ..
mkdir -p hooks
cd hooks
wget -c https://raw.githubusercontent.com/simono41/archiso/master/archiso/initcpio/hooks/archiso
cp archiso ../../${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/archiso
cd ..
cd ..

echo "HOOKS=\"base udev block filesystems keyboard archiso\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
echo "COMPRESSION=\"xz\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

echo ${iso_name} > ${work_dir}/${arch}/airootfs/etc/hostname

cp make_mksquashfs.sh ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
chmod +x ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
cd ${script_path}
if [ -f arch-graphical-install ]
then
rm arch-graphical-install
else
echo "arch-graphical-install nicht vorhanden!"
fi
if [ -f arch-install ]
then
rm arch-install
else
echo "arch-install nicht vorhanden!"
fi
wget -c https://raw.githubusercontent.com/simono41/Arch-Install-Script/master/arch-graphical-install
wget -c https://raw.githubusercontent.com/simono41/Arch-Install-Script/master/arch-install
wget -c https://raw.githubusercontent.com/simono41/Arch-Install-Script/master/pacman.conf
cp arch-graphical-install ../${work_dir}/${arch}/airootfs/usr/bin/
cp arch-install ../${work_dir}/${arch}/airootfs/usr/bin/
cp pacman.conf ../${work_dir}/${arch}/airootfs/etc/
chmod +x ../${work_dir}/${arch}/airootfs/usr/bin/arch-graphical-install
chmod +x ../${work_dir}/${arch}/airootfs/usr/bin/arch-install
cd ..

echo "Server = http://mirror.23media.de/archlinux/\$repo/os/\$arch" > ${work_dir}/${arch}/airootfs/etc/pacman.d/mirrorlist

arch-chroot ${work_dir}/${arch}/airootfs pacman-key --init
arch-chroot ${work_dir}/${arch}/airootfs pacman-key --populate archlinux
arch-chroot ${work_dir}/${arch}/airootfs pacman-key --refresh-keys

arch-chroot ${work_dir}/${arch}/airootfs pacman -Syu

arch-chroot ${work_dir}/${arch}/airootfs mkinitcpio -p linux

read -p "Welches Passwort soll der Root erhalten?: " pass
arch-chroot ${work_dir}/${arch}/airootfs /bin/bash <<EOT
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
    arch-chroot ${work_dir}/${arch}/airootfs /usr/bin/arch-graphical-install
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
arch-chroot ${work_dir}/${arch}/airootfs/ pacman -Q > ${work_dir}/${arch}/airootfs/pkglist.txt
cp ${work_dir}/${arch}/airootfs/pkglist.txt ${work_dir}/iso/${install_dir}/${arch}/
arch-chroot ${work_dir}/${arch}/airootfs pacman -Sc
arch-chroot ${work_dir}/${arch}/airootfs pacman -Scc
read -p "Sollen Nvidia-Treiber zwischengespeichert werden?: [Y/n] " nvidia
if [ "$nvidia" != "n" ]
  then
    echo "Nvidia-treiber werden zwischengespeichert!"
    arch-chroot ${work_dir}/${arch}/airootfs pacman -Sw nvidia nvidia-libgl nvidia-settings lib32-nvidia-libgl
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
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LABEL arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "MENU LABEL ${iso_label}-COPYTORAM" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "LINUX ../x86_64/vmlinuz" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "INITRD ../x86_64/archiso.img" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
echo "APPEND archisolabel=${iso_label} copytoram=y cow_spacesize=1024M" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
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

cd ${script_path}
wget -c https://raw.githubusercontent.com/simono41/archiso/master/configs/releng/efiboot/loader/entries/uefi-shell-v1-x86_64.conf
wget -c https://raw.githubusercontent.com/simono41/archiso/master/configs/releng/efiboot/loader/entries/uefi-shell-v2-x86_64.conf
wget -c https://raw.githubusercontent.com/simono41/archiso/master/configs/releng/efiboot/loader/loader.conf
cd ..
cp ${script_path}/loader.conf ${work_dir}/efiboot/loader/
cp ${script_path}/uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
cp ${script_path}/uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/

echo "title   ${iso_label} x86_64 UEFI USB" > ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label}" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf

echo "title   ${iso_label} x86_64 UEFI USB TORAM" > ${work_dir}/efiboot/loader/entries/archiso-x86_64-toram.conf
echo "linux   /EFI/archiso/vmlinuz.efi" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-toram.conf
echo "initrd  /EFI/archiso/intel_ucode.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-toram.conf
echo "initrd  /EFI/archiso/archiso.img" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-toram.conf
echo "options archisobasedir=${install_dir} archisolabel=${iso_label} copytoram=y cow_spacesize=1024M" >> ${work_dir}/efiboot/loader/entries/archiso-x86_64-toram.conf

# EFI Shell 2.0 for UEFI 2.3+
curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/master/ShellBinPkg/UefiShell/X64/Shell.efi
# EFI Shell 1.0 for non UEFI 2.3+
curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/master/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi ${work_dir}/iso/EFI/boot/

cp ${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

cp ${script_path}/loader.conf ${work_dir}/iso/loader/loader.conf
cp ${script_path}/uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v1-x86_64.conf
cp ${script_path}/uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/uefi-shell-v2-x86_64.conf

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

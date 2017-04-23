#!/bin/bash
#
set -ex
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

iso_name=simon-os
iso_label="SIMON_OS"
iso_version=$(date +%Y.%m.%d)
work_dir=work
out_dir=out
install_dir=arch

arch=$(uname -m)

read -p "Soll das System neu aufgebaut werden?: [Y/n] " system
if [ "$system" != "n" ]
then
  echo "Scripte werden heruntergeladen!"

  mkdir -p ${work_dir}/${arch}/airootfs

  read -p "Sollen die base Packete neu aufgebaut werden? [Y/n] " pacstrap
  if [ "$pacstrap" != "n" ]
  then
    pacman -Sy arch-install-scripts xorriso cdrtools squashfs-tools wget dosfstools btrfs-progs gdisk
    pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs base base-devel syslinux efibootmgr efitools grub intel-ucode os-prober btrfs-progs dosfstools arch-install-scripts wget gdisk squashfs-tools
    read -p "Sollen weitere Packete installiert werden? [Y/n] " pacstrap
    if [ "$pacstrap" != "n" ]
    then
      pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs base base-devel dosfstools arch-install-scripts btrfs-progs alsa-utils pulseaudio pulseaudio-alsa devtools xorriso cdrtools squashfs-tools wget libisoburn libisofs gdisk ntfs-3g android-tools xorg xorg-apps xorg-drivers xorg-fonts xorg-twm xorg-xclock xterm ttf-dejavu xorg-server xorg-utils xorg-server-utils xorg-xinit xorg-xdm xscreensaver cdrdao links x11vnc tigervnc htop git lm_sensors sudo openssl acpid ntp dbus avahi cronie net-tools procps zip gcc autoconf automake make libconfig obconf patch fakeroot pkg-config mplayer gparted pigz pixz simple-scan brasero qemu vlc libdvdread libdvdcss libdvdnav cups hplip python-pyqt5 python-pip python2-pip geckodriver macchanger transmission-gtk transmission-cli youtube-dl flac ffmpeg libreoffice-fresh libreoffice-fresh-de inkscape audacity gimp openssh firefox firefox-i18n-de firefox-adblock-plus flashplugin jdk8-openjdk wireshark-gtk hydra nmap pygtk aircrack-ng bless mumble teamspeak3 cmatrix file-roller atom obs-studio 0ad megaglest assaultcube teeworlds freeciv scratch minetest gnome-chess gnuchess hedgewars netbeans chromium steam wine
    fi
    read -p "Soll ein root passwort festgelegt werden? [Y/n] " root
    if [ "$root" != "n" ]
    then
      arch-chroot ${work_dir}/${arch}/airootfs passwd root
    fi
  fi

  arch-chroot ${work_dir}/${arch}/airootfs pacman-key --init
  arch-chroot ${work_dir}/${arch}/airootfs pacman-key --populate archlinux

  cp install/archiso ${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/archiso
  cp hooks/archiso ${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/archiso

  echo "HOOKS=\"base udev block filesystems keyboard archiso\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
  echo "COMPRESSION=\"gzip\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

  echo ${iso_name} > ${work_dir}/${arch}/airootfs/etc/hostname

  cp make_mksquashfs.sh ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs

  cp write_cowspace ${work_dir}/${arch}/airootfs/usr/bin/write_cowspace
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/write_cowspace

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

  arch-chroot ${work_dir}/${arch}/airootfs pacman -Syu

  arch-chroot ${work_dir}/${arch}/airootfs mkinitcpio -p linux

else
  echo "Wird nicht neu aufgebaut!!!"
  echo "Es muss aber vorhanden sein für ein reibenloser Ablauf!!!"
fi
echo "Jetzt können sie ihr Betriebssystem nach ihren Belieben anpassen:D"
read -p "Wollen sie ihr Betriebssystem nach Belieben anpassen? [Y/n] " packete
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

  if [ -f ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs ]
  then
    rm ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs
  else
    echo "airootfs.sfs nicht vorhanden!"
  fi

  mksquashfs ${work_dir}/${arch}/airootfs ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs -comp gzip

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

  sed "s|%ISO_LABEL%|${iso_label}|g;
  s|%INSTALL_DIR%|${install_dir}|g" syslinux.cfg >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

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
  truncate -s 128M ${work_dir}/iso/EFI/archiso/efiboot.img
  mkfs.fat -n ${iso_label}_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

  mount -t vfat -o loop ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

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

  for _cfg in releng/archiso-x86_64-usb-*.conf; do
    sed "s|%ISO_LABEL%|${iso_label}|g;
    s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/iso/loader/entries/${_cfg##*/}
  done

  ###

  for _cfg in releng/archiso-x86_64-cd-*.conf; do
    sed "s|%ISO_LABEL%|${iso_label}|g;
    s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/efiboot/loader/entries/${_cfg##*/}
  done

  read -p "efiboot jetzt trennen? [Y/n] "
  if [ "$trennen" != "n" ]
  then
    umount -d ${work_dir}/efiboot
  fi
fi

read -p "Soll das Image jetzt gemacht werden? [Y/n] " image
if [ "$image" != "n" ]
then

  imagename=arch-${iso_name}-$(date "+%y.%m.%d")-${arch}.iso

  read -p "Soll das Image jetzt gemacht werden? [Y/n] " run
  if [ "$run" != "n" ]
  then
    if [ -f ${out_dir}/${imagename} ]
    then
      rm ${out_dir}/${imagename}
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
    -output ${out_dir}/${imagename} ${work_dir}/iso/
  fi


  read -p "Soll das Image jetzt ausgeführt werden? [Y/n] " run
  if [ "$run" != "n" ]
  then
    qemu-system-x86_64 -enable-kvm -cdrom out/${imagename} -boot d -m 8092
  fi


  read -p "Soll das Image jetzt geschrieben werden? [Y/n] " write
  if [ "$write" != "n" ]
  then
    fdisk -l
    read -p "Wo das Image jetzt geschrieben werden? [sda/sdb/sdc/sdd] " device

    #
    if cat /proc/mounts | grep /dev/${device}1 > /dev/null; then
      echo "gemountet"
      umount /dev/${device}1
    else
      echo "nicht gemountet"
    fi
    #
    if cat /proc/mounts | grep /dev/${device}2 > /dev/null; then
      echo "gemountet"
      umount /dev/${device}2
    else
      echo "nicht gemountet"
    fi
    #
    if cat /proc/mounts | grep /dev/${device}3 > /dev/null; then
      echo "gemountet"
      umount /dev/${device}3
    else
      echo "nicht gemountet"
    fi
    #

    dd bs=4M if=out/${imagename} of=/dev/${device} status=progress && sync
  fi


  read -p "Soll das Image jetzt eine btrfs Partition zum Offline-Schreiben erhalten? [Y/n] " btrfs
  if [ "$btrfs" != "n" ]
  then
    if [ "$device" == "" ]
    then
      fdisk -l
      read -p "Wo das Image jetzt geschrieben werden? [sda/sdb/sdc/sdd] " device
    fi

fdisk -W always /dev/${device} <<EOT
p
n




p
w
y
EOT

    sleep 2

    mkfs.btrfs -L cow_device /dev/${device}3

  fi
fi
echo "Fertig!!!"

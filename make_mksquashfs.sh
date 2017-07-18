#!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

iso_name=spectre-os
iso_label="SPECTRE_OS"
iso_version=$(date +%Y.%m.%d)
work_dir=work
out_dir=out
install_dir=arch

arch=$(uname -m)

function minimalinstallation() {
  #Mehrzeiler
  while read line
  do
    ./pacstrap -c -d -G -M ${work_dir}/${arch}/airootfs $line
  done < packages.txt

}

function secureumount() {
  #statements
  #
  if cat /proc/mounts | grep ${device}1 > /dev/null; then
    echo "gemountet"
    umount ${device}1
  else
    echo "nicht gemountet"
  fi
  #
  if cat /proc/mounts | grep ${device}2 > /dev/null; then
    echo "gemountet"
    umount ${device}2
  else
    echo "nicht gemountet"
  fi
  #
  if cat /proc/mounts | grep ${$device}3 > /dev/null; then
    echo "gemountet"
    umount ${device}3
  else
    echo "nicht gemountet"
  fi
  #
}

read -p "Soll das System neu aufgebaut werden?: [Y/n] " system
if [ "$system" != "n" ]
then
  read -p "Sollen die Scipte installiert wernden? [Y/n] " scripte
  if [ "$scripte" != "n" ]
  then
    echo "Scripte werden heruntergeladen!"
    pacman -Sy arch-install-scripts xorriso cdrtools squashfs-tools wget dosfstools btrfs-progs gdisk qemu
  fi

  mkdir -p ${work_dir}/${arch}/airootfs

  read -p "Sollen die base Packete neu aufgebaut werden? [Y/n] " pacstrap
  if [ "$pacstrap" != "n" ]
  then
    minimalinstallation
    ## nur einmal bereich
    read -p "Soll ein root passwort festgelegt werden? [Y/n] " root
    if [ "$root" != "n" ]
    then
      arch-chroot ${work_dir}/${arch}/airootfs passwd root
    fi
  fi

  ## doppelt bereich
  read -p "Soll die aktuelle .config mitkoppiert werden?: [Y/n] " config
  if [ "$config" != "n" ]
  then
    read -p "Vom welchen Benutzer soll die .config koppiert werden?: " username
    cp -Rv /home/${username}/.config ${work_dir}/${arch}/airootfs/root/
  fi

  # screenfetch
  #  echo "screenfetch" >> ${work_dir}/${arch}/airootfs/etc/bash.bashrc

  # initalizise keys
  arch-chroot ${work_dir}/${arch}/airootfs pacman-key --init
  arch-chroot ${work_dir}/${arch}/airootfs pacman-key --populate archlinux

  # hooks
  cp install/archiso ${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/archiso
  cp hooks/archiso ${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/archiso

  # module and hooks
  echo "MODULES=\"i915 radeon\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
  echo "HOOKS=\"base udev block filesystems keyboard archiso\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
  echo "COMPRESSION=\"xz\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

  # iso_name
  echo ${iso_name} > ${work_dir}/${arch}/airootfs/etc/hostname

  # makeiso
  cp make_mksquashfs.sh ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/make_mksquashfs

  # write-partitions manager
  cp write_cowspace ${work_dir}/${arch}/airootfs/usr/bin/write_cowspace
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/write_cowspace

  # pacman-config
  cp pacman.conf ${work_dir}/${arch}/airootfs/etc/

  # custom-installer
  cp arch-graphical-install ${work_dir}/${arch}/airootfs/usr/bin/
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-graphical-install

  # installer-/usr/bin/
  cp arch-install ${work_dir}/${arch}/airootfs/usr/bin/
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-install
  cp packages.txt ${work_dir}/${arch}/airootfs/etc/

  # sudo-installer
  cp arch-install-non_root ${work_dir}/${arch}/airootfs/usr/bin/
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/arch-install-non_root

  # installer
  mkdir -p ${work_dir}/${arch}/airootfs/usr/share/applications/
  cp arch-install.desktop ${work_dir}/${arch}/airootfs/usr/share/applications/
  chmod +x ${work_dir}/${arch}/airootfs/usr/share/applications/arch-install.desktop

  # install-picture
  mkdir -p ${work_dir}/${arch}/airootfs/usr/share/pixmaps/
  cp install.png ${work_dir}/${arch}/airootfs/usr/share/pixmaps/

  # background
  mkdir -p ${work_dir}/${arch}/airootfs/usr/share/backgrounds/xfce/
  cp background.jpg ${work_dir}/${arch}/airootfs/usr/share/backgrounds/xfce/

  # mirrorlist
  cp mirrorlist ${work_dir}/${arch}/airootfs/etc/pacman.d/mirrorlist

  # bash.bashrc
  cp bash.bashrc ${work_dir}/${arch}/airootfs/etc/

  # startup
  cp startup ${work_dir}/${arch}/airootfs/usr/bin/
  chmod +x ${work_dir}/${arch}/airootfs/usr/bin/startup

  cp startup.service ${work_dir}/${arch}/airootfs/etc/systemd/system/

  arch-chroot ${work_dir}/${arch}/airootfs /bin/bash <<EOT

mkdir -p /etc/systemd/system/getty\@tty1.service.d
echo "[Service]" > /etc/systemd/system/getty\@tty1.service.d/autologin.conf
echo "ExecStart=" >> /etc/systemd/system/getty\@tty1.service.d/autologin.conf
echo "ExecStart=-/sbin/agetty --noclear -a root %I 38400 linux" >> /etc/systemd/system/getty\@tty1.service.d/autologin.conf
systemctl enable getty@tty1

systemctl daemon-reload
systemctl enable startup.service
systemctl start startup.service
pacman -Syu
mkinitcpio -p linux
EOT

  # packages
  cp packages* ${work_dir}/${arch}/airootfs/etc/

  # xfce4
  #  echo "exec startxfce4" > ${work_dir}/${arch}/airootfs/etc/X11/xinit/xinitrc

else
  echo "Wird nicht neu aufgebaut!!!"
  echo "Es muss aber vorhanden sein für ein reibenloser Ablauf!!!"
fi
echo "Jetzt können sie ihr Betriebssystem nach ihren Belieben anpassen:D"
read -p "Wollen sie ihr Betriebssystem nach Belieben anpassen? [Y/n] " packete
if [ "$packete" != "n" ]
then
  arch-chroot ${work_dir}/${arch}/airootfs /usr/bin/arch-graphical-install n
fi

# System-image

read -p "Soll das System-Image neu aufgebaut werden?: [Y/n] " image

if [ "$image" != "n" ]
then

  mkdir -p ${work_dir}/iso/${install_dir}/${arch}/airootfs/

  arch-chroot ${work_dir}/${arch}/airootfs /bin/bash <<EOT
  pacman -Scc
  y
  y
  pacman -Q > /pkglist.txt
EOT

  cp ${work_dir}/${arch}/airootfs/pkglist.txt ${work_dir}/iso/${install_dir}/${arch}/

  if [ -f ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs ]
  then
    rm ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs
  else
    echo "airootfs.sfs nicht vorhanden!"
  fi

  mksquashfs ${work_dir}/${arch}/airootfs ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs -comp xz -b 262144

  md5sum ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs > ${work_dir}/iso/${install_dir}/${arch}/airootfs.md5

else
  echo "Image wird nicht neu aufgebaut!!!"
fi

# BIOS

read -p "Soll das BIOS installiert werden?: [Y/n] " bios
if [ "$bios" != "n" ]
then

  mkdir -p ${work_dir}/iso/isolinux
  mkdir -p ${work_dir}/iso/${install_dir}/${arch}
  mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
  mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux

  cp -R ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/* ${work_dir}/iso/${install_dir}/boot/syslinux/
  cp ${work_dir}/${arch}/airootfs/boot/initramfs-linux.img ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
  cp ${work_dir}/${arch}/airootfs/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
  cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
  cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
  cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/

  echo "DEFAULT menu.c32" > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
  echo "PROMPT 0" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
  echo "MENU TITLE ${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
  echo "TIMEOUT 300" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
  echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

  sed "s|%ISO_LABEL%|${iso_label}|g;
  s|%arch%|${arch}|g;
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

  mkdir -p ${work_dir}/iso/EFI/archiso
  mkdir -p ${work_dir}/iso/EFI/boot
  mkdir -p ${work_dir}/iso/loader/entries

  if [ -f ${work_dir}/iso/EFI/archiso/efiboot.img ]
  then
    rm ${work_dir}/iso/EFI/archiso/efiboot.img
  else
    echo "efiboot.img nicht vorhanden!"
  fi

  truncate -s 128M ${work_dir}/iso/EFI/archiso/efiboot.img
  mkfs.fat -n ${iso_label}_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

  mkdir -p ${work_dir}/efiboot

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

  cp uefi-shell-v2-${arch}.conf ${work_dir}/efiboot/loader/entries/
  cp uefi-shell-v1-${arch}.conf ${work_dir}/efiboot/loader/entries/
  cp uefi-shell-v1-${arch}.conf ${work_dir}/iso/loader/entries/uefi-shell-v1-${arch}.conf
  cp uefi-shell-v2-${arch}.conf ${work_dir}/iso/loader/entries/uefi-shell-v2-${arch}.conf

  # EFI Shell 2.0 for UEFI 2.3+
  if [ -f ${work_dir}/iso/EFI/shellx64_v2.efi ]
  then
    echo "Bereits Vorhanden!"
    sleep 1
  else
    curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/master/ShellBinPkg/UefiShell/X64/Shell.efi
  fi
  # EFI Shell 1.0 for non UEFI 2.3+
  if [ -f ${work_dir}/iso/EFI/shellx64_v1.efi ]
  then
    echo "Bereits Vorhanden!"
    sleep 1
  else
    curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/master/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
  fi

  cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
  cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

  cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
  cp ${work_dir}/${arch}/airootfs/usr/share/efitools/efi/HashTool.efi ${work_dir}/iso/EFI/boot/

  cp ${work_dir}/${arch}/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

  echo "timeout 3" > ${work_dir}/iso/loader/loader.conf
  echo "default archiso-${arch}-usb-default" >> ${work_dir}/iso/loader/loader.conf
  echo "timeout 3" > ${work_dir}/efiboot/loader/loader.conf
  echo "default archiso-${arch}-cd-default" >> ${work_dir}/efiboot/loader/loader.conf

  for file in releng/archiso-x86_64-usb*
  do
    echo "$file"
    sed "s|%ISO_LABEL%|${iso_label}|g;
      s|%arch%|${arch}|g;
    s|%INSTALL_DIR%|${install_dir}|g" $file >> ${work_dir}/iso/loader/entries/${file##*/}
  done

  ###

  for file in releng/archiso-x86_64-cd*
  do
    echo "$file"
    sed "s|%ISO_LABEL%|${iso_label}|g;
      s|%arch%|${arch}|g;
    s|%INSTALL_DIR%|${install_dir}|g" $file >> ${work_dir}/efiboot/loader/entries/${file##*/}
  done

  ###

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
    if [ -f arch.img ]
    then
      echo "arch.img vorhanden!"
    else
      echo "arch.img nicht vorhanden!"
      qemu-img create -f qcow2 arch.img 64G
    fi
    qemu-system-${arch} -enable-kvm -cdrom out/${imagename} -hda arch.img -boot d -m 1028M
  fi


  read -p "Soll das Image jetzt geschrieben werden? [Y/n] " write
  if [ "$write" != "n" ]
  then
    fdisk -l
    read -p "Wo das Image jetzt geschrieben werden? [sda/sdb/sdc/sdd] " device

    secureumount

    dd bs=4M if=out/${imagename} of=${$device} status=progress && sync
  fi


  read -p "Soll das Image jetzt eine Partition zum Offline-Schreiben erhalten? [Y/n] " partition
  if [ "$partition" != "n" ]
  then
    if [ "$device" == "" ]
    then
      fdisk -l
      read -p "Wo das Image jetzt geschrieben werden? /dev/sda " device
    fi

    secureumount

fdisk -W always ${$device} <<EOT
p
n




p
w
y
EOT

    sleep 1

    echo "mit j bestätigen"
    mkfs.btrfs -L cow_device ${$device}3

    sync

  fi
fi
echo "Fertig!!!"

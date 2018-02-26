#!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0 $1 $2 $3 $4 $5
    exit 0
fi

iso_name=spectre_os
iso_label="SPECTRE_OS"
iso_version=$(date +%Y.%m.%d)
work_dir=work
out_dir=out
install_dir=arch
version="$1"
parameter1="$2"
parameter2="$3"
parameter3="$4"
parameter4="$5"

arch=$(uname -m)

[[ -z "${version}" ]] && version="voll"

if [ "${version}" == "libre" ]; then
    linuxparameter="-libre"
fi

function minimalinstallation() {
    cp pacman* /etc/
    cp mirrorlist* /etc/pacman.d/

    if [ "${version}" == "libre" ]; then
        ./pacstrap -C /etc/pacman.conf_libre -c -d -G -M ${work_dir}/${arch}/airootfs $(cat base.txt)
    else
        ./pacstrap -C /etc/pacman.conf -c -d -G -M ${work_dir}/${arch}/airootfs $(cat base.txt)
    fi
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
    if cat /proc/mounts | grep ${device}3 > /dev/null; then
        echo "gemountet"
        umount ${device}3
    else
        echo "nicht gemountet"
    fi
    #
}

function filesystem() {

    if [ "$system" != "n" ]
    then
        if [ "$scripte" != "n" ]
        then
            echo "Scripte werden heruntergeladen!"
            pacman -Sy arch-install-scripts xorriso squashfs-tools btrfs-progs dosfstools  --needed --noconfirm

        fi

        if [ "$pacstrap" != "n" ]
        then
            if [ "$pacstrap" != "debug" ]; then
                if [ "${parameter1}" != "skip" ]; then
                    if [ -d ${work_dir} ]; then
                        echo "delete work"
                        sleep 5
                        rm -Rv ${work_dir}
                    fi
                fi
                mkdir -p ${work_dir}/${arch}/airootfs
                minimalinstallation
            fi

        fi

        # module and hooks
        echo "MODULES=\"i915 radeon\"" > ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
        echo "HOOKS=\"base udev memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms block pcmcia filesystems keyboard\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
        echo "COMPRESSION=\"lz4\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf
        echo "FILES=\"/etc/modprobe.d/blacklist-floppy.conf\"" >> ${work_dir}/${arch}/airootfs/etc/mkinitcpio.conf

        # hooks
        cp -v install/archiso* ${work_dir}/${arch}/airootfs/usr/lib/initcpio/install/
        cp -v hooks/archiso* ${work_dir}/${arch}/airootfs/usr/lib/initcpio/hooks/

        cp -v script/archiso* ${work_dir}/${arch}/airootfs/usr/lib/initcpio/

    fi




}

function IMAGE() {

    if [ "$image" != "n" ]
    then

        mkdir -p ${work_dir}/iso/${install_dir}/${arch}/airootfs/

        arch-chroot ${work_dir}/${arch}/airootfs /bin/bash <<EOT
    pacman -Scc
j
j
    pacman -Q > /pkglist.txt
EOT

        cp ${work_dir}/${arch}/airootfs/pkglist.txt ${work_dir}/iso/${install_dir}/${arch}/

        if [ -f ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs ]
        then
            echo "${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs wird neu angelegt!!!"
            rm ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs
        else
            echo "airootfs.sfs nicht vorhanden!"
        fi

        mksquashfs ${work_dir}/${arch}/airootfs ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs -comp xz -b 262144

        sha512sum ${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs > airootfs.sha512
        sed s/"${work_dir}\/iso\/${install_dir}\/${arch}\/airootfs.sfs"/"\/run\/archiso\/bootmnt\/${install_dir}\/${arch}\/airootfs.sfs"/g airootfs.sha512 > ${work_dir}/iso/${install_dir}/${arch}/airootfs.sha512

    else
        echo "Image wird nicht neu aufgebaut!!!"
    fi




}

function BIOS() {

    if [ "$bios" != "n" ]
    then

        mkdir -p ${work_dir}/iso/isolinux
        mkdir -p ${work_dir}/iso/${install_dir}/${arch}
        mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux

        cp -R ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/* ${work_dir}/iso/${install_dir}/boot/syslinux/
        cp ${work_dir}/${arch}/airootfs/boot/initramfs-linux${linuxparameter}.img ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
        cp ${work_dir}/${arch}/airootfs/boot/vmlinuz-linux${linuxparameter} ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
        cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/${arch}/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/

        echo "DEFAULT menu.c32" > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        echo "PROMPT 0" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        echo "MENU TITLE ${iso_label}" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        echo "TIMEOUT 300" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

        if [ "$parameter4" != "all" ]
        then

            sed "s|%ISO_LABEL%|${iso_label}|g;
    s|%arch%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" syslinux-standart.cfg >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

        else

            sed "s|%ISO_LABEL%|${iso_label}|g;
    s|%arch%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" syslinux.cfg >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

        fi

        echo "" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        echo "ONTIMEOUT arch" >> ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg

        echo "DEFAULT loadconfig" > ${work_dir}/iso/isolinux/isolinux.cfg
        echo "" >> ${work_dir}/iso/isolinux/isolinux.cfg
        echo "LABEL loadconfig" >> ${work_dir}/iso/isolinux/isolinux.cfg
        echo "  CONFIG /arch/boot/syslinux/syslinux.cfg" >> ${work_dir}/iso/isolinux/isolinux.cfg
        echo "  APPEND /arch/boot/syslinux/" >> ${work_dir}/iso/isolinux/isolinux.cfg

    fi


}

function UEFI() {

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
        mkfs.vfat -n ${iso_label}_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

        mkdir -p ${work_dir}/efiboot

        mount -t vfat -o loop ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

        mkdir -p ${work_dir}/efiboot/EFI/boot
        mkdir -p ${work_dir}/efiboot/EFI/archiso
        mkdir -p ${work_dir}/efiboot/loader/entries

        cp ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
        cp ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img ${work_dir}/efiboot/EFI/archiso/archiso.img

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
        else
            cp Shell.efi ${work_dir}/iso/EFI/shellx64_v2.efi
            #curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/master/ShellBinPkg/UefiShell/X64/Shell.efi
        fi
        # EFI Shell 1.0 for non UEFI 2.3+
        if [ -f ${work_dir}/iso/EFI/shellx64_v1.efi ]
        then
            echo "Bereits Vorhanden!"
        else
            cp Shell_Full.efi ${work_dir}/iso/EFI/shellx64_v1.efi
            #curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/master/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
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
            s|%INSTALL_DIR%|${install_dir}|g" $file > ${work_dir}/iso/loader/entries/${file##*/}
        done

        ###

        for file in releng/archiso-x86_64-cd*
        do
            echo "$file"
            sed "s|%ISO_LABEL%|${iso_label}|g;
      s|%arch%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" $file > ${work_dir}/efiboot/loader/entries/${file##*/}
        done

        if [ "$parameter4" == "all" ]
        then

            for file in releng/all/archiso-x86_64-usb*
            do
                echo "$file"
                sed "s|%ISO_LABEL%|${iso_label}|g;
      s|%arch%|${arch}|g;
                s|%INSTALL_DIR%|${install_dir}|g" $file > ${work_dir}/iso/loader/entries/${file##*/}
            done

            ###

            for file in releng/all/archiso-x86_64-cd*
            do
                echo "$file"
                sed "s|%ISO_LABEL%|${iso_label}|g;
      s|%arch%|${arch}|g;
                s|%INSTALL_DIR%|${install_dir}|g" $file > ${work_dir}/efiboot/loader/entries/${file##*/}
            done

        fi

        ###

        if [ "$trennen" != "n" ]
        then
            umount -d ${work_dir}/efiboot
        fi

    fi

}

function makeiso() {

    if [ "$image" != "n" ]
    then

        imagename=arch-${iso_name}-${version}-${iso_version}-${arch}.iso

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

    fi



}

if [ "${parameter2}" != "skip" ]; then

    filesystem

    echo "Jetzt können sie ihr Betriebssystem nach ihren Belieben anpassen:D"
    cp arch-graphical-install-auto ${work_dir}/${arch}/airootfs/usr/bin/arch-graphical-install-auto
    ./arch-chroot ${work_dir}/${arch}/airootfs /usr/bin/arch-graphical-install-auto ${version}

fi

if [ "${parameter3}" != "skip" ]; then

    # System-image

    IMAGE

fi

# BIOS

BIOS

# EFI

UEFI

# MAKEISO

makeiso

# chroot

echo "Fertig!!!"
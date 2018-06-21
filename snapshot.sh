#!/bin/bash

set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0 $1 $2 $3 $4 $5 $6 $7 $8 $9
    exit 0
fi
echo "Als root Angemeldet"

if [ "make" == "$1" ]; then

    while (( "$(expr $# - 1)" ))
    do

        pfad="${2}"

        echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/${pfad}/SNAPSHOT
        echo "BACKUP" >> /run/btrfs-root/__current/${pfad}/SNAPSHOT


        #only root for the fstab
        if [ "${pfad}" == "ROOT" ]; then
          sed "s|__current/${pfad}|__snapshot/${pfad}@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`|g;" /etc/fstab.example > /etc/fstab
          rootsnapshot="y"
        fi

        mkdir -p /run/btrfs-root/__snapshot/${pfad%/*}
        btrfs subvolume snapshot /run/btrfs-root/__current/${pfad} /run/btrfs-root/__snapshot/${pfad}@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`
        #btrfs subvolume snapshot -r /run/btrfs-root/__current/${pfad} /run/btrfs-root/__snapshot/${pfad}@`head -n 1 /run/btrfs-root/__current/${pfad}/SNAPSHOT`

        if ! [ "${pfad}" == "ROOT" ]; then
          rm /run/btrfs-root/__current/${pfad}/SNAPSHOT
        fi

        shift

    done

    if [ "${rootsnapshot}" == "y" ]; then
        #reset-fstab
        cp /etc/fstab.example /etc/fstab
    fi

    #stable-snapshot-boot
    if [ -f "/boot/arch-uefi.conf.example" ] && [ "${rootsnapshot}" == "y" ]; then

        cp "$(echo $(find /boot/ -name "initramfs*.img") | cut -d" " -f2)" /boot/initramfs-linux-stable.img
        cp "$(echo $(find /boot/ -name "vmlinuz*") | cut -d" " -f1)" /boot/vmlinuz-stable

        kernel1="$(echo $(find /boot/ -name "initramfs*-stable.img") | cut -d" " -f2)"
        linuz1="$(find /boot/ -name "vmlinuz*-stable")"
        kernel="${kernel1#/*/}"
        linuz="${linuz1#/*/}"

sed "s|%LINUZ%|${linuz}|g;
s|%KERNEL%|${kernel}|g;
s|rootflags=subvol=__current/ROOT|rootflags=subvol=__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/ROOT/SNAPSHOT`|g" /boot/arch-uefi.conf.example > /boot/loader/entries/arch-uefi-stable.conf

        if [ -f /run/btrfs-root/__current/ROOT/SNAPSHOT ]; then
          rm /run/btrfs-root/__current/ROOT/SNAPSHOT
        fi


    fi

elif [ "restore" == "$1" ]; then

    while (( "$(expr $# - 1)" ))
    do

        pfad="${2}"

        if [ -d /run/btrfs-root/__current/${pfad/@*}.old ]; then
            btrfs subvolume delete /run/btrfs-root/__current/${pfad/@*}.old
        fi
        mv /run/btrfs-root/__current/${pfad/@*} /run/btrfs-root/__current/${pfad/@*}.old
        btrfs subvolume snapshot /run/btrfs-root/__snapshot/${pfad} /run/btrfs-root/__current/${pfad/@*}

        shift

    done


    btrfs subvolume list -p /

    #echo "Bitte noch die /etc/fstab editieren und die neuen IDs eintragen!!!"

    echo "Bitte damit die Änderungen wirksam werden das System neustarten!!!"

    #reboot

else

    echo "bash ./snapshot.sh PARAMETER PFAD"
    echo "Parameters: make restore"
    echo "make ROOT home opt var/cache/pacman/pkg"
    echo "restore ROOT@20170725-235544 home@20170725-235544 opt@20170725-235544 var/cache/pacman/pkg@20170725-235544"

    btrfs subvolume list -p /

fi

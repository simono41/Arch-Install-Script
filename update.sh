#!/bin/bash
#
# sudo update standart username userpass
#
set -ex

echo "Version : Fr 22. Dez 00:00:41 CET 2017"

WEBADDRESS="ssh://git@5.83.162.84:22/home/git/SpectreOS"
repo="SpectreOS"
user="user1"
hostname="$(cat /etc/hostname)"
version="${1}"
[[ -z "${version}" ]] && version="${hostname#*-}"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0 $1 $2 $3 $4 $5 $6 $7 $8 $9
    exit 0
fi
echo "Als root Angemeldet"

function gitclone() {
    if [ -d "/opt/${repo}" ]; then
        echo "${repo} existiert bereits!!!"
        cd /opt/${repo}
        git reset --hard
        git pull
    else
        git clone ${WEBADDRESS} /opt/${repo}
    fi
    cd /
}

if [ "${1}" != "n" ]
then
    read -p "Soll im Internet geguckt werden ob es neue Updates gibt?: [Y/n] " update
    if [ "${update}" == "debug" ]
    then
        echo "Überspringe das herunterladen einen neuen Scriptes!!!"
    else
        if [ "${update}" != "n" ]
        then
            if [ -f /usr/bin/git ]; then
                gitclone
            else
                echo "Git is not installet"
                pacman -S git --needed --noconfirm
            fi
            /opt/${repo}/arch-graphical-install-auto "${version}" "${2}" "${3}"
            read -p "Aktualisierung erfolgreich Abgeschlossen. Wollen sie den PC NEUSTARTEN?: [Y/n] " sicherheitsabfrage
            if [ "$sicherheitsabfrage" != "n" ]
            then
                echo "starte neu"
                reboot
            fi
            exit 0
        fi
    fi
fi

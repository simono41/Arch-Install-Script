#!/bin/bash
#
# sudo update standart username userpass
#
set -ex

echo "Version : Fr 22. Dez 00:00:41 CET 2017"

WEBADDRESS="http://137.74.140.105/simono41/SpectreOS.git"
repo="SpectreOS"
user="user1"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0
    exit 0
fi
echo "Als root Angemeldet"

function gitclone() {
    cd /root/
    if [ -d "${repo}" ]; then
        echo "${repo} existiert bereits!!!"
        cd ${repo}
        git pull
        cd ..
    else
        git clone ${WEBADDRESS}
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
            /root/${repo}/arch-graphical-install-auto "$1" "$2" "$3"
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

#!/bin/bash

set -x

url="$1"
url1=${url%.*}
url2=${url1#*//}
packagename=${url2#*/}

function aurinstaller() {
    if git clone ${url}; then
        echo "git erfolgreich runtergeladen!!!"
    else
        echo "verändere URL zum erfolgreichen herunterladen!!!"
        git clone "https://aur.archlinux.org/${url}.git"
    fi
    cd ${packagename}


}

cd
pwd
if [ -d ${packagename} ];then
    echo "Bereits vorhanden!!!"
    cd ${packagename}
    git reset --hard
    if ! git pull; then
        cd
        pwd
        rm -Rv ${packagename}
        aurinstaller
    fi
else
    aurinstaller
fi
makepkg -si --skipchecksums --skippgpcheck --nocheck --noconfirm --install --needed


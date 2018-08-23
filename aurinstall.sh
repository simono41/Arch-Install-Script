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
if makepkg -si --skipchecksums --skippgpcheck --nocheck --noconfirm --install --needed; then
  echo "Installation von ${packagename} erfolgreich beendet!!!"
else
  echo "Installation von ${packagename} fehlgeschlagen!!!"
  echo "DEBEUG-MODUS"
  echo "Bitte laden sie eine aktuelle PKBUILD herunter und tippen sie die URL hier ein!!!"
  echo "Wenn sie die PKBUILD manuell bearbeitet haben einfach mit enter bestätigen? "

  read -p "URL: " befehl
  if [ -n "${befehl}" ]; then
    curl -o PKGBUILD ${befehl}
  fi
  makepkg -si --skipchecksums --skippgpcheck --nocheck --noconfirm --install --needed

fi

echo "Fertig!!!"

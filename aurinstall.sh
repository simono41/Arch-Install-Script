#!/bin/bash

set -ex

url="$1"
url1=${url%.*}
url2=${url1#*//}
packagename=${url2#*/}

cd
pwd
if [ -d ${packagename} ];then
  echo "Bereits vorhanden!!!"
  cd ${packagename}
  git reset --hard
  git pull
else
  git clone ${url}
  cd ${packagename}
fi
makepkg -si --skipchecksums --skippgpcheck --nocheck --noconfirm --install --needed


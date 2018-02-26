#!/bin/bash

set -ex

repo="SpectreOS"
server="137.74.140.105"
user="simono41"
version="$1"
[[ -z "${version}" ]] && version="standart"

cd /root/
if [ -d "/root/${repo}/" ]; then
  echo "Existiert bereits!!!"
else
  git clone http://${server}/${user}/${repo}.git
fi
cd /root/${repo}/
git pull
if [ -d "out/" ]; then
  rm -Rv out/
fi
./make_mksquashfs-auto.sh ${version}
scp out/* ${server}:/var/www/html/

echo "Fertig!!!"

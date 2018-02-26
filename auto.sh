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
    rm -Rv ${repo}
fi
git clone http://${server}/${user}/${repo}.git
cd /root/${repo}/
./make_mksquashfs-auto.sh ${version}
scp out/* ${server}:/var/www/html/

echo "Fertig!!!"

#!/bin/bash

set -ex

server="$1"
[[ -z "${server}" ]] && echo "Bitte einen SSH-Server eintragen!!!" && exit 1

server=root@${server}

ssh-keygen -b 4096
cat ~/.ssh/id_rsa.pub
ssh-copy-id -i ~/.ssh/id_rsa.pub ${server}

echo "Fertig!!!"

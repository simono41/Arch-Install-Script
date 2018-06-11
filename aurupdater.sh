#!/bin/bash

set -x

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo "$0" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    exit 0
fi

username="user1"

echo "Durchsuche auf neue Packete indem fremde Packete angezeigt werden!!!"

# for-schleife
for wort in $(pacman -Qmq)
  do
    echo "$wort"
    su "$username" -c "/usr/bin/aurinstaller ${wort}"
done

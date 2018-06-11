#!/bin/bash

set -x

username="user1"

echo "Durchsuche auf neue Packete indem fremde Packete angezeigt werden!!!"

# for-schleife
for wort in $(pacman -Qmq)
  do
    echo "$wort"
    su "$username" -c "/usr/bin/aurinstaller ${wort}"
done

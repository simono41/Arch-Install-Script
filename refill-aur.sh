#!/bin/sh

set -ex

fill="$(pacman -Qqm)"

while (( "$(expr $#)" ))
do
    for wort in ${fill}
    do
        if grep ${wort} $1; then
            grep -v ${wort} $1 > tempdatei
            mv tempdatei $1
        else
            echo "überspringe ${wort}"
        fi
    done
    shift
done

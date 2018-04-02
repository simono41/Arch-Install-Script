#!/bin/bash

set -ex

wort=${1}
shift
ersetzen=${1}
shift

while (( "$(expr $#)" ))
do
  sed "s|${wort}|${ersetzen}|g;" $1 > tempdatei
  mv tempdatei $1
  shift
done

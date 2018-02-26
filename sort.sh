#!/bin/sh

set -ex

while (( "$(expr $#)" ))
do
    for i in $(cat $1) ; do echo $i ; done | sort | uniq > test
    cp test $1
    shift
done

#!/bin/sh

set -ex

fill=$1
shift

while (( "$(expr $#)" ))
do
    echo ${fill} >> $1
    for i in $(cat $1) ; do echo $i ; done | sort | uniq > test
    cp test $1
    shift
done

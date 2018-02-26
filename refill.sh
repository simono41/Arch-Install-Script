#!/bin/sh

set -ex

fill=$1
shift

while (( "$(expr $#)" ))
do
    grep -v ${fill} $1 > tempdatei
    mv tempdatei $1
    shift
done

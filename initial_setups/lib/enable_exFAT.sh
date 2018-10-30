#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


sudo apt -y install exfat-fuse exfat-utils


cd $INITIALDIR
exit 0
#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`

CONFFILE="/boot/grub/grub.cfg"
sudo ls -al $CONFFILE
sudo chmod 644 $CONFFILE

#sudo cat $CONFFILE | grep "if \[ \"\${recordfail}\" = 1 ] ; then"
sudo cat $CONFFILE | grep -P "^if\s\[\s\"\${recordfail}\""

sudo chmod 444 $CONFFILE
sudo ls -al $CONFFILE

#set dock size 24
#delete unuse appp icons
#blank screen off
#auto suspend off

cd $INITIALDIR
exit 0
#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`

SHARED_DIRS=`ls /media/ | grep sf_`
for shared_dir in ${SHARED_DIRS[@]}; do
	sed_dir=`echo $shared_dir | sed 's/sf_//'`
	[ -e ~/$sed_dir ] && echo "~/$sed_dir exist. mv to ~/$sed_dir.`date +%Y%m%d%H%M%S`" && mv ~/$sed_dir ~/$sed_dir.`date +%Y%m%d%H%M%S`
	ln -s /media/$shared_dir $HOME/$sed_dir
done

sudo gpasswd -a alladmin vboxsf

cd $INITIALDIR
exit 0
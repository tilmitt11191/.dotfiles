#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


CREATE_DIR="$HOME/lib/VBox_guest_additions_CD"
[ ! -d $CREATE_DIR ] && echo "####create_directory $CREATE_DIR" && mkdir -p $CREATE_DIR

VBOX_GUEST_ADDITIONS=`ls /media/$USER/ | grep VBox_`
sudo cp -r /media/$USER/$VBOX_GUEST_ADDITIONS $CREATE_DIR
cd $CREATE_DIR/$VBOX_GUEST_ADDITIONS
sudo bash VBoxLinuxAdditions.run

echo "install finished. after reboot, please execute create_shared_dirs_symbolic_link.sh"


cd $INITIALDIR
exit 0
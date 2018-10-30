#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


##todo if not exitst in repository~~
sudo add-apt-repository -y -n ppa:sicklylife/ppa #for japanese
sudo add-apt-repository -y -n ppa:graphics-drivers/ppa #for NVIDIA Drivers
sudo add-apt-repository -y -n ppa:sicklylife/mozc #for Mozc
sudo add-apt-repository -y -n ppa:libreoffice/ppa # for libreoffice
#sudo add-apt-repository -y -n ppa:relan/exfat #to support exFAT with gparted

sudo apt -y update && sudo apt -y dist-upgrade


cd $INITIALDIR
exit 0
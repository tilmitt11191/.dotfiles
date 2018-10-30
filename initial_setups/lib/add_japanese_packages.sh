#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


## for fix bug protruding character
sudo apt update -y && sudo apt dist-upgrade -y 2>&1 >/dev/null
echo "####sudo apt -y install gdebi"
sudo apt -y --fix-broken install
sudo apt -y install gdebi 'fonts-takao-*'

echo "####sudo gdebi change-topbar-colon-extend_8_all.deb"
wget -T 5 -t 3 --waitretry=5 https://sicklylife.jp/ubuntu/1804/change-topbar-colon-extend_8_all.deb -P $HOME/tmp/change-topbar-colon-extend_8_all.deb
if [ $? -ne 0 ];then
	echo "####wget https://sicklylife.jp/ubuntu/1804/change-topbar-colon-extend_8_all.deb. exit 1"
	exit 1
fi

MESSAGE=`sudo gdebi --n $HOME/tmp/change-topbar-colon-extend_8_all.deb/change-topbar-colon-extend_8_all.deb`
echo $MESSAGE | grep  -E "^i.+[ \t]+OKのようです" 2>&1 >/dev/null
echo "result"
if [ $? -ne 0 ];then
	echo "####gdebi change-topbar-colon-extend_8_all.deb failed. exit 1"
	exit 1
fi


WGET_GPG="ubuntu-ja-archive-keyring.gpg"
wget -T 5 -t 3 --waitretry=5 https://www.ubuntulinux.jp/$WGET_GPG -P $HOME/tmp/$WGET_GPG -O- | sudo apt-key add -
if [ $? -ne 0 ];then
	echo "####wget $WGET_GPG failed. exit 1"
	exit 1
fi

WGET_GPG="ubuntu-jp-ppa-keyring.gpg"
wget -T 5 -t 3 --waitretry=5 https://www.ubuntulinux.jp/$WGET_GPG -P $HOME/tmp/$WGET_GPG -O- | sudo apt-key add -
if [ $? -ne 0 ];then
	echo "####wget $WGET_GPG failed. exit 1"
	exit 1
fi

sudo wget https://www.ubuntulinux.jp/sources.list.d/bionic.list -O /etc/apt/sources.list.d/ubuntu-ja.list
if [ $? -ne 0 ];then
	echo "####wget https://www.ubuntulinux.jp/sources.list.d/bionic.list -O /etc/apt/sources.list.d/ubuntu-ja.list failed. exit 1"
	exit 1
fi

sudo apt -y update && sudo apt -y dist-upgrade
sudo apt -y install ubuntu-defaults-ja


cd $INITIALDIR
exit 0
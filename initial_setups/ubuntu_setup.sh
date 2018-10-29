#!/usr/bin/env bash

INITIALDIR=`sudo pwd`
cd `dirname $0`

[! -d $HOME/tmp ] && echo "create_directory $HOME/tmp"
mkdir -p $HOME/tmp
echo "create_directory $HOME/lib"
mkdir -p $HOME/lib

: <<'#__CO__'
echo -n "Swap caps for ctrl? [Y/n] default[Y]:"
read ANSWER

case $ANSWER in
	"N" | "n" | "no" | "No" | "NO" ) SWAP_KEY=false;;
	* ) SWAP_KEY=true;;
esac

$SWAP_KEY && bash lib/keyswap.sh && echo "success to swap caps for ctrl"


echo -n "enable hibernate? [Y/n] default[n]:"
read ANSWER

case $ANSWER in
	"Y" | "y" | "yes" | "Yes" | "YES" ) ENABLE_HIBERNATE=true;;
	* ) ENABLE_HIBERNATE=false;;
esac

#if "${ENABLE_HIBERNATE}" && "$(bash lib/enable_hibernate.sh)"; then
$ENABLE_HIBERNATE && bash lib/enable_hibernate.sh && echo "success to enable hibernate"
#__CO__



#LANG=C xdg-user-dirs-gtk-update
#sudo add-apt-repository -y -n ppa:sicklylife/ppa #for japanese
#sudo add-apt-repository -y -n ppa:graphics-drivers/ppa #for NVIDIA Drivers
#wget https://sicklylife.jp/ubuntu/1804/change-topbar-colon-extend_8_all.deb
#sudo apt update && sudo apt dist-upgrade
#kyeborad setting(全角半角)
#terminal size
#apt install
#oh-my-zsh
#chsh zsh

#ln dotfiles
#ln shared dir

#renv
#pyenv
#anaconda
#apt update


cd $INITIALDIR
true
#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`

PACKAGES=(git zsh)
for package in ${PACKAGES[@]}; do
	dpkg -l $package | grep -E "^i.+[ \t]+$package" > /dev/null
	if [ $? -ne 0 ];then
		m="$package not installed. sudo apt-get install -y $package."
		echo "$m"
		sudo apt install -y $package
	else
		m="$package already installed."
		echo "$m"
	fi
done

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
	ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

cd "${ZDOTDIR:-$HOME}"/.zprezto
git pull
git submodule update --init --recursive

FONTS_DIR=$HOME/.fonts/other_fonts/Powerline_fonts_for_prezto
[ -d $FONTS_DIR ] && cd $FONTS_DIR && echo "####install fonts" && bash install.sh


cd $INITIALDIR
exit 0
#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


dpkg -l $package | grep -E "^i.+[ \t]+$package" > /dev/null || sudo apt -y install git

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
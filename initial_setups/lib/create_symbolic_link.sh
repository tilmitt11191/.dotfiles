#!/usr/bin/env bash

echo "####`basename $0` start."
INITIALDIR=`sudo pwd`
cd `dirname $0`


DOTFILES=(vimrc vim tmux.conf fonts)
for file in ${DOTFILES[@]}; do
	[ $1 == "backup" ] && cp -r ~/.$file ~/."$file".`date +%Y%m%d%H%M%S`
	[ -e ~/.$file ] && rm -rf ~/.$file
	ln -s ~/.dotfiles/$file ~/.$file
done


cd $INITIALDIR
exit 0
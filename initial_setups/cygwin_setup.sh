#!/usr/bin/env bash

#git,which,wget,ca-certificates,gnupg,(openssl-perl)

#apt-cyg

: <<'#__CO__'
gcc-g++
make
w32api-headers
git

git clone https://github.com/juho-p/fatty.git
cd fatty
make
cp src/fatty.exe /bin
#__CO__

: <<'#__CO__'
mkdir ~/.ssh
(/home/tilmi/.ssh/id_rsa): /cygdrive/c/Users/tilmi/home/.ssh/id_rsa
#__CO__


: <<'#__CO__'
echo " After zsh console launched, put \"\"exit\"\" and press Enter"
read -p "install oh-my-zsh.press Enter(or [n/N]): " n
case "$n" in [nN]*) echo "abort." ; exit ;; *) ;; esac

sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh --no-check-certificate -O -)"

echo "after install oh-my-zsh"
rm ~/.zshrc*
ln -s ~/.dotfiles/zshrc ~/.zshrc
rm ~/.zcompdump*
#__CO__


#apt-cyg install vim --no-check-certificate
#apt-cyg install tmux --no-check-certificate
DOTFILES=(minttyrc vimrc tmux.conf)
read -p "overwrite ${DOTFILES[*]}. Press Enter(or [n/N]): " n
case "$n" in [nN]*) echo "abort." ; exit ;; *) ;; esac
for dotfile in ${DOTFILES[@]}; do
	dotfile_link="$HOME/.$dotfile"
	dotfile="$HOME/.dotfiles/$dotfile"
	echo "dotfile_link: $dotfile_link"
	if [ -e "$dotfile_link" ] || [ -L "$dotfile_link" ];then
		echo "rm $dotfile_link"
		rm $dotfile_link
	fi
	echo "ln -s $dotfile $dotfile_link"
	ln -s $dotfile $dotfile_link
done

#ls -al ~/

#ln ~/.dotfiles/minttyrc ~/.minttyrc
#ln ~/.dotfiles/dir_colors ~/.dir_colors

#ln ~/.dotfiles/vimrc ~/.vimrc

#ln ~/.dotfiles/tmux.conf ~/.tmux.conf

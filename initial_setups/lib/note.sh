
#cd ~/
#mkdir lib
#cp -r /media/alladmin/VBOXADDITIONS_5_1_18_114002 lib/
#cd lib/VBOXADDITIONS_5_1_18_114002/
#sudo bash VBoxLinuxAdditions.run
#sudo gpasswd -a alladmin vboxsf
#sudo reboot

PWD=`sudo pwd`
cd `dirname $0`

function log_info() { echo "$1";}

PACKAGES=(zsh vim git curl autossh tmux xclip default-jre default-jdk mysql-server)
for package in ${PACKAGES[@]}; do
	dpkg -l $package | grep -E "^i.+[ \t]+$package" > /dev/null
	if [ $? -ne 0 ];then
		m="$package not installed. sudo apt-get install -y $package."
		log_info "$m"
		sudo apt-get install -y $package
	else
		m="$package already installed."
		log_info "$m"
	fi
done



cd ~/
git clone https://github.com/tilmitt11191/.dotfiles
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


DOTFILES=(vimrc fonts vim zshrc)
for file in ${DOTFILES[@]}; do
	ln -s ~/.dotfiles/$file ~/.$file
done

LANG=C xdg-user-dirs-gtk-update

SHAREDIRS=(c f)
#SHAREDIRS=(c d f g h)
for dir in ${SHAREDIRS[@]}; do
	ln -s /media/sf_$dir ~/$dir
done

git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build


git clone https://github.com/yyuu/pyenv.git ~/.pyenv
pyenv install anaconda3-4.3.0
pyenv rehash
pyenv global anaconda3-4.3.0
conda update conda






sudo apt-get -y update && sudo apt-get -y dist-upgrade





cd $PWD
#chsh -s /bin/zsh
#rm ~/.zshrc
#ln -s ~/.dotfiles/zshrc ~/.zshrc
#source ~/.zshrc
exit 0



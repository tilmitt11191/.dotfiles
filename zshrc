
if [ $HOST = "macos.local" ];then
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="dieter"
#ZSH_THEME="cloud"
#ZSH_THEME="robbyrussell"
#ZSH_THEME="avit"
#ZSH_THEME="aussiegeek"
#ZSH_THEME="candy"

# Example aliases
alias ls~'ls -G'
alias ll='ls -lhG'
##export LSCOLORS=exfxcxdxbxegedabagacad
#export LSCOLORS=exfxcxdxbxegedabagacfx
export LSCOLORS=excxcxdxcxegedabagacgx
##export LSCOLORS=DxDxcxdxbxegedabagacad
alias mkdir='mkdir -p'
alias vi='vim'
alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"
PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
fi

#### config
if [ $HOST = "macos.local" ];then
export ZSH=~/.oh-my-zsh
plugins=(git brew)
source $ZSH/oh-my-zsh.sh
elif [ $HOST = "ubuntuMain" ];then
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
fi

#### COLOR
if [ $HOST = "macos.local" ];then
ZSH_THEME="gentoo"
export LSCOLORS=excxcxdxcxegedabagacgx
PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
elif [ $HOST = "ubuntuMain" ];then
ZSH_THEME="cloud"
#ZSH_THEME="dieter"
#ZSH_THEME="gentoo"
export LSCOLORS=exfxcxdxbxegedabagacad
#export LSCOLORS=excxcxdxcxegedabagacgx
PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
fi

#### PATH ####
if [ $HOST = "macos.local" ];then
	export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
	export PATH="$PATH:/Users/tilmitt/bin"
elif [ $HOST = "PC" ];then
	export PATH="/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0:/cygdrive/c/Program Files (x86)/EaseUS/Todo Backup/bin/x64:/cygdrive/f/Dropbox/pc/mba-win/home/bin"
	export PATH=$PATH:/cygdrive/f/Dropbox/pc/workingtower/home/bin
elif [ $HOST = "mba-win" ];then
	export PATH="/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0:/cygdrive/c/Program Files (x86)/EaseUS/Todo Backup/bin/x64:/cygdrive/f/Dropbox/pc/mba-win/home/bin"
	export PATH=$PATH:/cygdrive/f/Dropbox/pc/mba-win/home/bin
fi

#### alias #####
if [ $HOST = "macos.local" ];then
:
elif [ $HOST = "ubuntuMain" ];then
:
elif [ $HOST = "PC" -o $HOST = "mba-win" ];then
# Path to your oh-my-zsh installation.
#export ZSH=~/.oh-my-zsh
#ZSH_THEME="dieter"
#ZSH_THEME="xiong-chiamiov"
#source $ZSH/oh-my-zsh.sh
PS1="%1~ %(!.#.$) "
#PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '

alias ls='ls -FG --show-control-chars --color=auto'
alias ll='ls -lhF'
alias mkdir='mkdir -p'
alias vi='vim'

alias vim='/usr/bin/vim'
alias git='git.exe'
alias hidemaru='/cygdrive/c/Program\ Files\ \(x86\)/Hidemaru/Hidemaru.exe'
alias cygsetup='/cygdrive/f/bin/cygwin/setup-x86_64.exe'
export LANG=ja_JP.UTF-8

# cd した先のディレクトリをディレクトリスタックに追加する
# ディレクトリスタックとは今までに行ったディレクトリの履歴のこと
# `cd +<Tab>` でディレクトリの履歴が表示され、そこに移動できる
setopt auto_pushd
# <Tab> でパス名の補完候補を表示したあと、
# 続けて <Tab> を押すと候補からパス名を選択できるようになる
# 候補を選ぶには <Tab> か Ctrl-N,B,F,P
zstyle ':completion:*:default' menu select=1
fi

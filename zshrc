
#### config
if [ $HOST = "macos.local" ];then
export ZSH=~/.oh-my-zsh
plugins=(git brew)
source $ZSH/oh-my-zsh.sh
elif [ $HOST = "ubuntuMain" ];then
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
elif [ $HOST = "ubuntu128" ];then
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
fi

#### COLOR
if [ $HOST = "macos.local" ];then
	#ZSH_THEME="dieter"
	#ZSH_THEME="cloud"
	#ZSH_THEME="robbyrussell"
	#ZSH_THEME="avit"
	#ZSH_THEME="aussiegeek"
	#ZSH_THEME="candy"
	#ZSH_THEME="Solish"
	export LSCOLORS=excxcxdxcxegedabagacgx
	#export LSCOLORS=excxcxdxcxexexaxaxaxgx
	#export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
	export LS_COLORS='di=4;32;32:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
	autoload colors
	colors
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
	PROMPT='%{${fg[yellow]}%}$(git_prompt_info)%{${fg[green]}%}%1~ $%{${reset_color}%} '
elif [ $HOST = "ubuntuMain" ];then
	ZSH_THEME="cloud"
	#ZSH_THEME="dieter"
	#ZSH_THEME="gentoo"
	export LSCOLORS=exfxcxdxbxegedabagacad
	#export LSCOLORS=excxcxdxcxegedabagacgx
	PROMPT='%{${fg[white]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
elif [ $HOST = "ubuntu128" ];then
	ZSH_THEME="dieter"
	export LSCOLORS=exfxcxdxbxegedabagacad
	export LSCOLORS=exfxcxdxbxegedabagacad
	PROMPT='%{${fg[white]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
elif [ $HOST = "PC" -o $HOST = "mba-win" ];then
	PS1="%1~ %(!.#.$) "
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
elif [ $HOST = "ubuntu128" ];then
	export PATH="$PATH:$ZSH:/home/ffffe/bin"
fi

#### alias #####
if [ $HOST = "macos.local" ];then
	alias ls~'ls -G'
	alias ll='ls -lhG'
	alias mkdir='mkdir -p'
	alias vi='vim'
	#alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"
	alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"
elif [ $HOST = "ubuntuMain" ];then
	:
elif [ $HOST = "PC" -o $HOST = "mba-win" ];then
	#source $ZSH/oh-my-zsh.sh
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

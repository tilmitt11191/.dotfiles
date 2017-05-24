
echo "welcome to $HOST!!"

#### config
echo "this is config"
if [ $HOST = "macos.local" -o $HOST = "macos" ];then
	echo "this is config(mac $HOST)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	plugins=(git brew)
	HISTFILE=~/.zsh_history
	HISTSIZE=100000
	SAVEHIST=100000
	#setopt hist_ignore_dups     # ignore duplication command history list
	setopt share_history        # share command history data
elif [ $HOST = "PC" -o $HOST = "mba-win" -o $HOST = "ozu-PC" -o $HOST = "libra" ];then
	echo "this is config(PC or mba-win or o-PC or libra)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	HISTFILE=~/.zsh_history
	HISTSIZE=100000
	SAVEHIST=100000
	setopt share_history        # share command history data
elif [ $HOST = "ubuntuMain" ];then
	echo "this is config(ubuntuMain)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	HISTFILE=~/.zsh_history
	HISTSIZE=100000
	SAVEHIST=100000
elif [ $HOST = "ubuntuMain4" ];then
	echo "this is config(ubuntuMain4)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	HISTFILE=~/.zsh_history
	HISTSIZE=1000000
	SAVEHIST=1000000
elif [ $HOST = "Leo" -o $HOST = "Aries" -o $HOST = "Cancer" -o $HOST = "Gemini" ];then
	echo "this is config(Leo -o Aries -o Cancer -o Gemini)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	HISTFILE=~/.zsh_history
	HISTSIZE=1000000
	SAVEHIST=1000000
elif [ $HOST = "ubuntuVM" ];then
	echo "this is config(ubuntuVM)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	HISTFILE=~/.zsh_history
	HISTSIZE=100000
	SAVEHIST=100000
	setopt share_history # share command history data
elif [ $HOST = "www2271.sakura.ne.jp" ];then
	echo "this is config(sakura)"
	export ZSH=~/.oh-my-zsh
	source $ZSH/oh-my-zsh.sh
	export MAILCHECK=0
	HISTFILE=~/.zsh_history
	HISTSIZE=100000
	SAVEHIST=100000
	setopt share_history
else
	echo "this is config(else)"
fi

#### COLOR
echo "this is color"
if [ $HOST = "macos.local" -o $HOST = "macos" ];then
	echo "this is color(mac $HOST)"
	#ZSH_THEME="dieter"
	#ZSH_THEME="cloud"
	#ZSH_THEME="robbyrussell"
	#ZSH_THEME="avit"
	#ZSH_THEME="aussiegeek"
	#ZSH_THEME="candy"
	#ZSH_THEME="Solish"
	#export LSCOLORS=excxcxdxcxegedabagacgx
	export LSCOLORS=gxcxcxdxcxexexaxaxaxgx
	#export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
	export LS_COLORS='di=4;32;32:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
	#autoload colors
	#colors
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
	PROMPT='%{${fg[yellow]}%}$(git_prompt_info)%{${fg[green]}%}%1~ $%{${reset_color}%} '
elif [ $HOST = "ubuntuMain" ];then
	echo "this is color(ubuntuMain)"
	export LSCOLORS=exfxcxdxbxegedabagacad
	PS1="%1~ %(!.#.$) "
elif [ $(echo $HOST | grep -e "ubuntu") ];then
	echo "this is color(ubuntu***)"
	export LSCOLORS=exfxcxdxbxegedabagacad
	PS1="%1~ %(!.#.$) "
elif [ $HOST = "Leo" -o $HOST = "Aries" -o $HOST = "Cancer" -o $HOST = "Gemini" ];then
	echo "this is color(Leo -o Aries -o Cancer -o Gemini)"
	export LSCOLORS=exfxcxdxbxegedabagacad
	PS1="%1~ %(!.#.$) "
elif [ $HOST = "PC" -o $HOST = "mba-win" -o $HOST = "ozu-PC" -o $HOST = "libra" ];then
	echo "this is color(PC or mba-win or o-PC)"
	eval "`dircolors.exe ~/.dir_colors -b`"
	#source ~/.colorsets/mintty-colors-solarized/sol.dark
	#ZSH_THEME="dieter"
	#export LSCOLORS=exfxcxdxbxegedabagacad
	#export LSCOLORS=bxbxcxdxbxegedabagacad
	#export LSCOLORS=gxfxcxdxbxegedabagacad
	#PROMPT='%{${fg[yellow]}%}$(git_prompt_info)%1~ $%{${fg[yellow]}%}%{${reset_color}%} '
	PS1="%1~ %(!.#.$) "
elif [ $HOST = "www2271.sakura.ne.jp" ];then
	echo "this is color(sakura)"
	#export CLICOLOR=1
	#export LSCOLORS=excxcxdxcxegedabagacgx
	#export LSCOLORS=Exfxcxdxbxegedabagacad
	export LSCOLORS=CxGxcxdxCxegedabagacad
	#export LSCOLORS=exfxcxdxbxegedabagacad
	#PROMPT='%{${fg[white]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
	PS1="%1~ %(!.#.$) "
else
	echo "this is color(else)"
fi


#### PATH ####
echo "this is path"
if [ $HOST = "macos.local" -o $HOST = "macos" ];then
	echo "this is path(mac $HOST)"
	export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
	export PATH="$PATH:/Users/tilmitt/bin"

elif [ $HOST = "PC" ];then
	echo "this is path(PC or mba-win or o-PC)"
	export PATH="/cygdrive/c/Program\ Files/NVIDIA\ GPU\ Computing\ Toolkit/CUDA/v8.0/cuda/bin:/cygdrive/d/Anaconda3/envs/python35:/cygdrive/d/Anaconda3/envs/python35/Scripts:/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0:/cygdrive/c/Program Files (x86)/EaseUS/Todo Backup/bin/x64:/cygdrive/f/eclipse/java/8/bin:$PATH:"
	export PATH=$PATH:~/bin

elif [ $HOST = "mba-win" ];then
	export PATH=$PATH:$HOME/bin:$HOME/bin/cygwin/bin:/cygdrive/f/Dropbox/pc/mba-win/home/bin

elif [ $HOST = "ozu-PC" ];then
	export PATH="$PATH:~/bin"

elif [ $HOST = "libra" ];then
	export PATH="/cygdrive/c/Program\ Files/NVIDIA\ GPU\ Computing\ Toolkit/CUDA/v8.0/cuda/bin:/cygdrive/c/Users/ozu/AppData/Local/conda/conda/envs/paper_graph:/cygdrive/c/Users/ozu/AppData/Local/conda/conda/envs/paper_graph/Scripts:/home/ozu/bin:/usr/local/bin:/usr/bin:/usr/sbin:$PATH"
	export PATH="/cygdrive/c/Program\ Files/Docker\ Toolbox":$PATH
	
	export DOCKER_HOST=tcp://192.168.99.100:2376
	export DOCKER_MACHINE_NAME=default
	export DOCKER_TLS_VERIFY=1
	#export DOCKER_CERT_PATH=/cygdrive/c/Users/ozu/.docker/machine/machines/default
	export DOCKER_CERT_PATH=C:\\Users\\ozu\\.docker\\machine\\machines\\default
	export TERM=xterm

elif [ $HOST = "ubuntu128" ];then
	export PATH="$PATH:$ZSH:/home/ffffe/bin"

elif [ $HOST = "ubuntuMain4" ];then
	echo "this is path(ubuntuMain4)"
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/versions/anaconda3-4.3.0/envs/paper_graph/bin:$PYENV_ROOT/versions/anaconda3-4.3.0/bin/:$PYENV_ROOT/bin:$PATH"
	export PATH="$HOME/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
	eval "$(rbenv init -)"

elif [ $HOST = "ubuntuVM" ];then
	echo "this is path(ubuntuVM)"
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$HOME/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
	#export PATH="$PYENV_ROOT/versions/anaconda3-4.3.0/envs/paper_graph/bin:$PYENV_ROOT/versions/anaconda3-4.3.0/bin/:$PYENV_ROOT/bin:$PATH"
	export PATH="$PYENV_ROOT/versions/anaconda3-4.3.0/envs/tfos/bin:$PYENV_ROOT/versions/anaconda3-4.3.0/bin/:$PYENV_ROOT/bin:$PATH"
		eval "$(rbenv init -)"

	export SPARK_HOME=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/spark-1.6.0-bin-hadoop2.6
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
	export TFoS_HOME=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark
	export PYTHONPATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/src
	export PYTHONPATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/spark-1.6.0-bin-hadoop2.6/python/:$PYTHONPATH
	export PATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/src:${PATH}
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
	export LOG_DIRS=$HOME/program/test/tensorFlow_test/var/log/
	export HADOOP_HOME=/usr/local/lib/hadoop/hadoop
	export PATH=$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH
	export HADOOP_CONF_DIR=/usr/local/lib/hadoop/hadoop/etc/hadoop
	export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
	export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
	export SPARK_YARN_STAGING_DIR=$SPARK_HOME/log

elif [ $(echo $HOST | grep -e "ubuntu") ];then
	echo "this is path(ubuntu***)"
	export PATH="$PATH:$HOME/bin:$HOME/.rbenv/bin:$HOME/.local/bin"
	#export CLASSPATH=$CLASSPATH:~/c/Program\ Files/Weka-3-8/weka.jar          
	eval "$(rbenv init -)"
	##http://www.virment.com/setup-rails-ubuntu/

elif [ $HOST = "Leo" -o $HOST = "Aries" -o $HOST = "Cancer" -o $HOST = "Gemini" ];then
	echo "this is path(Leo -o Aries -o Cancer -o Gemini)"
	export PYENV_ROOT="$HOME/.pyenv"
	#export PATH="$PYENV_ROOT/versions/anaconda3-4.3.0/envs/paper_graph/bin:$PYENV_ROOT/versions/anaconda3-4.3.0/bin/:$PYENV_ROOT/bin:$PATH"
	export PATH="$PYENV_ROOT/versions/anaconda3-4.3.0/envs/tfos/bin:$PYENV_ROOT/versions/anaconda3-4.3.0/bin/:$PYENV_ROOT/bin:$PATH"
	export PATH="$HOME/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
	eval "$(rbenv init -)"

	export SPARK_HOME=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/spark-1.6.0-bin-hadoop2.6
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
	export TFoS_HOME=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark
	export PYTHONPATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/src
	export PYTHONPATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/spark-1.6.0-bin-hadoop2.6/python/:$PYTHONPATH
	export PATH=/usr/local/lib/tensorflowonspark/TensorFlowOnSpark/src:${PATH}
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
	export LOG_DIRS=$HOME/program/test/tensorFlow_test/var/log/
	export HADOOP_HOME=/usr/local/lib/hadoop/hadoop
	export PATH=$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH
	export HADOOP_CONF_DIR=/usr/local/lib/hadoop/hadoop/etc/hadoop
	export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
	export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
	export SPARK_YARN_STAGING_DIR=$SPARK_HOME/log


	
elif [ $HOST = "www2271.sakura.ne.jp" ];then
	echo "this is path(sakura)"
	export PATH="$PATH:$HOME/bin"
	#export PATH="$PATH:$HOME/bin:$HOME/.rbenv/bin"
	#export TMPDIR=$HOME/tmp
	#export MAKE=gmake
	#eval "$(rbenv init -)"
	export GEM_HOME=$HOME/local/rubygems/gems
	#export RUBYLIB=$HOME/local/rubygems/lib
	#export RB_USER_INSTALL=true
	#export PATH=$PATH:$HOME/local/rubygems/gems/bin
#elif [ $(echo $HOST | grep -e "ubuntu") ];then
#	echo "this is path(ubuntu)"
#	export PATH=$PATH:~/bin:

else
	echo "this is path(else)"
fi

#### alias #####
echo "this is alias"
if [ $HOST = "macos.local" -o $HOST = "macos" ];then
	echo "this is alias(mac $HOST)"
	alias ls~'ls -G'
	alias ll='ls -lhG'
	alias mkdir='mkdir -p'
	alias vi='vim'
	#alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"
	alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"
	alias st="open $1 -a /Applications/Sublime\ Text.app/Contents/MacOS/Sublime\ Text"

elif [ $(echo $HOST | grep -e "ubuntu") ];then
	echo "this is alias(ubuntu***)"
	alias ls='ls -FG --show-control-chars --color=auto'
	alias ll='ls -lhF'
	alias mkdir='mkdir -p'
	alias vi='vim'
elif [ $HOST = "Leo" -o $HOST = "Aries" -o $HOST = "Cancer" -o $HOST = "Gemini" ];then
	echo "this is alias(Leo -o Aries -o Cancer -o Gemini)"
	alias ls='ls -FG --show-control-chars --color=auto'
	alias ll='ls -lhF'
	alias mkdir='mkdir -p'
	alias vi='vim'
elif [ $HOST = "PC" -o $HOST = "mba-win" -o $HOST = "ozu-PC" -o $HOST = "libra" ];then
	echo "this is alias(PC or mba-win or o-PC)"
	#alias ls='ls -FG --show-control-chars --color=auto'
	alias ls='ls -G --show-control-chars --color=always'
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
elif [ $HOST = "www2271.sakura.ne.jp" ];then
	echo "this is alias(sakura)"
	#alias ls='ls -FG --show-control-chars --color=auto'
	alias ll='ls -lhF'
	alias mkdir='mkdir -p'
	alias vi='vim'
else
	echo "this is alias(else)"
fi

##etc
if [ $HOST = "www2271.sakura.ne.jp" ];then
	echo "for node.js at sakura"

	#export PATH=$PATH:$HOME/local/ports/bin
	#export NODE_PATH=$HOME/local/ports/bin/node
	#export NODE_MODULES=$HOME/local/lib/node_modules
	#export LD_LIBRARY_PATH
	#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/local/lib

	#export INSTALL_AS_USER=yes
	#export PREFIX=$HOME/local/ports
	#export LOCALBASE=$HOME/local/ports
	#export PKG_DBDIR=$LOCALBASE/var/db/pkg
	#export PKG_TMPDIR=$LOCALBASE/tmp/
	#export PORT_DBDIR=$LOCALBASE/var/db/pkg
	#export DISTDIR=$LOCALBASE/tmp/dist
	#export WRKDIRPREFIX=$LOCALBASE/tmp/work
	#export PORTSDIR=$HOME/local/work/ports
	#export PKGTOOLS_CONF=$LOCALBASE/etc/pkgtools.conf
	#export DEPENDS_TARGET='install clean'
	
	#export X11BASE=$LOCALBASE
	
	#export PKG_CONFIG_PATH="$HOME/local/ports/lib/pkgconfig:$HOME/local/ports/libdata/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/libdata/pkgconfig:/usr/libdata/pkgconfig"
	
# Set user and group variables to ourself
	#export BINOWN=`whoami`
	#export BINGRP=`id -G -n $BINOWN`
	#export SHAREOWN=$BINOWN
	#export SHAREGRP=$BINGRP
	#export MANOWN=$BINOWN
	#export MANGRP=$BINGRP
	
	# Make sure files are installed with correct default permissions
	#export BINMODE=744
	#export SHAREMODE=644
	#export MANMODE=644
	
	# Make sure we don't really try to become root, but just execute everything as ourselves
	#export SU_CMD="sh -c"

	# Make sure the systemdefault make.conf is not read
	#export __MAKE_CONF=$LOCALBASE/etc/make.conf

	# Keep our own version of ldconfig hints
	#export LDCONFIG="/sbin/ldconfig -i -f $LOCALBASE/var/run/ld-elf.so.hints"
	#export LDCONFIG="/sbin/ldconfig -f=$LOCALBASE/var/run/ld-elf.so.hints -i -R=$LOCALBASE/etc/ld-elf.so.conf "
	#export LD_LIBRARY_PATH=$LOCALBASE/lib
	#export LD_RUN_PATH=$LOCALBASE/lib

	#export PATH=$LOCALBASE/bin:$LOCALBASE/sbin:$PATH
	#export MANPATH_MAP=$LOCALBASE/bin:$LOCALBASE/man

	# Set application specific variables to make sure it doesn't pick up things from the main system
	#export APXS=$LOCALBASE/sbin/apxs
	#export PERL=$LOCALBASE/bin/perl
	#export PERL5=$PERL
	#export SITE_PERL=$LOCALBASE/lib/perl5/site_perl/5.18.4
	#export SITE_PERL5=$SITE_PERL
	#export PERL_VERSION=5.18.4
	#export PERL_VER=$PERL_VERSION
	
	#export SRCCONF=~/local/ports/etc/src.conf
fi

#PATH="/home/tilmi_000/perl5/bin${PATH:+:${PATH}}"; export PATH;
#PERL5LIB="/home/tilmi_000/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
#PERL_LOCAL_LIB_ROOT="/home/tilmi_000/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
#PERL_MB_OPT="--install_base \"/home/tilmi_000/perl5\""; export PERL_MB_OPT;
#PERL_MM_OPT="INSTALL_BASE=/home/tilmi_000/perl5"; export PERL_MM_OPT;

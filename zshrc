

if [ `hostname` = "macos.local" ];then
# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="dieter"
#ZSH_THEME="cloud"
#ZSH_THEME="robbyrussell"
#ZSH_THEME="gentoo"
#ZSH_THEME="avit"
#ZSH_THEME="aussiegeek"
#ZSH_THEME="candy"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew)

# User configuration

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export PATH="$PATH:/Users/tilmitt/bin"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias ls~'ls -G'
alias ll='ls -lhG'
export LSCOLORS=exfxcxdxbxegedabagacad
#export LSCOLORS=DxDxcxdxbxegedabagacad
#export LSCOLORS="no=00:fi=00:di=01;36:ln=01;34"
alias mkdir='mkdir -p'
alias vi='vim'

alias mi="open $1 -a /Applications/mi.app/Contents/MacOS/mi"

PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '
fi

if [ `hostname` = "PC" -o `hostname` = "mba-win" ];then
# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

ZSH_THEME="dieter"
#ZSH_THEME="xiong-chiamiov"

# User configuration
export PATH="/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0:/cygdrive/c/Program Files (x86)/EaseUS/Todo Backup/bin/x64:/cygdrive/f/Dropbox/pc/mba-win/home/bin"
# export MANPATH="/usr/local/man:$MANPATH"
export PATH=$PATH:/cygdrive/f/Dropbox/pc/`hostname`/home/bin

source $ZSH/oh-my-zsh.sh


alias ls='ls -FG --show-control-chars --color=auto'
alias ll='ls -lhF'
alias mkdir='mkdir -p'
alias vi='vim'

alias vim='/usr/bin/vim'
alias git='git.exe'
alias hidemaru='/cygdrive/c/Program\ Files\ \(x86\)/Hidemaru/Hidemaru.exe'
alias cygsetup='/cygdrive/f/bin/cygwin/setup-x86_64.exe'
export LANG=ja_JP.UTF-8

#PS1="%1~ %(!.#.$) "
PROMPT='%{${fg[green]}%}$(git_prompt_info)%1~ $%{${reset_color}%} '

# cd した先のディレクトリをディレクトリスタックに追加する
# ディレクトリスタックとは今までに行ったディレクトリの履歴のこと
# `cd +<Tab>` でディレクトリの履歴が表示され、そこに移動できる
setopt auto_pushd
# <Tab> でパス名の補完候補を表示したあと、
# 続けて <Tab> を押すと候補からパス名を選択できるようになる
# 候補を選ぶには <Tab> か Ctrl-N,B,F,P
zstyle ':completion:*:default' menu select=1
fi

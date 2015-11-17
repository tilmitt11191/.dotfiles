"echo hostname()

""general
set tabstop=2
set autoindent
set backspace=indent,eol,start
set title
set showmatch


""special key
if hostname() == "PC" || hostname() == "mba-win"
"	set list
"	set listchars=tab:>-,trail:-,extends:>,precedes:<,nbsp:%
endif


""color
syntax enable
if hostname() == "ubuntu128"
	colorscheme twilight
	highlight Normal ctermbg=none
elseif hostname() == "macos.local"
	"colorscheme molokai
	"colorscheme base16-railscasts
	"colorscheme railscasts
	"colorscheme elflord
	"colorscheme jellybeans
	colorscheme twilight
	highlight Normal ctermbg=none
elseif hostname() == "PC"
	colorscheme base16-railscasts
	"colorscheme molokai
elseif hostname() == "mba-win"
	colorscheme molokai
endif	
	"colorscheme hybrid
	":colorscheme molokai
	"let g:molokai_original = 1
	"let g:rehash256 = 1
	"colorscheme twilight
	"colorscheme molokai
	"let g:molokai_original = 1
	"let g:rehash256 = 1
	"colorscheme elflord
	"colorscheme base16-railscasts
	":colorscheme badwolf
	"hi Normal ctermgb=none
	"colorscheme inkpot
	":colorscheme lucius
	":colorscheme railscasts
	":colorscheme jellybeans


""corsor
set number
if hostname() == "ubuntu128"
	hi Normal ctermfg=252 ctermbg=none
	hi LineNr ctermbg=none ctermfg=darkcyan
	hi clear CursorLine
	hi CursorLineNr ctermbg=4 ctermfg=0
	hi clear CursorLine
	set cursorline
	let &t_EI = "\<Esc>]50;CursorShape=0\x7"
	let &t_SI = "\<Esc>]50;CursorShape=1\x7"
elseif hostname() == "macos.local"
	set cursorline
	hi LineNr ctermbg=none ctermfg=blue
	hi CursorLine cterm=underline ctermfg=none ctermbg=none
	hi CursorLineNr ctermbg=4 ctermfg=0
	"hi clear CursorLine
	let &t_SI = "\<Esc>]50;CursorShape=1\x7"
	let &t_EI = "\<Esc>]50;CursorShape=0\x7"

elseif hostname() == "PC" || hostname() == "mba-win"
	hi LineNr ctermbg=0 ctermfg=blue
	hi CursorLineNr ctermbg=4 ctermfg=8
	set cursorline
	"hi clear CursorLine
endif

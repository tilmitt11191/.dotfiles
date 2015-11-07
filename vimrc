
set tabstop=2
set autoindent
set backspace=indent,eol,start
set title

syntax enable
if hostname() == "ubuntu128"
	colorscheme twilight
elseif hostname() == "macos.local"
	colorscheme default
elseif hostname() == "PC"
	"colorscheme base16-railscasts
	colorscheme molokai
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


""corsorline
set number
if hostname() == "ubuntu128"
	hi Normal ctermfg=252 ctermbg=none
	hi LineNr ctermbg=none ctermfg=darkcyan
	hi CursorLineNr ctermbg=4 ctermfg=0
	"hi LineNr ctermbg=none ctermfg=67
	set cursorline
	hi clear CursorLine
	"hi CursorLineNr term=bold cterm=none ctermbg=none ctermfg=none
elseif hostname() == "macos.local"
	hi LineNr ctermbg=none ctermfg=darkcyan
	hi CursorLineNr ctermbg=4 ctermfg=0
	set cursorline
	hi clear CursorLine
elseif hostname() == "PC" || hostname() == "mba-win"
	hi LineNr ctermbg=0 ctermfg=blue
	hi CursorLineNr ctermbg=4 ctermfg=8
	set cursorline
	"hi clear CursorLine
endif


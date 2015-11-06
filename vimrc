
set tabstop=2
set autoindent

syntax enable
if hostname() == "ubuntu128"
	colorscheme twilight
elseif hostname() == "macos"
	:colorscheme default
endif	
	"colorscheme hybrid
	":colorscheme molokai
	let g:molokai_original = 1
	let g:rehash256 = 1
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
elseif hostname() == "macos"
	hi LineNr ctermbg=none ctermfg=darkcyan
	hi CursorLineNr ctermbg=4 ctermfg=0
	set cursorline
	hi clear CursorLine
endif


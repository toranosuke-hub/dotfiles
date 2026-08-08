" ====================================================================
" Neovim configuration
" Based on the existing ~/.vimrc, adapted for Neovim only.
" ====================================================================

" --------------------------------------------------------------------
" 1. Plugin management (vim-plug)
" --------------------------------------------------------------------

" Keep Neovim plugins separate from Vim plugins.
let s:plug_vim = stdpath('data') . '/site/autoload/plug.vim'
let s:plug_dir = stdpath('data') . '/plugged'

" Install vim-plug automatically when it is missing.
if empty(glob(s:plug_vim))
  silent execute '!curl -fLo ' . shellescape(s:plug_vim) .
        \ ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(s:plug_dir)

" Color scheme
Plug 'nordtheme/vim'

" Editing support
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'gosukiwi/vim-smartpairs'
Plug 'dominikduda/vim_current_word'
Plug 'ntpeters/vim-better-whitespace'
Plug 'ConradIrwin/vim-bracketed-paste'

" denops-based translation
"Plug 'vim-denops/denops.vim'
"Plug 'skanehira/denops-translate.vim'

" UI / navigation
Plug 'luochen1990/rainbow'
Plug 'liuchengxu/vim-which-key'
Plug 'psliwka/vim-smoothie'
Plug 'simeji/winresizer'
Plug 'preservim/nerdtree'

" Markdown
Plug 'preservim/vim-markdown'
Plug 'bullets-vim/bullets.vim'
Plug 'mattn/vim-maketable'
Plug 'i9wa4/vim-markdown-number-header'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }

call plug#end()


" --------------------------------------------------------------------
" 2. Basic settings
" --------------------------------------------------------------------

" Mouse support.  Neovim does not use the old 'ttymouse' option.
set mouse=a

" Encoding
set encoding=utf-8
set fileencoding=utf-8

" Files / buffers
set nobackup
set noswapfile
set autoread
set hidden
set showcmd

" Appearance
set number
set virtualedit=onemore
set smartindent
set visualbell
set showmatch
set laststatus=2
set wildmode=list:longest
set signcolumn=no

" Move by screen lines when text is wrapped.
nnoremap j gj
nnoremap k gk

syntax enable
filetype plugin indent on

" Tabs / indentation
set list
set listchars=tab:\▸\-
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Search
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" Clipboard
set clipboard=unnamedplus


" --------------------------------------------------------------------
" 3. Color scheme / highlights
" --------------------------------------------------------------------

silent! colorscheme nord

highlight Visual ctermbg=239 ctermfg=255 guibg=#434C5E guifg=#ECEFF4
highlight LineNr ctermfg=8 ctermbg=NONE guifg=#4C566A guibg=NONE
highlight CursorLineNr ctermfg=14 ctermbg=NONE guifg=#D8DEE9 guibg=NONE
highlight StatusLine ctermfg=14 ctermbg=NONE guifg=#D8DEE9 guibg=NONE
highlight StatusLineNC ctermfg=8 ctermbg=NONE guifg=#4C566A guibg=NONE


" --------------------------------------------------------------------
" 4. Plugin-specific settings
" --------------------------------------------------------------------

" vim_current_word
let g:vim_current_word#highlight_current_word = 0
let g:vim_current_word#highlight_delay = 500

" Rainbow parentheses
let g:rainbow_active = 1
let g:rainbow_conf = {
\ 'guifgs': ['orange', 'magenta', 'cyan'],
\ 'ctermfgs': ['yellow', 'magenta', 'cyan'],
\ 'guis': ['bold'], 'cterms': ['bold']
\ }

" vim-markdown
let g:vim_markdown_folding_disabled = 0
let g:markdown_recommended_style = 0

" bullets.vim
let g:bullets_pad_right = 0
let g:bullets_outline_levels = []

" vim-markdown-number-header / denops
"let g:denops_disable_version_check = 1
"let g:mnh_header_level_shift = 1

"function! RemoveNumbers()
 " let g:mnh_header_level_shift = 99
  "NumberHeader
  "let g:mnh_header_level_shift = 1
"endfunction


" --------------------------------------------------------------------
" 5. Window controls
" --------------------------------------------------------------------

" Temporarily maximize the current window, then equalize all windows.
let g:toggle_window_size = 0

function! ToggleWindowSize()
  if g:toggle_window_size == 1
    wincmd =
    let g:toggle_window_size = 0
  else
    resize
    vertical resize
    let g:toggle_window_size = 1
  endif
endfunction

nnoremap <silent> fz :call ToggleWindowSize()<CR>


" --------------------------------------------------------------------
" 6. NERDTree
" --------------------------------------------------------------------

" Ctrl+n: open / close NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>

" <Leader>f: locate the current file in NERDTree
nnoremap <leader>f :NERDTreeFind<CR>

let NERDTreeShowHidden=1
let NERDTreeWinSize=35

" Close Neovim when NERDTree is the only remaining window.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 &&
      \ exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

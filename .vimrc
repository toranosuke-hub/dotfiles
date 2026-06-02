" ====================================================================
" 1. プラグイン管理 (vim-plug)
" ====================================================================
" dotfiles運用向け：vim-plugが存在しない場合は自動でダウンロードする
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" --- カラースキーム ---
Plug 'nordtheme/vim'

" --- 文章入力・編集サポート ---
Plug 'obcat/vim-hitspop'                 " 検索ヒット数を画面隅に表示
Plug 'tpope/vim-surround'                " 選択範囲をカッコや記号で囲む/変更する
Plug 'tpope/vim-commentary'              " 複数行を一括コメントアウト/解除
Plug 'gosukiwi/vim-smartpairs'           " 囲み記号の自動入力
Plug 'dominikduda/vim_current_word'      " カーソル下のワードを自動ハイライト
Plug 'ntpeters/vim-better-whitespace'    " 不要な空白（ホワイトスペース）を強調表示
Plug 'ConradIrwin/vim-bracketed-paste'   " ペースト時のインデント崩れを防止
Plug 'skanehira/denops-translate.vim'    " 選択範囲を翻訳（※別途Denoが必要）

" --- UI改善・システム系 ---
Plug 'obcat/vim-sclow'                   " スクロールバーを表示
Plug 'luochen1990/rainbow'               " 階層ごとにカッコを色分け
Plug 'liuchengxu/vim-which-key'          " ショートカットのナビゲーション表示
Plug 'psliwka/vim-smoothie'              " スクロールをなめらかにする
Plug 'simeji/winresizer'                 " ウィンドウサイズを直感的に変更(Ctrl+e)

" --- Markdown特化 ---
Plug 'preservim/vim-markdown'            " Markdownのシンタックスハイライト・折り畳み
Plug 'bullets-vim/bullets.vim'           " 箇条書きリストの自動継続・整形
Plug 'mattn/vim-maketable'               " CSVとMarkdownテーブルの相互変換
Plug 'i9wa4/vim-markdown-number-header'  " ヘッダーの自動ナンバリング（※別途Denoが必要）
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' } " ブラウザプレビュー

call plug#end()


" ====================================================================
" 2. 基本設定
" ====================================================================

" 一行目: 全モードでマウス操作を可能に設定。
" 二行目: screen使用時にマウス操作がフリーズする対策らしい。
if has("mouse")
    set mouse=a
    set ttymouse=xterm2
endif


"文字コードをUFT-8に設定
set fenc=utf-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd

" 見た目系
" 行番号を表示
set number
" 現在の行を強調表示
"set cursorline
" 現在の行を強調表示（縦）
"set cursorcolumn
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" シンタックスハイライトの有効化
syntax enable

" Tab系

set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=4
" 行頭でのTab文字の表示幅
set shiftwidth=4

" 検索系
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>

"clipboard rennkei
set clipboard=unnamedplus


" ====================================================================
" 3. プラグイン固有の設定（※衝突時はこちらが優先されます）
" ====================================================================

" --- カラースキーム ---
colorscheme nord

" --- 選択範囲（ビジュアルモード）の文字を見やすくする ---
" 背景を少し明るいブルーグレーに、文字を白（#ECEFF4）にして同化を防ぐ
highlight Visual ctermbg=239 ctermfg=255 guibg=#434C5E guifg=#ECEFF4

" 1. 行番号の背景色を完全に透明（NONE）にして「帯」を消す（数字だけ残す）
" ※Nordの文字色（#4C566A, #D8DEE9）に最適化
highlight LineNr ctermfg=8 ctermbg=NONE guifg=#4C566A guibg=NONE
highlight CursorLineNr ctermfg=14 ctermbg=NONE guifg=#D8DEE9 guibg=NONE

" 2. 行番号のさらに左側にある、記号用の無駄な余白帯（サインカラム）を消す
set signcolumn=no

" --- ステータスラインの帯を周りの背景色と合わせる ---
" アクティブなウィンドウのステータスラインの背景を透明化
highlight StatusLine ctermfg=14 ctermbg=NONE guifg=#D8DEE9 guibg=NONE

" 非アクティブなウィンドウのステータスラインの背景を透明化
highlight StatusLineNC ctermfg=8 ctermbg=NONE guifg=#4C566A guibg=NONE

" 【オプション】もし文字や帯自体が一切不要な場合、以下の行のコメント（"）を外してください
" set laststatus=0

" --- vim_current_word の設定 ---
" キビキビ動きすぎるのを抑制し、カレントワード自体のハイライトはオフにする
let g:vim_current_word#highlight_current_word = 0
let g:vim_current_word#highlight_delay = 500

" --- vim-sclow (スクロールバー) の設定 ---
"let g:sclow_block_buftypes = ['terminal', 'prompt']
"let g:sclow_hide_full_length = 1
"let g:sclow_sbar_text = '|'
" --- vim-sclow (スクロールバー) の色をNordの背景色(#2E3440)付近に変更 ---
highlight SclowSbar ctermbg=0 ctermfg=NONE guibg=#2E3440 guifg=NONE

" --- rainbow (カッコの色分け) の設定 ---
let g:rainbow_active = 1
let g:rainbow_conf = {
\ 'guifgs': ['orange', 'magenta', 'cyan'],
\ 'ctermfgs': ['yellow', 'magenta', 'cyan'],
\ 'guis': ['bold'], 'cterms': ['bold']
\ }

" --- ウィンドウの一時最大化・復元 (UI改善・システムコントロール) ---
let g:toggle_window_size = 0
function! ToggleWindowSize()
  if g:toggle_window_size == 1
    exec "normal f="
    let g:toggle_window_size = 0
  else
    :resize
    :vertical resize
    let g:toggle_window_size = 1
  endif
endfunction
nnoremap <silent> fz call ToggleWindowSize()<CR>

" --- vim-markdown の設定 ---
" 折り畳みを無効化
let g:vim_markdown_folding_disabled = 0
" Tabなどのインデント幅が4に固定されてしまうのを防ぐ
let g:markdown_recommended_style = 0

" --- bullets.vim の設定 ---
" マークダウンでの箇条書き時の捻れを修正
let g:bullets_pad_right = 0
let g:bullets_outline_levels = []

" --- vim-markdown-number-header の設定 ---
" Denoのバージョンチェックを無効化
let g:denops_disable_version_check = 1
" ナンバリングを h2 から開始する設定
let g:mnh_header_level_shift = 1

" 現在のナンバリングを全削除する関数
function! RemoveNumbers()
  let g:mnh_header_level_shift = 99
  NumberHeader
  let g:mnh_header_level_shift = 1
endfunction

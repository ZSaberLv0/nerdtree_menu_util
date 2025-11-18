Plugin for [NERDTree](https://github.com/scrooloose/nerdtree) that supply some utilities

# Installation

use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

```
Plugin 'scrooloose/nerdtree'
Plugin 'ZSaberLv0/nerdtree_menu_util'

" optional, auto backup for destructive operations
Plugin 'ZSaberLv0/ZFVimBackup'

" optional, remove some useless builtin menu item to prevent key conflict
Plugin 'ZSaberLv0/nerdtree_fs_menu'
let g:loaded_nerdtree_exec_menuitem = 1
let g:loaded_nerdtree_fs_menu = 1
```

# Config

```vim
" whether you want this menu
let g:nmu_xxx_enable = 1
" change menu item text
let g:nmu_xxx_text = '(y)ank the node'
" change menu item key
let g:nmu_xxx_key = 'y'
```

where `xxx` is the menu items listed below

# Menu Items

## mark

mark/unmark multiple nodes for yank/cut/paste/delete

default config: `(i) mark/unmark for yank/cut/paste/delete`

## unmark

unmark all for yank/cut/paste/delete

default config: `(u)nmark all for yank/cut/paste/delete`

## yank

yank the node so that it can be 'paste'

default config: `(y)ank the node`

## cut

cut the node so that it can be 'paste'

default config: `(x) cut the node`

## paste

after `yank` or `cut`, paste the node to current node

default config: `(p)aste yanked/cut node`

## copypath

copy the full path of current node

default config: `copy (n)ode path`

extra config:

```vim
" copy to which register
let g:nmu_copypath_registers = ['*', '"', '0']
```

## run

run the node by system default behavior

default config: `(r)un the node`

## sizeof

print the file or dir's size

default config: `siz(e)of the node`

extra config:

```vim
" copy to which register
let g:nmu_sizeof_registers = ['*', '"', '0']
```

## shell

run shell on node dir

default config: `(s)hell`

extra config:

```vim
" copy result to which register
let g:nmu_shell_registers = ['t']
```

## quit

simply quit the menu

default config: `(q)uit`


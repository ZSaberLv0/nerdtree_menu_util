Plugin for [NERDTree](https://github.com/scrooloose/nerdtree) that supply some utilities

# Installation

recommended to instal via [Vundle](https://github.com/VundleVim/Vundle.vim):

```
Plugin 'ZSaberLv0/nerdtree_menu_util'
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

## size

print the file or dir's size

default config: `(s)ize of the node`

## quit

simply quit the menu

default config: `(q)uit`


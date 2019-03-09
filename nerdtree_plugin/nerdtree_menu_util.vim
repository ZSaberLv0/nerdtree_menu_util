" ============================================================================
" File:        nerdtree_menu_util.vim
" Description: plugin for NERD Tree that supply some utilities
" Maintainer:  ZSaberLv0 <z@zsaber.com>
" Last Change: 20171130
" ============================================================================
if exists("g:ZF_nerdtree_menu_util_loaded")
    finish
endif

let g:ZF_nerdtree_menu_util_loaded = 1

" ============================================================
function! s:setupModule(module, enable, text, key, callback)
    if !exists('g:nmu_' . a:module . '_enable')
        execute 'let g:nmu_' . a:module . '_enable=' . a:enable
    endif
    if !exists('g:nmu_' . a:module . '_text')
        execute 'let g:nmu_' . a:module . '_text="' . a:text . '"'
    endif
    if !exists('g:nmu_' . a:module . '_key')
        execute 'let g:nmu_' . a:module . '_key="' . a:key . '"'
    endif
    if eval('g:nmu_' . a:module . '_enable')
        call NERDTreeAddMenuItem({
                    \ 'text': eval('g:nmu_' . a:module . '_text'),
                    \ 'shortcut': eval('g:nmu_' . a:module . '_key'),
                    \ 'callback': a:callback })
    endif
endfunction

" ============================================================
" yank/cut/paste
call s:setupModule('yank', 1, '(y)ank the node', 'y', 'NERDTreeYankNode')
call s:setupModule('cut', 1, '(x) cut the node', 'x', 'NERDTreeCutNode')
call s:setupModule('paste', 1, '(p)aste yanked/cut node', 'p', 'NERDTreePasteNode')

let s:nmu_yanked_node = {}
let s:nmu_yanked_path = ''
let s:nmu_yanked_is_cut = 0
function! NERDTreeYankNode()
    let s:nmu_yanked_node = g:NERDTreeFileNode.GetSelected()
    let s:nmu_yanked_path = s:nmu_yanked_node.path.str()
    let s:nmu_yanked_is_cut = 0
    redraw!
    echo 'Yanked node: ' . s:nmu_yanked_path
endfunction
function! NERDTreeCutNode()
    let s:nmu_yanked_node = g:NERDTreeFileNode.GetSelected()
    let s:nmu_yanked_path = s:nmu_yanked_node.path.str()
    let s:nmu_yanked_is_cut = 1
    redraw!
    echo 'Cut node: ' . s:nmu_yanked_path
endfunction
function! NERDTreePasteNode()
    let l:oldssl=&shellslash
    set noshellslash
    call s:NERDTreePasteNode()
    let &shellslash=l:oldssl
endfunction
function! s:NERDTreePasteNode()
    if empty(s:nmu_yanked_path)
        redraw!
        echo 'Nothing yanked/cut'
        return
    endif

    let curNode = g:NERDTreeFileNode.GetSelected()
    let dstPath = curNode.path.isDirectory ? curNode.path.str() : curNode.path.getParent().str()
    let dstPath .= g:NERDTreePath.Slash() . fnamemodify(s:nmu_yanked_path, ':t')

    if filereadable(dstPath)
        echohl ErrorMsg | echo 'Overwrite ' . dstPath . '? y/n: '  | echohl None
        let choice=getchar()
        if choice != char2nr('y')
            redraw!
            echo 'Canceled paste: ' . s:nmu_yanked_path
            return
        endif
    endif

    try
        if s:nmu_yanked_is_cut
            let bufnum = bufnr("^" . s:nmu_yanked_node.path.str() . "$")
            call s:nmu_yanked_node.rename(dstPath)
            call NERDTreeRender()
            call s:nmu_yanked_node.putCursorHere(1, 0)
            if bufnum != -1
                let prompt = "\nNode moved\n\nThe old file is open in buffer ". bufnum
                            \ . (bufwinnr(bufnum) ==# -1 ? " (hidden)" : "")
                            \ . ". Replace this buffer with a new file? (yN)"
                call s:promptToRenameBuffer(bufnum, prompt, dstPath)
            endif
        else
            let newNode = s:nmu_yanked_node.copy(dstPath)
            if !empty(newNode)
                call NERDTreeRender()
                call newNode.putCursorHere(0, 0)
            endif
        endif
    catch /^NERDTree/
        call nerdtree#echoWarning('Failed to ' . (s:nmu_yanked_is_cut ? 'move' : 'copy') . ' node ' . s:nmu_yanked_path)
        return
    endtry
    redraw!
    echo (s:nmu_yanked_is_cut ? 'Moved to ' : 'Copied to ') . dstPath

    if s:nmu_yanked_is_cut
        let s:nmu_yanked_node = {}
        let s:nmu_yanked_path = ''
    endif
endfunction
function! s:promptToRenameBuffer(bufnum, msg, newFileName)
    echo a:msg
    if g:NERDTreeAutoDeleteBuffer || nr2char(getchar()) ==# 'y'
        let quotedFileName = fnameescape(a:newFileName)
        " 1. ensure that a new buffer is loaded
        exec "badd " . quotedFileName
        " 2. ensure that all windows which display the just deleted filename
        " display a buffer for a new filename.
        let s:originalTabNumber = tabpagenr()
        let s:originalWindowNumber = winnr()
        let editStr = g:NERDTreePath.New(a:newFileName).str({'format': 'Edit'})
        exec "tabdo windo if winbufnr(0) == " . a:bufnum . " | exec ':e! " . editStr . "' | endif"
        exec "tabnext " . s:originalTabNumber
        exec s:originalWindowNumber . "wincmd w"
        " 3. We don't need a previous buffer anymore
        exec "bwipeout! " . a:bufnum
    endif
endfunction


" ============================================================
" copypath
call s:setupModule('copypath', 1, 'copy (n)ode path', 'n', 'NERDTreeCopyPath')
if !exists('g:nmu_copypath_registers')
    let g:nmu_copypath_registers = ['*', '"', '0']
endif
function! NERDTreeCopyPath()
    let treenode = g:NERDTreeFileNode.GetSelected()
    let src = treenode.path.str()
    let src = substitute(src, '\\', '/', 'g')

    for item in g:nmu_copypath_registers
        if item == '*'
            if !has('clipboard')
                continue
            endif
        endif
        execute 'let @' . item . ' = "' . src . '"'
    endfor

    redraw!
    echo 'Copied path to clipboard: ' . src
endfunction


" ============================================================
" run
call s:setupModule('run', 1, '(r)un the node', 'r', 'NERDTreeRunNode')
function! NERDTreeRunNode()
    if !exists('s:haskdeinit')
        let s:haskdeinit = system("ps -e") =~ 'kdeinit'
    endif
    if !exists('s:hasdarwin')
        let s:hasdarwin = system("uname -s") =~ 'Darwin'
    endif

    let l:oldssl=&shellslash
    set noshellslash
    let treenode = g:NERDTreeFileNode.GetSelected()
    let path = treenode.path.str()

    if has("gui_running")
        let args = shellescape(path,1)." &"
    else
        let args = shellescape(path,1)." > /dev/null"
    end

    if has("unix") && executable("gnome-open") && !s:haskdeinit
        exe "silent !gnome-open ".args
        let ret= v:shell_error
    elseif has("unix") && executable("kde-open") && s:haskdeinit
        exe "silent !kde-open ".args
        let ret= v:shell_error
    elseif has("unix") && executable("open") && s:hasdarwin
        exe "silent !open ".args
        let ret= v:shell_error
    elseif has("win32") || has("win64")
        exe "silent !start explorer ".shellescape(path,1)
    end
    let &shellslash=l:oldssl
    redraw!
endfunction


" ============================================================
" size
call s:setupModule('size', 1, '(s)ize of the node', 's', 'NERDTreeNodeSize')
function! NERDTreeNodeSize()
    let treenode = g:NERDTreeFileNode.GetSelected()
    let path = treenode.path.str()

    redraw!
    echo 'calculating size...     ' . path
    let result = system('du -d0 -h "' . path . '" | cut -f1')
    let result = substitute(result, "[ \t\n\r]", '', 'g')

    redraw!
    echo result . '    ' . path
endfunction


" ============================================================
" quit
call s:setupModule('quit', 1, '(q)uit', 'q', 'NERDTreeQuitNode')
function! NERDTreeQuitNode()
    redraw!
endfunction



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

if !exists('g:nmu_copytoregisters')
    let g:nmu_copytoregisters = ['*', '"', '0']
endif

function! s:tryBackup(fileOrDir)
    if !exists('*ZFBackupSave')
        return
    endif
    if isdirectory(a:fileOrDir)
        call ZFBackupSaveDir(a:fileOrDir)
    else
        call ZFBackupSave(a:fileOrDir)
    endif
endfunction

" ============================================================
" mark/unmark
call s:setupModule('mark', 1, '(i) mark/unmark for yank/cut/paste/delete', 'i', 'NERDTreeMarkNode')
call s:setupModule('unmark', 1, '(u)nmark all for yank/cut/paste/delete', 'u', 'NERDTreeUnmarkAll')
function! NERDTreeMarkNode()
    if !exists('s:nmu_marked_nodes')
        let s:nmu_marked_nodes = {}
    endif
    let node = g:NERDTreeFileNode.GetSelected()
    let path = node.path.str()
    if empty(path)
        echo 'empty path'
        return
    endif
    if exists('s:nmu_marked_nodes[path]')
        unlet s:nmu_marked_nodes[path]
        let isMark = 0
    else
        let s:nmu_marked_nodes[path] = node
        let isMark = 1
    endif
    let s:nmu_marked_is_cut = 0
    redraw!
    echo printf('[%d total] %s %s for yank/cut/paste/delete'
                \ , len(s:nmu_marked_nodes)
                \ , fnamemodify(path, ':t')
                \ , isMark ? 'marked' : 'unmarked'
                \ )
endfunction
function! NERDTreeUnmarkAll()
    if exists('s:nmu_marked_nodes')
        unlet s:nmu_marked_nodes
    endif
    redraw!
    echo 'all nodes unmarked for yank/cut/paste/delete'
endfunction

" ============================================================
" yank/cut/paste
call s:setupModule('yank', 1, '(y)ank', 'y', 'NERDTreeYankNode')
call s:setupModule('cut', 1, '(x) cut', 'x', 'NERDTreeCutNode')
call s:setupModule('paste', 1, '(p)aste', 'p', 'NERDTreePasteNode')

function! s:prepareMark()
    if !exists('s:nmu_marked_nodes')
        let s:nmu_marked_nodes = {}
    endif
    if empty(s:nmu_marked_nodes)
        let node = g:NERDTreeFileNode.GetSelected()
        let path = node.path.str()
        if empty(path)
            echo 'empty path'
            return 0
        endif
        let s:nmu_marked_nodes[path] = node
    endif
    return 1
endfunction
function! NERDTreeYankNode()
    if !s:prepareMark()
        return
    endif
    let s:nmu_marked_is_cut = 0
    redraw!
    echo len(s:nmu_marked_nodes) . ' nodes yanked'
endfunction
function! NERDTreeCutNode()
    if !s:prepareMark()
        return
    endif
    let s:nmu_marked_is_cut = 1
    redraw!
    echo len(s:nmu_marked_nodes) . ' nodes cut'
endfunction

function! NERDTreePasteNode()
    let l:oldssl=&shellslash
    set noshellslash
    call s:NERDTreePasteNode()
    let &shellslash=l:oldssl
endfunction
function! s:NERDTreePasteNode()
    if empty(get(s:, 'nmu_marked_nodes', {}))
        redraw!
        echo 'Nothing yanked/cut'
        return
    endif

    let dstNode = g:NERDTreeFileNode.GetSelected()
    let dstPath = dstNode.path.isDirectory ? dstNode.path.str() : dstNode.path.getParent().str()

    let pastedCount = 0
    for node in values(s:nmu_marked_nodes)
        if empty(node.path.str())
            continue
        endif

        let dstFile = dstPath . nerdtree#slash() . fnamemodify(node.path.str(), ':t')
        if filereadable(dstFile)
            call s:tryBackup(dstFile)
            redraw!
            echohl ErrorMsg | echo 'Overwrite ' . dstFile . '? y/n: '  | echohl None
            let choice = getchar()
            if choice != char2nr('y')
                redraw!
                echo 'Skipped paste: ' . node.path.str()
                continue
            endif
        endif

        try
            if s:nmu_marked_is_cut
                let bufnum = bufnr("^" . node.path.str() . "$")
                call node.rename(dstFile)
                call NERDTreeRender()
                call node.putCursorHere(1, 0)
                if bufnum != -1
                    let prompt = "\nNode moved\n\nThe old file is open in buffer ". bufnum
                                \ . (bufwinnr(bufnum) ==# -1 ? " (hidden)" : "")
                                \ . ". Replace this buffer with a new file? (yN)"
                    call s:promptToRenameBuffer(bufnum, prompt, dstFile)
                endif
            else
                let newNode = node.copy(dstFile)
                if !empty(newNode)
                    call NERDTreeRender()
                    call newNode.putCursorHere(0, 0)
                endif
            endif
        catch /^NERDTree/
            call nerdtree#echoWarning('Failed to ' . (s:nmu_marked_is_cut ? 'move' : 'copy') . ' node ' . s:nmu_yanked_path)
            continue
        endtry
        let pastedCount += 1
    endfor

    redraw!
    echo pastedCount . ' files ' . (s:nmu_marked_is_cut ? 'moved' : 'copied') . ' to ' . dstPath
    if s:nmu_marked_is_cut
        unlet s:nmu_marked_nodes
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
" replacement of original delete, to support NERDTreeMarkNode
function! NERDTreeDeleteNode()
    if !s:prepareMark()
        return
    endif
    let nmu_marked_nodes = copy(s:nmu_marked_nodes)
    unlet s:nmu_marked_nodes

    redraw!
    let deleteCount = 0
    let confirmAll = 0
    for node in values(nmu_marked_nodes)
        if !confirmAll
            echo 'Delete node? ' . node.path.str()
            if len(nmu_marked_nodes) > 1
                echo '  (a)ll'
            endif
            echo '  (y)es'
            echo '  (n)o'
            echo 'choice: '
            let confirm = nr2char(getchar())
            redraw!
            if confirm == 'a'
                let confirmAll = 1
            elseif confirm != 'y'
                continue
            endif
        endif
        if s:NERDTreeDeleteNode(node)
            let deleteCount += 1
        endif
    endfor
    echo deleteCount . ' nodes deleted'
endfunction
function! s:NERDTreeDeleteNode(node)
    let currentNode = a:node
    if empty(currentNode.path.str())
        return 0
    endif
    call s:tryBackup(currentNode.path.str())

    try
        call currentNode.delete()
        call NERDTreeRender()

        "if the node is open in a buffer, ask the user if they want to
        "close that buffer
        let bufnum = bufnr('^'.currentNode.path.str().'$')
        if buflisted(bufnum)
            let prompt = "\nNode deleted.\n\nThe file is open in buffer ". bufnum . (bufwinnr(bufnum) ==# -1 ? ' (hidden)' : '') .'. Delete this buffer? (yN)'
            call s:promptToDelBuffer(bufnum, prompt)
        endif

        redraw!
    catch /^NERDTree/
        call nerdtree#echoWarning('Could not remove node')
        return 0
    endtry
    return 1
endfunction
function! s:promptToDelBuffer(bufnum, msg)
    echo a:msg
    if g:NERDTreeAutoDeleteBuffer || nr2char(getchar()) ==# 'y'
        " 1. ensure that all windows which display the just deleted filename
        " now display an empty buffer (so a layout is preserved).
        " Is not it better to close single tabs with this file only ?
        let s:originalTabNumber = tabpagenr()
        let s:originalWindowNumber = winnr()
        " Go to the next buffer in buffer list if at least one extra buffer is listed
        " Otherwise open a new empty buffer
        if v:version >= 800
            let l:listedBufferCount = len(getbufinfo({'buflisted':1}))
        elseif v:version >= 702
            let l:listedBufferCount = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
        else
            " Ignore buffer count in this case to make sure we keep the old
            " behavior
            let l:listedBufferCount = 0
        endif
        if l:listedBufferCount > 1
            call nerdtree#exec('tabdo windo if winbufnr(0) ==# ' . a:bufnum . " | exec ':bnext! ' | endif", 1)
        else
            call nerdtree#exec('tabdo windo if winbufnr(0) ==# ' . a:bufnum . " | exec ':enew! ' | endif", 1)
        endif
        call nerdtree#exec('tabnext ' . s:originalTabNumber, 1)
        call nerdtree#exec(s:originalWindowNumber . 'wincmd w', 1)
        " 3. We don't need a previous buffer anymore
        call nerdtree#exec('bwipeout! ' . a:bufnum, 0)
    endif
endfunction


" ============================================================
" copypath
call s:setupModule('copypath', 1, '(n)ode path', 'n', 'NERDTreeCopyPath')
function! NERDTreeCopyPath()
    let treenode = g:NERDTreeFileNode.GetSelected()
    let src = treenode.path.str()
    let src = substitute(src, '\\', '/', 'g')

    for item in get(g:, 'nmu_copypath_registers', g:nmu_copytoregisters)
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
call s:setupModule('run', 1, '(r)un', 'r', 'NERDTreeRunNode')
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
" sizeof
call s:setupModule('sizeof', 1, '(s)izeof', 's', 'NERDTreeNodeSize')
function! NERDTreeNodeSize()
    let treenode = g:NERDTreeFileNode.GetSelected()
    let path = treenode.path.str()

    redraw!
    echo 'calculating size...     ' . path

    let sizeFriendly = system('du -d0 -h "' . path . '" | cut -f1')
    let sizeFriendly = substitute(sizeFriendly, "[ \t\n\r]", '', 'g')

    if treenode.path.isDirectory
        let hint = sizeFriendly
    else
        let size = system('wc -c "' . path . '"')
        let size = substitute(size, "[\t\n\r]", ' ', 'g')
        " ^ *([0-9]+) +.*$
        let size = substitute(size, '^ *\([0-9]\+\) \+.*$', '\1', 'g')

        for item in get(g:, 'nmu_sizeof_registers', g:nmu_copytoregisters)
            if item == '*'
                if !has('clipboard')
                    continue
                endif
            endif
            execute 'let @' . item . ' = "' . size . '"'
        endfor

        let hint = sizeFriendly . ' (' . size . ')'
    endif

    redraw!
    echo hint . '    ' . path
endfunction


" ============================================================
" quit
call s:setupModule('quit', 1, '(q)uit', 'q', 'NERDTreeQuitNode')
function! NERDTreeQuitNode()
    redraw!
endfunction


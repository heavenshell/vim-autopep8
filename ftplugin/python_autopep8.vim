"=========================================================
" File: autopep8.vim
" Author: tell-k <ffk2005[at]gmail.com>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Last Change: 13-Sep-2014.
" Version: 1.1.0
" Original WebPage: https://github.com/tell-k/vim-autopep8
" WebPage: https://github.com/heavenshell/vim-autopep8
" License: MIT Licence
"
" This plugin is almost copied from Golang's vim plugin.
" see https://github.com/vim-jp/vim-go-extra/blob/master/ftplugin/go/fmt.vim
"
" Copyright 2011 The Go Authors. All rights reserved.
" Copyright 2013 tell-k <ffk2005[at]gmail.com> All rights reserved.
" Copyright 2014 Shinya Ohyanagi. All rights reserved.
"==========================================================
if exists("b:did_ftplugin_autopep8")
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:autopep8_commands")
    let g:autopep8_commands = 1
endif

" autopep8 options.
let s:autopep8_options = []

if exists("g:autopep8_ignore")
    call add(s:autopep8_options, " --ignore=" . g:autopep8_ignore)
endif

if exists("g:autopep8_select")
    call add(s:autopep8_options, " --select=" . g:autopep8_select)
endif

if exists("g:autopep8_pep8_passes")
    call add(s:autopep8_options, " --pep8-passes=" . g:autopep8_pep8_passes)
endif

if exists("g:autopep8_max_line_length")
    call add(s:autopep8_options, " --max-line-length=" . g:autopep8_max_line_length)
endif

if exists("g:autopep8_aggressive")
    call add(s:autopep8_options, " --aggressive")
endif

if exists("g:autopep8_indent")
    call add(s:autopep8_indent, " --indent-size=" . g:autopep8_indent)
endif

if !exists("g:autopep8_disable_show_diff")
    let g:autopep8_disable_show_diff = 0
endif

if !exists("g:autopep8_diff_split_window")
    let g:autopep8_diff_split_window = "botright"
endif

if !exists("g:autopep8_command")
    let g:autopep8_command = "autopep8"
endif

let s:autopep8_args = [
  \ 'range'
  \]

function! s:complete(lead, cmd, pos)
  let args = map(copy(s:autopep8_args), '"--" . v:val . "="')
  return filter(args, 'v:val =~# "^".a:lead')
endfunction

if g:autopep8_commands
    command! -buffer -nargs=* -range=0 -complete=customlist,<SID>complete Autopep8 call s:Autopep8(<q-args>, <count>, <line1>, <line2>)
    nnoremap <silent> <Plug>(autopep8) :<C-u>call <SID>Autopep8()<CR>

    if !exists("g:autopep8_no_default_key_mapping")
        silent! map <unique> <F8> <Plug>(autopep8)
    endif
endif

let s:debug = 0
if exists("g:autopep8_debug")
    let s:debug = g:autopep8_debug
endif

function! s:get_range()
    " Get visual mode selection for execute `autopep8 --range`.
    let range = ""
    let mode = visualmode(1)
    if mode == "v" || mode == "V" || mode == ""
        let start_lnum = line("'<")
        let end_lnum = line("'>")
        let range = printf(" --range %s %s ", start_lnum, end_lnum)
    endif

    return range
endfunction

function! s:parse_options(args)
    let options = ''
    "" Check given args are collect arg.
    "" eg. --range is ok, but --foo is not ok.
    let args_list = split(a:args, '--')
    for arg in args_list
        if arg =~ '^range='
            let options = options . ' --' . substitute(arg, '=', ' ', '') . ' '
        endif
    endfor
    return options
endfunction

function! s:Autopep8(...)
    let args = s:parse_options(len(a:000) > 0 ? a:000[0] : '')
    let options = join(s:autopep8_options, "")
    let range = s:get_range()
    if range == ''
        let range = args
    endif
    let commands = g:autopep8_command . options . " " . range
    if s:debug == 1
        echomsg commands
    endif

    let file_path = expand("%:p")

    if g:autopep8_disable_show_diff == 0
        let winnum = bufwinnr(bufnr("^autopep8$"))
        if winnum != -1
            if winnum != bufwinnr("%")
                execute winnum "wincmd w"
            endif
        else
            execute "silent " . g:autopep8_diff_split_window . " noautocmd new autopep8"
        endif
        setlocal modifiable

        silent %d _
        call s:execute(commands . " --diff " . file_path)

        setlocal buftype=nofile bufhidden=delete noswapfile
        setlocal nomodified
        setlocal nomodifiable
        nnoremap <buffer> q <C-w>c
        setlocal filetype=diff

        if winnum != -1
            if winnum != bufwinnr("%")
                execute winnum "wincmd w"
            else
                execute "wincmd w"
            endif
        else
            execute "wincmd w"
        endif
    endif

    setlocal modifiable
    call s:execute(commands . file_path)

    hi Green ctermfg=green
    echohl Green
    redraw | echon "Fixed with autopep8 this file."
    echohl
endfunction

function! s:execute(command)
    " This function is almost copied from Golang's vim plugin.
    " Copyright 2011 The Go Authors. All rights reserved.
    " see also
    "   https://github.com/vim-jp/vim-go-extra/blob/master/ftplugin/go/fmt.vim
    if s:debug != 0
        echomsg a:command
    endif

    let view = winsaveview()
    silent execute "%!" . a:command

    if v:shell_error
        let errors = []
        for line in getline(1, line('$'))
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if s:debug == 1
                echomsg line
            endif
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"col":      tokens[3],
                                 \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect autopep8 error format, output errors
        endif
        undo
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "Autopep8 returned error" | echohl None
    endif
    call winrestview(view)
endfunction

let b:did_ftplugin_autopep8 = 1

let &cpo = s:save_cpo
unlet s:save_cpo

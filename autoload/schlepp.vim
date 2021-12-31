function! schlepp#block(dir) abort
"  Logic for moving a visual block selection, this is much more complicated than
"  lines since I have to be able to part text in order to insert the incoming
"  line

    "Save virtualedit settings, and enable for the function
    let l:ve_save = &l:virtualedit
    "So that if something fails, we can set virtualedit back
    try
        setlocal virtualedit=all

        " While '< is always above or equal to '> in linenum, the column it
        " references could be the first or last col in the block selected
        let [l:fbuf, l:fline, l:fcol, l:foff] = getpos("'<")
        let [l:lbuf, l:lline, l:lcol, l:loff] = getpos("'>")
        let [l:left_col, l:right_col]  = sort([l:fcol + l:foff, l:lcol + l:loff])
        if &selection ==# "exclusive" && l:fcol + l:foff < l:lcol + l:loff
            let l:right_col -= 1
        endif

        if a:dir ==? 'up' "{{{ Up
            if l:fline == 1 "First lines of file
                call append(0, '')
            endif
            normal! gvxkPgvkoko
            "}}}
        elseif a:dir ==? 'down' "{{{ Down
            if l:lline == line('$') "Moving down past EOF
                call append(line('$'), '')
            endif
            normal! gvxjPgvjojo
            "}}}
        elseif a:dir ==? 'right' "{{{ Right
            normal! gvxpgvlolo
            "}}}
        elseif a:dir ==? 'left' "{{{ Left
            if l:left_col == 1
                execute "normal! gvA \<esc>"
                if g:Schlepp#allowSquishingBlock || match(getline(l:fline, l:lline), '^[^ \t]') == -1
                    for l:linenum in range(l:fline, l:lline)
                        if match(getline(l:linenum), "^[ \t]") != -1
                            call setline(l:linenum, substitute(getline(l:linenum), "^\\s", '', ''))
                            execute 'normal! :' . l:linenum . "\<cr>" . l:right_col . "|a \<esc>"
                        endif
                    endfor
                endif
                call schlepp#reset_selection()
            else
                normal! gvxhPgvhoho
            endif
        endif "}}}

        "Strip Whitespace
        "Need new positions since the visual area has moved
        if g:Schlepp#trimWS
            let [l:fbuf, l:fline, l:fcol, l:foff] = getpos("'<")
            let [l:lbuf, l:lline, l:lcol, l:loff] = getpos("'>")
            let [l:left_col, l:right_col]  = sort([l:fcol + l:foff, l:lcol + l:loff])
            if &selection ==# "exclusive" && l:fcol + l:foff < l:lcol + l:loff
                let l:right_col -= 1
            endif
            for l:linenum in range(l:fline, l:lline)
                call setline(l:linenum, substitute(getline(l:linenum), "\\s\\+$", '', ''))
            endfor
            "Take care of trailing space created on lines above or below while
            "moving past them
            if a:dir ==? 'up'
                call setline(l:lline + 1, substitute(getline(l:lline + 1), "\\s\\+$", '', ''))
            elseif a:dir ==? 'down'
                call setline(l:fline - 1, substitute(getline(l:fline - 1), "\\s\\+$", '', ''))
            endif
        endif

    endtry
    let &l:virtualedit = l:ve_save

endfunction "}}}

" utility
function! schlepp#reset_selection() abort
    execute "normal! \<Esc>gv"
endfunction


" Using a script in the "autoload" directory is simpler, but requires using
" exactly the right file name.  A function that can be autoloaded has a name
" like this: >
" 	:call filename#funcname()

fun! supercollidercomplete#CompleteMonths(findstart, base)
  if a:findstart
    " locate the start of the word
    echom "Heeeere!!!"
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    " find months matching with "a:base"
    let res = []
    for m in split("January February March April May June July August September October November December")
      if m =~ '^' . a:base
  call add(res, m)
      endif
    endfor
    return res
  endif
endfun

echom "There!!!!"

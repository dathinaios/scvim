"                       ____   ______     ___                               "
"                      / ___| / ___\ \   / (_)_ __ ___                      "
"                      \___ \| |    \ \ / /| | '_ ` _ \                     "
"                       ___) | |___  \ V / | | | | | | |                    "
"                      |____/ \____|  \_/  |_|_| |_| |_|                    "
"                                                                           "
"              _                                  _      _   _              "
"   __ _ _   _| |_ ___   ___ ___  _ __ ___  _ __ | | ___| |_(_) ___  _ __   "
"  / _` | | | | __/ _ \ / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __| |/ _ \| '_ \  "
" | (_| | |_| | || (_) | (_| (_) | | | | | | |_) | |  __/ |_| | (_) | | | | "
"  \__,_|\__,_|\__\___/ \___\___/|_| |_| |_| .__/|_|\___|\__|_|\___/|_| |_| "
"                                          |_|                              "
"                                                                           "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                         Copyright 2015 Dionysis Athinaios "
"                                                This file is part of SCVIM "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This function is called first to find the start of the text to be complete
" and then to find the actual completion text

fun! supercollidercomplete#Complete(findstart, base)
  if a:findstart
    return SCCompleteFindStart(getline('.'), col('.'))
  else
    let list_with_result_of_taglist = []
    let theStringIsAfteraPeriod = 0
    let passedWord = a:base
    let matches = taglist("^" . passedWord .  "*")
    for item in matches
      let kind = item['kind']
      "for method matches display only when there was a dot before the word
      if ( ( kind == "m" ) ||  ( kind == "M" ) ) && (s:theStringIsAfteraPeriod == 1) "for methods display the class
        call add(list_with_result_of_taglist, {'word':item['name'], 'menu': item['class'], 'kind': kind})
      elseif ( kind == "c" ) && ( s:theStringIsAfteraPeriod == 0 )
        call add(list_with_result_of_taglist, {'word':item['name'], 'kind': kind})
      endif
    endfor
    return list_with_result_of_taglist
  endif
endfun

fun! SCCompleteFindStart(line, column)
    let start = a:column - 1
    while start > 0 && a:line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    call SCCompleteCheckForPeriodAtStart(a:line, start)
    return start
endfun

fun! SCCompleteCheckForPeriodAtStart(line, start)
  " echom "This is the whole line: " . a:line
  " echom "This is the start index: " . a:start
  " echom "This is where we are: " . a:line[a:start - 1]
  if a:line[a:start - 1] == "\."
    echom "We have found a period!!"
    let s:theStringIsAfteraPeriod = 1
  else
    echom "We have NOT found a period!!"
    let s:theStringIsAfteraPeriod = 0
  endif

endfun


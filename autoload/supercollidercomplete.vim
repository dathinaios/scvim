"                       ____   ______     ___                               "
"                      / ___| / ___\ \   / (_)_ __ ___                      "
"                      \___ \| |    \ \ / /| | '_ ` _ \                     "
"                       ___) | |___  \ V / | | | | | | |                    "
"                      |____/ \____|  \_/  |_|_| |_| |_|                    "
"                                                                           "
"              _                                 _      _   _               "
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

fun! supercollidercomplete#CompleteMonths(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    let list_with_result_of_taglist = []
    let matches = taglist("^" . a:base .  "*")
    for item in matches
      let kind = item['kind']
      if kind == "f" "for methods display the class
        call add(list_with_result_of_taglist, {'word':item['name'], 'menu': item['class'], 'kind': kind})
      else
        call add(list_with_result_of_taglist, {'word':item['name'], 'kind': kind})
      endif
    endfor
    return list_with_result_of_taglist
  endif
endfun

" insert other info
" call add(list_with_result_of_taglist, '------------')
" call add(list_with_result_of_taglist, item['name'])
" call add(list_with_result_of_taglist, item['name'] . item['kind'])
" return {'words': list_with_result_of_taglist}

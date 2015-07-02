
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
    " find words matching with "a:base"
    let list_with_result_of_taglist = []
    let matches = taglist("^" . a:base .  "*")
    for item in matches
        call add(list_with_result_of_taglist, {'word':item['name'], 'menu': 'here add other info', 'kind': item['kind']})
    endfor
    return list_with_result_of_taglist
  endif
endfun

"insert other info
" call add(list_with_result_of_taglist, '------------')
"call add(list_with_result_of_taglist, item['name'])
" call add(list_with_result_of_taglist, item['name'] . item['kind'])
" return {'words': list_with_result_of_taglist}

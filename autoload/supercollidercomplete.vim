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

" SuperCollider kinds
" c  classes
" m  instance methods
" x  class methods

" TODO: This can not be the solution as it set the ignorecase for the user's
" environment too
"setlocal noignorecase "I need to do that or else the comparison for M with m is not working!!!

fun! supercollidercomplete#Complete(findstart, base)
  if a:findstart
    return SCCompleteFindStart(getline('.'), col('.'))
  else
    let list_with_result_of_taglist = []
    let matches = taglist("^" . a:base .  "*")
    for item in matches
      call SCCompleteAddItemsToListAccordingToKind(item, list_with_result_of_taglist)
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
    call SCCompleteCheckForClassMethod(a:line, start)
    return start
endfun

fun! SCCompleteCheckForPeriodAtStart(line, start)
  if a:line[a:start - 1] == "\."
    let s:theStringIsAfteraPeriod = 1
  else
    let s:theStringIsAfteraPeriod = 0
  endif
endfun

fun! SCCompleteCheckForClassMethod(line, start)
  let startOfWordThatStartedCompletion= copy(a:start-2)
  let startOfWordBeforeTheOneThatStartedCompletion= copy(a:start-2)
  while l:startOfWordBeforeTheOneThatStartedCompletion > 0 && a:line[l:startOfWordBeforeTheOneThatStartedCompletion- 1] =~ '\a'
    let l:startOfWordBeforeTheOneThatStartedCompletion -= 1
  endwhile

  let s:wordThatTheMethodIsCalledFrom = a:line[(l:startOfWordBeforeTheOneThatStartedCompletion):(l:startOfWordThatStartedCompletion)]
  if match(l:startOfWordBeforeTheOneThatStartedCompletion[0],'\*[A-Z]*') < 0
    let s:thePeriodIsAfteraClass = 1
  else
    let s:thePeriodIsAfteraClass = 0
  endif
endfun

fun! SCCompleteAddItemsToListAccordingToKind(item, list)
  let l:kind = a:item['kind']
  if s:theStringIsAfteraPeriod
    if s:thePeriodIsAfteraClass
      "TODO filter according to class or superclass. Dont forget that when
      "daling with class methods we are daling with metaclasses
      if l:kind == "x" "&& ( ( a:item['class'] == ('Meta_' . s:wordThatTheMethodIsCalledFrom) ) || (match(a:item['superclasses'], ('Meta_' . a:item['class'])) >= 0))        
        call add(a:list, {'word':a:item['name'], 'menu': a:item['class'], 'kind': l:kind})
      endif
    elseif l:kind == "m" "if it i not a class it must be a method call on a variable TODO
      call add(a:list, {'word':a:item['name'], 'menu': a:item['class'], 'kind': l:kind})
    endif
  elseif ( l:kind == "c" ) && ( s:theStringIsAfteraPeriod == 0 )
    call add(a:list, {'word':a:item['name'], 'kind': l:kind})
  endif
endfun

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

" TODO for no match return all methods or nothing
" TODO class methods filter correctly but instance methods after resolution
" don't

" SuperCollider kinds
" c  classes
" m  instance methods
" M  class methods

fun! supercollidercomplete#Complete(findstart, base)
  if a:findstart
    return SCCompleteFindStart(getline('.'), col('.'))
  else
    let list_with_result_of_taglist = []
    let matches = taglist("^" . a:base .  "*")

    for item in l:matches
      if item['class'] ==# s:wordBeforeThePeriodAtTheStartOfOurCall "if a class method
        let superClassList = split(item['classTree'], ';')
        for classFromSuperClassList in superClassList
          for matchedItem in l:matches
            call SCCompleteAddItemsToListAccordingToKind(matchedItem , list_with_result_of_taglist, classFromSuperClassList )
          endfor
        endfor
      elseif s:theVariableWasSuccesfullyresolved && (s:classFoundAfterVariableResolution ==# item['class'])
        let superClassList = split(item['classTree'], ';')
        for classFromSuperClassList in superClassList
          " TODO this is called 4-5 times instead of one. A waste of processing time. possible duplicates in tag file
          " echom "from here: " . classFromSuperClassList
          for matchedItem in l:matches
            call SCCompleteAddItemsToListAccordingToKind(matchedItem , list_with_result_of_taglist, classFromSuperClassList )
          endfor
        endfor
      else 
        call SCCompleteAddItemsToListAccordingToKind(item, list_with_result_of_taglist, item['class'])
        "-----------------------------
      endif
    endfor
    return list_with_result_of_taglist
  endif
endfun

fun! SCCompleteResolveVariableToClass()
  let l:foundVariable = search(s:wordBeforeThePeriodAtTheStartOfOurCall . '\s*=\s*\u', 'b')
  let l:foundClass = matchstr(getline(l:foundVariable) , '\(' . s:wordBeforeThePeriodAtTheStartOfOurCall . '\s*=\s*\)\@<=\w\{-}\ze[\.\[\(]' ) 

  if l:foundClass == "" "If I  dont have result check for strings, arrays and functions
    let l:foundClass = matchstr(getline(l:foundVariable) , '\(' . s:wordBeforeThePeriodAtTheStartOfOurCall . '\s*=\s*\)\@<=["[{]' )

    "TODO detect all these from variable
    if l:foundClass == '['
      let l:foundClass = "Array"
      " elseif l:foundClass == '{'
      "   let l:foundClass = "Function"
      " elseif l:foundClass == "\""
      "   let l:foundClass = "String"
      " elseif l:foundClass == "\'"
      "   let l:foundClass = "Symbol"
    endif
  endif

  if l:foundClass == ""
    let s:theVariableWasSuccesfullyresolved = 0
  else
    let s:theVariableWasSuccesfullyresolved = 1
    let s:classFoundAfterVariableResolution = l:foundClass
  endif
  
endfun

fun! SCCompleteFindStart(line, column)
    let start = a:column - 1
    while start > 0 && a:line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    call SCCompleteCheckForPeriodAtStart(a:line, start)
    call SCCompleteCheckForParenthesisAtStart(a:line, start)
    call SCCompleteCheckForClassMethod(a:line, start)
    call SCCompleteCheckForMethodArgs(a:line, start)
    call SCCompleteResolveVariableToClass()
    return start
endfun

fun! SCCompleteCheckForPeriodAtStart(line, start)
  if a:line[a:start - 1] == "\."
    let s:theStringIsAfteraPeriod = 1
  else
    let s:theStringIsAfteraPeriod = 0
  endif
endfun

fun! SCCompleteCheckForParenthesisAtStart(line, start)
  if a:line[a:start - 1] == "("
    let s:theStringIsAfteraParenthesis = 1
  else
    let s:theStringIsAfteraParenthesis = 0
  endif
endfun

fun! SCCompleteCheckForClassMethod(line, start)
  let startOfWordThatStartedCompletion= copy(a:start-2)
  let startOfWordBeforeTheOneThatStartedCompletion= copy(a:start-2)
  while l:startOfWordBeforeTheOneThatStartedCompletion > 0 && a:line[l:startOfWordBeforeTheOneThatStartedCompletion- 1] =~ '\a'
    let l:startOfWordBeforeTheOneThatStartedCompletion -= 1
  endwhile

  let s:wordBeforeThePeriodAtTheStartOfOurCall = a:line[(l:startOfWordBeforeTheOneThatStartedCompletion):(l:startOfWordThatStartedCompletion)]

  if match(s:wordBeforeThePeriodAtTheStartOfOurCall,'\u') < 0
    let s:thePeriodIsAfteraClass = 0
  else
    let s:thePeriodIsAfteraClass = 1
  endif
endfun

fun! SCCompleteCheckForMethodArgs(line, start)
  let startOfWordThatStartedCompletion= copy(a:start-2)
  let startOfWordBeforeTheOneThatStartedCompletion= copy(a:start-2)
  while l:startOfWordBeforeTheOneThatStartedCompletion > 0 && a:line[l:startOfWordBeforeTheOneThatStartedCompletion- 1] =~ '\a'
    let l:startOfWordBeforeTheOneThatStartedCompletion -= 1
  endwhile

  let s:wordBeforeTheParenthesisAtTheStartOfOurCall = a:line[(l:startOfWordBeforeTheOneThatStartedCompletion):(l:startOfWordThatStartedCompletion)]

  if match(s:wordBeforeTheParenthesisAtTheStartOfOurCall,'\u') < 0
    let s:theParenthesisIsAfteraClass = 0
    let s:theParenthesisIsAfteraMethod = 1
  else
    let s:theParenthesisIsAfteraClass = 1
    let s:theParenthesisIsAfteraMethod = 0
  endif
endfun

fun! SCCompleteAddItemsToListAccordingToKind(item, list, forClass)
  let l:kind = a:item['kind']

  if s:theStringIsAfteraParenthesis
    call add(a:list, {'word': "Here we should be displaying arguments!!", 'menu': a:item['class'] , 'kind': l:kind})
    if s:theParenthesisIsAfteraClass
    endif
  endif

  " echom s:theStringIsAfteraPeriod

 if s:theStringIsAfteraPeriod
   " TODO For acting upon end of completion, see the |CompleteDone| autocommand event.
    if s:thePeriodIsAfteraClass
      if l:kind ==# "M" && (a:item['class'] ==# ('Meta_' . a:forClass))
        call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': l:kind})
      endif
    elseif ( l:kind ==# "m" )  && ( a:item['class'] ==# a:forClass )
      " echom a:item['class'] . "   " . a:forClass
      call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': l:kind})
    elseif ( s:theVariableWasSuccesfullyresolved == 0 ) && ( a:item['kind'] ==# "m" )
      " echom a:item['class'] . "   " . a:forClass
      call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': l:kind})
    endif
  elseif ( l:kind ==# "c" ) "&& ( s:theStringIsAfteraPeriod == 0 )
    call add(a:list, {'word':a:item['name'], 'kind': l:kind})
  endif
endfun

" debuging ============
" if a:item['class'] ==# 'Meta_GameLoop'
"   echom "-------------------------------------------------------------------------------------------------"
"   echom a:item['kind']
"   echom a:item['class']
"   echom a:forClass
"   echom a:item['name'] . a:item['methodArgs']
" endif
" ======================


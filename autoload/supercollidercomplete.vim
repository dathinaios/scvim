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


"TODO
"Have a good default result for when completion is called without anything
"being typed yet. Would be useful to have all the methods to choose from
"and type front and back to see if something exists.

" SuperCollider kinds
" c  classes
" m  instance methods
" M  class methods
"

fun! supercollidercomplete#Complete(findstart, base)
  if a:findstart
    return SCCompleteFindStart(getline('.'), col('.'))
  else
    let list_with_result_of_taglist = []

    "get superclasses in a list as it is useful information for later filtering
    if s:theVariableWasSuccesfullyresolved
      let superClassesString = taglist("^" . s:classFoundAfterVariableResolution . "$")[0]['classTree']
      let superClassList = split(superClassesString, ';')
    elseif s:wordBeforeThePeriodAtTheStartOfOurCall != ""
      let superClassesString = taglist("^" . s:wordBeforeThePeriodAtTheStartOfOurCall . "$")[0]['classTree']
      let superClassList = split(superClassesString, ';')
    endif

    if s:theStringIsAfteraParenthesis
      let baseString = substitute(a:base, '(', '', 'g')
      let matches = taglist("^" . l:baseString)
      let s:wordBeforeParenthesis = l:baseString
    else
      let baseString = a:base
      let matches = taglist("^" . l:baseString)
    endif
    
    " echom "---------------------------------------------------------------"
    " for it in matches
    "   if it['class'] == "ArrayedCollection"
    "     echom it['name'] . "   :    "  . it['class']
    "   endif
    " endfor
    " echom "---------------------------------------------------------------"

    let s:columnOfCompletionStart = col('.')
    for item in l:matches
      if CheckIfListContains(superClassList, item['class']) "if a class method
        call SCCompleteIterateThroughSupeClasses(item, list_with_result_of_taglist, l:matches)
        break " break out of the main search as we have started a new iteration
      elseif s:theVariableWasSuccesfullyresolved && CheckIfListContains(superClassList, item['class']) " TODO if the class precedes one of the superclasses the method is overwritten by the superclass for example GameLoop.n
        call SCCompleteIterateThroughSupeClasses(item, list_with_result_of_taglist, l:matches)
        break " break out of the main search as we have started a new iteration
      elseif s:theVariableWasSuccesfullyresolved == 0 && ( item['kind'] ==# "m")        
        call SCCompleteAddItemsToListAccordingToKind(item, list_with_result_of_taglist, item['class'])
      elseif item['kind'] ==# "c"
        call SCCompleteAddItemsToListAccordingToKind(item, list_with_result_of_taglist, item['class'])
      endif
    endfor
    return list_with_result_of_taglist
  endif
endfun

fun! CheckIfListContains(list, string)
  for item in a:list
    if item == a:string
      let result = 1
      break
    else
      let result = 0
    endif
  endfor
  return result
endfun

fun! SCCompleteIterateThroughSupeClasses(item, list, matches)
  let superClassList = split(a:item['classTree'], ';')
  for classFromSuperClassList in superClassList
    for matchedItem in a:matches
      call SCCompleteAddItemsToListAccordingToKind(matchedItem , a:list, classFromSuperClassList )
    endfor
  endfor
endfun

fun! SCCompleteResolveVariableToClass()
  let l:foundVariable = search(s:wordBeforeThePeriodAtTheStartOfOurCall . '\s*=\s*\w', 'b')
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

  if a:line[a:column - 2] == "("
    let start = a:column - 2
  else
    let start = a:column - 1
  endif

  "TODO when finding the start with \a it stops in numbers and this methods
  "like fill2D will not get matched
  
  while start > 0 && a:line[start - 1] =~ '\a'
    let start -= 1
  endwhile

  call SCCompleteCheckForMethodArgs(a:line, start)
  call SCCompleteCheckForParenthesisAtStart(a:line, start)
  call SCCompleteCheckForPeriodAtStart(a:line, start)
  call SCCompleteCheckForClassMethod(a:line, start)
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
  if a:line[col('.') - 2] == "("
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



fun! SCCompleteAddItemsToListAccordingToKind(item, list, forClass)

  " echom "---------------------------------------------------------------"
  " echom "general INFO" . " " . a:item['class'] . " " . a:item['kind']
  " echom "---------------------------------------------------------------"
  
  if s:theStringIsAfteraParenthesis
    if s:theStringIsAfteraPeriod
      if s:thePeriodIsAfteraClass
        if a:item['kind'] ==# "M" && (a:item['class'] ==# ('Meta_' . a:forClass)) && (s:wordBeforeParenthesis == a:item['name'])
          call add(a:list, {'word': a:item['name'] .  a:item['methodArgs'], 'menu': a:item['class'], 'kind': a:item['kind']})
        endif
      elseif (s:theVariableWasSuccesfullyresolved == 1) && ( a:item['kind'] ==# "m" )  && ( a:item['class'] ==# a:forClass )
        call add(a:list, {'word': a:item['name'] . a:item['methodArgs'], 'menu': a:item['class'], 'kind': a:item['kind']})
      elseif ( s:theVariableWasSuccesfullyresolved == 0 ) && ( a:item['kind'] ==# "m" ) && (s:wordBeforeParenthesis == a:item['name'])
        call add(a:list, {'word': a:item['name'] . a:item['methodArgs'], 'menu': a:item['class'], 'kind': a:item['kind']})
      endif
    endif
  endif

  if s:theStringIsAfteraParenthesis == 0
    if s:theStringIsAfteraPeriod
      if s:thePeriodIsAfteraClass
        if a:item['kind'] ==# "M" && (a:item['class'] ==# ('Meta_' . a:forClass))
          call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': a:item['kind']})
        endif
      elseif (s:theVariableWasSuccesfullyresolved == 1) && ( a:item['kind'] ==# "m" )  && ( a:item['class'] ==# a:forClass )
        call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': a:item['kind']})
      elseif ( s:theVariableWasSuccesfullyresolved == 0 ) && ( a:item['kind'] ==# "m" )
        call add(a:list, {'word':a:item['name'], 'menu': a:item['class'] . " - " . a:item['methodArgs'], 'kind': a:item['kind']})
      endif
    elseif ( a:item['kind'] ==# "c" ) "&& ( s:theStringIsAfteraPeriod == 0 )
      call add(a:list, {'word':a:item['name'], 'kind': a:item['kind']})
    endif
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
"
"
"
" EXPERIMENTS

fun! SCCompleteCheckForMethodArgs(line, start)
  " let placeAfterParenthesis = copy(a:start-1)
  " let startOfWordBeforeParenthesis = copy(a:start-2)
  " while l:startOfWordBeforeParenthesis > 0 && a:line[l:startOfWordBeforeParenthesis- 1] =~ '\a'
  "   let l:startOfWordBeforeParenthesis -= 1
  " endwhile

  " let s:wordBeforeThePeriodBeforeTheWordBeforeTheParenthesis = a:line[(l:startOfWordBeforeParenthesis):(l:placeAfterParenthesis - 1)]

  " " -------------------------
  " " TRYING -------------------------
  " let  l:startOfWordBeforeTheOneBeforeTheParenthesis = copy(l:startOfWordBeforeParenthesis)
  " while l:startOfWordBeforeTheOneBeforeTheParenthesis > 0 && a:line[l:startOfWordBeforeParenthesis- 1] =~ '\a'
  "   let l:startOfWordBeforeTheOneBeforeTheParenthesis -= 1
  "   echom "--------------------------->     " . l:startOfWordBeforeTheOneBeforeTheParenthesis
  " endwhile
  " -------------------------

  " if match(s:wordBeforeThePeriodBeforeTheWordBeforeTheParenthesis,'\u') < 0
  "   let s:theParenthesisIsAfteraClass = 0
  "   let s:theParenthesisIsAfteraMethod = 1
  "   echom "It is a method!!  " . s:wordBeforeThePeriodBeforeTheWordBeforeTheParenthesis
  "   let s:wordBeforeParenthesis =  a:line[(l:startOfWordBeforeParenthesis):(l:placeAfterParenthesis)]
  " else
  "   let s:theParenthesisIsAfteraClass = 1
  "   let s:theParenthesisIsAfteraMethod = 0
  "   echom "It is a class!!  " . s:wordBeforeThePeriodBeforeTheWordBeforeTheParenthesis
  "   let s:wordBeforeParenthesis =  a:line[(l:startOfWordBeforeParenthesis):(l:placeAfterParenthesis)]
  " endif
endfun

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
"                                                   2015 Dionysis Athinaios "
"                                                This file is part of SCVIM "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" TODO allow for more clever completion of method arguments
" TODO when creating the tags in SCVim.sc I add parenthesis only to remove
" them on this script!

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
      let l:taglistForSuperClasses = taglist("^" . s:classFoundAfterVariableResolution . "$")
      if len(l:taglistForSuperClasses) != 0
        let superClassesString = l:taglistForSuperClasses[0]['classTree']
        let superClassList = split(superClassesString, ';')
      else
        let l:superClassList = []
      endif
    elseif s:wordBeforeThePeriodAtTheStartOfOurCall != ""
      let l:taglistForSuperClasses = taglist("^" . s:wordBeforeThePeriodAtTheStartOfOurCall . "$")
      if len(l:taglistForSuperClasses) != 0
        let superClassesString = l:taglistForSuperClasses[0]['classTree']
        let superClassList = split(superClassesString, ';')
      else
        let l:superClassList = []
      endif
    endif

    if s:theStringIsAfteraParenthesis
      let baseString = substitute(a:base, '(', '', 'g')
      let matches = taglist("^" . l:baseString)
      let s:wordBeforeParenthesis = l:baseString
    else
      let baseString = a:base
      if baseString == ""
        " make sure we dont find a match without given letter
        let baseString = "€"
      endif
      let matches = taglist("^" . l:baseString)
    endif
    
    let s:columnOfCompletionStart = col('.')
    for item in l:matches
      if CheckIfListContains(superClassList, item['class']) "if a class method
        call SCCompleteIterateThroughSupeClasses(superClassList, list_with_result_of_taglist, l:matches)
        break " break out of the main search as we have started a new iteration
      elseif s:theVariableWasSuccesfullyresolved && CheckIfListContains(superClassList, item['class'])
        call SCCompleteIterateThroughSupeClasses(superClassList, list_with_result_of_taglist, l:matches)
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
  if len(a:list) != 0
    for item in a:list
      if item == a:string
        let result = 1
        break
      else
        let result = 0
      endif
    endfor
  else
    let result = 0
  endif
  return result
endfun

fun! SCCompleteIterateThroughSupeClasses(sclassList, listForResults, matches)
  for classFromSuperClassList in a:sclassList
    for matchedItem in a:matches
      call SCCompleteAddItemsToListAccordingToKind(matchedItem , a:listForResults, classFromSuperClassList )
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
  
  while start > 0 && a:line[start - 1] =~ '\w'
    let start -= 1
  endwhile

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
          " let argString = substitute(a:item['methodArgs'], '[()]', '', 'g')
          let argString = a:item['methodArgs']
          " let argString = substitute(argString, '=', ':', 'g')
          call add(a:list, {'word': a:item['name'] . '(' . argString , 'menu': a:item['class'], 'kind': a:item['kind']})
          " let g:supecolliderCompleteCurrentMethodArguments = split(l:argString, ',')
          " au! CompleteDone <buffer> call EnableAutocommandForMethodArgumentCompletion()
          " call feedkeys(" ")
        endif
      elseif (s:theVariableWasSuccesfullyresolved == 1) && ( a:item['kind'] ==# "m" )  && ( a:item['class'] ==# a:forClass )
          let argString = a:item['methodArgs']
        " let argString = substitute(argString, '=', ':', 'g')
        call add(a:list, {'word': a:item['name'] . '(' . argString , 'menu': a:item['class'], 'kind': a:item['kind']})
      elseif ( s:theVariableWasSuccesfullyresolved == 0 ) && ( a:item['kind'] ==# "m" ) && (s:wordBeforeParenthesis == a:item['name'])
          let argString = a:item['methodArgs']
        " let argString = substitute(argString, '=', ':', 'g')
        call add(a:list, {'word': a:item['name'] . '(' . argString , 'menu': a:item['class'], 'kind': a:item['kind']})
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

fun! EnableAutocommandForMethodArgumentCompletion()
  call complete(col('.'), g:supecolliderCompleteCurrentMethodArguments)
  au! CompleteDone <buffer>
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

" fun! SCCompleteCheckForMethodArgs(line, start)
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
" endfun

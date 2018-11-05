function! wild#cmdline#substitute#do(ctx) abort
  call wild#cmdline#substitute#parse(a:ctx)
endfunction

function! wild#cmdline#substitute#parse(ctx) abort
  " returns [{delimiter}, {from}, {delimiter}, {to}, {delimiter}, {flags}]

  if a:ctx.pos >= len(a:ctx.cmdline)
    return []
  endif

  let l:cmd_start = a:ctx.pos

  let l:delimiter = a:ctx.cmdline[a:ctx.pos]

  " delimiter cannot be alphanumeric, '\' or '|', see E146
  if l:delimiter >=# 'a' && l:delimiter <=# 'z' ||
        \ l:delimiter >=# 'A' && l:delimiter <=# 'Z' ||
        \ l:delimiter >=# '0' && l:delimiter <=# '9' ||
        \ l:delimiter ==# '\' || l:delimiter ==# '|'
    return []
  endif

  let l:result = [l:delimiter]

  let a:ctx.pos += 1
  let l:arg_start = a:ctx.pos

  " delimiter not reached
  if !wild#cmdline#skip_regex#do(a:ctx, l:delimiter)
    let l:result += [a:ctx.cmdline[l:arg_start :]]
    let a:ctx.pos = l:cmd_start
    return l:result
  endif

  let l:result += [a:ctx.cmdline[l:arg_start : a:ctx.pos - 1]]

  " skip delimiter
  let a:ctx.pos += 1
  let l:arg_start = a:ctx.pos
  let l:result += [l:delimiter]

  let l:delimiter_reached = 0

  while a:ctx.pos < len(a:ctx.cmdline)
    if a:ctx.cmdline[a:ctx.pos] ==# '\' &&
          \ a:ctx.pos + 1 < len(a:ctx.cmdline)
      let a:ctx.pos += 1
    elseif a:ctx.cmdline[a:ctx.pos] ==# l:delimiter
      let l:delimiter_reached = 1

      break
    endif

    let a:ctx.pos += 1
  endwhile

  if !l:delimiter_reached
    let l:result += [a:ctx.cmdline[l:arg_start :]]
    let a:ctx.pos = l:cmd_start
    return l:result
  endif

  let l:result += [a:ctx.cmdline[l:arg_start : a:ctx.pos - 1]]

  " skip delimiter
  let a:ctx.pos += 1
  let l:arg_start = a:ctx.pos
  let l:result += [l:delimiter]

  " consume until | or " is reached
  while a:ctx.pos < len(a:ctx.cmdline)
    if a:ctx.cmdline[a:ctx.pos] ==# '"'
      let a:ctx.pos = len(a:ctx.cmdline)

      return []
    elseif a:ctx.cmdline[a:ctx.pos] ==# '|'
      let a:ctx.pos += 1
      let a:ctx.cmd = ''

      call wild#cmdline#main#do(a:ctx)
      return []
    endif

    let a:ctx.pos += 1
  endwhile

  if a:ctx.pos != l:arg_start
    let l:result += [a:ctx.cmdline[l:arg_start :]]
  endif

  let a:ctx.pos = l:cmd_start

  return l:result
endfunction

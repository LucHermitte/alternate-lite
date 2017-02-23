"=============================================================================
" File:         addons/alternate-lite/autoload/lh/alternate.vim   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
" Version:      0.1.0.
let s:k_version = 010
" Created:      15th Nov 2016
" Last Update:  23rd Feb 2017
"------------------------------------------------------------------------
" Description:
"    Simplification of Michael Sharpe's alternate.vim plugin
"
" Objectives:
" - Support for project/buffer specific settings
" - Use dictionaries to set variables
" - lazy definition of functions through autoload plugin
"
" Licence:
"    We grant permission to use, copy modify, distribute, and sell this
"    software for any purpose without fee, provided that the above copyright
"    notice and this text are not removed. We make no guarantee about the
"    suitability of this software for any purpose and we are not liable for any
"    damages resulting from its use. Further, we are under no obligation to
"    maintain or extend this software. It is provided on an "as is" basis
"    without any expressed or implied warranty.
"
" Contributions:
" - Directory & regex enhancements added by Bindu Wavell who is well known on
" vim.sf.net
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#alternate#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#alternate#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#alternate#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Plugin initialisation {{{2
" Function: lh#alternate#register_extension(scope, ext, assoc [, uppercase]) {{{3
function! lh#alternate#register_extension(scope, ext, assoc, ...) abort
  let dict = lh#let#if_undef(a:scope.':alternates.extensions', {})
  if !has_key(dict, a:ext) " Don't use lh#let#* here as some extensions may contain dots...
    let dict[a:ext] = a:assoc
  endif
  if get(a:, '1', 0) " uppercase
    call lh#alternate#register_extension(a:scope, toupper(a:ext), map(copy(a:assoc), 'toupper(v:val)'))
  endif
endfunction

function! s:register_ft(ft, assoc, ...) abort " {{{3
  call lh#let#if_undef('g:alternates.fts.'.a:ft, a:assoc)
  if get(a:, '1', 0) " uppercase
    call s:register_ft(a:ft, map(copy(a:assoc), 'toupper(v:val)'))
  endif
endfunction

" # Fetch options {{{2
function! s:search_path(ft) abort " {{{3
  " TODO detect when a.vim's `g:alternateSearchPath` is set to something in
  " order to ensure retro compatibility
  let res = lh#ft#option#get('alternates.searchpath', a:ft)
  return res
endfunction

" Function: lh#alternate#expand_alternate_path(pathSpec, sfPath) {{{3
" Purpose  : {{{4
"            Expand path info.  A path with a prefix of "wdr:" will be
"            treated as relative to the working directory (i.e. the
"            directory where vim was started.) A path prefix of "abs:" will
"            be treated as absolute. No prefix or "sfr:" will result in the
"            path being treated as relative to the source file (see sfPath
"            argument).
"
"            A prefix of "reg:" will treat the pathSpec as a regular
"            expression substitution that is applied to the source file
"            path. The format is:
"
"              reg:<sep><pattern><sep><subst><sep><flag><sep>
"
"            <sep> seperator character, we often use one of [/|%#]
"            <pattern> is what you are looking for
"            <subst> is the output pattern
"            <flag> can be g for global replace or empty
"
"            EXAMPLE: 'reg:/inc/src/g/' will replace every instance
"            of 'inc' with 'src' in the source file path. It is possible
"            to use match variables so you could do something like:
"            'reg:|src/\([^/]*\)|inc/\1||' (see 'help :substitute',
"            'help pattern' and 'help sub-replace-special' for more details
"
"            NOTE: a.vim uses ',' (comma) internally so DON'T use it
"            in your regular expressions or other pathSpecs unless you update
"            the rest of the a.vim code to use some other seperator.
"
" Args     : pathSpec -- path component (or substitution patterns)
"            sfPath -- source file path
" Returns  : a path that can be used by AlternateFile()
" Author   : Bindu Wavell <bindu@wavell.net>
" Licence  : See a.vim licence
" }}}4
function! lh#alternate#_expand_alternate_path(pathSpec, sfPath) abort
  let prfx = strpart(a:pathSpec, 0, 4)
  if (prfx == "wdr:" || prfx == "abs:")
    let path = strpart(a:pathSpec, 4)
  elseif (prfx == "reg:")
    let re = strpart(a:pathSpec, 4)
    let sep = strpart(re, 0, 1)
    let patend = match(re, sep, 1)
    let pat = strpart(re, 1, patend - 1)
    let subend = match(re, sep, patend + 1)
    let sub = strpart(re, patend+1, subend - patend - 1)
    let flag = strpart(re, strlen(re) - 2)
    if (flag == sep)
      let flag = ''
    endif
    if a:sfPath =~ pat
      let path = substitute(a:sfPath, pat, sub, flag)
    else
      " LH, 24th Jan 2008: pattern not found => with "reg:" is rejected
      let path = ''
    endif
  else
    let path = a:pathSpec
    if (prfx == "sfr:")
      let path = strpart(path, 4)
    endif
    let path = a:sfPath . "/" . path
  endif
  return path
endfunction

" Function: lh#alternate#_alternate_dirnames(relPathBase [,ft]) {{{3
function! lh#alternate#_alternate_dirnames(relPathBase, ...) abort
  let ft = get(a:, '1', &ft)
  let pathSpecList = split(s:search_path(ft), ',')
  let res = []
  for pathSpec in pathSpecList
    let alt = lh#alternate#_expand_alternate_path(pathSpec, a:relPathBase)
    if !empty(alt)
      let res += [lh#path#simplify(alt)]
    endif
  endfor
  return res
endfunction

" Function: lh#alternate#_find_extentions(filename, ft) {{{3
" Get extensions associated to {ext} and those associated to {ft}
" Then filter extensions associated to {ext} that are valid for the given {ft}
" This filtering is important as a foo.h file could be associated to a foo.cpp
" and a foo.m, except the later doesn't make any sense in C nor in C++.
function! lh#alternate#_find_extentions(ext, ft) abort
  let alt_exts_for_ext = lh#ft#option#get('alternates.extensions.'.a:ext, a:ft)
  let alt_exts_for_ft  = lh#option#get('alternates.fts.'.a:ft)

  if     lh#option#is_set(alt_exts_for_ext) && lh#option#is_set(alt_exts_for_ft)
    return lh#list#intersect(alt_exts_for_ext, alt_exts_for_ft)
  elseif lh#option#is_set(alt_exts_for_ext) " && unset(4ft)
    call s:Verbose("No known extensions associated to %1 filetype", a:ft)
    return alt_exts_for_ext
  elseif lh#option#is_set(alt_exts_for_ft) " && unset(4ext)
    call s:Verbose("No known extensions associated to .%1", a:ext)
    return alt_exts_for_ft
  else
    return []
  endif
endfunction

" Function: lh#alternate#_find_alternates([{'filename': ..., 'ft': ...}]) {{{3
function! lh#alternate#_find_alternates(...) abort
  if a:0 > 0
    let ft       = a:1.ft
    let filename = a:1.filename
  else
    let ft       = &ft
    let filename = expand('%')
  endif
  let [dir, file, ext] = lh#alternate#_decomp_pathname(filename)
  let alt_dirs = lh#alternate#_alternate_dirnames(dir, ft)
  " keep only existing directories
  call filter(alt_dirs, 'isdirectory(v:val)')
  if empty(alt_dirs)
    " Accept the current dir in case none of the alternates exists
    let alt_dirs += [dir]
  endif

  let alt_exts = lh#alternate#_find_extentions(ext, ft)
  if empty(alt_exts)
    let msg = lh#fmt#printf("No known extensions associated to .%1, nor to %2 filetype either", ext, ft)
    call s:Verbose(msg." => abort")
    return lh#option#unset(msg)
  endif

  call s:Verbose("Extensions associated to %1 -> %2", filename, alt_exts)

  let alt_files_ext = map(copy(alt_exts), 'file.".".v:val')

  let alts = []
  for d in alt_dirs
    let alts += map(copy(alt_files_ext), 'd."/".v:val')
  endfor

  " Partition them according to "existing or not"
  let res = {
        \ 'existing': filter(copy(alts), 'lh#path#exists(v:val)')
        \,'theorical': filter(alts, '! lh#path#exists(v:val)')
        \ }
  call s:Verbose("Alternates for %1 are %2", filename, res)
  return res
endfunction

" Function: lh#alternate#_find_existing_alternates([{'filename': ..., 'ft': ...}]) {{{3
function! lh#alternate#_find_existing_alternates(...) abort
  let res = call('lh#alternate#_find_alternates', a:000)
  return res.existing
endfunction

" # Commands related {{{2
" Function: lh#alternate#_jump(cmd, ...) {{{3
" @param[in] {cmd} command opening action
" @param[in] {a:1} new extension
function! lh#alternate#_jump(cmd, ...) abort
  " 1- Find all matching files
  let files = lh#alternate#_find_alternates() " on current file
  if lh#option#is_unset(files)
    call lh#common#warning_msg('Alternate: '.files.__msg)
    return
  endif

  " 2- Find the file to open/jump-to
  if a:0 > 0
    let extention = a:1
    let matching = filter(files.existing+files.theorical, 'v:val =~ extention."$"')
    if empty(matching)
      throw "Cannot find an alternate for the current file in `.".extention."`"
    else
      call lh#assert#equal(1, len(matching), "There should be only one valid file ending in `.".extention."`")
      let selected_file = matching[0]
    endif
  else
    if len(files.existing) == 1
      let selected_file = files.existing[0]
    else
      if !empty(files.existing)
        let lFiles = files.existing
      else
        let lFiles = files.theorical
      endif
      let selected_file = lh#path#select_one(lFiles, "What should be the name of the new file?")
    endif
  endif

  " 3- Jump to that file
  if !empty(selected_file)
    let all_files = [expand('%')]+files.existing+files.theorical
    call lh#let#to('b:alternates.__all_files', all_files)
    call lh#buffer#jump(selected_file, a:cmd)
    " We may set the option twice, it's not important.
    call lh#let#to('b:alternates.__all_files', all_files)
  endif
endfunction

" Function: lh#alternate#_next(bang) {{{3
function! lh#alternate#_next(bang) abort
  if exists('b:alternates.__all_files')
    let all_files = b:alternates.__all_files
    let files = {
          \ 'existing': filter(copy(all_files), 'lh#path#exists(v:val)')
          \,'theorical': filter(copy(all_files), '! lh#path#exists(v:val)')
          \ }
  else
    let files = lh#alternate#_find_alternates()
    let all_files = [expand('%')]+files.existing+files.theorical
  endif
  " TODO: handle possible change of directories...
  let crt_idx = index(files.existing, expand('%'))
  if crt_idx >= 0
    let nxt_idx = (crt_idx + 1) % len(files.existing)
    if nxt_idx != crt_idx
      call lh#let#to('b:alternates.__all_files', all_files)
      call lh#buffer#jump(files.existing[nxt_idx], "e".a:bang)
    endif
  endif
endfunction

" Function: lh#alternate#_complete(ArgLead, CmdLine, CursorPos) {{{3
function! lh#alternate#_complete(ArgLead, CmdLine, CursorPos) abort
  let ft       = &ft
  let filename = expand('%')
  let [dir, file, ext] = lh#alternate#_decomp_pathname(filename)
  let alt_exts = lh#alternate#_find_extentions(ext, ft)

  call filter(alt_exts, 'v:val =~ a:ArgLead')
  return alt_exts
endfunction

" ## Initialize options {{{1
" # Extensions {{{2
" - C, C++, cuda, and objective-C {{{3
call lh#alternate#register_extension('g', 'h',   ['c', 'cpp', 'cxx', 'cc', 'txx', 'inc', 'm', 'mm', 'cu'], 1)
call lh#alternate#register_extension('g', 'hpp', ['cpp', 'inc'], 1)
call lh#alternate#register_extension('g', 'hxx', ['cxx', 'inc', 'txx'], 1)
call lh#alternate#register_extension('g', 'hh',  ['cc', 'inc', 'mm'], 1)
call lh#alternate#register_extension('g', 'c',   ['h', 'inc'], 1)
call lh#alternate#register_extension('g', 'cpp', ['h', 'hpp', 'inc'], 1)
call lh#alternate#register_extension('g', 'cc',  ['h', 'hh', 'inc'], 1)
call lh#alternate#register_extension('g', 'cxx', ['h', 'hxx', 'inc'], 1)
call lh#alternate#register_extension('g', 'txx', ['h', 'hxx', 'inc'], 1)
call lh#alternate#register_extension('g', 'inc', ['h', 'hpp', 'hh','hxx', 'c', 'cpp', 'cxx', 'txx'], 1)
call lh#alternate#register_extension('g', 'm',   ['h'], 1)
call lh#alternate#register_extension('g', 'mm',  ['h', 'hh'], 1)
call lh#alternate#register_extension('g', 'cu',  ['h'], 1)
call s:register_ft('c', ['h', 'c', 'inc'], 1)
call s:register_ft('cpp', ['hpp', 'h', 'cpp', 'cxx', 'cc', 'H', 'C', 'txx', 'inc'], 1)
call s:register_ft('cuda', ['h', 'cu'])
call s:register_ft('objc', ['h', 'm'], 1)
call s:register_ft('objcpp', ['h', 'm', 'mm'], 1)
" - PSL7 {{{3
call lh#alternate#register_extension('g', 'psl', ['psh'])
call lh#alternate#register_extension('g', 'psh', ['psl'])
call s:register_ft('psl', ['psl', 'psh'])
" - ADA {{{3
call lh#alternate#register_extension('g', 'adb', ['ads'])
call lh#alternate#register_extension('g', 'ads', ['adb'])
call s:register_ft('ada', ['adb', 'ads'])
" - lex and yacc {{{3
call lh#alternate#register_extension('g', 'l',       ['y', 'yacc', 'ypp'])
call lh#alternate#register_extension('g', 'lex',     ['yacc', 'y', 'ypp'])
call lh#alternate#register_extension('g', 'lpp',     ['ypp', 'y', 'yacc'])
call lh#alternate#register_extension('g', 'y',       ['l', 'lex', 'lpp'])
call lh#alternate#register_extension('g', 'yacc',    ['lex', 'l', 'lpp'])
call lh#alternate#register_extension('g', 'ypp',     ['lpp', 'l', 'lex'])
" - OCaml {{{3
call lh#alternate#register_extension('g', 'ml',      ['mli'])
call lh#alternate#register_extension('g', 'mli',     ['ml'])
" - ASP {{{3
call lh#alternate#register_extension('g', 'aspx.cs', [ 'aspx'])
call lh#alternate#register_extension('g', 'aspx.vb', [ 'aspx'])
call lh#alternate#register_extension('g', 'aspx',    [ 'aspx.cs', 'aspx.vb'])

" # Paths {{{2
call lh#let#to('g:alternates.searchpath', 'sfr:../source,sfr:../src,sfr:../include,sfr:../inc')

"------------------------------------------------------------------------
" ## Exported functions {{{1
function! s:extensions(...) abort " {{{2
  let ft = get(a:, '1', &ft)
  return lh#ft#option#get_all('alternates.extensions', ft)
endfunction

" Function: lh#alternate#_decomp_pathname(pathname[, ft]) {{{2
" Replaces a.vim DetermineExtension()
" Purpose  : Determines the extension of a filename based on the register
"            alternate extension. This allow extension which contain dots to
"            be considered. E.g. foo.aspx.cs to foo.aspx where an alternate
"            exists for the aspx.cs extension.
" History  : idea from Tom-Erik Duestad
" Notes    : - unlike DetermineExtension(), no magic here (except /\v)
"            - no limitation on the number of dots
function! lh#alternate#_decomp_pathname(pathname, ...) abort
  let ft = get(a:, '1', &ft)
  let dir  = fnamemodify(a:pathname, ':h')
  let file = fnamemodify(a:pathname, ':t')
  let regex = '\v\.('.escape(join(keys(s:extensions(ft)), '|'), '.').')$'
  call s:Verbose('Path decomp regex: %1', regex)
  let p = match(file, regex)
  if p >= 0
    let ext  = file[(p+1) : ]
    let file = file[ : (p-1)]
  else
    let ext  = fnamemodify(file, ':e')
    let file = fnamemodify(file, ':r')
  endif
  call s:Verbose("Decomp for %1 (%2 / %3 + .%4)", a:pathname, dir, file, ext)
  return [dir, file, ext]
endfunction

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

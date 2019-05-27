"=============================================================================
" File:         plugin/alternate-lite.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/alternate-lite>
" Version:      0.1.3
let s:k_version = '0.1.3'
" Created:      23rd Feb 2017
" Last Update:  27th May 2019
"------------------------------------------------------------------------
" Description:
"    Simplification of Michael Sharpe's alternate.vim plugin
"
" Objectives:
" - Support for project/buffer specific settings
" - Use dictionaries to set variables
" - lazy definition of functions through autoload plugin
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

" ## Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim

if &cp || (exists("g:loaded_alternate_lite")
      \ && (g:loaded_alternate_lite >= s:k_version)
      \ && !exists('g:force_reload_alternate_lite'))
  let &cpo=s:cpo_save
  finish
endif
let g:loaded_alternate_lite = s:k_version

" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" ## Functions (always loaded) {{{1
function! s:warn_a_vim_is_installed()
  echomsg "WARNING:"
  echomsg "  It seems you have installed a.vim plugin *and* alternate-lite plugin (likelly through lh-cpp)."
  echomsg "  alternate-lite can be subtituted to a.vim. It only misses :IS* commands and related mappings."
  echomsg "  In order to remove this message,"
  echomsg "   - either remove a.vim from your configuration"
  echomsg "   - or add the following line into your .vimrc:"
  echomsg "     :let g:loaded_alternate_lite = 'noway'"
  echomsg "  Please note that a.vim is currently overridden!"
endfunction

"------------------------------------------------------------------------
" ## Commands and Mappings {{{1
if exists(':AS') && get(g:, 'loaded_alternateFile', '') !~ '^blocked'
  call s:warn_a_vim_is_installed()
endif

command! -nargs=? -bang -complete=customlist,lh#alternate#_complete A  call lh#alternate#_jump("e<bang>",      <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AS call lh#alternate#_jump("sp<bang>",     <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AV call lh#alternate#_jump("vsp<bang>",    <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AT call lh#alternate#_jump("tab sp<bang>", <f-args>)
command! -nargs=0 -bang AN call lh#alternate#_next("<bang>")

" :IH* and related mappings are not provided as I already provide equivalent in
" SearchInRuntime.

"------------------------------------------------------------------------
" ## Initialize option {{{1
" # Paths {{{2
call lh#let#if_undef('g:alternates.searchpath', 'sfr:../source,sfr:../src,sfr:../include,sfr:../inc')

"------------------------------------------------------------------------
" ## Prevent a.vim from being loaded ? {{{1
"
" Note that you can load alternate-lite and THEN a.vim if you override
" g:lh#alternate.block_original_a_vim to 0 in your .vimrc.
call lh#let#if_undef('g:lh#alternate.block_original_a_vim', 1)
if g:lh#alternate.block_original_a_vim
  let g:loaded_alternateFile = 'blocked_by_alternate_lite_'.s:k_version
  " Check whether a.vim is installed
  if ! empty(globpath(&rtp, 'plugin/a.vim'))
    call s:warn_a_vim_is_installed()
  endif
endif

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

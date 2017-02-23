"=============================================================================
" File:         plugin/alternate-lite.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/alternate-lite>
" Version:      0.1.0
let s:k_version = '0.1.0'
" Created:      23rd Feb 2017
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
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
if &cp || (exists("g:loaded_alternate_lite")
      \ && (g:loaded_alternate_lite >= s:k_version)
      \ && !exists('g:force_reload_alternate_lite'))
  finish
endif
let g:loaded_alternate_lite = s:k_version
let s:cpo_save=&cpo
set cpo&vim

call lh#let#if_undef('g:lh#alternate.block_original', 1)
if g:lh#alternate.block_original
  let g:loaded_alternateFile = 'blocked_by_alternate_lite_'.s:k_version
endif

" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and Mappings {{{1
if exists(':AS') && get(g:, 'loaded_alternateFile', '') !~ '^blocked'
  " TODO: Warning and require user to choose what it whishes to use!
endif
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete A  call lh#alternate#_jump("e<bang>",      <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AS call lh#alternate#_jump("sp<bang>",     <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AV call lh#alternate#_jump("vsp<bang>",    <f-args>)
command! -nargs=? -bang -complete=customlist,lh#alternate#_complete AT call lh#alternate#_jump("tab sp<bang>", <f-args>)
command! -nargs=0 -bang AN call lh#alternate#_next("<bang>")

" :IH* and related mappings are not provided as I already provide equivalent in
" SearchInRuntime.
" Commands and Mappings }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

# alternate-lite  [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

## Features
This plugin is meant to be a simplification of Michael Sharpe's alternate.vim plugin.

The design decisions that distinguishes _alternate-lite_ from _alternate_ are the
following:

 * Support for project/buffer specific settings
 * Use dictionaries to set variables
 * Lazy definition of functions through autoload plugin
 * `:IH` commands and related mappings are already defined in my
   [SearchInRuntime plugin](http://github.com/LucHermitte/SearchInRuntime).

My main use case for this plugin is to build things like
[lh-cpp's `:GOTOIMPL` command](http://github.com/LucHermitte/lh-cpp).

## Commands

alternate-lite implements slightly differently all `:A` commands provided by
original `a.vim` plugin.

All these commands first deduce an alternate file for the current one. The
priority is given to files that exist. Then, they try to jump to the window
where this alternate file is displayed, if the file wasn't displayed, it'll be
opened:

 * In the current window with `:A`,
 * In a horizontally split opened window with `:AS`,
 * In a vertically split opened window with `:AV`,
 * In a new tab with `:AT`.

In case several alternate files are found, we'll be asked to choose which one
we wish to open or to jump-to.

The previous commands also take an optional parameter: the extension we wish
precisally to use to deduce the alternate file.

There is also the `:AN` command that permits to cycle through the buffers
associated to the current buffer. If possible, this command will search for a
window where the next buffer is already displayed.

## Options

Some usual extensions are already registered. This can be extended globally,
locally, on project basis, etc.
See [`lh#ft#option#get()`](https://github.com/LucHermitte/lh-dev#filetype-polymorphism).

You can obtain the latest status with a `:echo g:alternates.extensions`.

### Extension map
Let's say you want to register `.tpp` as a new extension for files where C++
template functions would be defined, you'll need to execute (in your `.vimrc`
for instance):

```vim
" The actual {extension -> extensions} map
call lh#alternate#register_extension('g', 'h'  , g:alternates.extensions.h + ['tpp'])
call lh#alternate#register_extension('g', 'hpp', g:alternates.extensions.hpp + ['tpp'])
call lh#alternate#register_extension('g', 'tpp', ['h', 'hpp'])

" The {filetype -> extensions} map
let g:alternates.ft.cpp += ['tpp']
```

This says that this new extension may be used in all your projects. If you
prefer to register it only in one project, with
[lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) project feature, you
could define instead:

```vim
" The actual {extension -> extensions} map
call lh#alternate#register_extension('p', 'h'  , g:alternates.extensions.h + ['tpp'])
call lh#alternate#register_extension('p', 'hpp', g:alternates.extensions.hpp + ['tpp'])
call lh#alternate#register_extension('p', 'tpp', ['h', 'hpp'])

" The {filetype -> extensions} map
let g:alternates.ft.cpp += ['tpp']
```

### Directory selection
The option `(bpg):[{ft}_]alternates.searchpath` can contain a comma separated
list of directory alternance policy:

 * A path with a prefix of `"wdr:"` will be treated as relative to the working
   directory.
 * A path prefix of `"abs:"` will be treated as absolute.
 * No prefix or `"sfr:"` will result in the path being treated as relative to the
   source file (see sfPath argument).

 * A prefix of `"reg:"` will treat the pathSpec as a regular expression
   substitution that is applied to the source file path. The format is:

   ```
   reg:<sep><pattern><sep><subst><sep><flag><sep>
   ```

   * `<sep>` seperator character, we often use one of `[/|%#]`
   * `<pattern>` is what you are looking for
   * `<subst>` is the output pattern
   * `<flag>` can be g for global replace or empty

Examples:

 * `'reg:/inc/src/g/'` will replace every instance of `'inc'` with `'src'` in
   the source file path. It is possible to use match variables so you could do
   something like: `'reg:|src/\([^/]*\)|inc/\1||'` (see `'help :substitute'`,
   `'help pattern'` and `'help sub-replace-special'` for more details

Note: ',' (comma) are used internally so DON'T use it in your regular expressions
or other pathSpecs.


## TODO
Many features from the original a.vim plugin are still missing, starting with
`:A*` commands. I should eventually define them. For now I just need a simpler
tool to define correctly
[lh-cpp's `:GOTOIMPL` command](http://github.com/LucHermitte/lh-cpp).

## Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib)

  * With [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), install alternate-lite. This is the preferred method because of the various dependencies.
```vim
ActivateAddons alternate-lite
```
  * or with [vim-flavor](http://github.com/kana/vim-flavor) which also supports
    dependencies:
```
flavor 'LucHermitte/alternate-lite'
```
  * or you can clone the git repositories (expecting I haven't forgotten anything):
```
git clone git@github.com:LucHermitte/lh-vim-lib.git
git clone git@github.com:LucHermitte/alternate-lite.git
```
  * or with Vundle/NeoBundle (expecting I haven't forgotten anything):
```vim
Bundle 'LucHermitte/lh-vim-lib'
Bundle 'LucHermitte/alternate-lite'
```

## Credits
 * Michael Sharpe for his original plugin
 * Directory & regex enhancements added by Bindu Wavell who is well known on
   vim.sf.net

## License
We grant permission to use, copy modify, distribute, and sell this software for
any purpose without fee, provided that the above copyright notice and this text
are not removed. We make no guarantee about the suitability of this software
for any purpose and we are not liable for any damages resulting from its use.
Further, we are under no obligation to maintain or extend this software. It is
provided on an "as is" basis without any expressed or implied warranty.


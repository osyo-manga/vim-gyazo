scriptencoding utf-8
if exists('g:loaded_gyazo')
  finish
endif
let g:loaded_gyazo = 1

let s:save_cpo = &cpo
set cpo&vim


command! -nargs=1 -bar -complete=file
\	GyazoPost
\	echo gyazo#post_from_image(<q-args>)

command! -nargs=1 -bar -complete=file
\	GyazoOpenBrowser
\	call OpenBrowser(gyazo#post_from_image(<q-args>))


command! -range=0 -bar
\	GyazoPostCurrentWindow
\	echo call("gyazo#post_from_current_window", <count> ? [{}, { "first" : <line1>, "last" : <line2>}] : [])

command! -range=0 -bar
\	GyazoOpenBrowserCurrentWindow
\	call OpenBrowser(call("gyazo#post_from_current_window", <count> ? [{}, { "first" : <line1>, "last" : <line2>}] : []))

let &cpo = s:save_cpo
unlet s:save_cpo

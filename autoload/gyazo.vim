scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:gyazo_root = substitute(expand("<sfile>:h:h"), '\\', '/', "g") . "/gyazo"

function! s:tempname(...)
	let result = tempname()
	if a:0 > 0
		let result = substitute(result, '\.tmp$', '\.' . a:1, "")
	endif
	return substitute(result, '\\', '/', "g")
endfunction


function! gyazo#make_html_from_current_window(...)
	let opt = extend({
\		"first"  : line("w0"),
\		"last"   : line("w$"),
\		"output" : s:tempname("html"),
\	}, get(a:, 1, {}))
	if opt.first > opt.last
		echoerr "Invalid last value."
		return ""
	endif
	call tohtml#Convert2HTML(opt.first, opt.last)
	try
		call writefile(getline(1, "$"), opt.output)
		return opt.output
	finally
		bw!
	endtry
endfunction


function! gyazo#make_html_from_current_window_full(...)
	return gyazo#make_html_from_current_window({
\	"first" : 1,
\	"last"  : line("$"),
\	"output" : a:0 >= 1 ? a:1 : s:tempname("html"),
\	})
endfunction


function! gyazo#make_png_from_html(...)
	let opt = extend({
\		"input"  : a:1,
\		"width"  : 600,
\		"output" : s:tempname("png"),
\	}, get(a:, 1, {}))

	if !filereadable(opt.input)
		echoerr "Not found : " . a:file
		return ""
	endif
	if !executable("phantomjs")
		echoerr "Please Install phantomjs."
		return ""
	endif
	let width = get(a:, 1, 600)
	let result = system(printf("phantomjs %s %s %s %d", s:gyazo_root."/capture.js", opt.input, opt.output, opt.width))
	if v:shell_error
		return ""
	endif
	return opt.output
endfunction


function! gyazo#make_png_from_current_window(...)
	let html_opt = get(a:, 2, {})
	let png_opt  = extend({
\		"input" : gyazo#make_html_from_current_window(html_opt),
\	}, get(a:, 1, {}))
	return gyazo#make_png_from_html(png_opt)
endfunction


function! gyazo#post_from_image(image)
	if !filereadable(a:image)
		echoerr "Not found : " . a:image
		return ""
	endif
	if !executable("ruby")
		echoerr "Please Install Ruby."
		return ""
	endif
	if fnamemodify(a:image, ":e") !=# "png"
		echoerr "Not png file"
		return ""
	endif
	let image = substitute(a:image, '\\', '/', "g")
	let result = system(printf("ruby %s %s", s:gyazo_root . "/gyazo.rb", image))
	let result = substitute(result, "\n", "", "g")
	let s:gyazo_last_post = result
	return result
endfunction

function! gyazo#last_post_url()
	return get(s:, "gyazo_last_post", "")
endfunction


function! gyazo#post_from_current_window(...)
	if executable("curl")
		if s:invalid_zsh_option()
			echoerr "Please add a setup 'setopt nonomatch' in .zshenv(not .zshrc)"
			return ""
		endif
		let html = call("gyazo#make_html_from_current_window", [get(a:000, 1, {})])
		let result = system(printf('curl -s -F file=@%s "http://trickstar.herokuapp.com/api/gyazo/upload/?width=%d"', html, 600))
		let s:gyazo_last_post = result
		return result
	else
		return gyazo#post_from_image(call("gyazo#make_png_from_current_window", a:000))
	endif
endfunction


function! s:invalid_zsh_option()
	let is_zsh_active = exists("$SHELL") && (stridx($SHELL, "zsh") !=# -1)
	return is_zsh_active && !s:is_zsh_option("nonomatch", "on")
endfunction

function! s:is_zsh_option(optname, expected_value)
	" ex) set -o | grep nonomatch
	"
	" nonomatch             off
	let option = system('set -o | grep ' . a:optname)
	let matched = matchstr(option, printf('%s\s\+%s', a:optname, a:expected_value))
	return !empty(matched)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

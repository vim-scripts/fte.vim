" vim:ff=unix ts=4 ss=4
" vim60:fdm=marker
"
"	\brief	codefragments_menu.vim: Vim menu built from a directory, based on
"			colormenu.vim by Geoff Reedy
"
" \author	Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
" \date		Fri, 13 Dec 2002 10:35 Pacific Standard Time
" \$Id: codefragments_menu.vim,v 1.3 2002/11/13 06:56:48 root Exp $
" Version:	0.3
" History: {{{
"	[Feral:316/02@22:25] 0.3
"	Now uses g:fte_template_path as the location for the templates to make the
"	menu from; defaults to ~/.vim/template/
"	[Feral:283/02@18:33] 0.2
"	Improvments:
"	* Catagorizes into submenus by extensions.
"
"	0.1
"	Initial based on colormenu.vim by Geoff Reedy
" }}}

if exists("loaded_codefragments_menu")
	finish
endif
let loaded_codefragments_menu = 1


if exists("g:fte_template_path")
	let s:CodeFragFolder = substitute(g:fte_template_path.'', '\(\|/\|\\\)\(\|/\|\\\)$', '/', '')
else
	let s:CodeFragFolder = '~/.vim/template/'
endif

function! s:Feral_Codefragments_ReloadMenu()
"	call confirm(s:CodeFragFolder)
	aunmenu Co&deFragmets
	amenu Co&deFragmets.Reload						<Esc><Esc>:call <SID>Feral_Codefragments_ReloadMenu()<CR>
	amenu Co&deFragmets.&Open\ Explorer\ Window		<Esc><Esc>:call <SID>Feral_Codefragments_OpenExplorerWindow()<CR>
	amenu Co&deFragmets.-Sep-						:
	" Cpp.Crt
	call s:AddMenuItems('&Cpp.C&rt', 'cpp/crt/*.cpp')
	call s:AddMenuItems('&Cpp.C&rt', 'cpp/crt/*.h')
	" Cpp.Sdk
	call s:AddMenuItems('&Cpp.&Sdk', 'cpp/sdk/*.cpp')
	call s:AddMenuItems('&Cpp.&Sdk', 'cpp/sdk/*.h')
	" Cpp.Torque
	call s:AddMenuItems('&Cpp.&Torque', 'cpp/tor/*.cc')
	call s:AddMenuItems('&Cpp.&Torque', 'cpp/tor/*.h')
	" TorqueScript -- .cs
	call s:AddMenuItems('&TorqueScript', 'torquescript/*.cs')
	" Cpp. misc
	call s:AddMenuItems('&Cpp', 'cpp/*.cpp')
	call s:AddMenuItems('&Cpp', 'cpp/*.h')
	" Html -- .html
	call s:AddMenuItems('&Html', 'html/*.html')
	" Ftf -- .ftf
	call s:AddMenuItems('&FTF', 'ftf/*.ftf')
	" Vim -- .vim
	call s:AddMenuItems('&Vim', 'vim/*.vim')
	" BUG -- .bug (and .note)
	call s:AddMenuItems('&Bug', 'bug/*.bug')

endfunction

" MenuPathPrefix can be '', if it is then no submenu is created, else it is
"	the name of the subment to place the files found in the globpattern
"	TheFiles.
" TheFiles is the globpattern used to fill the (sub)menu. *.cpp as an example.
function s:AddMenuItems(MenuPathPrefix, TheFiles) " {{{
	let GlobedFiles = globpath(s:CodeFragFolder, a:TheFiles)
"	echo confirm(GlobedFiles)

	" Ignore unfound entries.
	if strlen(GlobedFiles) == 0
		return
	endif

	let GlobedFiles = GlobedFiles . "\n" "[Feral:242/02@12:23] add a last \n so we break out AFTER the last entry.
	while strlen(GlobedFiles) > 0
		let newline = stridx(GlobedFiles, "\n")
		if newline == -1
			break
		endif
		let current = strpart(GlobedFiles, 0, newline)
		let GlobedFiles = strpart(GlobedFiles, newline+1)
		let Fname = fnamemodify(current, '%:t')
		let PacifiedName = '.'.escape(fnamemodify(current, ':t'), ' \\.')
		if a:MenuPathPrefix != ""
			let PacifiedName = '.'.a:MenuPathPrefix.PacifiedName
		endif
		execute ('amenu Co&deFragmets'.PacifiedName.' <Esc><Esc>:FLT '.Fname.'<cr>')
	endwhile
	unlet current
	unlet Fname
	unlet PacifiedName
	unlet GlobedFiles
endfunction
" }}}



amenu Co&deFragmets.dummy :
call s:Feral_Codefragments_ReloadMenu()


function <SID>Feral_Codefragments_OpenExplorerWindow()
	if has("gui_running")
		if has("win32")
			execute "!start explorer.exe ".expand(s:CodeFragFolder)
		endif
	endif
endfunc


"EOF

"	vim:ff=unix ts=4 ss=4
"	vim60:fdm=marker
"	\file		fte.vim
"
"	\brief		VIM6.0+ Global plugin to expand and load templates.
"				«expression» format supported.
"	\note		That the loading and expanding are two SEPERATE functions.
"				This is deliberate so that you can load how you like (or even
"				expand how you like) Note also that it is a 3 stage process
"				(load, modify, expand) to expand a template from start to
"				finish. This is also deliberate, see below.
"	\note		Bits and pieces and ideas and sniplets from templatefile.vim
"				1.5 and mu-template.vim 0.11, many thanks to the authors of
"				those two scripts.
"	\note		This should probably be called vts - VIM template system,
"				assuming people use this that is :)
"	Last Changed:
"	\date		Sun, 18 May 2003 21:38 Pacific Daylight Time
"	Maintainer:
"	\author		Robert KellyIV <Sreny@SverGbc.Pbz> (Rot13ed)
"	\author		Many usefull comments and suggestions from Luc Hermitte
"	\version	$Id: fte.vim,v 1.16 2002/12/07 02:38:11 Feral Exp $
"	Version:	0.42
"	History: {{{
"	[Feral:340/02@18:35] 0.42
"	Bugfix:
"		Refined how vars are unlet and fixed bug pertaining to pattern
"		matching `Parse prompts, script variable style`; We were matching a
"		register style prompt (because we were using '*', now using '\+')
"	[Feral:340/02@06:37] 0.41
"	Bugfix:
"		Refined DaFile_ext and DaFile and where they are inserted;
"	[Feral:340/02@05:54] 0.40
"		Rewrote s:FeralTemplateExpansion().... Now hopefully it will work like
"			the last version should have (I don't think either a lot of :s :g
"			or SOMETHING the last version did works right.). Anyway...
"	Improvements:
"		Processes the template sequentually, except for prompt comments and
"			unlet/restor of vars. This means that if you want to use a var you
"			must define it before you use it, just as you would expect (which
"			is NOT how the last version worked).
"		Mu-Template ¡¡ and ¿¿ format fully supported. Yea, so this is not
"			secure, know thy templates!
"		To reiterate, there are now three main passes in the expansionn
"			process: first Preproecessing is done (prompt comments are
"			removed), then the template is expanded (see the script at the
"			moment for the order things are done) then cleanup is done(vars
"			are unlet/optional restore of registers; FTE: lines deleted) and
"			then finaly the cursor is placed.
"	Possible Hazards:
"		Removed my band-aid fixes to weird-can't-do-that undo errors. Unknown
"			if aformentioned weird-can't-do-that undo errors exist anymore (I
"			am now running 6.1.200 (errors were with 6.1) so I really cannot
"			test... (I am 99% ertain it was a VIM BUG; just like that HUGELY
"			annoying as heck containedin=all bug; very thankfully fixed now!
"			*HUG* thank you whoever did that!)
"		This script is no longer secure; but I don't think anyone really
"			cares... I found it to not be worth the bother to reinvent the
"			wheel to do just TWO of the things Luc was doing with
"			Mu-Template... I dare say Luc's design be better ;)
"	[Feral:329/02@02:51] 0.39
"		FTE LINE COMMAND `^FTE:SAVEREGS:` can be use to preserve registers; If
"			this line is not present then the registers are clobbered.
"	[Feral:316/02@22:29] 0.38
"		<c-r><tab> search path is determined by g:fte_template_path (no longer
"			hard coded) defaults to ~/.vim/template/
"	[Feral:313/02@21:12] 0.37
"		Added «ifs:ScriptVarToTest:VarOrTextToInsert»
"		This means that you can now do something like this:
"«ifs:ftplug:if exists('b:loaded_ftplug_»«ifs:ftplug:fn»«ifs:ftplug:') | finish | endif»
"compare to MuTemplate's method:
"¡s:ftplug ? "if exists('b:loaded_ftplug_". s:fn."') | finish | endif" : ""¡
"	[Feral:312/02@17:31] 0.36
"		Fixed bug in FTE:Indent: code; was indenting too many lines; twas a
"			silly mistake; all better now.
"		Added insert mode <c-r><tab> mapping to do basicaly what :FLT does on
"			the commandline, which is to say type mems<c-r><tab> and a
"			templated by name of mems* is looked for; paths can be supplied,
"			i.e.  crt/mems<c-r><tab>.
"		Base template path is hardcoded at the moment.
"		This is directly inspired by Luc Hermitte's MuTempalte 0.25's CTRL_R
"	[Feral:311/02@18:15] 0.35
"		Undid 0.34 changes; fixed (via kludge) the undo error by placing a FTE
"			comment line at the top of the range; if that line is not there
"			then the undo gets messed up in certain text configurations
"			(subing a string above a prompt line. !shurg! still confuses me)
"		If you specify ^FTE:Indent: the template will be formated (via
"			normal! ==)
"	[Feral:305/02@14:51] 0.34
"		walking out the door -- quick comments.
"		reorded guts of :FTE function; «keywords» now are proceed before ^FTE
"			lines. this seems to have fixed a strange undo error, COMBAK and
"			describe this.
"	[Feral:305/02@00:25] 0.33
"		Added ^FTE:[X]ScriptVar:«Prompt text»
"		Added ^FTE:(*)ScriptVar:«Prompt text»
"		These will insert the «unlet:s:ScriptVar» keyword automatically, aka
"			they will unlet themselves.
"	[Feral:303/02@18:07] 0.32
"		Added «:text that is executed line :execute, big back door»
"			i.e. «:let s:MyVar = "Some Text"»
"		Added «unlet:myvar»  does :unlet myvar; specify all of it i.e. s:MyVar
"			Done absolutly last.
"			i.e. «unlet:s:MyVar»
"		Added «s:VarName» for script vars; set them with the new
"			«:let s:myvar = "yea"» format.
"			i.e. This is my new MyVar, «s:MyVar», pretty isn't it?
"		Note: The «:text» method will probably become an option.
"		Trying to make this usefull in the `real world`. Specificly my html
"			templates/api thing. Messy those are!
"	[Feral:303/02@13:18] 0.31
"		Bug fix in s:FeralTemplateExpansion(); cursor mark is only travled to
"			when in the work area. Previous «CURSOR» was found anywhere in the
"			file.
"	[Feral:301/02@13:41] 0.3
"		Converted to «keyword» method from %%%(keyword) method.
"	[Feral:297/02@05:50] 0.21
"		Changes based on Luc's suggestions. Checkbox is now [X] and raido
"		buttons are now (*) .. see the help file.
"		../doc/fte.txt
"	[Feral:266/02@02:15] 0.2
"		bugfix: changed SetRegister to allow "quoted strings" by escaping the
"		input text.
"
"		0.1
"		misc made it workie!
" }}}
"
"	Design Decisions: {{{ (or why I did what I did)
"	There Are Three Stages:
"		Stage One:		Get the template into the buffer.
"			Method One:
"				Use :FLT or :FLTI to load a template file and place template
"				markers (used by Method One of Stage Three) which are used to
"				mark the start and end of the newly inserted template.  I.e.:
"FTE: --------------------- SO: feral-template pass 1 ---------------------
"<loaded_template_here>
"FTE: --------------------- EO: feral-template pass 1 ---------------------
"			Method Two:
"				Insert the template how YOU want.. via :read, an abrevation,
"				DrChip's Cstubs, or anything that inserts text. Add the
"				template markers (illistrated above) IF you want to use Stage
"				Three-Method One.
"		Stage Two:		Fill in the prompts, if any.
"			(prompt for var name and the like);
"			This allows FULL VIM editing ability(compleation, expansions, etc.),
"			ability to come back later, and you have the ability to use the
"			marker method you prefer to goto the next prompt.
"
"			Some templates do not need anything filled in and this stage can
"			be bypassed for those cases. (You proceed as if this stage is
"			done)
"		Stage Three:	Expand the template.
"			Method One: Hit the key (<F3>) to call FeralFindAndExpandTemplate
"				which will find the start and end of the template (searches for
"				the template pass 1 markers), This assumes the cursor is in the
"				template (which is where it is in normal use)
"			Method Two: Visual the template you want to expand and :FTE (you
"				may specify the range however you like, using visual mode
"				tends to be easy). The default range for :FTE is the current
"				line (normal VIM) so if your tempate is only one line all you
"				need do is :FTE
"
"		At first glance this probably seems like a whole lot of work to go to
"		just to expand a simple template, but consider this allows for YOU to
"		load the template however you like (via :read or an abrevation or
"		DrChip'sCStubs or whatever), that this method allows YOU to use the
"		marker method you like for the entering of information and last but
"		not least that the actual guts of the template expansion (:FTE) can be
"		used compltealy seperatly -- it simply operates on a range (default
"		currently line).
" }}}
"
"	Nice Features: {{{
"		Lines that start with '^FTE:' are considered comments and removed from
"		the template during expansion (Stage Three, in :FTE). This allows for
"		comments (anywhere) in your template files
"
"		You can `load` your template via :read, put a register or whatever.
"
"		You can use whatever marker method (jump to a location) you like, or
"		none at all. (my examples use a similar «my text» method
"		(markjump.vim), do not confuse this with the template markers which
"		will be expanded during template expansion (Stage Three, :FTE).
"
"		Multiple template markers that are expanded during Stage 3 (:FTE):
"		TODO list all the templates; look to :FTE
"		[Feral:301/02@13:44] This list is in the help file.
"
" to invoke :FTE when in:
"FTE: --------------------- SO: feral-template pass 1 ---------------------
"<cursor_here>
"FTE: --------------------- EO: feral-template pass 1 ---------------------
" }}}


if exists("loaded_fte")
	finish
endif
let loaded_fte = 1

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" ---------------------------------------------------------------------

" ---------------------------------------------------------------------
" {{{ How best to include text if a file exists...
" [Feral:340/02@05:37] !EXACTLY! the same way Luc does...
" from Luc's version of mu-template; from the template.cpp; if the header file
" exists, #include it. Neat idea!
"¡filereadable(expand("%:p:r").'.h')  ? '#include "'.expand('%:t:r').'.h"'  :""¡
"¡filereadable(expand("%:p:r").'.hh') ? '#include "'.expand('%:t:r').'.hh"' :""¡
"¡filereadable(expand("%:p:r").'.inl')? '#include "'.expand('%:t:r').'.inl"':""¡
" «IfExists:--can't-do-nested-things-damn!--»
"«fe:filename:text to insert here»
"«whatever:filename:#include "%s"»
"which is to say, if filename exists insert eh text '#include "filename"'.

"NOTE we can support compound keywords for SOME of them.. just sub them first.
"expand("%:p:r")
"C:\Vim\vimfiles\plugin\fte
"expand('%:t:r')
"fte
"COMBAK I think this is good, look at it again in a while.
"[Feral:303/02@16:29]
"	Method Proposal: «IfReadable:path,name,ext,lead,trail»
"	check path.name.ext
"	if that is readable, insert lead.name.ext.trail
"
"	«IfReadable:path,name,ext,lead,trail»
"		path	= the path (absolute or relitive-to-this-file) to look for the
"			name.ext
"			DEFAULTS To: fullpath to this file
"		name	= the file name
"			DEFAULTS To: this file's filename
"		ext		= the extension
"			DEFAULTS To: this file's extension
"		lead	= leading text to insert before name.ext
"			DEFAULTS To: "" (an empty string)
"		tail	= trailing text to insert after name.ext
"			DEFAULTS To: "" (an empty string)
"
"		IE: if path.name.ext is readable insert lead.name.ext.tail
"		Example:	If a headerfile is readable, #include it, idea ported from
"		Luc Hermitte's template.cpp idea:
"			«IfReadable:,,.h,#include ","»
"			«IfReadable:,,.hh,#include ","»
"			«IfReadable:,,.inl,#include ","»
"		Exaple:		If a documtation file exists, referance it (in
"		documtation)
"			«IfReadable:../doc/,,.txt," Documtation File:	:"»
"			This amounts to:
"			expand("%:p:h").'/'.'../doc/'.expand("%:t:r").'.txt'
"			NOTE textlink.vim has absolute/relitive path stuff perfect for
"				this
"			I.e. C:\Vim\vimfiles\plugin/../doc/fte.txt
"			and will insert:" Documtation File:	../doc/fte.txt
"
"		Can just as easily be a COPYING file or the like. I.e.
"			«IfReadable:../,COPYING, ,See , for redistrobution information.»
"		NOTE ext is a space; because empty = default...
"			Will insert:See ../COPYING  for redistrobution information.»
"		NOTE in this situation you can just omit the leading space for the
"			trail param and everything is fine.
"
"	The bad part about this method is simple usage (i.e.
"	«IfReadable:,,.h,#include ","») is convoluted.
"
"}}}

"“ and ”
"<c-K>TS and <c-K>CC

" ---------------------------------------------------------------------
" TODO Luc's method of storing/seting information. {{{
"¿let s:clsname = inputdialog("class name ?")¿
"...
"class ¡s:clsname¡
"[Feral:303/02@14:21]
" FTE:INPUTDIALOG:varname:This is the prompt text for the inputdialog().
" FTE:INPUT:varname:This is the prompt text for the input().
" FTE:[ ]varname:Just like the register version.
" FTE:( )varname:Just like the register version.
" Useage is a very similar to «g:varname»,
" class «s:clsname»
" i.e.
" FTE:INPUTDIALOG:clsname:«class name ?»
" FTE:INPUT:clsname:«class name ?»
" FTE:[X]clsname:«class name ?»
" We keep the ability to toggle the entry on and off so that we can easily
" have default values, i.e.
" FTE: Which sprintf do you actually want?
" FTE:RAIDO_PROMPT_START
" FTE:( )ScriptVar:_stprintf			FTE: TCHAR.H routine
" FTE:(*)ScriptVar:sprintf				FTE: _UNICODE & _MBCS not defined
" FTE:( )ScriptVar:sprintf				FTE: _MBCS defined
" FTE:( )ScriptVar:swprintf				FTE: _UNICODE defined
" FTE:RAIDO_PROMPT_END
" Then usage is an easy «s:FunName»(...);
"
" This makes Luc's fragment above:
" FTE:INPUTDIALOG:clsname:class name ?
"...
"class «s:clsname»
" an the user will be prompted when the template is expanded.
" COMBAK .. there should probably be a default value for INPUTDIALOG and
"	INPUT, else Looks good!
"...
"
" FTE:CONFIRM:ScriptVar:msg:choices:default
" i.e.
"¿let s:ftplug = confirm("Is this script an ftplugin ?", "&Yes\n&No", 2) == 1 ¿
" is:
" FTE:CONFIRM:ftplug:Is this script a ftplugin ?:&Yes\n&No:2
"
" [Feral:312/02@05:02] I think these will work:
" FTE:INPUTDIALOG:varname:This is the prompt text for the inputdialog().
" FTE:INPUT:varname:This is the prompt text for the input().
" FTE:CONFIRM:ScriptVar:msg:choices:default
" i.e.
" FTE:INPUTDIALOG:clsname:class name ?
" FTE:INPUT:clsname:class name ?
" FTE:CONFIRM:ftplug:Is this script a ftplugin ?:&Yes\n&No:2
"
"
"
"[Feral:313/02@21:25] Working;
" Related, if var is true do this: (rather insert this text)
"
" if var is true, insert text, else this text.
"¡s:ftplug ? "if exists('b:loaded_ftplug_". s:fn."') | finish | endif" : ""¡
"FTE can do this like so:
"«ifs:ftplug:if exists('b:loaded_ftplug_»«ifs:ftplug:fn»«ifs:ftplug:') | finish | endif»
"Not quite the same, but mayhaps a little easier to type? !shrug!
"
" Probably should have more kinds of if; specificly if NOT; so we could do an
" if else (rather if ifNot)
"
" [Feral:304/02@13:02] The kinds of if..
"	If true insert text
"	if NOT true insert text
"	if true insert text, else insert text.
"	if true set var to text
"	if true append text to var (var = var.text)
"
"
" }}}

" ---------------------------------------------------------------------
"TODO make the string returned by «INCLUDE_GATE» configurable via vars {{{
"Luc's method of headergate
"#ifndef __¡substitute(toupper(expand("%")),'\c[^a-z0-1_]','_','g')¡__
"i.e.
" __FTE_VIM__
"while I use:
" macHeader_FTE_vim
"
" Config Options:
"	leading_text:		Left leading text
"	trailing_text:		Right trailing text
"	file_sub_method:	file name substituion method
"	ext_sub_method:		extension substition method
"	fname_case:			chage case method for fname (0=nochange, 1= upper, 2= lower)
"	ext_case:			chage case method for ext (0=nochange, 1= upper, 2= lower)
"
"	the chars that match the substition method will be turned into '_'
"	i.e. (basicaly)
"	substitute(expand("%:t:r"),file_sub_method,'_','g')
"	substitute(expand("%:e"),ext_sub_method,'_','g')
"
"	Mine:
"	"macHeader_"
"	""
"	'\W'
"	'\W'
"	1
"	2
"
"	Luc:
"	"__"
"	"__"
"	'\c[^a-z0-1_]'
"	'\c[^a-z0-1_]'
"	1
"	1
"
"	I.e.
"	let SubedCasedFname	= substitute(expand("%:t:r"),file_sub_method,'_','g')
"	" change case of SubedCasedFname based on var
"	let SubedCasedExt	= substitute(expand("%:e"),ext_sub_method,'_','g')
"	" change case of SubedCasedExt based on var
"	insert leading.SubedCasedFname.'_'.SubedCasedExt.trail
"
"COMBAK Shoudl work great, make sure it sounds good in a bit :)
"	[Feral:303/02@16:37] Still, is it actually worth the bother to do this?
"	Considering how picky I am at how my code looks I imagine so.
"	[Feral:312/02@04:37] I still like this; pitty it takes 6 vars though..
"	let g:fte_incgate_leading_text		="macHeader_"
"	let g:fte_incgate_trailing_text		=""
"	let g:fte_incgate_file_sub_method	='\W'
"	let g:fte_incgate_ext_sub_method	='\W'
"	let g:fte_incgate_fname_case		=1
"	let g:fte_incgate_ext_case			=2
"}}}

" ---------------------------------------------------------------------
" More examples; From Luc's template.vim {{{
"¿let s:ftplug = confirm("Is this script an ftplugin ?", "&Yes\n&No", 2) == 1 ¿
"¿let s:fn = substitute(expand("%"),'\W', '_', 'g') ¿
"" Avoid reinclusion
"¡s:ftplug ? "if exists('b:loaded_ftplug_". s:fn."') | finish | endif" : ""¡
"¡s:ftplug ? "let b:loaded_ftplug_".s:fn." = 1" : "" ¡
"¡s:ftplug ? '"' : "" ¡
"¡s:ftplug ? 'let s:cpo_save=&cpo' : "" ¡
"¡s:ftplug ? 'set cpo&vim' : "" ¡
"¡s:ftplug ? '"' : "" ¡
"¿if s:ftplug | exe "normal a\"\r\<esc>73a-\<esc>D" | endif ¿
"¡s:ftplug ? '"' : "" ¡
"¡s:ftplug ? "«Buffer relative definitions»" : "" ¡
"¡s:ftplug ? " " : "" ¡
""
"¿if s:ftplug | exe "normal a\"\r\<esc>78a=\<esc>D" | endif ¿
"if exists("g:loaded_¡s:fn¡")
"¡s:ftplug ? "  let &cpo=s:cpo_save" : "" ¡
"  finish
"endif
"let g:loaded_¡s:fn¡ = 1
"¡!s:ftplug ? 'let s:cpo_save=&cpo' : "" ¡
"¡!s:ftplug ? 'set cpo&vim' : "" ¡
"
" }}}

" ---------------------------------------------------------------------
" TODO How Luc is doing the xsl templates: {{{
"¿"{xsl:if} Template, Luc Hermitte, 07th nov 2002 ¿
"¿ let s:reindent = 1 ¿
"<xsl:if test="¡Marker_Txt('condition')¡">
"¡Marker_Txt()¡
"</xsl:if>
"
"Currently I would do this like so:
"FTE:{xsl:if} Template, Luc Hermitte, 07th nov 2002
"FTE:Indent:
"<xsl:if test="«condition»">
"«»
"</xsl:if>
"
"Hum, the marker chars... «g:L_Marker»; but if that does not exist that's no
"	good!
"	[Feral:316/02@22:31] «LM» and «RM» to insert the marker chars; need to
"		know what they are however. (recall that FTE's «» keyword denotion
"		method is totally not relivent to the markjump symbols.)
"	What the markers are is deteremed by markjump's global method.
"
"" From: MarjUmp.vim
"" GetL_Marker() and GetR_Marker() general idea inspired by Luc Hermitte's
""	bracketing.base.vim (a modified version of Stephen Riehm's braketing
""	macros for vim) Also usefull coments from Luc
"" Note: b:L_Marker is used before g:L_Marker and if neither are defined then
""	the default is used, same for b:R_Marker before g:R_Marker
"function s:GetL_Marker() " {{{
"	if exists('b:L_Marker')
"		return b:L_Marker
"	elseif exists('g:L_Marker')
"		return g:L_Marker
"	else
"		" <c-k><<
"		return '«'
"	endif
"endfunction
"" }}}
"function s:GetR_Marker() " {{{
"	if exists('b:R_Marker')
"		return b:R_Marker
"	elseif exists('g:R_Marker')
"		return g:R_Marker
"	else
"		" <c-k>>>
"		return '»'
"	endif
"endfunction
"" }}}
"
"Proposed:
"FTE:{xsl:if} Template, Luc Hermitte, 07th nov 2002
"FTE:Indent:
"<xsl:if test="«LM»condition«RM»">
"«LM»«RM»
"</xsl:if>
"
"
"Ok so is this worthwhile todo? If I or someone ever changes their mark/jump
"	marker symbols then yes; and Recall that Luc does not use «» for French
"	LaTex but does for everything else.
"
"	So, if Luc is using one template for mutiple file types then it would be
"		nice to automatticly insert the proper markjump chars.; Probably why
"		he made his version work like that ;)
"
"Hum, it would be nice if there was a user created file that specified these
"	type of settings (forinstance it would be called to parse «LM» and «RM».
"	Standard keyword but different expansion depending.
" }}}

" ---------------------------------------------------------------------
" ---------------------------------------------------------------------



" INFO: Works on a range of lines, range defaults to line the cursor is on.
" {{{
"
" This function will scan a range of text and replace templates (in the form
" of «keyword» ). Prompt ones are removed and the rest are replaced with what
" they evaulate to. Should be secure and no backdoors (for some reason that
" bothered me).
"
" Sugested method of expansion is make a new keyword and make it do what you
" want it to. (for instance a
" «if:@a:this-text-if-true»«if!:@a:this-text-if-false» type idea.) (Keep in
" mind blindly executing things is what makes a script insecure, if that
" worries you, don't blindly execute things!)
"
" [Feral:339/02@21:32] Oh and yes this is insecure now because it was too much
" pain in the reinvented wheel to bother with making an if command and all the
" varations there of. Know thy templates and you will be ok :)
"
" [Feral:340/02@05:08] This method (mark II) iterates each line of the
" template twice, once to pre-porocess (get rid of FTE: prompt comments) and a
" second time to expand the template. (then a third time to get rid of FTE:
" lines and normal! == if needed)
"
" }}}
function s:FeralTemplateExpansion(JustOne) range " {{{

"// --------------------------------------------------------------------- //
"// -----------------------------[ I N I T ]----------------------------- //
"// --------------------------------------------------------------------- //

	if a:JustOne == 1
		let SubOptions = ""
	else
		let SubOptions = "g"
	endif

" [Feral:339/02@21:33] Hopeing this had something to do with the unpatched 6.1
" release (currently running 6.1.200) {{{
"	" [Feral:306/02@17:51] This HACK is a bandaid to fix the undo problem;
"	" COMBAK and describe and stuffs. TEST MORE too!
"	" [Feral:327/02@08:20] from feralformatfunction.vim: {{{
"""[Feral:322/02@14:25] THIS method causes undo errors.
"""		execute "normal! lciw\<CR>\<esc>j"
"""[Feral:322/02@14:25] THIS method does not.
"""	no like cr and or j in exe line I guess.
"""		echo confirm("Found one at:".line('.'))
""		normal! lD
""		normal! o{
""		normal! j
""	"
""}}}
"	:put! ='FTE: Dummy line'
"	let LR = a:firstline.",".(a:lastline+1)
"	}}}

	let LR = a:firstline.",".a:lastline
"	echo confirm(LR)

	"[Feral:339/02@21:35] This is as of unpatched 6.1
	" expand folds (required), else :s will operate on the entire fold count
	"	times, with count being the number of lines in the fold.
	"[Feral:138/03@21:38] much better would be to use zn and zN at end. COMBAK
	"	TODO.
	silent! execute LR."foldopen!"

"// --------------------------------------------------------------------- //
"// ----------------------[ P R E - P R O C E S S ]---------------------- //
"// --------------------------------------------------------------------- //
" In general things that control how FTE works; for this template only.
" [Feral:329/02@02:47] NOTE TODO heh could set the L_Marker/R_Marker chars
"	like this then could we not?


	" [Feral:339/02@21:00] What if I just rewrote this sob script...
	" [Feral:340/02@05:40] Did (with time out to make a morrowind house for Dad); it even seems to work!


	" Remove prompt comments
	"^FTE:«anything»	FTE:comment
	" {{{ Pre-process: Remove Prompt Comments
	let EndLine = a:lastline
	" Go to the top line of the template:
	execute ":".a:firstline
	" Loop while we are not done.
	while 1
		let DaLine = getline('.')
"		call confirm("Processing line(".line('.')."): ".DaLine)

		if match(DaLine, '^FTE:.\{-}\s\+FTE:') != -1
			" match found
			let NewText = substitute(DaLine, '^\(FTE:.\{-}\)\s\+FTE:.*', '\1', '')
			execute 'normal! 0"_C'.NewText
		endif

		" Now, go down a line and try again.
		" (only if we are not on the last line already)
		if(line('.') == EndLine)
			" We are done now because we are on the last line
			break
		else
			normal! j
		endif

	endwhile
	" }}}



	"{{{ Fill in some variables
	" TODO this should be the same idea as markjump.vim
	" [Feral:329/02@02:24] Be mindfull; currently the markers are hardcoded in
	"	places; (the var/register unlet/restore parts, though they use
	"	[LR]_Marker (like below) other places may not.)
	" [Feral:329/02@02:47] See above; Can probably use FTE LINE COMMANDS to
	"	set these on a per template file basis.
	let L_Marker = '«'
	let R_Marker = '»'

	"Vars for the templatefile.vim 1.5 method
	let DaFile = expand("%:p:t:r")
	let DaFile_ext = expand("%:p:t")
	" Use Luc's idea of \W, tis better than my original \\.!
	let DaInclude_GATE = substitute(DaFile, "\W", "_", "g")
	" TODO Text for DaInclude_GATE should be configurable!
	let DaInclude_GATE = "macHeader_".toupper(DaInclude_GATE)."_".tolower(expand("%:e"))
	" }}}


	" Process each line and `do` the template expansion thing.
	" {{{ Process each line and expand the template.
	let EndLine = a:lastline
	" Go to the top line of the template:
	execute ":".a:firstline
	" Loop while we are not done.
	while 1
		let DaLine = getline('.')
"		call confirm("Processing line(".line('.')."): ".DaLine)

"// --------------------------------------------------------------------- //
"// ----------------[ F T E   L I N E   C O M M A N D S ]---------------- //
"// --------------------------------------------------------------------- //

		"[Feral:339/02@23:28] I wonder if the ¡¡ and ¿¿ should be pre-process
		"Actually these shold be proper FTE line commands...... or should
		"	they?

		"{{{3 (Pre-process) ^FTE:Indent:
		if match(DaLine, "^FTE:[Ii][Nn][Dd][Ee][Nn][Tt]:") != -1
			"^FTE:Indent:
			" MATCH FOUND
			" Indent (via normal! == for each line) the template? (If not
			"	present then no indenting is done)
			let s:IndentTemplate = 1
		endif

		"{{{3 (Pre-process) ^FTE:saveregs:
		if match(DaLine, "^FTE:[Ss][Aa][Vv][Ee][Rr][Ee][Gg][Ss]:") != -1
			"^FTE:savereg:
			" MATCH FOUND
			" Save register contents? (if not present registers are overwritten)
			let s:SaveRegs = 1
		endif

		"{{{3 (Pre-process) ¡expression to evaluate and insert as text¡
		if match(DaLine, '¡[^¡]*¡') != -1
			" MATCH FOUND
			" [Feral:336/02@00:58] Directly inspred Luc's version of mu-template.
			" execute LR.'s/¡\([^¡]*\)¡/\=<SID>Exec(submatch(1))/'.SubOptions
"			let NewText = substitute(DaLine, '¡\([^¡]*\)¡', '\1', '')
"			call s:Exec(NewText)
			execute 's/¡\([^¡]*\)¡/\=<SID>Exec(submatch(1))/'.SubOptions
		endif

		"{{{3 (Pre-process) ¿expression to execute¿ and «:expression to execute»
		" just execute any ol bit o script code.
		" TODO make this an option, i.e. operate in a secure mode and an
		"	unsecure mode, based on a global var (or something).
		" [Feral:305/02@18:53] This is the first of the marker keywords as it
		"	can set vars.
		if match(DaLine, '¿\_.[^¿]*¿\n\?') != -1
			" MATCH FOUND
			" [Feral:336/02@00:58] Directly inspred Luc's version of mu-template.
			execute 's/¿\(\_.[^¿]*\)¿\n\?/\=<SID>ExecReally(submatch(1))/'.SubOptions
		endif
		if match(DaLine, L_Marker.':.\{-}'.R_Marker) != -1
			execute 's/'.L_Marker.':\(.\{-}\)'.R_Marker.'/\=<SID>ExecReally(submatch(1))/'.SubOptions
		endif


		"{{{3 Parse prompts, register style
		"FTE:[X]r:value
		"FTE:(*)r:value
		if match(DaLine, '^FTE:[[(]\S[])]\a:.*') != -1
			" MATCH FOUND
			call s:SetRegister()
		endif

		"{{{3 Parse prompts, script variable style
		"FTE:[X]HREF:«Prompt text»
		"FTE:(*)HREF:«Prompt text»
		if match(DaLine, '^FTE:[[(]\S[])]\I\i\+:.*') != -1
			" MATCH FOUND

			call s:SetVariable()
		endif

		"{{{3 [Feral:339/02@23:32] Wondering if we still want this(IF.); why
		"	not just use mu-template's ¡¡ method? More flexable and less is
		"	more! (aka don't add a needless command if it is not needed)(less
		"	complexity and so on)
		"[Feral:340/02@05:07] Currently I prefer to use ¡¡¿¿ method
		"	?)
		"{{{3 Logic, if append -- [Feral:305/02@00:51]
		"FTE:IF.:VarToTest:VarToDotTo:Leading:Text:Trailing
		"FTE:IF.:@c:Elements: HREF=":@c:"
		"FTE:IF.:HREF:Elements: HREF=":HREF:"
		"FTE:IF.:HREF:Elements: HREF=":HREF:"
		if match(DaLine, '^FTE:IF\.:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*') != -1
			" MATCH FOUND
			call s:IfDot()
		endif

		"{{{3 «New one!»

"		if match(DaLine, '') != -1
"			" MATCH FOUND
"		endif

		"{{{3 END
		"}}}3

"// --------------------------------------------------------------------- //
"// ------------------[ M a r k e r   K e y w o r d s ]------------------ //
"// --------------------------------------------------------------------- //


		"Expansion method based on templatefile.vim 1.5
		"{{{3 FILE
		if match(DaLine, L_Marker.'FILE'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'FILE'.R_Marker.'/'.DaFile.'/'.SubOptions
		endif

		"{{{3 FILE_EXT
		if match(DaLine, L_Marker.'FILE_EXT'.R_Marker) != -1
			" MATCH FOUND
"			echo confirm(DaFile_ext)
			execute 's/'.L_Marker.'FILE_EXT'.R_Marker.'/'.DaFile_ext.'/'.SubOptions
		endif

		"{{{3 INCLUDE_GATE
		if match(DaLine, L_Marker.'INCLUDE_GATE'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'INCLUDE_GATE'.R_Marker.'/'.DaInclude_GATE.'/'.SubOptions
		endif

		"{{{3 «New one!»

"		if match(DaLine, '') != -1
"			" MATCH FOUND
"		endif

		"{{{3 END
		"}}}3

	"Expansion method based on mu-template.vim 0.11
"«ifs:ftplug:if exists('b:loaded_ftplug_»«ifs:ftplug:fn»«ifs:ftplug:') | finish | endif»

		"{{{3 TS: (insert time stamp; strftime)
		if match(DaLine, L_Marker.'TS:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'TS:\(.\{-}\)'.R_Marker.'/\=strftime(submatch(1))/'.SubOptions
		endif

		"{{{3 @ (insert register)
		if match(DaLine, L_Marker.'@\l'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'@\(\l\)'.R_Marker.'/\=<SID>Exec("@".submatch(1))/'.SubOptions
		endif

		"{{{3 g (insert global variable)
		if match(DaLine, L_Marker.'g:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'g:\(.\{-}\)'.R_Marker.'/\=<SID>Exec("g:".submatch(1))/'.SubOptions
		endif

		"{{{3 s (insert script variable)
		if match(DaLine, L_Marker.'s:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'s:\(.\{-}\)'.R_Marker.'/\=<SID>Exec("s:".submatch(1))/'.SubOptions
		endif

		"{{{3 ifs (if script var is true insert global var or text)
		if match(DaLine, L_Marker.'ifs:.\{-}:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'ifs:\(.\{-}\):\(.\{-}\)'.R_Marker.'/\=<SID>Ifsg(0,submatch(1), submatch(2))/'.SubOptions
		endif

		"{{{3 ifg (if global var is true insert global var or text)
		if match(DaLine, L_Marker.'ifg:.\{-}:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'ifg:\(.\{-}\):\(.\{-}\)'.R_Marker.'/\=<SID>Ifsg(1,submatch(1), submatch(2))/'.SubOptions
		endif

		"{{{3 «New one!»
"		if match(DaLine, '') != -1
"			" MATCH FOUND
"		endif

		"{{{3 END
		"}}}3


		" Now, go down a line and try again.
		" (only if we are not on the last line already)
		if(line('.') == EndLine)
			" We are done now because we are on the last line
			break
		else
			normal! j
		endif

	endwhile
	" }}}

"	echo confirm("returning now; no smoke I hope..")
"	return


"// --------------------------------------------------------------------- //
"// ------------------------[ C L E A N   U P ! ]------------------------ //
"// --------------------------------------------------------------------- //

	" {{{ Process each line and unlet/restore things.
	let EndLine = a:lastline
	" Go to the top line of the template:
	execute ":".a:firstline
	" Loop while we are not done.
	while 1
		let DaLine = getline('.')
"		call confirm("Processing line(".line('.')."): ".DaLine)

		"{{{3 Last but not least, unlet vars, if any.
		if match(DaLine, L_Marker.'unlet:.\{-}'.R_Marker) != -1
			" MATCH FOUND
"			execute 's/'.L_Marker.'unlet:\(.\{-}\)'.R_Marker.'/\=<SID>ExecReally("unlet ".submatch(1))/'.SubOptions
			execute 's/'.L_Marker.'unlet:\(.\{-}\)'.R_Marker.'/\=<SID>UnletVar(submatch(1))/'.SubOptions
		endif

		"{{{3 also restore registers, if wanted.
		if match(DaLine, L_Marker.'restoreregister:.\{-}'.R_Marker) != -1
			" MATCH FOUND
			execute 's/'.L_Marker.'restoreregister:\(.\{-}\)'.R_Marker.'/\=<SID>RestoreRegister(submatch(1))/'.SubOptions
		endif

		"{{{3 END
		"}}}3

		" Now, go down a line and try again.
		" (only if we are not on the last line already)
		if(line('.') == EndLine)
			" We are done now because we are on the last line
			break
		else
			normal! j
		endif

	endwhile
	" }}}

	if exists("s:SaveRegs")
		unlet s:SaveRegs
	endif

	" {{{ Remove comment lines (those starting with FTE:) (custom iteration)
	"[Feral:311/02@17:57] Doing this manually so we can optionally normal! ==
	"	non FTE: lines.
	if exists("s:IndentTemplate") && s:IndentTemplate
		let EndLine = a:lastline
		" Go to the top line of the template:
		execute ":".a:firstline
		" Loop while we are not done.
		while 1
			let DaLine = getline('.')
"			call confirm("Processing line(".line('.')."): ".DaLine)

			" goes down a line either by :deleteing the line we are on, or
			"	normal! j
			if match(DaLine, "^FTE:") != -1 "{{{3
				" MATCH FOUND, this is a comment line
				delete
				let EndLine = EndLine - 1
			else "{{{3
				"match NOT found; the is part of the resulting template
				normal! ==
				normal! j
			endif
			"{{{3 END
			"}}}3

			" If we are on the last line break out.
			if(line('.') == EndLine)
				" We are done now because we are on the last line
				break
			endif
		endwhile

	else
		" if not indenting we can use a :g to get rid of the lines; but do we
		" want to?
		execute LR.'g/^FTE:/:delete'
	endif
	if exists("s:IndentTemplate")
		unlet s:IndentTemplate
	endif
	" }}}

	" place the cursor {{{
	" Rules: {{{
	" if the a:JustOne == 1 then don't move the cursor at all.
	" if there is a «cursor» marker then place cursor
	" else place the cursor at the top (a:firstline)
	" }}}
"	echo confirm(a:firstline)
	if a:JustOne != 1
		" Start at the top of the template and search for a cursor marker,
		"	only the first is used.
"		echo confirm(a:firstline)
		execute ":".a:firstline
		if search(L_Marker.'CURSOR'.R_Marker, 'W') > 0
			" make sure the cursor is within LR..
			"[Feral:340/02@05:30] We use EndLine here (as defined by the
			"	Remove Comment Lines section) as that section above us has the
			"	potental to removes lines thus invalidating a:lastline, it
			"	however keeps track of the new a:lastline in EndLine so we use
			"	that.
			if line('.') >= a:firstline && line('.') <= EndLine
				" we are within LR
				" delete the cursor marker
				execute 'normal! "_'.(strlen(L_Marker)+6+strlen(R_Marker)).'x'
			else
				" position like no cursor mark.
				execute 'normal! '.a:firstline.'G0'
			endif
		else
			" no cursor mark, position cursor at top of range, col 1
			execute 'normal! '.a:firstline.'G0'
		endif
	endif
	" }}}

	unlet L_Marker
	unlet R_Marker

endfunc
"}}}
"On Hold, seems flawed in many ways (none of which sould be a flaw btw);
"	trying a new method above.
"function s:FeralTemplateExpansion(JustOne) range " {{{
"
""// --------------------------------------------------------------------- //
""// -----------------------------[ I N I T ]----------------------------- //
""// --------------------------------------------------------------------- //
"
"	if a:JustOne == 1
"		let SubOptions = ""
"	else
"		let SubOptions = "g"
"	endif
"	" [Feral:306/02@17:51] This HACK is a bandaid to fix the undo problem;
"	" COMBAK and describe and stuffs. TEST MORE too!
"	" [Feral:327/02@08:20] from feralformatfunction.vim: {{{
"""[Feral:322/02@14:25] THIS method causes undo errors.
"""		execute "normal! lciw\<CR>\<esc>j"
"""[Feral:322/02@14:25] THIS method does not.
"""	no like cr and or j in exe line I guess.
"""		echo confirm("Found one at:".line('.'))
""		normal! lD
""		normal! o{
""		normal! j
""	"
""}}}
"	:put! ='FTE: Dummy line'
"	let LR = a:firstline.",".(a:lastline+1)
"
"
"
""	echo confirm(LR)
"
""	" expand folds (required), else :s will operate on the entire fold count
""	"	times, with count being the number of lines in the fold.
"	silent! execute LR."foldopen!"
"
""// --------------------------------------------------------------------- //
""// ----------------[ F T E   L I N E   C O M M A N D S ]---------------- //
""// --------------------------------------------------------------------- //
"
"	" Remove prompt comments
"	"^FTE:«anything»	FTE:comment
"	"^FTE:«anything»	FTE:comment
"	" [Feral:339/02@20:55] This :s method that I was using suddenly caused an
"	" exception error when moved from just above the 'Parse prompts, register
"	" style'.. This :g method seems to work fine however; go figure.
"	" [Feral:339/02@20:57] No, no on third thought none of these work.
"	" [Feral:339/02@21:00] What if I just rewrote this sob script...
""	silent! execute LR.':s/^\(FTE:.\{-}\)\s\+FTE:.*/\1/'.SubOptions
""	silent! execute LR.':g/^FTE:.\{-}\s\+FTE:/:s/^\(FTE:.\{-}\)\s\+FTE:.*/\1/'
""	silent! execute LR.':g/^FTE:.\{-}\s\+FTE:/:call <sid>RemovePromptComment()'
"
"" In general things that control how FTE works; for this template only.
"" [Feral:329/02@02:47] NOTE TODO heh could set the L_Marker/R_Marker chars
""	like this then could we not?
"
"	" Indent (via normal! == for each line) the template? (If not present then
"	"	no indenting is done)
"	"^FTE:Indent:
"	silent! execute LR.'g/^FTE:[Ii][Nn][Dd][Ee][Nn][Tt]:/:let s:IndentTemplate = 1'
"	" Save register contents? (if not present registers are overwritten)
"	"^FTE:savereg:
"	silent! execute LR.'g/^FTE:[Ss][Aa][Vv][Ee][Rr][Ee][Gg][Ss]:/:let s:SaveRegs = 1'
"
"	"[Feral:336/02@01:27] Pre version
"	"Parse prompts, register style
"	"FTE:[X]!r:value
"	"FTE:(*)!r:value
"	silent! execute LR.'g/^FTE:[[(]\S[])]!\(\a\):\(.*\)/:call <SID>SetRegister()'
"	"Parse prompts, script variable style
"	"FTE:[X]!HREF:«Prompt text»
"	"FTE:(*)!HREF:«Prompt text»
"	silent! execute LR.'g/^FTE:[[(]\S[])]!\(\I\i*\):\(.*\)/:call <SID>SetVariable()'
"
"
"	" [Feral:336/02@00:58]
"	" Directly ripped from Luc's version of mu-template.
""	silent %s/¿\(\_.[^¿]*\)¿\n\?/\=<SID>Compute(submatch(1))/ge
""	silent %s/¡\([^¡]*\)¡/\=<SID>Exec(submatch(1))/ge
""	silent! execute LR.'s/¿\(\_.[^¿]*\)¿\n\?/\=<SID>ExecReally(submatch(1))/'.SubOptions
"	silent! execute LR.'s/¡\([^¡]*\)¡/\=<SID>Exec(submatch(1))/'.SubOptions
"
"
"
"
"	"[Feral:339/02@21:01] This is temp holding; should be above the pre
"	"	version (of parse prompts)
"	" Remove prompt comments
"	"^FTE:«anything»	FTE:comment
"	"^FTE:«anything»	FTE:comment
"	silent! execute LR.':s/^\(FTE:.\{-}\)\s\+FTE:.*/\1/'.SubOptions
"
"
"
"
"	"Parse prompts, register style
"	"FTE:[X]r:value
"	"FTE:(*)r:value
"	silent! execute LR.'g/^FTE:[[(]\S[])]\(\a\):\(.*\)/:call <SID>SetRegister()'
"
"	"Parse prompts, script variable style
"	"FTE:[X]HREF:«Prompt text»
"	"FTE:(*)HREF:«Prompt text»
"	silent! execute LR.'g/^FTE:[[(]\S[])]\(\I\i*\):\(.*\)/:call <SID>SetVariable()'
""
"	"Logic, if append -- [Feral:305/02@00:51]
""FTE:IF.:VarToTest:VarToDotTo:Leading:Text:Trailing
""FTE:IF.:@c:Elements: HREF=":@c:"
""FTE:IF.:HREF:Elements: HREF=":HREF:"
""FTE:IF.:HREF:Elements: HREF=":HREF:"
"	silent! execute LR.'g/^FTE:IF\.:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\)/:call <SID>IfDot()'
"
""FTE:ifs:ftplug:text to insert if ftplug is true.
""[Feral:336/02@00:37] Or not.. (wip)
""	silent! execute LR.'s/^FTE:ifs:\(.\{-}\):\(.\{-}\)/\=<SID>Ifsg(0,submatch(1), submatch(2))/'.SubOptions
""	silent! execute LR.'s/^FTE:ifg:\(.\{-}\):\(.\{-}\)/\=<SID>Ifsg(1,submatch(1), submatch(2))/'.SubOptions
"
"
""// --------------------------------------------------------------------- //
""// ------------------[ M a r k e r   K e y w o r d s ]------------------ //
""// --------------------------------------------------------------------- //
"
"	" TODO this should be the same idea as markjump.vim
"	" [Feral:329/02@02:24] Be mindfull; currently the markers are hardcoded in
"	"	places; (the var/register unlet/restore parts, though they use
"	"	[LR]_Marker (like below) other places may not.)
"	" [Feral:329/02@02:47] See above; Can probably use FTE LINE COMMANDS to
"	"	set these on a per template file basis.
"	let L_Marker = '«'
"	let R_Marker = '»'
"
"
"	" just execute any ol bit o script code.
"	" TODO make this an option, i.e. operate in a secure mode and an unsecure
"	"	mode, based on a global var (or something).
"	" [Feral:305/02@18:53] This is the first of the marker keywords as it can
"	"	set vars.
"	silent! execute LR.'s/'.L_Marker.':\(.\{-}\)'.R_Marker.'/\=<SID>ExecReally(submatch(1))/'.SubOptions
"
"	" {{{ Expansion method based on templatefile.vim 1.5
"	let DaFile = expand("%:t:r")
"	let DaFile_ext = expand("%")
"
"	" Luc's version of this from template.vim is better. Which is to say use
"	"	\W
""	let DaInclude_GATE = substitute(DaFile, "\\.", "_", "g")
"	let DaInclude_GATE = substitute(DaFile, "\W", "_", "g")
"
"	let DaInclude_GATE = "macHeader_".toupper(DaInclude_GATE)."_".tolower(expand("%:e"))
"	silent! execute LR."s/".L_Marker."FILE".R_Marker."/".DaFile."/".SubOptions
"	silent! execute LR."s/".L_Marker."FILE_EXT".R_Marker."/".DaFile_ext."/".SubOptions
"	silent! execute LR."s/".L_Marker."INCLUDE_GATE".R_Marker."/".DaInclude_GATE."/".SubOptions
""	call <SID>ProcessMarkerKeyword(LR, 'FILE',			DaFile,			SubOptions)
""	call <SID>ProcessMarkerKeyword(LR, 'FILE_EXT',		DaFile_ext,		SubOptions)
""	call <SID>ProcessMarkerKeyword(LR, 'INCLUDE_GATE',	DaInclude_GATE,	SubOptions)
"	" }}}
"	" {{{ Expansion method based on mu-template.vim 0.11
""	call <SID>ProcessMarkerKeyword(LR, 'TS:\(.\{-}\)',	'\=strftime(submatch(1))',			SubOptions)
""	call <SID>ProcessMarkerKeyword(LR, '@\(\l\)',		'\=<SID>Exec("@".submatch(1))',		SubOptions)
""	call <SID>ProcessMarkerKeyword(LR, 'g:\(.\{-}\)',	'\=<SID>Exec("g:".submatch(1))',	SubOptions)
""	call <SID>ProcessMarkerKeyword(LR, 's:\(.\{-}\)',	'\=<SID>Exec("s:".submatch(1))',	SubOptions)
"	silent! execute LR.'s/'.L_Marker.'TS:\(.\{-}\)'.R_Marker.'/\=strftime(submatch(1))/'.SubOptions
"	silent! execute LR.'s/'.L_Marker.'@\(\l\)'.R_Marker.'/\=<SID>Exec("@".submatch(1))/'.SubOptions
"	silent! execute LR.'s/'.L_Marker.'g:\(.\{-}\)'.R_Marker.'/\=<SID>Exec("g:".submatch(1))/'.SubOptions
"	silent! execute LR.'s/'.L_Marker.'s:\(.\{-}\)'.R_Marker.'/\=<SID>Exec("s:".submatch(1))/'.SubOptions
"
"
"	silent! execute LR.'s/'.L_Marker.'ifs:\(.\{-}\):\(.\{-}\)'.R_Marker.'/\=<SID>Ifsg(0,submatch(1), submatch(2))/'.SubOptions
"	silent! execute LR.'s/'.L_Marker.'ifg:\(.\{-}\):\(.\{-}\)'.R_Marker.'/\=<SID>Ifsg(1,submatch(1), submatch(2))/'.SubOptions
""«ifs:ftplug:if exists('b:loaded_ftplug_»«ifs:ftplug:fn»«ifs:ftplug:') | finish | endif»
"
"
""	silent! execute LR.'s/'.L_Marker.'P:\(\l\):\([^)]*\)'.R_Marker.'/\=<SID>DoPrompt(submatch(1), submatch(2) )/'.SubOptions
""	call <SID>DoPrompt("a","Yea what? ")
"	" }}}
"
"
"
""// --------------------------------------------------------------------- //
""// ------------------------[ C L E A N   U P ! ]------------------------ //
""// --------------------------------------------------------------------- //
"
"	" Last but not least, unlet vars, if any.
"	silent! execute LR.'s/'.L_Marker.'unlet:\(.\{-}\)'.R_Marker.'/\=<SID>ExecReally("unlet ".submatch(1))/'.SubOptions
""	call <SID>ProcessMarkerKeyword(LR, 'unlet:\(.\{-}\)', '<SID>ExecReally("unlet ".submatch(1))/', SubOptions)
"	" also restore registers, if wanted.
"	silent! execute LR.'s/'.L_Marker.'restoreregister:\(.\{-}\)'.R_Marker.'/\=<SID>RestoreRegister(submatch(1))/'.SubOptions
"
"	unlet L_Marker
"	unlet R_Marker
"	if exists("s:SaveRegs")
"		unlet s:SaveRegs
"	endif
"
"	" {{{ Remove comment lines (those starting with FTE:)
"	"[Feral:311/02@17:57] Doing this manually so we can optionally normal! ==
"	"	non FTE: lines.
""	echo confirm(LR)
""	echo confirm(a:firstline)
""	echo confirm(a:lastline+1)
"	let EndLine = (a:lastline+1)
"	if exists("s:IndentTemplate") && s:IndentTemplate
"		execute "normal! ".a:firstline."G"
"		while line('.') <= EndLine
"			let DaLine = getline('.')
"			if match(DaLine, "^FTE:") != -1
"				" match found, this is a comment line
"				delete
"				let EndLine = EndLine - 1
"			else
"				"match NOT found; the is part of the resulting template
"				normal! ==
"				normal! j
"			endif
"		endwhile
"	else
"		execute LR.'g/^FTE:/:delete'
"	endif
"	if exists("s:IndentTemplate")
"		unlet s:IndentTemplate
"	endif
"	" }}}
"
"	" place the cursor {{{
"	" Rules: {{{
"	" if the a:JustOne == 1 then don't move the cursor at all.
"	" if there is a «cursor» marker then place cursor
"	" else place the cursor at the top (a:firstline)
"	" }}}
""	echo confirm(a:firstline)
"	if a:JustOne != 1
"		" Start at the top of the template and search for a cursor marker,
"		" only the first is used.
""		echo confirm(a:firstline)
"		execute 'normal! '.a:firstline.'G'
"		if search('«CURSOR»', 'W') > 0
"			" make sure the cursor is within LR..
"			if line('.') >= a:firstline && line('.') <= a:lastline
"				" we are within LR
"				" delete the cursor marker
"				execute 'normal! "_8x'
"			else
"				" position like no cursor mark.
"				execute 'normal! '.a:firstline.'G0'
"			endif
"		else
"			" no cursor mark, position cursor at top of range, col 1
"			execute 'normal! '.a:firstline.'G0'
"		endif
"	endif
"	" }}}
"
"endfunc
""}}}
"




"function s:ProcessMarkerKeyword(LineRange, KeywordPattern, SubString, SubOptions) " {{{
""	echo confirm('In ProcessMarkerKeyword:'.a:LineRange.':'.a:KeywordPattern.':'.a:SubString.':'.a:SubOptions)
"
""	silent! execute LR.'g/^FTE:[[(]\S[])]\(\a\):\(.*\)/:call <SID>SetRegister()'
"
"	let L_Marker = '«'
"	let R_Marker = '»'
"
"	silent! execute a:LineRange.'s/'.L_Marker.a:KeywordPattern.R_Marker.'/'.a:SubString.'/'.a:SubOptions
"
"	unlet L_Marker
"	unlet R_Marker
"
"endfunction
"" }}}



"" INFO: Set a register (a:Register) based on a input(). Neat!
"function s:DoPrompt(Register, PromptText) " {{{
"	let Responce = input(a:PromptText)
"	if Responce == ""
"		return
"	endif
"	execute 'let @'.a:Register.' = "'.Responce.'"'
"endfunction
"" }}}
" INFO: Set a register (a:Register) based on the suplied text (called from a
"	:s)
"function s:SetRegister(Register, Text) "
function s:SetRegister() " {{{

	let DaLine = getline('.')
"	echo confirm('In s:SetRegister():'.DaLine)

	:" Set up the match bit
	:let mx='FTE:[[(]\S[])]\%[!]\(\a\):\(.*\)'
	:"get the part matching the whole expression
	:let Lummox = matchstr(DaLine, mx)
	:"get each item out of the match
	:let Register	= substitute(Lummox, mx, '\1', '')
	:let Text		= substitute(Lummox, mx, '\2', '')


	" get rid of the prompt line now.
	if exists("s:SaveRegs") && s:SaveRegs && Register =~# "[a-z]"
		" preserve register: (NOTE but ignore preserving appends)
		"	(in theory you'll use the register (which will save it here) then
		"	append to it one or more times)
		execute ':let s:OldReg_'.tolower(Register).' = @'.tolower(Register)
		let L_Marker = '«'
		let R_Marker = '»'
		execute 'normal! 0f:l"_C'.L_Marker.'restoreregister:'.tolower(Register).R_Marker
	else
		" No special processing, just get rid of it.(convert to plain comment
		"	line)
		normal! 0f:l"_D
	endif


	" Now fill in the register.
	execute ':let @'.Register.' = "'.escape(Text, '"').'"'
"	execute 'echo confirm(@'.Register.')'


	unlet mx
	unlet Lummox
	unlet Register
	unlet Text
	unlet DaLine

endfunction
" }}}

function s:RestoreRegister(DaRegister) " {{{
	let Register = tolower(a:DaRegister)
	execute ':let @'.Register.' = s:OldReg_'.Register
	execute ':unlet s:OldReg_'.Register
	unlet Register
endfunction
" }}}

function s:UnletVar(DaVar) " {{{
"[Feral:340/02@18:33] This replaces:
"	execute 's/'.L_Marker.'unlet:\(.\{-}\)'.R_Marker.'/\=<SID>ExecReally("unlet ".submatch(1))/'.SubOptions
	if strlen(a:DaVar)
		execute ':unlet '.a:DaVar
	endif
endfunction
" }}}

function s:SetVariable() " {{{

	let DaLine = getline('.')
"	echo confirm('In s:SetVariable():('.line('.').'):'.DaLine)

	:" Set up the match bit
	:let mx='FTE:[[(]\S[])]\%[!]\(\I\i*\):\(.*\)'
	:"get the part matching the whole expression
	:let Lummox = matchstr(DaLine, mx)
	:"get each item out of the match
	:let Variable	= substitute(Lummox, mx, '\1', '')
	:let Text		= substitute(Lummox, mx, '\2', '')

	let s:{Variable} = Text
"	execute 'echo confirm("s:'.Variable.':'.s:{Variable}.'")'

	" get rid of the prompt line and convert to a unlet keyword.
	"	so we do not get confused.
	let L_Marker = '«'
	let R_Marker = '»'
	execute 'normal! 0f:l"_C'.L_Marker.'unlet:s:'.Variable.R_Marker

	unlet mx
	unlet Lummox
	unlet Variable
	unlet Text
	unlet DaLine

endfunction
" }}}


"FTE:IF.:VarToTest:VarToDotTo:Leading:Text:Trailing
"FTE:IF.:@c:Elements: HREF=":@c:"
"FTE:IF.:HREF:Elements: HREF=":HREF:"
function s:IfDot() " {{{

"	silent! execute LR.'s/^FTE:IF\.:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\)/\=<SID>IfDot(submatch(1),submatch(2),submatch(3),submatch(4),submatch(5))/'.SubOptions

	let DaLine = getline('.')
"	echo confirm('In s:IfDot():'.DaLine)

	:" Set up the match bit
	:let mx='FTE:IF\.:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\)'
	:"get the part matching the whole expression
	:let Lummox = matchstr(DaLine, mx)
	:"get each item out of the match
	:let VarToTest	= substitute(Lummox, mx, '\1', '')
	:let VarToDotTo	= substitute(Lummox, mx, '\2', '')
	:let Leading	= substitute(Lummox, mx, '\3', '')
	:let Text		= substitute(Lummox, mx, '\4', '')
	:let Trailing	= substitute(Lummox, mx, '\5', '')

	let DaText = Text

	if exists('s:'.DaText)
"		echo confirm(DaText.' (text) exists as a script var, using that.')
		let DaText = s:{DaText}
	endif
	if exists('s:'.VarToTest)
		let DaContentsOfVatToTest = s:{VarToTest}
"		echo confirm(VarToTest.' (s:VarToTest) exists as a script var, using that.')
	else
		let DaContentsOfVatToTest = ""
	endif

	" HACK to handel quotes in DaText
"	if stridx(Leading, '"') > -1 && stridx(Trailing, '"') > -1
"		let DaText = escape(DaText, '"')
"	endif
"	if stridx(Leading, "'") > -1 && stridx(Trailing, "'") > -1
"		let DaText = escape(DaText, "'")
"	endif

	if strlen(DaContentsOfVatToTest)
"		echo confirm('s:'.VarToTest.' has a strlen, doing the if.')
"		echo confirm(DaContentsOfVatToTest)
		let s:{VarToDotTo} = s:{VarToDotTo}.Leading.DaText.Trailing
	endif


	" get rid of the prompt line so we do not get confused.
	execute 'normal! 0f:l"_D'

	unlet mx
	unlet Lummox
	unlet VarToTest
	unlet VarToDotTo
	unlet Leading
	unlet Text
	unlet Trailing
	unlet DaLine
	unlet DaText

endfunction
" }}}

function s:Ifsg(Mode, VarToTest, VarOrText) " {{{
"	a:Mode = 0 for script vars;
"	a:Mode = 1 for global vars;

"	echo confirm(a:Mode."\n".a:VarToTest."\n".a:VarOrText)

	if a:Mode
		if exists("g:".a:VarOrText)
			let DaText = g:{a:VarOrText}
		else
			let DaText = a:VarOrText
		endif
	else
		if exists("s:".a:VarOrText)
			let DaText = s:{a:VarOrText}
		else
			let DaText = a:VarOrText
		endif
	endif
"	echo confirm(DaText)

"	echo confirm('s:'.a:VarToTest.":".s:{a:VarToTest}."\n".DaText)
	if exists('s:'.a:VarToTest) && (s:{a:VarToTest} == 1)
		return DaText
	else
		return ""
	endif

endfunction
" }}}

" NOTE: evaluates a:what and returns the results as a string.
" Like Mu-Template's ¡text¡ you can use the short version of if-then-else (?:)
function s:Exec(what) " {{{
"	echo confirm('Exec:'.a:what)
	execute 'return' a:what
"	execute 'return ('.a:what.')'
endfunction
"}}}
" NOTE: executes a:what; returns ""
function s:ExecReally(what) " {{{
"	echo confirm('ExecReally:'.a:what)
	execute a:what
	return ""
endfunction
"}}}


" Info: Loads a template file and places markers top and bottem of it,
"	Can also indent based on the suplied string (last param) ONLY if
"	a:DoIndent == 1 (aka :FLTI)
" Example: FLT  C:/Dev/CODEFRAGS/memset.cpp
" Example: FLT  C:/Dev/CODEFRAGS/auto pointer class fragment.cpp
" Example: FLTI C:/Dev/CODEFRAGS/memset.cpp \t\t
" Example: FLTI C:/Dev/CODEFRAGS/auto pointer class fragment.cpp \t\t
function s:FeralLoadTemplate(DoIndent, ...) " {{{
	" [Feral:312/02@16:13] DoIndent is deprecated as :FTE can properly
	"	(normal! ==) indent now; Still this may be usefull so I'll leave this
	"	for now.

"	echo a:0
	let Index = 1
	let Fname = ''
	while Index <= a:0
		if a:DoIndent == 1 && Index == a:0
			" if we are indenting skip adding the last string (the indent
			"	string) to the Fname
			break
		endif
"		execute 'let Item = a:'.Index
"		echo Item
"		let Fname = Fname.Item.' '
		let Fname = Fname.a:{Index}.' '
		let Index = Index + 1
	endwhile
	unlet Index
"	unlet Item
"	echo 'Fname is '. Fname


"	if a:DoIndent == 1
"		execute 'let Item = a:'.a:0
"		echo 'We should indent with ' . Item
"	endif

"i.e.
"FTE: --------------------- SO: feral-template pass 1 ---------------------
"FTE: Change Prompts. Lines beginning with `FTE:' are removed automatically
"FTE: This is a comment, automaticaly removed.
"FTE:Prompt:e:_var
"memset(«@e», 0, sizeof(«@e»));
"FTE: --------------------- EO: feral-template pass 1 ---------------------
"If a:DoIndent == 1 then the last param will be inserted before non FTE lines,
"	the memset line in the above example.

	:put  ='FTE: --------------------- EO: feral-template pass 1 ---------------------'
	:put! ='FTE: --------------------- SO: feral-template pass 1 ---------------------'

	exe ":read ".Fname
	unlet Fname

	" :r leaves cursor at the top of the inserted file.
	" '[ is top, '] is bottem (of inserted text), wonderful.
	if a:DoIndent == 1
		execute 'let Item = a:'.a:0
		let Save_Line = line(".")
		execute ":'[,']v/^FTE:/s/^/".Item."/"
		unlet Item
		execute ":normal ".Save_Line."G0"
		unlet Save_Line
	endif


	"TODO a lot of choices and stuff ehhe
"	if g:mt_jump_to_first_markers
"		normal ¡jump!
"	endif

endfunction
"}}}


function s:FteInsertLoader() " {{{
	" [Feral:312/02@16:16] This is directly inspired by Luc Hermitte's
	" MuTemplate 0.25 (or is that0.24?) 's insert mode control-r tab method.


" ---[Feral:312/02@18:17]--------------------------------------------------
" TODO
" need a good way to get rid of the text that invokes us; and to (I guess
" optionally like FTE:Indent:) place the finished contents of the template on
" that line;
"
" Right now this is less than seamless. Functional and works tho ;)
" -------------------------------------------------------------------------


" ---[Feral:312/02@16:17]----------------------------------------------
"P s u d o
" find the word to our rear; this is the (probably partial) keyword for the
"	file we want to load.
"
"do a glob for this file in the template path;
"
"If more than one file is found, echo what they are so the user can type more
"	and reinvoke us.
"
"Else, only one globed file; load that via :FLT (direct call to function
"	actually)
" ---------------------------------------------------------------------


	" TypedWord can contain a leading path at this point
	let FoundTypedWord = expand("<cWORD>")
"	echo confirm(FoundTypedWord)
	let TypedWord = FoundTypedWord

	if exists('g:fte_template_path')
		let PathToUse = substitute(g:fte_template_path.'', '\(\|/\|\\\)\(\|/\|\\\)$', '/', '').&ft.'/'
	else
		let PathToUse = '~/.vim/template/'.&ft.'/'
	endif
"	call confirm(PathToUse)

	" if TypedWord contains path chars then rip out the path portion and
	"	append that to PathToUse
	let WhereMatch = matchend(TypedWord, '.*[/\\]')
	if WhereMatch > -1
"		echo confirm("has a path; WhereMatch:".WhereMatch)

"		echo confirm("path:".strpart(TypedWord, 0, WhereMatch) )
		let PathToUse = PathToUse.strpart(TypedWord, 0, WhereMatch)

"		echo confirm("word:".strpart(TypedWord, WhereMatch) )
		let TypedWord = strpart(TypedWord, WhereMatch)
	endif

	" Fixup typed word to make sure it's valid
	" \w = not word chars; another option might be not \f (isfname chars)
	let TypedWord = substitute(TypedWord, '\W', '-', 'g')

"	echo confirm(PathToUse)
"	echo confirm(TypedWord)


	let Old_WildIgnore = &wildignore
	"mayahps we should += that way the user's wildignore items are acounted
	"	for also, as is we just ignore standard VIM backups.
	set wildignore=*~
	let GlobedFiles = glob(PathToUse.TypedWord.'*')
	let &wildignore=Old_WildIgnore

	if strlen(GlobedFiles)
		"TODO we will want to stridx to find a newline (I believe that is
		"glob's method of seperating the found files) and if that exists glob
		"found more than one; echo this (via dialog or echo) and prompt user
		"to be more specific and try again.
		if stridx(GlobedFiles, "\n") > -1
			call confirm("Too many found files:\n".GlobedFiles)
		else
"			execute ":FLT ".GlobedFiles
			" Remove what we typed from the end of the line; Presumable we are
			"	at the end of line when this is called.
			execute ':s/'.FoundTypedWord.'$//'
			"If the line is empty (contains nothing but spaces) or is empty
			"	delete it.
			if match(getline('.'), '^\s*$') > -1
				delete
				normal! k
			endif
			:call s:FeralLoadTemplate(0,GlobedFiles)
		endif
	endif
endfunction
"}}}

function! s:FeralFindAndExpandTemplate() " {{{

"FTE: --------------------- SO: feral-template pass 1 ---------------------
"<cursor_here>
"FTE: --------------------- EO: feral-template pass 1 ---------------------

"/* -[Feral:257/02@19:52]--------------------------------------------------
"  Basicaly:
"  Find top marker and save that line number (top of range)
"  Find bottem marker and save that line number (bottem of range)
"
"  Notes:
"  Start searching ASSuming we are IN the feral-template block; i.e. search
"  backwards WRAPPING (just in case we are not in the template block).
"
"  Search for the bottem marker forward from the top marker.
"
"  --------------------------------------------------------------------- */

	" search for the top marker and abort if it is not found.
	if search("FTE: --------------------- SO: feral-template pass 1 ---------------------", "bw") == 0
		echo "START template marker not found; Invoke :FTE manually I guess"
		return
	endif
	" found top marker, save line
	let TopLine = line(".")

	" now search for the bottem marker, aborting if it is not found.
	if search("FTE: --------------------- EO: feral-template pass 1 ---------------------", "W") == 0
		echo "END template marker not found;(but found the start) Invoke :FTE manually I guess"
		return
	endif
	let BotLine = line('.')

"	echo TopLine.",".BotLine

	execute ":".TopLine.",".BotLine."call s:FeralTemplateExpansion(0)"

endfunction
"}}}

" INFO: Toggles a FTE:[ ] line or FTE:( ) line, also handles a RAIDO_PROMPT
"	block.
function s:FeralTogglePromptLine() " {{{


" Luc's suggestions.
"(*) Using ? and ¿ is obscure. I think that it will be clearer (?English) if
"you use instead "[ ]" & "[x]" for check boxes and "( )" & "(*)" for radio
"boxes (or anything other than '*' like 'o', '¤', 'ø', ...)
"
"Lets have [ ] for a checkbox, with ANY NON WHITE SPACE char signifying it on,
"	i.e. [x] and [*] are both on, while [ ] is off.
"
"Lets have ( ) for a raido button ? hum, if we make the range for the bank on
"	the fly we limit some of the ability
"	[Feral:138/03@21:35] Althought it would result in cleaner templates;
"		current RAIDO_PROMPT_START and RAIDO_PROMPT_END as exampled below
"		function well enough.
"



" [Feral:280/02@15:48] For something like this:
" [Feral:297/02@04:30] No, this!
"FTE: RETURN VALUE:
"FTE: Think of this as a bank of raido buttons, choose one and hit <KEY>.
"FTE:RAIDO_PROMPT_START
"FTE:	Value:			Meaning:
"FTE:( )f:IDABORT		FTE: Abort button was selected.
"FTE:( )f:IDCANCEL		FTE: Cancel button was selected.
"FTE:( )f:IDCONTINUE	FTE: Continue button was selected.
"FTE:( )f:IDIGNORE		FTE: Ignore button was selected.
"FTE:( )f:IDNO			FTE: No button was selected.
"FTE:(*)f:IDOK			FTE: OK button was selected.
"FTE:( )f:IDRETRY		FTE: Retry button was selected.
"FTE:( )f:IDTRYAGAIN	FTE: Try Again button was selected.
"FTE:( )f:IDYES			FTE: Yes button was selected.
"
"FTE:RAIDO_PROMPT_END

	let LineOld = line(".")
	let ColOld = virtcol(".")
	let LineT = searchpair("RAIDO_PROMPT_START", "", "RAIDO_PROMPT_END", "bn")
	let LineB = searchpair("RAIDO_PROMPT_START", "", "RAIDO_PROMPT_END", "n")
"	echo confirm(LineT.",".LineB)

	if LineT != 0
		" raido bank toggle, turn them all off then turn cur line on.
" {{{ COMMENTED OLD ?¿ method.
"		execute LineT.",".LineB.'s/^FTE:?\(.*\)/FTE:¿\1/eI'
"		execute 'normal! '.LineOld.'G'
"		execute 's/^FTE:¿\(.*\)/FTE:?\1/eI'
" }}}
		execute LineT.",".LineB.'s/^FTE:(.)\(.*\)/FTE:( )\1/eI'
		execute 'normal! '.LineOld.'G'
		execute 's/^FTE:( )\(.*\)/FTE:(\*)\1/eI'
	else
		" single line toggle
		let DaLine = getline('.')
" {{{ COMMENTED OLD ?¿ method.
"		if match(DaLine, "^FTE:?") == 0
"			execute 's/^FTE:?\(.*\)/FTE:¿\1/eI'
"		else
"			execute 's/^FTE:¿\(.*\)/FTE:?\1/eI'
"		endif
" }}}
"		echo DaLine
		if match(DaLine, '^FTE:\[[^]]\]') > -1
			if match(DaLine, '^FTE:\[\S\]') == 0
"				echo 'Matched a on'
				execute 's/^FTE:\[\S\]\(.*\)/FTE:\[ \]\1/eI'
			else
"				echo 'Matched a off'
				execute 's/^FTE:\[ \]\(.*\)/FTE:\[X\]\1/eI'
			endif
"		else
"			echo 'No match'
		endif
	endif

	execute 'normal! '.ColOld.'|'
	return ""
endfunction
" }}}


"*****************************************************************
" Commands: {{{
"*****************************************************************
" Feral Template Expansion
if !exists(":FTE")
	command -range FTE						:<line1>,<line2>call <SID>FeralTemplateExpansion(0)
endif
" Feral Template Edit 1
" so you can process only a single template marker. Kind of a hack really.
if !exists(":FTE1")
	command FTE1							:call <SID>FeralTemplateExpansion(1)
endif
" Feral Load Template
"[Feral:297/02@05:58] Mark III
if !exists(":FLT")
	command -nargs=1 -complete=file FLT		:call <SID>FeralLoadTemplate(0,<f-args>)
endif
if !exists(":FLTI")
	command -nargs=1 -complete=file FLTI	:call <SID>FeralLoadTemplate(1,<f-args>)
endif


if !exists(":FTEF")
	command FTEF							:call <SID>FeralFindAndExpandTemplate()
endif
if !exists(":FTET")
	command FTET							:call <SID>FeralTogglePromptLine()
endif

" to invoke :FTE when in:
"FTE: --------------------- SO: feral-template pass 1 ---------------------
"<cursor_here>
"FTE: --------------------- EO: feral-template pass 1 ---------------------
"nnoremap <F3> :call <SID>FeralFindAndExpandTemplate()<CR>
"inoremap <F3> <ESC>:call <SID>FeralFindAndExpandTemplate()<CR>


" Menu entries.
noremenu <script> Plugin.FTE.Find\ and\ expand\ template	<SID>FteFfaet
noremenu <script> Plugin.FTE.Toggle\ prompt\ line			<SID>FteFtpl

if !hasmapto('<Plug>FteFfaet', 'n')
	nmap <unique> <leader><F3>  <Plug>FteFfaet
endif
if !hasmapto('<Plug>FteFfaet', 'i')
	imap <unique> <leader><F3>  <ESC><Plug>FteFfaet
endif
noremap <unique> <script> <Plug>FteFfaet  <SID>FteFfaet
noremap <SID>FteFfaet  :call <SID>FeralFindAndExpandTemplate()<CR>


" to easily toggle a checkbox or raido button bank
" {{{ Work...
"nnoremap <F4> :call <SID>FeralTogglePromptLine()<CR>
"inoremap <F4> <ESC>gV:call <SID>FeralTogglePromptLine()<CR>
"vnoremap <F4> <ESC>gV:call <SID>FeralTogglePromptLine()<CR>

"if !hasmapto('<Plug>FteFtpl', 'n')
"	nmap <unique> <F4>	<Plug>FteNFtpl
"endif
"if !hasmapto('<Plug>FteFtpl', 'i')
"	imap <unique> <F4>	<ESC><Plug>FteIFtpl
"endif
"if !hasmapto('<Plug>FteFtpl', 'v')
"	vmap <unique> <F4>	<Plug>FteVFtpl
"endif
"noremap <unique> <script> <Plug>FteNFtpl			<SID>FteNFtpl
"noremap <unique> <script> <Plug>FteIFtpl			<SID>FteIFtpl
"noremap <unique> <script> <Plug>FteVFtpl			<SID>FteVFtpl
"noremap <SID>FteNFtpl	:call <SID>FeralTogglePromptLine()<CR>
"noremap <SID>FteIFtpl	gV:call <SID>FeralTogglePromptLine()<CR>
"noremap <SID>FteVFtpl	<ESC>gV:call <SID>FeralTogglePromptLine()<CR>

"if !hasmapto('<Plug>FteFtpl', 'niv')
"	nmap <unique> <F4>	<Plug>FteFtpl
"	imap <unique> <F4>	<C-o><Plug>FteFtpl
"	vmap <unique> <F4>	<Plug>FteFtpl
"endif
" }}}
if !hasmapto('<Plug>FteFtpl', 'n')
	nmap <unique> <leader><F4>	<Plug>FteFtpl
endif
if !hasmapto('<Plug>FteFtpl', 'i')
	imap <unique> <leader><F4>	<ESC><Plug>FteFtpl
endif
if !hasmapto('<Plug>FteFtpl', 'v')
	vmap <unique> <F4>	<Plug>FteFtpl
endif
noremap <unique> <script> <Plug>FteFtpl			<SID>FteFtpl
noremap <SID>FteFtpl	:call <SID>FeralTogglePromptLine()<CR>

" {{{ More work...
"if !hasmapto('<Plug>AddVimFootnote', 'i')
"	imap <Leader>f <Plug>AddVimFootnote
"endif
"if !hasmapto('<Plug>ReturnFromFootnote', 'i')
"    imap <leader>r <Plug>ReturnFromFootnote
"endif
"
"imap <Plug>AddVimFootnote <C-O>:call <SID>VimFootnotes()<CR>
"imap <Plug>ReturnFromFootnote <C-O>:q<CR><Right>

"(*) Enable to easily use keybindings other than <F3> and <F4> (thanks to the
"!hasmapto() + <Plug> features) as they are already mapped for almost
"everybody.
"
" 20	if !hasmapto('<Plug>TypecorrAdd')
" 21	  map <unique> <Leader>a  <Plug>TypecorrAdd
" 22	endif
" 23	noremap <unique> <script> <Plug>TypecorrAdd  <SID>Add
" ..
" 25	noremenu <script> Plugin.FTE.Add\ Correction      <SID>Add
" ..
" 27	noremap <SID>Add  :call <SID>Add(expand("<cword>"), 1)<CR>
" ..
" 37	if !exists(":Correct")
" 38	  command -nargs=1  Correct  :call s:Add(<q-args>, 0)
" 39	endif
" }}}

" [Feral:312/02@16:28] InsertLoader mappings
if !exists(":FTEIL")
	command FTEIL				:call <SID>FteInsertLoader()<CR>
endif
if !hasmapto('<Plug>FteFteil', 'i') && mapcheck("<c-r><tab>", "i") == ""
	imap <unique> <c-r><tab>	<Plug>FteFteil
endif
inoremap <unique> <script> <Plug>FteFteil			<c-o>:call <SID>FteInsertLoader()<CR>

"}}}


let &cpo = s:save_cpo

"EOF

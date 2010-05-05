" Vim indent file
" Language:		JavaScript
" Author: 		Preston Koprivica (pkopriv2@gmail.com)	
" URL:
" Last Change: 	April 30, 2010

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetJsIndent(v:lnum)
setlocal indentkeys=0{,0},0),:,!^F,o,O,e,*<Return>,=*/


" 1. Variables
" ============


" Inline comments (for anchoring other statements)
let s:js_line_comment = '\s*\(//.*\)*'

" Simple Objects
let s:js_object_beg = '[{\[]\s*'
let s:js_object_end = '^[^}\]][}\]][;,]\=\s*'

" Immediately Executed Anonymous Function
let s:js_s_anon_beg = '(\s*function\s*(.*)\s*'
let s:js_s_anon_end = ')(.*)[;,]\s*'

let s:js_m_anon_beg = s:js_s_anon_beg . '\s*{\s*'
let s:js_m_anon_end = '\s*}\s*' . s:js_s_anon_end

" Simple control blocks (those not beginngin with "{")
let s:js_s_cntrl_beg = '\(\(\(if\|for\|with\)\s*(.*)\)\|try\)\s*' 		
let s:js_s_cntrl_mid = '\(\(\(else\s*if\|catch\)\s*(.*)\)\|\(finally\|else\)\)\s*'

" Multi line control blocks (those beginning with "{")
let s:js_m_cntrl_beg = s:js_s_cntrl_beg . '\s*{\s*'
let s:js_m_cntrl_mid = '}\=\s*' . s:js_s_cntrl_mid . '\s*{\s*'
let s:js_m_cntrl_end = '}\s*'

" Multi line declarations & invocations
let s:js_multi_beg = '([^()]*\s*'
let s:js_s_multi_end = '^[^()]*)\s*'
let s:js_m_multi_end = s:js_s_multi_end . '\s*{\s*'

" Special switch control
let s:js_s_switch_beg = 'switch\s*(.*)\s*' "Actually not allowed. 
let s:js_m_switch_beg = s:js_s_switch_beg . '\s*{\s*'

let s:js_switch_mid = '\(case.*\|default\)\s*:\s*'

" Single line comment (// xxx)
let s:syn_comment = 'Comment'


" 2. Aux. Functions
" =================


" = Method: GetNonCommentLine
"
" Grabs the nearest non-commented line
function! s:GetNonCommentLine(lnum)
	let lnum = prevnonblank(a:lnum)

	while lnum > 0
		if s:IsComment(lnum)
			let lnum = prevnonblank(lnum - 1)
		else
			return lnum
		endif
	endwhile

	return lnum
endfunction



" = Method: IsInComment
"
" Determines whether the specified position is contained in a comment. "Note:
" This depends on a 
function! s:IsInComment(lnum, cnum) 
	return synIDattr(synID(a:lnum, a:cnum, 1), 'name') =~ s:syn_comment
endfunction



" = Method: IsComment
" 
" Determines whether a line is a comment or not.
function! s:IsComment(lnum)
	let line = getline(a:lnum)

	return s:IsInComment(a:lnum, 1) && s:IsInComment(a:lnum, strlen(line)) "Doesn't absolutely work.  Only Probably!
endfunction


" 3. Indenter
" ===========
function! GetJsIndent(lnum)
	" Grab the first non-comment line prior to this line
	let pnum = s:GetNonCommentLine(a:lnum-1)

	" First line, start at indent = 0
	if pnum == 0
		echo "No, noncomment lines prior to: " . a:lnum
		return 0
	endif

	" Grab the second non-comment line prior to this line
	let ppnum = s:GetNonCommentLine(pnum-1)

	echo "Line: " . a:lnum
	echo "PLine: " . pnum
	echo "PPLine: " . ppnum

	" Grab the lines themselves.
	let line = getline(a:lnum)
	let pline = getline(pnum)
	let ppline = getline(ppnum)

	" Determine the current level of indentation
	let ind = indent(pnum)

	" Handle: Immediately executed anonymous functions
	" ================================================'
	if pline =~ s:js_s_anon_beg . s:js_line_comment . '$'
		echo "PLine matched anonymous function without ending {"
		if line =~ s:js_object_beg . s:js_line_comment . '$'
			echo "Line matched object beginning"
			return ind
		else
			echo "Line didn't match object beginning. NOT SURE WHAT TO DO!"
			return ind
		endif
	endif

	if pline =~ s:js_m_anon_beg . s:js_line_comment . '$'
		echo "Pline matched anonymous function with ending {"
		if line =~ 	s:js_m_cntrl_end . s:js_line_comment . '$' || line =~ s:js_m_anon_end . s:js_line_comment . '$'
			echo "Line matched } or anonymous function end"
			return ind
		else
			echo "Line didn't match } or anymous function end"
			return ind + &sw
		endif
	endif

	if line =~ '^' . s:js_s_anon_end . s:js_line_comment . '$'
		echo "Line matched anonymous ending with )(*)"
		if pline =~ s:js_object_end . s:js_line_comment . '$'
			echo "PLine matched object end"
			return ind
		else
			echo "Line didn't match object end. NOT SURE WHAT TO DO!"
			return ind
		endif
	endif

	if line  =~ s:js_m_anon_end . s:js_line_comment . '$' 
		echo "Line matched anonymous ending with })(*)"
		if pline =~ s:js_object_beg . s:js_line_comment . '$'
			echo "PLine matched object beginning"
			return ind 
		else
			echo "PLine didnt' match object beginning"
			return ind - &sw
		endif
	endif



	" Handle: Mutli-Line Invocation/Declaration
	" ===========================================
	if pline =~ s:js_multi_beg . s:js_line_comment . '$'
		echo "Pline matched multi invoke/declare"
		return ind + &sw
	endif

	if pline =~ s:js_s_multi_end . s:js_line_comment . '$'
		echo "Pline matched multi end without inline {"
		if line =~ s:js_object_beg . s:js_line_comment . '$'
			echo "Line matched object beg"
			return ind - &sw
		else
			echo "line didn't match object beginning"
			return ind 
		endif
	endif

	if pline =~ s:js_m_multi_end . s:js_line_comment . '$'
		echo "Pline matched multi end with inline {"
		if line =~ s:js_object_end . s:js_line_comment . '$'
			echo "Line matched object end"
			return ind - &sw
		else
			echo "Line didn't matched object end"
			return ind
		endif
	endif

	if ppline =~ s:js_s_multi_end . s:js_line_comment . '$' &&
				\ pline !~ s:js_object_beg . s:js_line_comment . '$'
		echo "PPLine matched multi invoke/declaration end without inline {"
		return ind - &sw
	endif


	" Handle: Switch Control Blocks
	" ===============================
	if pline =~ s:js_m_switch_beg . s:js_line_comment . '$'
		echo "PLine matched switch cntrl beginning"
		return ind
	endif

	if pline =~ s:js_switch_mid . s:js_line_comment . '$'
		echo "PLine matched switch cntrl mid"
		if line =~ s:js_switch_mid . s:js_line_comment . '$'
			echo "Line matched a cntrl mid"
			return ind
		else
			echo "Line didnt matcha  cntrl mid"
			return ind + &sw
		endif 
	endif

	if line =~ s:js_switch_mid " Doesn't need end anchor
		echo "Line matched cntrl mid"
		return ind - &sw
	endif

	" Handle: Single Line Control Blocks
	" ==========================
	if pline =~ s:js_s_cntrl_beg . s:js_line_comment . '$'
		echo "Pline matched single line control beg"
		if line =~ s:js_s_cntrl_mid. s:js_line_comment . '$' || line =~ s:js_object_beg. s:js_line_comment . '$'
			echo "Line matched single line control mid"
			return ind
		else
			echo "Line didn't match single line control mid"
			return ind + &sw
		endif
	endif

	if pline =~ s:js_s_cntrl_mid . s:js_line_comment . '$'
		echo "Pline matched single line control mid"
		if line =~ s:js_s_cntrl_mid . s:js_line_comment . '$' || line =~ s:js_object_beg . s:js_line_comment . '$' 
			echo "Line matched single line control mid"
			return ind
		else
			echo "Line didn't match single line control mid"
			return ind + &sw
		endif
	endif

	if line =~ s:js_s_cntrl_mid . s:js_line_comment . '$'
		echo "Line matched single line control mid"
		if pline =~ s:js_m_cntrl_end . s:js_line_comment . '$'
			echo "PLine matched multi line control end"
			return ind
		else
			echo "Pline didn't match object end"
			return ind - &sw
		endif
	endif

	if ( ppline =~ s:js_s_cntrl_beg . s:js_line_comment . '$' || ppline =~ s:js_s_cntrl_mid . s:js_line_comment . '$' ) &&
				\ pline !~ s:js_object_beg . s:js_line_comment . '$'
		echo "PPLine matched single line control beg or mid"
		return ind - &sw
	endif


	" Handle: Multi Line Cntrl Blocks
	" ===============================
	if pline =~ s:js_m_cntrl_beg . s:js_line_comment . '$'
		echo "Pline matched multi line control beg"
		if line =~ s:js_m_cntrl_mid . s:js_line_comment . '$' || line =~ s:js_m_cntrl_end . s:js_line_comment . '$'
			echo "Line matched multi line control mid or end"
			return ind
		else
			echo "Line didn't match multi line control mid or end"
			return ind + &sw
		endif
	endif

	if pline =~ s:js_m_cntrl_mid . s:js_line_comment . '$'
		echo "Pline matched multi line control mid"
		if line =~ s:js_m_cntrl_mid . s:js_line_comment . '$' || line =~ s:js_m_cntrl_end . s:js_line_comment . '$'
			echo "Line matched multi line control mid or end"
			return ind
		else
			echo "Line didn't match multi line control mid or end"
			return ind + &sw
		endif
	endif

	if line =~ s:js_m_cntrl_mid . s:js_line_comment . '$'
		echo "Line matched multi line control mid"
		if pline =~ s:js_m_cntrl_end . s:js_line_comment . '$'
			echo "PLine matched multi line control end"
			return ind
		else 
			echo "PLine didn't match multi line control end"
			return ind - &sw
		endif
	endif

	if line =~ s:js_m_cntrl_end . s:js_line_comment . '$'
		echo "Line matched multi line control end"
		return ind - &sw
	endif

	" Handle: Basic Objects
	" =====================
	if pline =~ s:js_object_beg . s:js_line_comment . '$'
		echo "PLine matched object beginning"
		if line =~ s:js_object_end . s:js_line_comment . '$'
			echo "Line matched object end"
			return ind
		else 
			echo "Line didn't match object end"
			return ind + &sw
		endif
	endif

	if line =~ s:js_object_end . s:js_line_comment . '$'
		echo "Line matched object end"
		return ind - &sw
	endif

	echo "Line didn't match anything.  Retaining indent"
	return ind
endfunction

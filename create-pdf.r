REBOL [
    title: {create-pdf out of view objects}
    authour: {Johan Ingvast}
    help: {
	Call with one argument being a face object
	>> create-pdf face
	or 
	>> create-pdf layout [ field "We are the champions" ]
	In return you get a text stream. Save it to whatever file you want
	>> write/binary %my.pdf create-pdf layout [ text "This is file my.pdf" ]
	
	One pixel in the face will be one point in the pdf document.

}
    TODO: {
    * Clean up, hide scope
    * Fix some compressions
    * Handle images
    * Handle alpha values
    * Handle gradients
    * Handle the rest of draw commands (arc ...)
    * Make use of font given. (Write font data to pdf)
    }
    DONE: {
    * Rewrite printf routines
    * Improve the printing of strings to do proper escapes
    }

]

pdf-stream-syntax: {
taken from http://www.mactech.com/articles/mactech/Vol.15/15.09/PDFIntro/index.html
b 	closepath, fill,and stroke path.
B 	fill and stroke path.
b* 	closepath, eofill,and stroke path.
B* 	eofill and stroke path.
BI 	begin image.
BMC 	begin marked content.
BT 	begin text object.
BX 	begin section allowing undefined operators.
c 	curveto.
cm 	concat. Concatenates the matrix to the current transform.
cs 	setcolorspace for fill.
CS 	setcolorspace for stroke.
d 	setdash.
Do 	execute the named XObject.
DP 	mark a place in the content stream, with a dictionary.
EI 	end image.
EMC 	end marked content.
ET 	end text object.
EX 	end section that allows undefined operators.
f 	fill path.
f* 	eofill Even/odd fill path.
g 	setgray (fill).
G 	setgray (stroke).
gs 	set parameters in the extended graphics state.
h 	closepath.
i	setflat.
ID 	begin image data.
j 	setlinejoin.
J 	setlinecap.
k 	setcmykcolor (fill).
K 	setcmykcolor (stroke).
l 	lineto.
m 	moveto.
M 	setmiterlimit.
n 	end path without fill or stroke.
q 	save graphics state.
Q 	restore graphics state.
re 	rectangle.
rg 	setrgbcolor (fill).
RG 	setrgbcolor (stroke).
s 	closepath and stroke path.
S 	stroke path.
sc 	setcolor (fill).
SC 	setcolor (stroke).
sh 	shfill (shaded fill).
Tc 	set character spacing.
Td 	move text current point.
TD 	move text current point and set leading.
Tf 	set font name and size.
Tj 	show text.
TJ 	show text, allowing individual character positioning.
TL 	set leading.
Tm 	set text matrix.
Tr 	set text rendering mode.
Ts 	set super/subscripting text rise.
Tw	set word spacing.
Tz 	set horizontal scaling.
T* 	move to start of next line.
v 	curveto.
w 	'setlinewidth.
W 	clip.
y 	curveto.
}


; Utility functions
Z: func [ msg con][ print rejoin [ msg ": " mold con ] con]



pdf-bindings: make object! [
    ; Streams
    q: 'q   
    s: 's
    R: 'R
    m: 'm
    v: 'v
    stream: 'stream
    endstream: 'endstream
    re: 're
    h: 'h
    |: '| ; Wonder if this is needed
    Tf: 'Tf
    dict: 'dict
]

rebol-draw-commands: [
    pen fill-pen 
    line-width
    line-cap line-join line-pattern
    miter miter-bevel round bevel
    butt square round
    nearest bilinear
    box triangle
    line polygon
    circle ellipse arc
    spline 
    curve
    closed
    push
    invert-matrix reset-matrix matrix
    rotate  scale translate scew transformation
    
    arrow
    clip
    anti-alias
    image
    text
    font
    anti-aliased vectorial aliased
    image image-filter
    ; Skip the shape dialect for now.
]

; Make a context that can be used to bind all the keywords to itself. That way any block of draw 
; command can be evaluated after being bound to the context
rebol-draw-binding: copy []
foreach x rebol-draw-commands [ repend rebol-draw-binding [ to-set-word x to-lit-word x ] ]
rebol-draw-binding: context rebol-draw-binding

eval-draw: func [
    "Evalues a block so that all functions are run and variables replaced by its content"
    blk [block!] "The block to evaluate"
][
    reduce bind/copy blk rebol-draw-binding
]

xrefs: copy []

XsIf: func [
    {Use next word and see what reference it has in the object list.
    Make a pdf reference (3 0 R) out of it. 
    If no word matches, issue a warning}
    'name
    /local i
] [
    either i: find names name [
	reduce [ (index? i ) 0 'R]
    ][
	print ["Warning!" name "is not defined!" ]
	[]
    ]
]

Xs: func [
    {Use next word and see what reference it has in the object list.
    Make a pdf reference (3 0 R) out of it.
    Error if reference is not found}
    'name /local i
] [
    either i: find names name [
	reduce [ (index? i ) 0 'R]
    ][
	make error! rejoin [ {Cannot find object '} name {'} ]
    ]
]

do-functions: func [
    {Evaluate the block and return it evaluated.
    Do it recursively. 
    Typically done before parsing pdf content before making string
    }
    blk [block!]
    /local rslt ret
][
    rslt: copy []
    while [ not empty? blk ] [
	if all [		; Replace function references with the function
	    word? first blk
	    value? first blk
	    any-function? get first blk
	] [
	    change blk get first blk
	]
	either any-function? first blk
	[
	    ret: do/next blk
	    unless unset? first ret [
		append rslt first ret
	    ]
	    blk: second ret
	][
	    either block? first blk
	    [
		;Z "Calling with" first blk
		append/only rslt do-functions first+ blk
	    ][
		append rslt first+ blk
	    ]
	]
    ]
    rslt
]


to-pdf-string: func [
    {Takes a block of pdf graphics commands (encoded as rebol) and
    converts it to a string that pdf can parse.
    pairs are converted to two numbers.
    tuples are converted to a number of decimals by dividing them with 255
    TODO:
	Images are  converted to a byte sequence
    }
    blk
    /local str p space 
	string from to
] [

    space: #" "
    str: copy ""
    forall blk [
	arg: first blk
	if new-line? blk [ if all [ not empty? str #" " = last str ] [ clear back tail str ] append str newline ]
	case [
	    block? arg [
		append str rejoin [ "[ " to-pdf-string arg " ]" ]
	    ]
	    'dict = arg [
		unless block? second blk [ make error! "Dict must be following dict keyword" ]
		append str rejoin [ "<<" to-pdf-string second blk " >>" ]
		blk: next blk
	    ]
	    string? arg [
		string-replacements: [
		    "\" "\\"
		    "(" "\("
		    ")" "\)"
		]
		string: copy arg
		foreach [ from to ] string-replacements [ replace/all string from to ]
		append str rejoin [ "(" string ")" ]
		append str space
	    ]
	    binary? arg [
		append str copy/part skip p: mold arg 2 back tail p
	    ]
	    image? arg [
		append str copy/part skip p: mold to-binary arg 2 back tail p
	    ]
	    pair? arg [
		repend str reform [ arg/x arg/y ]
		append str #" "
	    ]
	    tuple? arg [
		repeat i length? arg [
		    repend str form   ( pick arg i ) / 255
		    append str #" "
		]
	    ]
	    true [
		append str mold arg
		append str space
	    ]
	]
    ]
    if all [ not empty? str #" " = last str ] [ clear back tail str ]
    str
]

names: copy []
objs: copy []

obj: func [ name blk /local obj ret ][
    append names name
    append objs context [
	type: 'obj
	name: last names
	block: bind blk pdf-bindings
	proc-func: func [][
	    block: do-functions block
	]
	to-string: func [/local str ][
	    new-line block off
	    str: reform [ index? find names name 0 "obj" newline ]
	    append str to-pdf-string block
	    repend str [ newline "endobj" newline ]
	    str
	]
    ]
    last objs
]

stream: func [ name blk /local obj ret stream ][
    append names name
    append objs context [
	type: 'stream
	name: last names
	block: bind blk pdf-bindings
	dict: copy/part block
	    stream: find block 'stream 
	stream: copy/part  next stream find stream 'endstream
	proc-func: func [][
	    dict:   do-functions dict
	    stream: do-functions stream
	]
	to-string: func [/local str stream-str ] [
	    str: reform [ index? find names name 0 "obj" newline ] 
	    stream-str: to-pdf-string stream
	    new-line dict off
	    change next find dict/dict /Length (length? stream-str)
	    repend str  [
		to-pdf-string dict newline
		"stream" newline
		stream-str newline
		"endstream" newline
		"endobj" newline
	    ]
	    str
	]
    ]
    last objs
]

draw-circle: func [ x y rx /xy ry /local dx dy c m ][
    ry: any [ ry rx ]
    dx: rx * 4 * ( ( square-root 2 ) - 1 ) / 3 
    dy: ry * 4 * ( ( square-root 2 ) - 1 ) / 3 
    reduce [
	x - rx y     'm 
	x - rx y + dy
	x - dx y + ry
	x      y + ry 'c
	x + dx y + ry
	x + rx y + dy
	x + rx y     'c
	x + rx y - dy
	x + dx y - ry
	x      y - ry 'c
	x - dx y - ry
	x - rx y - dy
	x - rx y     'c 'h
    ]
]

rotating: func [
    {Rotates the angle alpha (degrees) around (x,y)
    A: 
	[  ca sa 0 ]
	[ -sa ca 0 ]
	[  tx ty 1 ]

    x [ x y 1]
    X*A:
	[ ca*x - sa*y + tx, sa*x+ca*y+ty, 1]
    [x0,y0] = X0 * A
	x0 = ca*x0-sa+tx
	tx = x0 - ca*x0 + sa*y0
	y0 = sa*x0+ca*y0+ty
	ty = y0-sa*x0-ca*y0}
    x0 y0 alpha
    /local ca sa Tx Ty cm Axx
][
    ca: cosine alpha
    sa: sine   alpha
    Tx: x0 - ( ca * x0 ) + ( sa * y0 )
    Ty: y0 - ( sa * x0 ) - ( ca * y0 )
    reduce [ ca sa negate sa ca Tx Ty 'cm]
]

translating: func [ dx dy /local cm ][
    reduce [ 1 0 0 1 dx dy 'cm ]
]
scaling: func [ 
    {Scales the angle alpha (degrees) around (x,y)
    A = 
	[  cx 0  0 ]
	[  0  cy 0 ]
	[  tx ty 1 ]

    x =  [ x y 1]
    X*A =
	[ cx*x + tx, +cy*y+ty, 1]
    [x0,y0] = X0 * A
	x0 = cx*x0+tx
	tx = x0 - cx*x0 = ( 1 - cx ) * x0
	y0 = cy*y0+ty
	ty = y0-cy*y0 ( 1 - cy ) * y0
    }
    scalex [number!] {Scale factor}
    /xy scaley [number!] {Scale x with scalex and y with this}
    /around x [number!] y [number!] {Scale around [x,y]}
    /local cm
][
    x: any [ x 0 ]
    y: any [ y 0 ]
    scaley: any [ scaley scalex ]
    reduce [ scalex 0 0 scaley 1 - scalex * x 1 - scaley * y 'cm ]
]


; Make the font in face/font be the default font by using it once
current-font: make face/font [  ]
; The standard Type1 fonts in pdf are:
; Times-Roman, Helvetica, Courier, Symbol,
; Times-Bold, Helvetica-Bold, Courier-Bold,
; ZapfDingbats, Times-Italic, Helvetica-Oblique,
; Courier-Oblique, Times-BoldItalic,
; Helvetica-BoldOblique, Courier-BoldOblique
if system/version/4 == 4
[
   current-font/name: "/usr/share/fonts/gnu-free/FreeSans.ttf"
   current-font/size: 12
]

face-to-page: func [
    name [word!]
    current-face [ object!]
    contents [block!]  {The objects that make  up the page, contents}
    resources  [word!]  {Reference to the object specifying the resources}
] [

    fy-py: func [ y ][ current-face/size/y - y ]
    get-media-box: func [  ][
	reduce [ 0 0 current-face/size/x current-face/size/y  ]
    ]

    face-box: first get-media-box f
    
    contents: copy contents
    forall contents [ insert contents 'Xs first+ contents ]

    obj name  compose/deep [ dict [ /Type /Page
			/Parent Xs pages
			/Contents [( contents) ]
			/MediaBox [(get-media-box )]
			/Resources Xs (resources)
		] ]

]

draw-to-stream: func [
    name [word!]  {Name of the stream object }
    cmd [ block!] {The draw commands to parse}
    f  [object!]  {The face from what to calculate original colours, and size}
    /noregister {Set this to only return a stream, do not register with name}
    /size sz
    /local
][

    fy-py: func [ y ][ ( any [ all [  sz sz/y ] f/size/y ])  - y ]

    strea: copy [ ]
    patterns: context [
	; locals 
	p: radius: string: pair: none
	current-pen:
	current-fill: none
	current-line-width: none

	; local functions
	stroke-aor-fill: does [
	    stroke-cmd: either current-pen
		[ either current-fill ['B] ['S ] ]
		[ either current-fill [ 'f] [ 'n ] ]
	]
	; Patterns
	line: [
	    'line opt [ set p pair! ( repend strea [ p/x fy-py p/y 'm ] ) ]
		  any [ set p pair! ( repend strea [ p/x fy-py p/y 'l ] )]
	    (append strea 'S) 
	]
	polygon: [
	    'polygon opt [ set p pair! ( repend strea [ p/x fy-py p/y 'm ] ) ]
		     any [ set p pair! ( repend strea [ p/x fy-py p/y 'l ] )]
		(append strea 'h append strea stroke-aor-fill)
	]
	line-width: [
	    'line-width set p number! ( current-line-width: p repend strea [ p 'w ] )
	]
	fill-pen:  [
	    'fill-pen [
		set color tuple! (
		    current-fill:  color 
		    repend strea [ current-fill 'rg ]
		) 
		| 
		none! ( current-fill: none )
	    ]
	]
	pen:  [
	    'pen [
		set color tuple! (
		    current-pen: color
		    repend strea [ current-pen 'RG ]
		) 
		| none! ( current-pen: none )
	    ]
	]
	circle: [
	    [ 'circle | 'ellipse ] set p pair!
		[ copy radius 1 2 number!  (   if 1 = length? probe radius [ append radius radius/1 ]  )
		    | copy radius pair! ( radius: to-block radius )
		]
		(
		    append strea draw-circle/xy p/x fy-py p/y radius/1 radius/2
		    append strea stroke-aor-fill
		)
	]
	translate: [
	    'translate set p pair! (
		append strea translating p/x negate p/y
	    )
	]
	scale: [
	    'scale copy p 2 number! (
		append strea scaling/xy/around p/1 p/2 0 f/size/y
	    )
	]
	rotate: [
	    'rotate set p number! (
		append strea probe rotating 0 f/size/y negate p
	    )
	]
	push: [
	    'push set cmds block! 
	    (
		repend strea [ 
		    'q ]
		eval-patterns cmds
		repend strea [ 'Q
		    ]
		set-current-env
	    )
	]
	text: [
	    'text ( render-mode: 0 )
		some [ 
		    set p pair! ( pair: p )
		    |
		    set s string! (string: s )
		    |
		    set word [ 'anti-aliased | 'vectorial ( render-mode: 'vectorial )| 'aliased ]
	    ]
	    (
		if render-mode = 'vectorial [
		    render-mode:    case [
			all [current-pen current-fill ][ 2 ]
			all [ not current-pen current-fill ] [ 0 ]
			all [ current-pen not current-fill ] [ 1 ]
			all [ not current-pen  not current-fill ] [ 3 ]
		    ]
		][
		    render-mode: 0
		]

		repend strea [
		    'q
		    'BT
		]
	    
		if all [ current-pen render-mode = 0 ][ repend strea [ current-pen  'rg ] ]
		repend strea [
		    use-font current-font current-font/size 'Tf
		    render-mode 'Tr
		    pair/x fy-py pair/y + current-font/size
		    'Td
		    string 'Tj
		]
		if all [ render-mode = 0 current-fill ][ repend strea [ current-fill  'rg ] ]
		repend strea [
		    'ET
		    'Q
		]
	    )
	]
	font: [
	    'font set fnt object!
	    (
		current-font: fnt
	    )
	]
	set-current-env: does [
	    if current-pen  [ repend strea [ current-pen 'rg ] ]
	    if current-fill [ repend strea [ current-fill 'rg ] ]
	    repend strea [ current-line-width 'w ]
	]

	eval-patterns: func [ pattern ][
	    
	    set-current-env

	    unless parse dbg: eval-draw pattern [
		any [ here:
		      line 
		    | polygon
		    | line-width
		    | fill-pen
		    | pen
		    | circle
		    | translate
		    | scale
		    | rotate
		    | push
		    | text
		    | font here: (print mold here)
		]
	    ] [
		make error! remold [ "Did not find end of pattern" here  newline "-----------------"]
	    ]
	]
    ]

    patterns/current-line-width: 1
    patterns/current-pen: any [ f/color white ]

    patterns/eval-patterns cmd
    
    unless noregister [
	stream name compose [ 
	    dict [
		/Length none
	    ]
	    stream
	    (strea)  ; Remove the space in previous line
	    endstream
	]
    ]
    strea
]

compose-file: func [
    /local str
] [

    fill-zeros: func [
	number 
	digits
	/local s
    ][
	head change skip insert/dup copy "" "0" digits negate length? s: to-string number s
    ]

    str: copy "%PDF-1.6"
    foreach o objs [ 
	print [ "Processing object" o/name ]
	o/proc-func
	append str newline
	append xrefs length? str
	append str o/to-string
    ]

    append str newline

    xref-str: copy ""
    append str rejoin [
	"xref" newline
	0 " " 1 + length? objs newline
	"0000000000 65535 f " newline
	rejoin map-each x xrefs [ rejoin [ fill-zeros x 10 " 00000 n "  newline ] ]
	"trailer" newline 
	to-pdf-string do-functions [dict [
	    /Size add length? xrefs 1 
	    /Root Xs catalog
	]] newline
	"startxref" newline
	length? str newline
	"%%EOF"
    ]
    str
]


obj 'catalog [ dict
    [ /Type /Catalog
	/Pages Xs pages
    ] ]

obj 'pages [ dict [
	/Type /Pages
	/Kids [ Xs page ]
	/Count 1
    ]
]

obj 'info [ dict [
	/Creator "pdf-creator.r"
	/CreationDate to-string now
] ]


used-fonts: copy []
font-translations: [
    "helvetica"		Helvetica
    "arial"		Helvetica
    "font-sans-serif"	Helvetica
    "FreeSans"		Helvetica
    "Courier"		Courier
    "font-fixed"	Courier
    "Times"		Times-Roman
    "Times-Roman"	Times-Roman
    "font-serif"	Times-Roman
]

translate-fontname: func [ name [string! word! ] /local new ] [
    if word? name [ name: to-string name ]
    new: any [ select font-translations name to-word name ]
    to-refinement new
]

use-font: func [ name /local use-name tmp ][
    if object? name [
	either all [ string? name/name find name/name "/" ][
	    name: copy/part tmp: next find/last name/name "/" any [ find/last tmp "." tail tmp ]
	][
	    name: name/name
	]
    ]
    append used-fonts use-name: translate-fontname name
    use-name
]
    

reduce-fonts: func [] [
    used-fonts: union used-fonts []
]

create-fonts-resource: func [
    /local dict
][
    dict: copy [
    ]
    foreach x used-fonts [
	repend dict  [ x 'Xs to-word x ]
	obj to-word x compose/deep [
	    dict [
		/Type /Font
		/Subtype /Type1
		/BaseFont   (to-refinement x )
	    ]
	]
    ]
    obj 'fonts-resource compose [ dict (reduce [ dict ] ) ]
]

{
Exampe of how fonts should be organized
obj page
<<  /Type /Page
    /Parent pages
    /Contents [ conts ]
    /MediaBox [ x y x y]
    /Resources resources
>>
endobj
obj conts
<<>>
endobj
obj resources
<<  /Font fonts
    /XObject xrefs
>>
endobj
obj fonts
<<  /Helvetica helvetica
    /Times-Roman times-roman
>>
endobj
obj helvetica
<<  /Type /Font
    /Subtype /Type1
    /BaseFont /Helvetica
>>
endobj
obj times-roman
<<  /Type /Font
    /Subtype /Type1
    /BaseFont /Times-Roman
>>
}
    
obj 'resources [
    dict [
	/Font Xs fonts-resource 
    ]
] 

register-image: func [
    img [image!]
][
    stream 'image compose/deep [
	dict [
	    /Type /XObject
	    /Subtype /Image
	    /Width (img/size/x)
	    /Height (img/size/y)
	    /ColorSpace /DeviceRGB
	    /BitsPerComponent 8
	    /Length none
	    /Filter /ASCIIHexDecode
	]
	stream
	(img)
	endstream
    ]
]

parse-face: func [
    face [object!]
    /local strea
][
    strea: copy []

    fy-py: func [ y ][ face/size/y - y ]

    repend strea [ 0x0 face/size 're 'W ] ; Set clipping
    
    if face/color [ ; background
	repend strea [
	    face/color 'rg
	    0 0 face/size 're 'f
	]
    ]
    if face/image [
	reference: register-image face/image
    ]

    if  block? p: face/effect [
	offset: any [
		    all [ face/edge face/edge/size ]
		    0x0
	]
	while [p: find p 'draw] [
	    append strea compose [
		q
		( translating offset/x offset/y )
		(
		    draw-to-stream/noregister/size
			'anything p/2
			face
			face/size - ( 2x2 * offset )
		)
		Q    
	    ]
	    p: skip p  2
	]
    ]
    if all [ face/text not find system/view/screen-face/pane face ] [
	line-info: make system/view/line-info []
	n: 0
	while [  textinfo face line-info n ][
	    edge: either all [ face/edge face/edge/size ][ face/edge/size ] [ 0x0 ]
	    x: line-info/offset/x + edge/x
	    y: face/size/y
		- line-info/offset/y
		- face/font/size
		- edge/y
	    append strea compose [
		BT (use-font face/font/name) (face/font/size) Tf
		(face/font/color) rg 
		( reduce [ x y ] )
		Td
		(copy/part line-info/start line-info/num-chars) Tj
		ET
	    ]
	    n: n + 1
	]
    ]
    if all [ face/edge face/edge/size face/edge/color ][
	use [ edge size nw-color se-color ][
	    edge: face/edge/size size: face/size
	    nw-color: se-color: face/edge/color
	    switch face/edge/effect [
		ibevel [
		    nw-color: hsv-to-rgb (rgb-to-hsv face/edge/color) - 0.0.63
		    se-color: hsv-to-rgb (rgb-to-hsv face/edge/color) + 0.0.63
		]
		bevel [
		    nw-color: hsv-to-rgb (rgb-to-hsv face/edge/color) + 0.0.63
		    se-color: hsv-to-rgb (rgb-to-hsv face/edge/color) - 0.0.63
		]
	    ]
	    repend strea [
		red 'RG
		nw-color 'rg
		0 0 'm
		edge 'l
		edge/x size/y - edge/y 'l
		size/x - edge/x size/y - edge/y 'l
		size 'l
		0 size/y 'l
		'h  'f
		se-color 'rg
		0 0 'm
		edge 'l
		size/x - edge/x edge/y 'l
		size/x - edge/y size/y - edge/y 'l
		size 'l
		size/x 0 'l
		'h 'f
	    ]
	]
    ]
    pane: get in face 'pane
    if :pane [
	print "*Parsing pane"
	unless block? :pane [ pane: reduce [ :pane ] ]
	foreach p pane [
	    case [
		object? :p [
		    probe pos: as-pair p/offset/x face/size/y - ( p/offset/y + p/size/y)
		    append strea 'q
		    append strea translating pos/x pos/y
		    append strea probe parse-face p
		    append strea 'Q
		]
		function? :p [ print "Transformation of functional panes not implemented" ]
		true	    [  print [ "Unknown object in pane!" type? :p ] ]
	    ]
	]
    ]
    strea
]



face-to-pdf: func [
    face
    /local
][
    strea: parse-face face

    stream 'content compose [
	dict [ /Length none ]
	stream
	(strea)
	endstream
    ]

    reduce-fonts
    create-fonts-resource


    face-to-page 'page f [ content ]  'resources 

    to-binary compose-file 
]

    


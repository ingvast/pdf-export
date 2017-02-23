REBOL []

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
w 	setlinewidth.
W 	clip.
y 	curveto.
}

do to-rebol-file rejoin [ get-env("BIOSERVO") %/Tools/rebol/libs/printf.r ]

space: #" "

Z: func [ msg con][ print rejoin [ msg ": " mold con ] con]

to-rgb: func [ rgb [tuple!] ][
    reduce [ rgb/1 / 255 rgb/2 / 255 rgb/3 / 255 ]
]
unpair: func [ p [pair!] ][ reduce [ p/1 p/2 ] ]

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
    |: '|
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

;1 0 obj
;<</Type /Catalog /Pages 2 0 R>>
;endobj

XsIf: func [ 'name /local i] [
    ? name
    either i: find names name [
	reduce [ (index? i ) 0 'R]
    ][
	print ["Warning!" name "is not defined!" ]
	[]
    ]
]

Xs: func [ 'name /local i] [
    ? name
    either i: find names name [
	reduce [ (index? i ) 0 'R]
    ][
	make error! rejoin [ {Cannot find object '} name {'} ]
    ]
]

refSort: func [ blk ][
    change blk sort/skip probe do-functions blk 3
    reduce [ blk ]
]

do-functions: func [ blk /local rslt ret ][
    rslt: copy []
    ;Z "call to do-cuntion with" mold blk
    while [ not empty? blk ] [
	if all [ word? first blk value? first blk any-function? get first blk ]
	[
	    change blk get first blk
	]
	either any-function? first blk
	[
	    ;Z "FUnction" blk
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


to-pdf-string: func [ blk /local str p ] [
    str: copy ""
    ;print [ type? blk copy/part _: mold blk any [find _ newline tail _ ]]
    forall blk [
	if new-line? blk [ if all [ not empty? str #" " = last str ] [ clear back tail str ] append str newline ]
	case [
	    block? first blk [
		append str rejoin [ "[ " to-pdf-string first blk " ]" ]
	    ]
	    'dict = first blk [
		unless block? second blk [ make error! "Dict must be following dict keyword" ]
		append str rejoin [ "<<" to-pdf-string second blk " >>" ]
		blk: next blk
	    ]
	    string? first blk [
		append str rejoin [ "(" first blk ")" ]
		append str space
	    ]
	    binary? first blk [
		append str copy/part skip p: mold first blk 2 back tail p
	    ]
	    image? first blk [
		append str copy/part skip p: mold to-binary first blk 2 back tail p
	    ]
	    pair? first blk [
		repend str form unpair first blk
	    ]
	    tuple? first blk [
		repend str form to-rgb first blk
	    ]
	    true [
		append str mold first blk
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
	    str: reform [ index? find names name 0 "obj" newline ]
	    append str to-pdf-string block
	    repend str [ newline "endobj" ]
	    str
	]
    ]
    last objs
]

stream: func [ name blk /local obj ret ][
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
	    change next find dict/dict /Length (length? stream-str)
	    append str to-pdf-string dict
	    repend str [ newline "stream" newline]
	    append str stream-str
	    repend str [ newline "endstream" ]
	    repend str [ newline "endobj" ]
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
	x - rx y     'c
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
	ty = y0-sa*x0-ca*y0
}

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
    ? scaley ? y
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
   ;current-font/name: "/usr/share/fonts/msttcore/times.ttf"
    current-font/size: 12
]
view/new layout [ box effect[draw [ font current-font text "test" font current-font text "jj" vectorial]]] unview/all


face-to-page: func [
    name [word!]
    current-face [ object!]
    contents [block!]  {The objects that make  up the page, contents}
    resources  [word!]  {Reference to the object specifying the resources}
] [

    fy-py: func [ y ][ current-face/size/y - y ]
    get-media-box: func [  ][
	reduce [ reduce [ 0 0 current-face/size/x current-face/size/y  ] ]
    ]

    face-box: first get-media-box f

    if current-face/color [
	stream 'background compose [
	    dict [
		/Length none
	    ]
	    stream
	    ( reduce [ current-face/color/1 / 255 current-face/color/2 / 255 current-face/color/3 / 255 ] ) rg
	    0 0 m
	    ( reduce [ face-box/3 0 'l face-box/3 face-box/4 'l 0 face-box/4 'l 'h 'f] )
	    endstream
	]
    ]
    
    contents: copy contents
    forall contents [ insert contents 'Xs first+ contents ]

    obj name  compose/deep [ dict [ /Type /Page
			/Parent Xs pages
			/Contents [ XsIf background ( contents) ]
			/MediaBox get-media-box 
			/Resources Xs (resources)
		] ]

]

draw-to-stream: func [
    name [word!]  {Name of the stream object }
    cmd [ block!] {The draw commands to parse}
    f  [object!]  {The face from what to calculate original colours, and size}
    /noregister {Set this to only return a stream, do not register with name}
    /local
][

    fy-py: func [ y ][ f/size/y - y ]

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
		    current-fill: reduce [ color/1 / 255 color/2 / 255 color/3 / 255 ] 
		    repend strea [ current-fill/1 current-fill/2 current-fill/3 'rg ]
		) 
		| 
		none! ( current-fill: none )
	    ]
	]
	pen:  [
	    'pen [
		set color tuple! (
		    current-pen: reduce [ color/1 / 255 color/2 / 255 color/3 / 255 ] 
		    repend strea [ current-pen/1 current-pen/2 current-pen/3 'RG ]
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
	    'text
		some [ 
		    set p pair! ( pair: p )
		    |
		    set s string! (string: s )
		    |
		    set word [ 'anti-aliased | 'vectorial | 'aliased ]
	    ]
	    (
		append strea 'BT
		repend strea [ use-font current-font current-font/size 'Tf pair/x f/size/y - pair/y - current-font/size 'Td ]
		repend strea [ string 'Tj ]
		append strea 'ET
	    )
	]
	font: [
	    'font set font object!
	    (
		current-font: font
	    )
	]
	set-current-env: does [
	    if current-pen  [ repend strea [ current-pen/1 current-pen/2 current-pen/3 'RG ] ]
	    if current-fill [ repend strea [ current-fill/1 current-fill/2 current-fill/3 'rg ] ]
	    repend strea [ current-line-width 'w ]
	]

	eval-patterns: func [ pattern ][
	    
	    set-current-env

	    unless parse eval-draw pattern [
		any [
		      patterns/line 
		    | patterns/polygon
		    | patterns/line-width
		    | patterns/fill-pen
		    | patterns/pen
		    | patterns/circle
		    | patterns/translate
		    | patterns/scale
		    | patterns/rotate
		    | patterns/push
		    | patterns/text
		    | patterns/font
		]
	    ] [
		print [ "Did not find end of pattern" pattern  newline "-----------------"]
	    ]
	]
    ]

    patterns/current-line-width: 1
    patterns/current-pen: if f/color [ 
			    reduce [ 255 - f/color/1 / 255 255 - f/color/2 / 255 255 - f/color/3 / 255 ]
			  ][
			    [ 1 1 1 ]
			  ]

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

compose-file: func [ ]
[
    str: copy "%PDF-1.6"
    forall objs [ 
	print [ "Processing object" objs/1/name ]
	objs/1/proc-func
	append str newline
	append xrefs length? str
	append str objs/1/to-string
    ]
    append str newline

    xref-str: copy ""
    append str rejoin [
	"xref" newline
	0 space 1 + length? objs newline
	"0000000000 65535 f " newline
	rejoin map-each x xrefs [ join sprintf [ "%010d 00000 n " x]  newline ]
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

    


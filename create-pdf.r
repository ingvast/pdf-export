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
    |: '|
    Tf: 'Tf
    dict: 'dict
]


xrefs: copy []

;1 0 obj
;<</Type /Catalog /Pages 2 0 R>>
;endobj

Xs: func [ 'name ] [
    reduce [ (index? find names name) 0 'R]
]
refSort: func [ blk ][
    change blk sort/skip do-functions blk 3
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

convert-strings: func [ blk ][
    error! "LKjlkJ"
    forall blk [
	case [
	    block? first blk [
		convert-strings first blk
	    ]
	    string? blk [
		change blk rejoin [ "(" blk ")" ]
	    ]
	]
    ]
]


to-pdf-string: func [ blk /local str ] [
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
		append str rejoin [ "<<" to-pdf-string second blk ">>" ]
		blk: next blk
	    ]
	    string? first blk [
		append str rejoin [ "(" first blk ")" ]
		append str " "
	    ]
	    true [
		append str mold first blk
		append str " "
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
	Z "Stream is" stream
	proc-func: func [][
	    dict:   do-functions dict
	    stream: do-functions stream
	]
	to-string: func [/local str stream-str ] [
	    str: reform [ index? find names name 0 "obj" newline ] 
	    stream-str: probe to-pdf-string probe stream
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
circle: func [ x y r /local d c m ][
    d: r * 4 * ( ( square-root 2 ) - 1 ) / 3 
    reduce [
	x - r y     'm 
	x - r y + d 
	x - d y + r
	x     y + r 'c
	x + d y + r
	x + r y + d
	x + r y     'c
	x + r y - d
	x + d y - r
	x     y - r 'c
	x - d y - r
	x - r y - d
	x - r y     'c
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
scaling: func [ scale /local cm ][
    reduce [ scale 0 0 scale 0 0 ]
]

[
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
    obj 'page [ dict [ /Type /Page
			/Parent Xs pages
			/Contents refSort [ Xs cont1 Xs cont2 ]
			/MediaBox [0 0 500 800 ]
			/Resources Xs resourse
		] ]
    obj 'resourse [ dict [ /Font dict [ /F1 Xs font ]] ]
    obj 'font [ dict [ 
			/Type /Font
			/Subtype /Type1
			/BaseFont /Helvetica
		]]
    stream 'cont1 [ dict [
	    /Length none
	]
	stream 
	100 100 m 100 150 l 200 150 l 200 100 l S
	100 100 m 100 150 200 150  200 100 c S
	q 1 0 0 1 300 100 cm
	-50 50 m 50 50 l 50 -50 l -50 -50 l s
	-50 0 m  -50 40 -40 50 0 50 v 
	         50 50 50 50 50 0 v
		 50 -50 50 -50 0 -50 v
		-50 -50 -50 -50 -50 0 v
	f
	1 0 0 RG
	-50 0 m 
	-50 -50 -50 50 y
	S
	Q
	q 1 0.1 -0.1 0.75 0 0 cm
	175 520 m 200 400 800 400 400 400 v 100 450 50 75 re h S 
	175 520 m 800 400 l 400 400 l  h S 
	Q
	3 w
	0 1 0 RG
	circle 175 520 100 S
	175 520 m 275 520 l S
	1 0 0 RG
	q
	translating 1 0
	2.5 w
	rotating 175 520 22.5
	circle 175 520 5 S
	circle 175 520 100 S
	175 520 m 275 520 l S
	Q
	
	BT
	/F1 12 Tf 100 450 Td
	"Me and Melindas" Tj
	12 TL
	"Ho Ho PPP" Tj
	12 TL
	"Ho HoC" Tj
	T*
	"Ho Ho3" Tj
	T*
	"Ho Ho4" Tj
	
	ET
	175 520 m 200 | 300 600 400 400 v 100 450 50 75 re h S 
	endstream
    ]

    stream 'cont2 [ dict [
	    /Length none
	]
	stream 
	BT
	/F1 24 Tf
	100 100 Td "Johan Ingvast" Tj
	ET
	endstream
    ]
]
[
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
    obj 'page [ dict [ /Type /Page
			/Parent Xs pages
			/Contents refSort Xs cont 
			/MediaBox [0 0 500 800 ]
			;/Resources dict [ /ProcSet [/PDF] ]
		] ]
    stream 'cont [ dict [
	    /Length none
	]
	stream 
	175 520 m 200 | 300 600 400 400 v 100 450 50 75 re h S 
	endstream
    ]
]
[
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
    obj 'page [ dict [ /Type /Page
			/Parent Xs pages
			/Resources Xs resourse
			/MediaBox [0 0 500 800 ]
			/Contents Xs cont
		] ]
    obj 'resourse [ dict [ /Font dict [ /F1 Xs font ]] ]
    obj 'font [ dict [ 
			/Type /Font
			/Subtype /Type1
			/BaseFont /Times-Roman
		]]
    stream 'cont [ dict [
	    /Length none
	]
	stream 
	BT /F1 24 Tf 175 720 Td "Hello World!" Tj ET
	;BT
	;/F1 24 Tf
	;100 100 Td "Johan Ingvast" Tj
	;ET
	endstream
    ]
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
obj 'resourse [ dict [ /Font dict [ /F1 Xs font ]] ]
obj 'font [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Helvetica
		]]

view/new layout [ f: box red 500x500 effect [ draw [ line 0x0 200x100  300x200 500x100] ] ]

current-face: none
fy-py: func [ y ][ current-face/size/y - y ]
get-media-box: func [ face ][
    current-face: face
    reduce [ reduce [ 0 0 face/size/x face/size/y  ] ]
]
face-box: first get-media-box f

obj 'page [ dict [ /Type /Page
		    /Parent Xs pages
		    /Contents refSort [ Xs background Xs cont ]
		    /MediaBox get-media-box f
		    /Resources Xs resourse
	    ] ]

strea: []
parse f/effect/draw [
    'line opt [ set p pair! ( repend strea [ p/x fy-py p/y 'm ] ) ]
	  any [ set p pair! ( repend strea [ p/x fy-py p/y 'l ] )]
    (append strea 'S) 
]
either f/color [
    stream 'background compose [
	dict [
	    /Length none
	]
	stream

	( reduce [ f/color/1 / 255 f/color/2 / 255 f/color/3 / 255 ] ) rg
	0 0 m
	( reduce [ face-box/3 0 'l face-box/3 face-box/4 'l 0 face-box/4 'l 'h 'f] )
	endstream
    ]
]
[
    obj 'background []
]

stream 'cont compose [ 
    dict [
	/Length none
    ]
    stream

    (strea)
    endstream
]

str: "%PDF-1.6"
forall objs [ 
    print [ "Procesing object" objs/1/name ]
    objs/1/proc-func
    append str newline
    append xrefs length? str
    append str objs/1/to-string
]
append str newline

xref-str: copy ""

append str reform [
    "xref" newline
    0 1 + length? objs newline
    "0000000000 65535 f" newline
    rejoin map-each x xrefs [ join sprintf [ "%010d 00000 n " x - 1]  newline ]
    "trailer" newline
    to-pdf-string do-functions [dict [
	/Size add length? xrefs 1 
	/Root Xs catalog
    ]] newline
    "startxref" newline
    length? str newline
    "%%EOF"
]

write %test.pdf str
    


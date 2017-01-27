%PDF-1.6
REBOL []

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
		append str rejoin [ "<< " to-pdf-string second blk " >>" ]
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
    if #" " = last str [ clear back tail str ]
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
	dict: bind copy/part block
	    stream: find block 'stream pdf-bindings
	proc-func: func [][
	    stream: do-functions stream
	]
	to-string: func [/local str stream-str ] [
	    str: reform [ index? find names name 0 "obj" newline ]
	    stream-str: to-pdf-string stream
	    change next find dict/dict /Length (length? stream-str)
	    append str to-pdf-string dict
	    append str newline
	    append str stream-str
	    repend str [ newline "endobj" ]
	    str
	]
    ]
    last objs
]

do def
def: [
  obj 'catalog [ dict
	[ /Type /Catalog
	    /Pages Xs pages 
	] ]
    obj 'pages [ dict [
	    /Type /Pages
	    /Kids [ Xs mbox Xs page ]
	    /Count 2
	]
    ]
    obj 'mbox [ dict [
	    /MediaBox [0 0 800 500]
	]]
    obj 'info [ dict [
	    /Creator "pdf-creator.r"
	    /CreationDate to-string now
    ] ]
    obj 'page [ dict [ /Type /Page /Parent pages /Contents Xs cont] ]
    stream 'cont [ dict [
	    /Length none
	]
	stream 
	175 720 m 500 | 300 800 400 600 v 100 650 50 75 re h S 
	endstream
    ]
]
str: "%PDF-1.6"
forall objs [ 
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
    rejoin map-each x xrefs [ join sprintf [ "%010d 00000 n" x ]  newline ]
    "trailer" newline
    to-pdf-string do-functions [dict [
	/Size add length? xrefs 1 
	/Root Xs catalog
	/Info Xs info
    ]] newline
    "startxref" newline
    length? str newline
    "%%EOF"
]

write %test.pdf str
    



;xref
;0 6
;0000000000 65535 f
;0000000009 00000 n
;0000000056 00000 n
;0000000117 00000 n
;0000000160 00000 n
;0000000222 00000 n
;trailer <</Size 4/Root 1 0 R>>
;startxref
;324
;%%EOF



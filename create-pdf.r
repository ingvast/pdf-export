%PDF-1.6
REBOL []

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

stream: 'stream
endstream: 'endstream

;1 0 obj
;<</Type /Catalog /Pages 2 0 R>>
;endobj
def: [
  'catalog [
	dict [
	    /Type 'Catalog
	    /Pages Xs pages 
	]
    ]
;2 0 obj
;<</Type /Pages /Kids [3 0 R 4 0 R] /Count 2>>
;endobj
    'pages [
	dict [
	    /Type 'Pages
	    /Kids [ Xs mbox Xs cont ]
	    /Count 2
	]
    ]
;3 0 obj
;<</MediaBox [0 0 800 500]>>
;endobj
    'mbox [
	dict [
	    /MediaBox [0 0 800 500]
	]
    ]
;4 0 obj
;<</Type /Page
;/Parent 2 0 R
;/Contents 5 0 R >>
;endobj
    'cont [
	'dict [
	    /Length none
	]
	stream 
	175 720 m 500 | 300 800 400 600 v 100 650 50 75 re h S 
	endstream
    ]
]

Xs: func [ 'arg ][
    o: context [ 
	name: arg
	f: func [] [
	    reduce [ (index? find d to-lit-word name) + 1 / 2 0 'R]
	]
    ]
    get in o 'f
]

do-functions: func [ blk /local rslt ret ][
    rslt: copy []
    while [ not empty? blk ] [
	if all [ word? first blk any-function? get first blk ]
	[
	    change blk get first blk ]
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

Z: func [ msg con][ print rejoin [ msg ": " mold con ] con]

to-pdf-string: func [ blk /local str ] [
    str: copy ""
    print [ type? blk copy/part _: mold blk any [find _ newline tail _ ]]
    forall blk [
	if new-line? blk [ if all [ not empty? str #" " = last str ] [ clear back tail str ] append str newline ]
	case [
	    block? first blk [
		append str rejoin [ "[ " to-pdf-string first blk " ]" ]
	    ]
	    'dict = first blk [
		print "FOund dict"
		unless block? second blk [ make error! "Dict must be following dict keyword" ]
		append str rejoin [ "<< " to-pdf-string Z "dict" second blk " >>" ]
		blk: next blk
	    ]
	    string? first blk [
		append str first blk
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


bind def pdf-bindings
probe d: do-functions def
probe dd: do-functions d
convert-strings dd
probe dd
probe to-pdf-string dd
halt



d: copy []
; make objects
foreach [name obj] def [ repend d [name reduce bind obj pdf-bindings ] ]

pdf-rslt: copy
{%PDF-1.6
}

emit-pdf: func [ blk /as-is ][
    either as-is
    [ append pdf-rslt blk  ]
    [
	case  [
	    any [ word? :blk  number? :blk ]
		[ append pdf-rslt rejoin [ " " blk ] ]
	    char? blk [ append pdf-rslt newline ]
	    string? :blk 
		[ repend pdf-rslt rejoin [ "(" blk ") " ] ]
	    block? :blk
		[ forall blk [ if new-line? blk [ emit-pdf/as-is newline ] emit-pdf first blk  ] ]
	    refinement? :blk
		[  append pdf-rslt rejoin [ mold :blk  " " ] ]
	    any-function? :blk  
		[ emit-pdf blk ]
	    true [ print [ "Can't process " :blk ] ]
	]
    ]
]

; Print out objects
xrslt: copy []
obj-names: copy []

repeat obj-number (length? d) / 2 [

    ; Put position into xref table
    append xrslt length? pdf-rslt

    emit-pdf reduce [ obj-number 0 'R 'obj newline ]

    append obj-names first d

    obj-content: second d

    while [not empty? obj-content] [  ; Loop thru the vector
	obj: first obj-content
	case [
	    obj = 'stream [
		emit-pdf copy/part obj-content
			      next obj-content: find obj-content 'endstream
	    ]
	    object? obj [
		emit-pdf/as-is "<<"
		foreach name next first obj [ 
		    emit-pdf reduce [ to-refinement name  get in obj name ]
		    ;if function? get in obj name [ dbg: get in obj name asdf]
		    emit-pdf/as-is newline
		]
		emit-pdf/as-is reform [ ">>" newline ]
	    ]
	    true [ 
		error reform ["Something not handled in" second d]
	    ]
	]
	obj-content: next obj-content
    ]
    d: skip d 2
]
    
probe pdf-rslt



;5 0 obj
;<</Length 17>>
;stream
;endstream
;endobj
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



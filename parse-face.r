REBOL [
]

do %create-pdf.r

view/new layout [
    f: text "Face text" green  500x500 effect [
	draw [
	    pen none
	    fill-pen red
	    font current-font 
	    text 50x50 "Draw text" vectorial
	    line-width 5
	    pen blue
	    line 50x74 150x74
	] ]
	edge [ size: 1x1 color: black ]
]

to-rgb: func [ rgb [tuple!] ][
    reduce [ rgb/1 / 255 rgb/2 / 255 rgb/3 / 255 ]
]
unpair: func [ p [pair!] ][ reduce [ p/1 p/2 ] ]

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
    "arial"		Helvetica
    "font-sans-serif"	Helvetica
    "Courier"		Courier
    "font-fixed"	Courier
    "Times"		Times-Roman
    "font-serif"	Times-Roman
]

translate-fontname: func [ name [string! word! ] /local new ] [
    if word? name [ name: to-string name ]
    new: any [ select font-translations name to-word name ]
    to-refinement new
]

use-font: func [ name /local use-name ][
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
    /Xref xrefs
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
	/Font dict [ Xs fonts-resource ]
    ]
] 

parse-face: func [
    face [object!]
    /local ;strea
][
    strea: copy []

    fy-py: func [ y ][ face/size/y - y ]
    
    if face/color [
	repend strea [
	    rgb face/color 'rg
	    0 0 unpair face/size 're
	]
    ]
    if face/edge [
    ]
    if face/image [
    ]

    if  block? p: face/effect [
	while [p: find p 'draw] [
	    append strea compose [ q ( draw-to-stream/noregister 'anything p/2 face ) Q ]
	    p: skip p  2
	]
    ]
    if face/text [
	append strea compose [
	    BT (use-font face/font/name) (face/font/size) Tf
	    (to-rgb face/font/color) rg 
	    ( unpair (as-pair 0 face/size/y ) + ( 1x-1 * caret-to-offset face face/text ) - as-pair 0 face/font/size ) Td
	    (face/text) Tj
	    ET
	]
    ]
    pane: get in face 'pane
    if :pane [
	unless block? :pane [ pane: reduce [ :pane ] ]
	foreach p pane [
	    case [
		object? :pane [
		    append strea 'q
		    append strea parse-face p
		    append strea 'Q
		]
		function? :pane [ print "Transformation of functional panes not implemented" ]
		true	    [  print [ "Unknown object in pane!" type? :p ] ]
	    ]
	]
    ]
    strea
]



strea: parse-face f

stream 'face-text compose [
    dict [ /Length none ]
    stream
    (strea)
    endstream
]
o: last objs
o/proc-func


comment [
    stream 'face-text compose [
	dict [ /Length none ] 
	stream
	q 
	BT use-font f/font/name 12 Tf
	to-rgb f/font/color rg 
	( unpair (as-pair 0 f/size/y ) + ( 1x-1 * caret-to-offset f f/text ) - as-pair 0 f/font/size ) Td
	(f/text) Tj
	ET
	Q
	endstream
    ]
]

reduce-fonts
create-fonts-resource

;draw-to-stream 'cont f/effect/draw f

face-to-page 'page f [ face-text ]  'resources 

write %test.pdf compose-file 



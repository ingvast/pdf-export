REBOL [
]

do %create-pdf.r

view/new  f: layout [
     area "asdfads" green  200x500 wrap effect [
	draw [
	    pen blue
	    fill-pen red
	    font current-font 
	    text 50x50 "Draw text" 
	    line-width 3
	    pen cyan
	    line 50x62 150x62
	] ]
	edge [ size: 20x20 color: brown effect: 'bevel]
	font [ name: "times" ]
]

f/pane/1/text: {
to-rgb: func [ rgb [tuple!] ][
	reduce [ rgb/1 / 255 rgb/2 / 255 rgb/3 / 255 ]
]
unpair: func [ p [pair!] ][ reduce [ p/1 p/2 ] ]
}
show f



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
	/Font Xs fonts-resource 
    ]
] 

parse-face: func [
    face [object!]
    /local strea
][
    strea: copy []

    fy-py: func [ y ][ face/size/y - y ]
    
    if face/color [ ; background
	repend strea [
	    face/color 'rg
	    0 0 face/size 're 'f
	]
    ]
    if face/image [
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
		    append strea 'q
		    append strea translating p/offset/x  p/offset/y
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



strea: parse-face f

stream 'content compose [
    dict [ /Length none ]
    stream
    (strea)
    endstream
]
o: last objs
o/proc-func

reduce-fonts
create-fonts-resource


face-to-page 'page f [ content ]  'resources 

write %test.pdf compose-file 



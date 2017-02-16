REBOL [
]

do %create-pdf.r

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

obj 'resources [ dict [ /Font dict [
	    /Helvetica Xs Helvetica
	    /Times-Roman Xs Times-Roman
]] ]

obj 'Helvetica [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Helvetica
		]]
obj 'Times-Roman [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Times-Roman
		]]

view/new layout [
    f: text "Face text" black  500x500 effect [
	draw [
	    pen none
	    fill-pen red
	    font current-font
	    text 40x3 "Draw text" vectorial
	    line-width 5
	    pen blue
	    line 50x74 150x74
	] ]
	edge [ size: 1x1 color: black ]
]

font-translations: [
    "arial"		/Helvetica
    "font-sans-serif"	/Helvetica
    "Courier"		/Courier
    "font-fixed"	/Courier
    "Times"		/Times-Roman
    "font-serif"	/Times-Roman
]

translate-fontname: func [ name [string! word! ] ] [
    if word? name [ name: to-string name ]
    any [ select font-translations name to-refinement name ]
]

to-rgb: func [ rgb [tuple!] ][
    reduce [ rgb/1 / 255 rgb/2 / 255 rgb/3 / 255 ]
]
unpair: func [ p [pair!] ][ reduce [ p/1 p/2 ] ]

stream 'face-text compose [
    dict [ /Length none ] 
    stream
    q 
    BT translate-fontname f/font/name 12 Tf
    to-rgb f/font/color rg 
    ( unpair (as-pair 0 f/size/y ) + ( 1x-1 * caret-to-offset f f/text ) - as-pair 0 f/font/size ) Td
    (f/text) Tj
    ET
    Q
    endstream
]

draw-to-stream 'cont f/effect/draw f

face-to-page 'page f [ cont face-text ]  'resources 

write %test.pdf compose-file 



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
	    /F1 Xs Helvetica
	    /F2 Xs Times-Roman
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

stream 'face-text compose [
    dict [ /Length none ] 
    stream
    q 
    BT /F1 12 Tf
    to-rgb f/font/color rg 
    0 (f/size/y - current-font/size) Td
    (f/text) Tj
    ET
    100 100 m 200 200 l S
    Q
    endstream
]

draw-to-stream 'cont f/effect/draw f

face-to-page 'page f [ cont face-text ]  'resources 

write %test.pdf compose-file 



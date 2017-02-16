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

obj 'resources [ dict [ /Font dict [ /F1 Xs font ]] ]

obj 'font [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Helvetica
		]]

view/new layout [
    f: box ivory  500x500 effect [
	draw [
	    pen none
	    fill-pen red
	    font current-font
	    text 50x50 "Johan" vectorial
	] ]
]

draw-to-stream 'cont f/effect/draw f
face-to-page 'page f [ cont ]  'resources 


write %test.pdf compose-file 



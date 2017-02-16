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

obj 'resource [ dict [ /Font dict [ /F1 Xs font ]] ]

obj 'font [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Helvetica
		]]

view/new layout [
    f: box white  500x500 effect [
	draw [
	    font current-font
	    text 50x50 "Johan" vectorial
	] ]
]

face-to-page 'page f [ cont ] [ resource ]

draw-to-stream 'cont f/effect/draw f

write %test.pdf compose-file 



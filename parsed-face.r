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
obj 'resourse [ dict [ /Font dict [ /F1 Xs font ]] ]

obj 'font [ dict [ 
		    /Type /Font
		    /Subtype /Type1
		    /BaseFont /Times-Roman
		]]

view/new layout [
    f: box snow 500x500 effect [
	draw [
	    font current-font
	    fill-pen black line-width 1 pen none
	    text 50x50 "Johan" vectorial
	    line-width 1
	    push [
		scale 0.9 1.1 
		translate 0x100
		rotate 30
		line-width 3
		fill-pen blue
		polygon 0x0 200x100  300x200 500x100 
		circle 300x200 50
		line 200x200 250x200
		pen none fill-pen black
		text 200x200 "Ingvast" vectorial
	    ]
	    pen green line-width 3
	    circle 200x200 50 40
	] ]
]

face-to-media 'draw f/effect/draw

draw-to-stream 'draw f/effect/draw




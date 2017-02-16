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
		    /BaseFont /Times-Roman
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
    draw-circle 175 520 100 S
    175 520 m 275 520 l S
    1 0 0 RG
    q
    translating 1 0
    2.5 w
    rotating 175 520 22.5
    draw-circle 175 520 5 S
    draw-circle 175 520 100 S
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

write %test.pdf compose-file

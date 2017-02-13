REBOL [
       ]

do %create-pdf.r
do [
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
    obj 'page [ dict [ /Type /Page
			/Parent Xs pages
			/Resources [ Xs resourse Xs pdf-image ]
			/MediaBox [0 0 500 800 ]
			/Contents Xs cont
		] ]
    obj 'resourse [ dict [ /Font dict [ /F1 Xs font ]] ]
    obj 'font [ dict [ 
			/Type /Font
			/Subtype /Type1
			/BaseFont /Times-Roman
		]]
    obj 'pdf-imgage [ dict [
	    /ProcSet [/PDF /ImageC ]
	    /XObject dict [  /Im1 Xs theImage ]
	]]

    stream 'theImage compose [
	dict [
	    Type /XObject
	    /Subtype /Image
	    /Width 124
	    /Height 24
	    /Colorspace /DeviceRGB
	    /BitsPeromponent 8
	    /Lenght none
	    /Filter /ASCIIHexDecode
	]
	stream
	    ( logo.gif )
	endstream
]
	
		
    stream 'cont [ dict [
	    /Length none
	]
	stream 
	BT /F1 24 Tf 175 720 Td "Hello World!" Tj ET
	;BT
	;/F1 24 Tf
	;100 100 Td "Johan Ingvast" Tj
	;ET
	endstream
    ]
]

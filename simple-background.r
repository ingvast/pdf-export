[
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
			/Contents refSort Xs cont 
			/MediaBox [0 0 500 800 ]
			;/Resources dict [ /ProcSet [/PDF] ]
		] ]
    stream 'cont [ dict [
	    /Length none
	]
	stream 
	175 520 m 200 | 300 600 400 400 v 100 450 50 75 re h S 
	endstream
    ]
]

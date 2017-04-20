REBOL [
    title: {PDF creation functions. Basics for building a pdf document}
    author: {Johan Ingvast}
]

module: :context

pdf-lib: module [
    space: #" "

    has-alpha: func [ im [
	{Returns none if there is a alpha value not zero}
	image!
    ] ][
	find im/alpha charset [ #"^(1)" - #"^(255)" ]
    ]

    image-rgb!: make object! [
	type: 'image-rgb!
	image: none
    ]

    image-alpha!: make object! [
	type: 'image-alpha!
	image: none
    ]

    image-rgb?: func [ obj ][
	all[
	    object? obj
	    get in obj 'type
	    obj/type = 'image-rgb!
	]
    ]

    image-alpha?: func [ obj ][
	all[
	    object? obj
	    get in obj 'type
	    obj/type = 'image-alpha!
	]
    ]

    to-pdf-string: func [
	{Takes a block of pdf graphics commands (encoded as rebol) and
	converts it to a string that pdf can parse.
	pairs are converted to two numbers.
	tuples are converted to a number of decimals by dividing them with 255
	}
	obj-list [block!] {A list of objects for the document}
	blk  [block!] {The content to make string of, objects are converted to references}
	/local str p 
	    string from to
    ] [

	str: copy ""
	forall blk [
	    arg: first blk
	    if new-line? blk [
		if all [
		    not empty? str
		    space = last str
		] [
		    clear back
		    tail str
		]
		append str newline
	    ]
	    case [
		block? arg [
		    append str rejoin [ "[ " to-pdf-string obj-list arg " ]" ]
		]
		string? arg [
		    string-replacements: [
			"\" "\\"
			"(" "\("
			")" "\)"
		    ]
		    string: copy arg
		    foreach [ from to ] string-replacements [ replace/all string from to ]
		    append str rejoin [ "(" string ")" ]
		    append str space
		]
		binary? arg [
		    append str copy/part skip p: mold arg 2 back tail p
		]
		image? arg [
		    append str copy/part skip p: mold to-binary arg/rgb 2 back tail p
		]
		image-rgb? arg [
		    append str copy/part skip p: mold to-binary arg/image/rgb 2 back tail p
		]
		image-alpha? arg [
		    append str copy/part skip p: mold to-binary arg/image/alpha 2 back tail p
		]
		pair? arg [
		    repend str reform [ arg/x arg/y ]
		    append str space
		]
		tuple? arg [
		    repeat i length? arg [
			append str sprintf reduce [ "%f " ( pick arg i ) / 255.0 ]
		    ]
		]
		logic? arg [
		    append str either arg [ "true " ]["false "]
		]
		object? arg [
			; If there is a object, assume it is a object representing 
			; a pdf-object
			; Hence write out id 0 R
			append str form get-obj-reference obj-list arg
			append str space
		]
		decimal? arg [
		    append str sprintf [ "%f " arg ]
		]
		true [
		    append str mold arg
		    append str space
		]
	    ]
	]
	if all [
	    not empty? str
	    space = last str
	] [
	    clear back tail str
	]
	str
    ]



    get-obj-id: func [ obj-list obj ][ index? find obj-list obj ]

    get-obj-reference: func [ obj-list obj ][
	reduce [ get-obj-id obj-list obj  0 'R ]
    ]

    base-obj!: make object! [
	header: func [ obj-list] [ reduce [ get-obj-id obj-list self 0 'obj ] ] ;Head should print the first line of object
	footer: "endobj"
	init: none
	
	Type: /base-obj!

	dict: [
	]

	obj-position: none
	string: ""
	check: func [
	    {Checks that all required fields are set.
	    A field is required by setting it 'required.
	    }
	][
	    foreach field dict [
		if 'required = get in self field [
		    err-obj: self
		    make error! reform [ "Field" field "in object of type" Type "is not set" ]
		]
	    ]
	]
	to-string: func[ obj-list /is-stream ] [
	    string: copy ""
	    if :header [
		append string to-pdf-string obj-list header obj-list
		append string newline
	    ]
	    append string "<<^/"
	    use [ val ][
		foreach field dict [
		    val: get in self field
		    if val [
			append string tab
			append string to-pdf-string obj-list reduce [ to-refinement field  ]
			append string tab
			append string to-pdf-string obj-list reduce [ val ] ; Execute function if necessary
			append string newline
		    ]
		]
	    ]
	    append string ">>^/"
	    if all [ footer  not is-stream ] [ repend string [ footer newline ] ]
	    string
	]
    ]

    base-stream!: make base-obj! [
	Type: /stream
	to-string*: :to-string
	stream-start: 'stream
	stream-end: 'endstream

	append dict 'Length

	stream: []
	Length: does [ length? stream-string ]
	stream-string: ""
	to-string: func [ obj-list ] [
	    unless block? stream [ stream: reduce [ stream ] ]
	    stream-string: to-pdf-string obj-list stream
	    to-string*/is-stream obj-list
	    append string stream-start
	    append string newline
	    append string stream-string
	    append string newline
	    if stream-end [ repend string [ stream-end newline ] ]
	    if footer [ repend string  [ footer newline ] ]
	    string
	]
	init: func [ spec ][
	    stream: :spec
	]
    ]

    pages-dict!: make base-obj! [
	Type: /Pages
	append dict [ Type Kids Count Parent ]
	Parent:  none
	Kids: []
	Count: does [length? Kids ]
	add-kid: func [ ps ][
	    unless block? ps [ ps: reduce [ ps ] ]
	    foreach p ps [
		if word? p [ p: get p ]
		unless all [
		    object? p 
		    find [ /page /pages ] p/Type
		][
		    make error! rejoin [ "Pages called with objects not being page or pages" p ]
		]
		p/Parent: self
		append Kids p
	    ]
	]

	init: func [ spec [block!] ][
	    add-kid spec
	]	    
    ]

    page-dict!: make base-obj! [
	Type: /Page
	Parent: 'required
	MediaBox: 'required
	Contents:  'required
	Resources: none

	append dict [ Type Parent Resources MediaBox Contents ]

	set-mediaBox: func [ re [ block! ] ][
	    MediaBox: re
	]
	add-content: func [ cont ][
	    unless block? cont [ cont: reduce [ cont ] ]
	    unless block? Contents [ Contents: copy [] ]
	    foreach c  cont [
		unless all [ object? c c/Type = 'stream ] [
		    make error! rejoin [ {Not a valid content} mold c ]
		]
		append Contents c
	    ]
	]
	add-resource: func [ res ][
	    unless res/Type = /Resource [
		make error! rejoin [ {Not a valid resource} mold res ]
	    ]
	    Resources: res
	]
	    
	init: func [ spec ][
	    foreach s spec [
		if word? s [ s: get s ]
		case [ 
		    any [ s/Type = /stream block? s ] [
			add-content s
		    ]
		    s/Type = /Resource [
			add-resource s
		    ]
		]
	    ]
	]
    ]

    image-rgb-stream!: make base-stream! [
	append dict [ Type Subtype Width Height ColorSpace BitsPerComponent Filter SMask ]
	Type: /XObject
	Subtype: /Image
	Interpolate: False
	Width: Height: 'required
	ColorSpace: /DeviceRGB
	BitsPerComponent: 'required
	Filter: /ASCIIHexDecode
	SMask: none ; Set to appropriate XObject when the the image has an alpha channel
	init: func [ spec /local im ][
	    spec: reduce spec
	    im: first spec
	    stream: make image-rgb! [ image: spec/1 ]
	    Width: im/size/x
	    Height: im/size/y
	    BitsPerComponent: 8
	    if spec/2 [
		SMask: spec/2
	    ]
	]
    ]

    image-alpha-stream!: make base-stream! [
	append dict [ Type Subtype Width Height ColorSpace BitsPerComponent Filter Decode Interpolate ]
	Type: /XObject
	Subtype: /Image
	Interpolate: True
	Width: Height: 'required
	ColorSpace: /DeviceGray
	BitsPerComponent: 'required
	Filter: /ASCIIHexDecode
	Decode: [ 1 0 ]
	init: func [ spec /local im ][
	    spec: reduce spec
	    im: first spec
	    stream: make image-alpha! [ image: spec/1 ]
	    Width: im/size/x
	    Height: im/size/y
	    BitsPerComponent: 8
	]
    ]


    font-dict!: make base-obj! [
	Type: /Font
	Subtype: /Type1
	BaseFont: 'required
	append dict [ Type Subtype BaseFont ]
	init: func [ spec ][
	    BaseFont: to-refinement spec/1
	]
    ]

    objs-dict!: make base-obj! [
	Type: /objs-dict!
	dict: none
	check: does [ true ]
	value-list: []
	add-obj: func [ name obj ][
	    append value-list reduce [ name obj ]
	]
	init: func [ spec ][
	    unless block? spec [ spec: reduce [ spec ] ]
	    foreach [n o ]  spec [
		if word? o [ o: get o ]
		add-obj  n o
	    ]
	]
	to-string: func[ obj-list ] [
	    string: copy ""
	    if :header [
		append string to-pdf-string obj-list header obj-list
		append string newline
	    ]
	    append string "<<^/"
	    foreach [name value ] value-list [
		append string tab
		append string to-pdf-string obj-list reduce [ to-refinement name ]
		append string tab
		append string to-pdf-string obj-list reduce [ value ]
		append string newline
	    ]
	    append string ">>^/"
	    string
	]
    ]
    fonts-dict!: make objs-dict! [
	Type: /Fonts
    ]
    XObjects-dict!: make objs-dict! [
	Type: /XObjects
    ]

    resources-dict!: make base-obj! [
	Type: /Resource
	Font: none
	XObject: none
	ExtGState: none
	ProcSet: [ /PDF /Text /ImageB /ImageC /ImageI ]
	append dict [ Font XObject ProcSet ExtGState ]
	init: func [ spec ][
	    foreach s spec [
		if word? s [ s: get s ]
		switch s/Type [
		    /Fonts [
			Font: s
		    ]
		    /XObjects [
			XObject: s
		    ]
		]
	    ]
	]
    ]


    catalog-dict!: make base-obj! [
	Type: /Catalog
	Pages:  'required
	dict: [ Type Pages ]

	set-pages: func [ p ][
	    if word? p [ p: get p ]
	    unless all [
		object? p 
		p/Type = /Pages
	    ][
		make error! rejoin [ "Contents should reference pages, not:" p ]
	    ]
	    p/Parent: self
	    Pages: p
	]

	init: func [ spec [block!] ][
	    foreach s spec [
		set-pages s
	    ]
	]
    ]

    xref-obj!: make base-obj! [
	Type: /xref
	fill-zeros: func [ number digits /local s ][
	    head change skip insert/dup copy "" "0" digits negate length? s: system/words/to-string number s
	]

	header: [ xref ]
	footer: none
	;objs: 'reqired
	string: ""
	to-string:  func [ obj-list ][
	    string: copy ""
	    counts:  index? find obj-list self
	    append string rejoin [
		header newline
		0 " " counts newline
		"0000000000 65535 f " newline
		rejoin map-each x obj-list [
		    if x = self [ break ]
		    rejoin [ fill-zeros any [ x/obj-position 0 ] 10 " 00000 n "  newline ]
		]
	    ]
	    if footer [ append string [ footer newline ] ]
	    string
	]
	init: func [ blk [block!] {List of objects to put in cross reference table} ][
	    ;objs: copy blk
	]
    ]

    trailer-dict!: make base-stream! [
	Type: /trailer
	header: [trailer]
	stream-start: 'startxref
	stream-end: none
	footer: "%%EOF"
	Info: ID: none
	Size:  'required
	Root: 'required
	dict: [ Size Root ID Info ]
	set-root: func [ catalog ][
	    unless catalog/Type = /Catalog [
		make error! rejoin [ "Argument need to be a catalog. Is:" catalog/Type ]
	    ]
	    Root: catalog
	]
	xref: none
	to-string**: :to-string
	to-string: func [ obj-list ] [
	    string: copy ""
	    stream: reduce [ xref/obj-position ]
	    to-string** obj-list
	]
	init: func [ objs ][
	    foreach o objs [
		if word? o [ o: get o ]
		switch o/Type [
		    /Catalog [
			set-root o
		    ]
		    /xref [
			xref: o
			;Size:  length? o/objs 
		    ]
		]
	    ]
	]
    ]
    
    set 'prepare-pdf func [
	/file-name file
    ][
	context [

	    file-name: file

	    write: does [
		either file-name [
		    system/words/write file-name to-string 
		][
		    make error! "No filename given"
		]
	    ]

	    obj-list: copy []
	    
	    add-obj: func [ obj ][
		append obj-list obj
	    ]

	    check: does [
		unless Root [ make error! {No catalog set} ]
		foreach o obj-list [ o/check ]
		'OK
	    ]
	    
	    set-root: func [ catalog ] [
		Root: catalog 
	    ]
	    Root: none	
	    
	    prepare: func [
		/keep {Keep oldest xrefs and trailers }
		/local xref trailer
	    ] [
		unless keep [
		    foreach o reverse obj-list [
			if o/Type = /xref [ remove find obj-list o break ]
		    ]
		    foreach o reverse obj-list [
			if o/Type = /trailer [ remove find obj-list o break ]
		    ]
		]
			
		xref: make-obj pdf-lib/xref-obj!  [ obj-list ]
		trailer: make-obj pdf-lib/trailer-dict! [ xref Root ]

		trailer/Size: length? obj-list

		check
		
	    ]

	    to-string: func [
		/root cat [object!] {The root object (a catalog)}
		/local string
		    xref trailer
	    ][
		if root [ set-root cat ]

		prepare

		string: copy "%PDF-1.6^/"
		foreach o obj-list [
		    o/obj-position: length? string
		    append string o/to-string obj-list
		]
		string
	    ]

	    make-obj: func [
		obj [object!] {Object prototype, decides how the specifiation should be treated}
		specification [block!] {A list of something that rather liberally will get parsed}
		/root {Mark that this object is the file's catalog to be referenced as root}
		/local o
	    ][
		append obj-list o: make obj [ ]
		o/init specification
		if root [ set-root o ]
		o
	    ]
	]
    ]

    test: func [
    ][
	; --------------------------------------------------------------

	image: xobjs: font: fonts: cont: text: resource: page: catalog: none

	if error? err: try [
	    
	    doc: prepare-pdf/file-name %newer.pdf

	    image: doc/make-obj pdf-lib/image-rgb-stream! [ logo.gif ]

	    im: make image! 2x2
	    poke im 0x0 ivory poke im 1x0 blue poke im 0x1 green poke im 1x1 magenta
	    image2: doc/make-obj pdf-lib/image-rgb-stream! [ im ]

	    xobjs: doc/make-obj pdf-lib/XObjects-dict! [ logo.gif image pix image2]
	    
	    font: doc/make-obj pdf-lib/font-dict!  [ Times-Roman ]
	    font2: doc/make-obj pdf-lib/font-dict!  [ Helvetica ]
	    fonts: doc/make-obj pdf-lib/fonts-dict! [ Times-Roman font H font2 H2 font ]
	    cont: doc/make-obj pdf-lib/base-stream! [
		q 4  w 0 1 0 RG 100 100 m 200 100 l 200 200 l 100 200 l s Q
		q 100 0 0 24 150 150 cm /logo.gif Do Q
		q 50 0 0 50 10x10 cm /pix Do Q
	]
	    text: doc/make-obj pdf-lib/base-stream! compose [
		BT 0 0 0 rg /Times-Roman 18 Tf 100 100 Td "Hello" Tj ET
		BT 0 0 1 rg /H 18 Tf 200 100 Td "Blue air" Tj ET
		BT 0 0 1 rg /H2 9 Tf 200 80 Td "Finnair" Tj ET
		BT (sky) rg /Times-Roman 10 Tf 150x15 Td (to-string now ) Tj ET
	    ]
	    resource: doc/make-obj pdf-lib/resources-dict! [ fonts xobjs ]
	    page: doc/make-obj pdf-lib/page-dict! [ cont resource text ]
	    page/set-mediaBox [ 0 0 300 300 ]
	    pages: doc/make-obj pdf-lib/pages-dict! [ page ]
	    catalog: doc/make-obj/root pdf-lib/catalog-dict! [ pages ]

	    doc/write
	    true
	] [
	    err: disarm err
	    ? err
	]
    ]
]



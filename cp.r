REBOL [
    document: [
	Fonts: [ font1 font2 .... ]
	Images: [ image1 image2 ]
	Pages: [
	    Page: [
		Resources: [
		    fonts: [ 
			/font1 /font1
			/font2 /font2
		    ]
		    XObjects: [
			/image1 N 0 R
			/image2 N 0 R
		    ]
		]
		Contents: 
	    ]
	]
    ]

    doc: {
    Make sure to divide the building of the pdf-document from parsing the face
    Called with:
	base-stream	the-stream
	image-stream    the-image
	resourses	Fonts Xobjects
	page		resourses  content-streams
	pages		page/pages
	fonts

    Methods:
	pages	link inserts page/pages to kids and sets parent in kid
	fonts	Add a font name (it will find the correct to use)

    }
]

space: #" "

to-pdf-string: func [
    {Takes a block of pdf graphics commands (encoded as rebol) and
    converts it to a string that pdf can parse.
    pairs are converted to two numbers.
    tuples are converted to a number of decimals by dividing them with 255
    TODO:
	Images are  converted to a byte sequence
    }
    blk 
    /local str p 
	string from to
] [

    str: copy ""
    unless block? blk [ blk: reduce [ blk ] ]
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
		append str rejoin [ "[ " to-pdf-string arg " ]" ]
	    ]
	    ;'dict = arg [
		;unless block? second blk [ make error! "Dict must be following dict keyword" ]
		;append str rejoin [ "<<" to-pdf-string second blk " >>" ]
		;blk: next blk
	    ;]
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
	    pair? arg [
		repend str reform [ arg/x arg/y ]
		append str space
	    ]
	    tuple? arg [
		repeat i length? arg [
		    repend str form   ( pick arg i ) / 255
		    append str space
		]
	    ]
	    object? arg [
		    ; If there is a object, assume it is a object representing 
		    ; a pdf-object
		    ; Hence write out id 0 R
		    append str form get-obj-reference arg
		    append str space
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

obj-list: copy []

create-obj: func [
    obj [object!] {The base object to start from}
    specification [block!] {A list of something that rather liberally will get parsed}
    /local o
][
    append obj-list o: make obj [ ]
    o/obj-id: length? obj-list
    o/init specification
    o
]

get-obj-reference: func [ obj ][
    reduce [ index? find obj-list obj 0 'R ]
]

base-obj!: make object! [
    header: does [ reduce [ obj-id 0 'obj ] ] ;Head should print the first line of object
    footer: "endobj"
    init: none

    dict: [
    ]

    obj-id: none
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
    to-string: func[ /is-stream ] [
	string: copy ""
	if header [
	    append string to-pdf-string header
	    append string newline
	]
	append string "<<^/"
	use [ val ][
	    foreach field dict [
		val: get in self field
		if val [
		    append string tab
		    append string to-pdf-string reduce [ to-refinement field  ]
		    append string tab
		    append string to-pdf-string reduce [ val ] ; Execute function if necessary
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
    to-string: does [
	stream-string: to-pdf-string stream
	to-string*/is-stream
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
    append dict [ Type Subtype Width Height ColorSpace
		    BitsPerComponent Filter
    ]
    Type: /XObject
    Subtype: /Image
    Width: Height: 'required
    ColorSpace: /DeviceRGB
    BitsPerComponent: 'required
    Filter: /ASCIIHexDecode
    init: func [ spec /local im ][
	spec: reduce spec
	im: first spec
	stream: spec
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
    Type: none
    dict: none
    check: does [ true ]
    obj-list: []
    add-obj: func [ name obj ][
	append obj-list reduce [ name obj ]
    ]
    init: func [ spec ][
	unless block? spec [ spec: reduce [ spec ] ]
	foreach [n o ]  spec [
	    if word? o [ o: get o ]
	    add-obj  n o
	]
    ]
    to-string: func[  ] [
	string: copy ""
	if header [
	    append string to-pdf-string header
	    append string newline
	]
	append string "<<^/"
	foreach [name obj ] obj-list [
	    append string tab
	    append string to-pdf-string  to-refinement name
	    append string tab
	    append string to-pdf-string obj  
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

    header: 'xref
    footer: none
    objs: 'reqired
    string: ""
    to-string:  func [ ][
	string: copy ""
	counts:  index? find obj-list self
	append string rejoin [
	    header newline
	    0 " " counts newline
	    "0000000000 65535 f " newline
	    rejoin map-each x objs [
		if x = self [ break ]
		rejoin [ fill-zeros any [ x/obj-position 0 ] 10 " 00000 n "  newline ]
	    ]
	]
	if footer [ append string [ footer newline ] ]
	string
    ]
    init: func [ blk [block!] {List of objects to put in cross reference table} ][
	objs: copy blk
    ]
]

trailer-dict!: make base-stream! [
    Type: /trailer
    header: 'trailer
    stream-start: 'startxref
    stream-end: none
    footer: "%%EOF"
    Info: ID: none
    Size:  'required
    Root: 'required
    dict: [ Size Root ID Info ]
    set-root: func [ catalog ][
	unless catalog/Type = /Catalog [
	    make error! rejoin [ "Argument need to be a catalog. Is:" p ]
	]
	Root: catalog
    ]
    xref: none
    to-string**: :to-string
    to-string: does [
	string: copy ""
	stream: reduce [ xref/obj-position ]
	to-string**
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
		    Size:  length? o/objs 
		]
	    ]
	]
    ]
]

create-pdf: func [
    objs [block!] {A catalog object with all children done}
    /local string
][

    foreach o objs [ o/check ]

    string: copy "%PDF-1.6^/"
    foreach o objs [
	o/obj-position: length? string
	append string probe o/to-string
    ]
    string
]

; --------------------------------------------------------------

image: xobjs: font: fonts: cont: text: resource: page: catalog: xref: trailer: none

if error? err: try [
    image: create-obj image-rgb-stream! [ logo.gif ]
    xobjs: create-obj XObjects-dict! [ logo.gif image ]
    
    font: create-obj font-dict!  [ Times-Roman ]
    font2: create-obj font-dict!  [ Helvetica ]
    fonts: create-obj fonts-dict! [ Times-Roman font H font2 ]
    cont: create-obj base-stream! [
	q 4  w 0 1 0 RG 100 100 m 200 100 l 200 200 l 100 200 l s Q
	q 100 0 0 24 150 150 cm /logo.gif Do Q ]
    text: create-obj base-stream! [
	BT 0 0 0 rg /Times-Roman 18 Tf 100 100 Td (Hello) Tj ET
	BT 0 0 1 rg /H 18 Tf 200 100 Td (Blue) Tj ET
    ]
    resource: create-obj resources-dict! [ fonts xobjs ]
    page: create-obj page-dict! [ cont resource text ]
    page/set-mediaBox [ 0 0 300 300 ]
    pages: create-obj pages-dict! [ page ]
    catalog: create-obj catalog-dict! [ pages ]
    xref: create-obj xref-obj! obj-list
    trailer: create-obj trailer-dict! [ xref catalog ]

    pdf: create-pdf obj-list
    true
] [
    err: disarm err
]

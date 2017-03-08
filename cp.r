REBOL [
]

to-pdf-string: func [
    {Takes a block of pdf graphics commands (encoded as rebol) and
    converts it to a string that pdf can parse.
    pairs are converted to two numbers.
    tuples are converted to a number of decimals by dividing them with 255
    TODO:
	Images are  converted to a byte sequence
    }
    blk 
    /local str p space 
	string from to
] [

    space: #" "
    str: copy ""
    unless block? blk [ blk: reduce [ blk ] ]
    forall blk [
	arg: first blk
	if new-line? blk [ if all [ not empty? str #" " = last str ] [ clear back tail str ] append str newline ]
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
		append str copy/part skip p: mold to-binary arg 2 back tail p
	    ]
	    pair? arg [
		repend str reform [ arg/x arg/y ]
		append str #" "
	    ]
	    tuple? arg [
		repeat i length? arg [
		    repend str form   ( pick arg i ) / 255
		    append str #" "
		]
	    ]
	    true [
		append str mold arg
		append str space
	    ]
	]
    ]
    if all [ not empty? str #" " = last str ] [ clear back tail str ]
    str
]

obj-list: copy []

document: [
    Fonts: [ font1 font2 .... ]
    Images: [ image1 image2 ]
    Pages: [
	Page: [
	    Resources: [
		Font: [ 
		    /font1 /font1
		    /font2 /font2
		]
		XObject: [
		    /image1 N 0 R
		    /image2 N 0 R
		]
	    ]
	    Content: 
	]
    ]
]

{ Called with:
    base-stream	    resourses the-stream
    image-stream    resourses the-image
    resourses
    page	    resourses  content-streams
    pages-obj	    page/pages
}
    

create-dict-obj: func [ obj specification ][
    make obj
	head append specification [ register ]
]

get-obj-reference: func [ obj ][
    reduce [ index? find obj-list obj 0 'R ]
]

base-obj!: make object! [
    header: does [ reduce [ obj-id 0 'obj ] ] ;Head should print the first line of object
    footer: "endobj"
    register: does [
	append obj-list self
	obj-id: length? obj-list
	do init
    ]
    init: []

    dict: [
    ]

    obj-id: none
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
	append string to-pdf-string header
	append string newline
	append string "<<^/"
	use [ val ][
	    foreach field dict [
		append string #"^-"
		append string to-pdf-string reduce [ to-refinement field  ]
		append string #"^-"
		val: get in self field
		append string to-pdf-string val ; Execute function if necessary
		append string #"^/"
		
	    ]
	]
	append string " >>^/"
	unless is-stream [ repend string [ footer #"^/" ]
	string
    ]
]

base-stream!: make base-obj! [
    to-string*: :to-string

    append dict 'Length

    stream: []
    Length: does [ length? stream-string ]
    stream-string: ""
    to-string: does [
	stream-string: to-pdf-string stream
	to-string*/is-stream
	append string "stream^/"
	append string stream-string
	repend string [ "^/endstream^/" footer ]
    ]
]


pages-dict!: make base-obj! [
    Type: /Pages
    append dict [ Type Kids Count ]
    Parent:  none
    Kids: []
    Count: does [length? Kids/1 ]
    append init [ insert/only Kids copy [] ]
]

page-dict!: make base-obj! [
    Type: /Page
    Parent:
    MediaBox: 'required
    Content:  none
    Resourses: []
    append dict [ Parent Resourses MediaBox Content ]
]

font-dict!: make base-obj! [
    Type: /Font
    Name: none
    Subtype: /Type1
    BaseFont: 'required
]

fonts-dict!: make object! [
    dict: []
    font-list: []
    add-font: func [ font-obj ][
	append font-list [ font-obj/Name font-obj ]
    ]
]

resources-dict!: make base-obj! [
    Font: none
    XObject: none
    ProcSet: [ /PDF /Text /ImageB /ImageC /ImageI ]
    append dict [ Font XObject ProcSet ]
]


catalog-dict!: make base-obj! [
    Type: /Catalog
    Pages:  []
    dict: [ Type Pages ]
]

trailer-dict!: make base-obj! [
    header: "trailer"
    footer: "startxref"
    Size: 
    Root:
    Info: 
    ID: 
	none
    dict: [ Size Root ID Info ]
]
    
cont: create-dict-obj base-stream! [ stream: [ q 0 0 m 100 100 l Q ] ]
pages: create-dict-obj pages-dict! []

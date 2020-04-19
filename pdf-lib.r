REBOL [
    title: {PDF creation functions. Basics for building a pdf document used primarily by face-to-pdf}
    author: {Johan Ingvast}

    requires: [ printf ]
]

context [
    
    do %printf.r

    context [
	; just some documentation
	pdf-stream-syntax: {
	    taken from http://www.mactech.com/articles/mactech/Vol.15/15.09/PDFIntro/index.html
	    b 	closepath, fill,and stroke path.
	    B 	fill and stroke path.
	    b* 	closepath, eofill,and stroke path.
	    B* 	eofill and stroke path.
	    BI 	begin image.
	    BMC 	begin marked content.
	    BT 	begin text object.
	    BX 	begin section allowing undefined operators.
	    c 	curveto.
	    cm 	concat. Concatenates the matrix to the current transform.
	    cs 	setcolorspace for fill.
	    CS 	setcolorspace for stroke.
	    d 	setdash.
	    Do 	execute the named XObject.
	    DP 	mark a place in the content stream, with a dictionary.
	    EI 	end image.
	    EMC 	end marked content.
	    ET 	end text object.
	    EX 	end section that allows undefined operators.
	    f 	fill path.
	    f* 	eofill Even/odd fill path.
	    g 	setgray (fill).
	    G 	setgray (stroke).
	    gs 	set parameters in the extended graphics state.
	    h 	closepath.
	    i	setflat.
	    ID 	begin image data.
	    j 	setlinejoin.
	    J 	setlinecap.
	    k 	setcmykcolor (fill).
	    K 	setcmykcolor (stroke).
	    l 	lineto.
	    m 	moveto.
	    M 	setmiterlimit.
	    n 	end path without fill or stroke.
	    q 	save graphics state.
	    Q 	restore graphics state.
	    re 	rectangle.
	    rg 	setrgbcolor (fill).
	    RG 	setrgbcolor (stroke).
	    s 	closepath and stroke path.
	    S 	stroke path.
	    sc 	setcolor (fill).
	    SC 	setcolor (stroke).
	    sh 	shfill (shaded fill).
	    Tc 	set character spacing.
	    Td 	move text current point.
	    TD 	move text current point and set leading.
	    Tf 	set font name and size.
	    Tj 	show text.
	    TJ 	show text, allowing individual character positioning.
	    TL 	set leading.
	    Tm 	set text matrix.
	    Tr 	set text rendering mode.
	    Ts 	set super/subscripting text rise.
	    Tw	set word spacing.
	    Tz 	set horizontal scaling.
	    T* 	move to start of next line.
	    v 	curveto.
	    w 	'setlinewidth.
	    W 	clip.
	    y 	curveto.
	}
    ]


    export: func [
	{Exports any variable you give as argumment from this lib to your context}
	adds [word! block! unset!]
    ] [
	unless  value? 'adds [ adds: [] ]
	unless block? adds [ adds: reduce [ adds ] ]
	foreach var  adds [
	    set bind var var get bind var self
	]
    ]
    

    space: #" "

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
    transform-content: func [
	{Transforms the data in stream into real values.
	 pairs are made into two values.
	 tuples with length three treated as colors and transformed into pdf color values,
	 i.e. 0.0 - 1.0}
	stream [block!]
	/rgb {Transforms tuples of length 3 to pdf color}
	/scale sc [block! number!] {Applies the values in sc on the resulting data}
	/local item  result s
    ][
	result: copy []

	sc: any [ sc copy [1] ]
	next-sc: does [
	    also first+ sc
		 if tail? sc [ sc: head sc ]
	]

	foreach item stream [
	    switch/default type? item reduce [ 
		integer! decimal! [ append  result item * next-sc ]
		pair! [ repend result [ item/x * next-sc item/y * next-sc] ]
		tuple! [
		    either all [ rgb 3 = length? item]  [
			foreach b to-binary item [ append result b / 255.0 * next-sc ] 
		    ][
			foreach b to-binary item [ append result b * next-sc] 
		    ]
		]
	    ] [
		make error!  reform [
		    "Error:"
		    type? item
		    "Cannot be given in this type of stream"
		]
	    ]
	]
	result
    ]

    to-pdf-string: func [
	{Takes a block of pdf graphics commands (encoded as rebol) and
	converts it to a string that pdf can parse.
	pairs are converted to two numbers.
	tuples are converted to a number of decimals by dividing them with 255
	}
	obj-list [block!] {A list of objects for the document}
	blk  [block!] {The content to make string of, objects are converted to references}
	/local str p  arg
	    string from to
	    string-replacements
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
	header: func [ obj-list [block!] ] [ reduce [ get-obj-id obj-list self 0 'obj ] ] ;Head should print the first line of object
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
	to-string: func[
	    {Converts the object to a text stream
	    Convention that letters + and - at the beginning of variable names are not printed.
	    (Use + for mostly upprcase and - for lowercase)
	    That way we can handle  same name only distinguishded by capitalization.
	    }
	    obj-list [block!] /is-stream
	] [
	    string: copy ""
	    if :header [
		append string to-pdf-string obj-list header obj-list
		append string newline
	    ]
	    append string "<<^/"
	    use [ val ][
		foreach field dict [
		    ;TODO: get field
		    val: get in self field
		    if val [
			field: system/words/to-string field
			if find "+-" field/1  [ remove field ]
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

    ext-graphic-state-dict!: make base-obj! [
	append dict [ Type 
	    LW LC LJ ML
	    D RI
	    +OP -op		
	    OPM
	    Font
	    BG BG2
	    UCR UCR2
	    TR TR2
	    HT
	    FL
	    SM
	    SA
	    BM SMask
	    +CA -ca
	    AIS
	    TK
	]

	Type: /ExtGState

	LW: LC: LJ: ML: D: RI:
	+OP: -op:		;+ denotes capital letters when in doubt (- small letters)
	OPM: Font: BG: BG2: UCR: UCR2: TR: TR2:
	HT: FL: SM: SA: BM: SMask: +CA: -ca: AIS:
	TK: none

	init: func [ spec ][
	    spec: bind/copy spec self
	    do spec
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
	    unless find value-list name [
		append value-list reduce [ name obj ]

	    ]
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
	    append string ">>^/endobj^/"
	    string
	]
    ]
    fonts-dict!: make objs-dict! [
	Type: /Fonts
    ]
    XObjects-dict!: make objs-dict! [
	Type: /XObjects
    ]
    extGStates-dict!: make objs-dict! [
	Type: /ExtGState
    ]
    shadings-dict!:  make objs-dict! [
	Type: /Shading
    ]
    patterns-dict!:  make objs-dict! [
	Type: /Pattern
    ]

    function-poly-dict!: make base-obj! [
	append dict [
	    C0 C1
	    N
	    FunctionType
	    Domain
	]
	C0: [ 0 ]
	C1: [ 1 ]
	N:  [ 1 ]
	Domain: [ 0 1 ]
	FunctionType: 2
    ]

    function-interp-dict!: make base-stream! [
	Type: /Function
	doc:
	{Interpolation of n inputs to m outputs
	    Size    is an array of the number of input samples of each input.
		    So for one input with five samples it is [ 5 ]
		    With two inputs three and eight samples it is [ 3 8 ]
	    Order   Integer 1 or 3 of the order of interpolation.
	    Encode  Array of how to encode the input.
		    Meaning of lowest repsecively highest sample of each input dimension.
		    [ in1SampleFirst in1_SampleLast ... in(n)SampleFirst in(n)SamleLast ]
		    Default  0 and Size-1 Decode Array similar to Encode but for output.
	    BitsPerSample Can be 1 2 4 8 12 16 24 32
	The interpolation does not extrapolate outside the Domain, input is clipped.
	Output is clipped to Range.
	The values given are scanned for lowest and highest values, so Decode is normally 
	set to the output dimension and Decode is calculated to precisely contain the samples.
	}
	append dict [
	    BitsPerSample
	    Size
	    Order
	    Decode Encode
	    Domain Range
	    FunctionType
	]
	FunctionType: 0
	BitsPerSample: 'required
	Size: 'required ; How many samples of each input dimension
	Order: 1 ; Interpolation order (1 or 3)
	Encode: none ; The input values are scaled against this vector.
	Decode: none 
	Domain: 'required
	Range: 'required

	sampleToBin: func [
	     value [number!] {A number to make binary. Values are bound to [0, 1]}
	     bits [integer!] {A value of number of bits, steps of 8}
	     /local result 
	][
	    value: max 0.0 value
	    value: min 1.0 value
	    value: to integer! round value * ( 2 ** bits - 1 )
	    result: copy []
	    repeat i bits / 8 [
		insert result value and 255
		value: shift value 8
	    ]
	    make binary! result
	]
	bin-to-block: func [ bin /local p result ][
	    result: copy []
	    parse/all bin [ any [ copy p skip ( append result to-integer to-char p ) ] ]
	    result 
	]
	to-binary-string: func [ 
	    /local
		inter base
		dims
		result
	][
	    base: to-integer 2 ** BitsPerSample

	    ; transform data that is not numbers.
	    inter: transform-content/rgb stream

	    result: copy #{}
	    if integer? Decode [  ; Automatically set Decode to the range that data spans
		dims: Decode
		Decode: copy []
		loop dims [ append Decode [ 1e36 -1e36 ] ]
		while [ not tail? inter ] [ 
		    x: first+ inter
		    Decode/1: min Decode/1 x
		    Decode/2: max Decode/2 x
		    if tail? Decode: skip Decode 2 [ Decode: head Decode ]
		]   
		; Check we have used all the Decode components, otherwise the data
		; is not the correct length
		unless head? Decode [ make error! {Data in type 0 function is not right length} ]
		while [ not tail? Decode ] [ ; Make sure Decode spans all dimensions
		    if Decode/1 = Decode/2 [ Decode/2: Decode/1 + 1 ]
		    Decode: skip Decode 2
		]
		Decode: head Decode
	    ]
	    inter: head inter
	    while [ not tail? inter ] [ 
		x: first+ inter
		low: first Decode
		high: second Decode
		append result sampleToBin x - low / ( high - low )  BitsPerSample
		if tail? Decode: skip Decode 2 [ Decode: head Decode ]
	    ]   
	    result
	]
	to-string: func [ obj-list ] [
	    unless block? stream [ stream: reduce [ stream ] ]

	    stream: reduce stream
	    stream-string: to-binary-string

	    to-string*/is-stream obj-list
	    append string stream-start
	    append string newline
	    append string stream-string
	    append string newline

	    if stream-end [ repend string [ stream-end newline ] ]
	    if footer [ repend string  [ footer newline ] ]
	    string
	]

	one-input-dimension: func [
	    { 
		Use when the input is one dimensional.
	    }
	    dims-out [integer!] {Number of dimensions in ouput}
	    spec [block!] {List of values}
	    /Domain domain-values [block!] {The low and high of input value. Default [0 1/(size-1)]}
	    /local Range-low Range-high
	] [
	    stream: transform-content/rgb reduce spec
	    Decode: dims-out
	    Size: reduce [ ( length? stream ) / dims-out ]
	    self/Domain: any [ domain-values copy [0 1] ]
	    insert/dup Range-low:  copy []  1e36 dims-out 
	    insert/dup Range-high: copy [] -1e36 dims-out 
	    Range-low: tail Range-low
	    Range-high: tail Range-high

	    foreach x stream [
		if tail? Range-low  [ Range-low:  head Range-low ]
		if tail? Range-high [ Range-high: head Range-high ]
		if x > Range-high/1 [ Range-high/1: x ]
		if x < Range-low/1  [ Range-low/1:  x ]
		first+ Range-high
		first+ Range-low
	    ]
	    Range: copy []
	    Range-low:  head Range-low
	    Range-high: head Range-high
	    repeat i dims-out [
		append Range Range-low/:i
		append Range Range-high/:i
	    ]
	]

	init: func [ spec ][
	    spec: bind/copy spec self
	    do spec
	]
    ]

    shading-pattern-dict!: make base-obj! [
	append dict [
		Type
		PatternType
		Matrix
		ExtGState
		Shading
	]
	Type: /Pattern
	PatternType: 2 ; shading patterns
	Shading: 'required  ; An object such as shading-axial-dict!
	Matrix: none
	ExtGState: none
	init: func [
	    spec
	    /local p mtrx
	][
	    parse reduce spec [
		any [ 
		    [ set p object! ( Shading: p ) ]
		    |
		    [ p: set mtrx  block!  :p into [ 6 number! any skip ] 
			(Matrix: copy/part mtrx 6 )
		    ]
		]
	    ]
	]
    ]

    shading-proto-dict!: make base-obj! [
	append dict [ 
	    ShadingType
	    ColorSpace
	    Background
	    BBox
	    AntiAlias
	]
	ShadingType: 'required
	ColorSpace: /DeviceRGB
	Background: none
	BBox: none
	AntiAlias: none
	init: func [ spec ][
	    spec: bind/copy spec self
	    do spec
	]
    ]

    shading-axial-dict!: make shading-proto-dict! [
	append dict [
		Coords Domain
		Function Extend
	]
	ShadingType: 2
	Coords:  'required
	Function: 'required
	Extend: none
	Domain: none
	from-to: func [ from to ][
	    if Coords = 'required [ Coords: reduce [ none none none none ] ]
	    Coords/1: from/1 Coords/2: from/2
	    Coords/3: to/1   Coords/4: to/2
	]
    ]

    shading-radial-dict!: make shading-proto-dict! [
	append dict [
		Coords Domain
		Function Extend
	]
	ShadingType: 3
	Coords:  'required
	Function: 'required
	Extend: none
	Domain: none
	from: func [ p [pair! block!] r [number!] ][
	    if Coords = 'required [ Coords: reduce [ none none none none none none ] ]
	    Coords/1: p/1 Coords/2: p/2 Coords/3: r
	]
	to: func [ p [pair! block!] r [number!] ][
	    if Coords = 'required [ Coords: reduce [ none none none none none none ] ]
	    Coords/4: p/1 Coords/5: p/2 Coords/6: r
	]
    ]

    shading-triangles-dict!: make base-stream! [
	doc: {
	    Makes shaded triangles, i.e. triangles with specified color in each corner.
	    Colors are interpolated inbetween.
	    Nodes of triangles are given in the stream.
	    Format of the nodes are:
		flag x-coord y-coord red green blue
	    The function then transforms them to binary format and also sets the Decode
	    vector so that one point in the coordinates is one point in the shading scale.
	    If you want details smaller than one point you need to scale first or fibble with 
	    the methods.
	    Flag tells which of the nodes of previous triangle that should not be used in
	    the next. Number starts counting with 1.  The zeroth index means start over a 
	    independent triangle.
	    The object is set for using DeviceRGB only, but should be pretty easy to change to 
	    other.
	    Colors are given as tuples or three numbers of 0-255. 
	    Coordinates -32767 -- 32767.

	    The final result of the given stream is transformed into a binary stream, however
	    not compressed. (It is not allowed to have it in nonbinary form).

	    To draw the triangles, simply
		/name-of-pattern sh

	    I have not figured out how to use the pattern as a color for general painting.

	    See also the  method test-triangles
	}
	append dict [
	    PatternType ShadingType
	    ColorSpace Decode BitsPerComponent
	    BitsPerCoordinate BitsPerFlag
	]
	Type: /Pattern
	PatternType: 2
	ShadingType: 4
	ColorSpace: /DeviceRGB
	BitsPerFlag: 8
	BitsPerCoordinate: 16
	BitsPerComponent: 8
	Decode: none
	componentsToBin: func [
	     value [integer!] {A unsigned value to make binary}
	     bits [integer!] {A value of number of bits, steps of 8}
	     /local result 
	][
	    result: copy []
	    repeat i bits / 8 [
		insert result value and 255
		value: shift value 8
	    ]
	    make binary! result
	]
	bin-to-block: func [ bin /local p result ][
	    result: copy []
	    parse/all bin [ any [ copy p skip ( append result to-integer to-char p ) ] ]
	    result 
	]
	to-binary-string: func [ 
	    /local
		inter shifting base
		result
	][
	    base: to-integer 2 ** BitsPerCoordinate
	    shifting: base / 2
	    Decode: reduce [ negate shifting shifting negate shifting shifting 0 1 0 1 0 1]

	    inter: transform-content stream

	    result: copy #{}
	    foreach [ flag x y r g b ] inter [
		append result componentsToBin flag BitsPerFlag
		append result componentsToBin x + shifting BitsPerCoordinate
		append result componentsToBin y + shifting BitsPerCoordinate
		append result componentsToBin r BitsPerComponent
		append result componentsToBin g BitsPerComponent
		append result componentsToBin b BitsPerComponent
	    ]
	    result
	]
	to-string: func [ obj-list ] [
	    unless block? stream [ stream: reduce [ stream ] ]

	    stream: reduce stream
	    stream-string: to-binary-string

	    to-string*/is-stream obj-list
	    append string stream-start
	    append string newline
	    append string stream-string
	    append string newline

	    if stream-end [ repend string [ stream-end newline ] ]
	    if footer [ repend string  [ footer newline ] ]
	    string
	]
    ]

    resources-dict!: make base-obj! [
	Type: /Resource
	Font: none
	XObject: none
	ExtGState: none
	ProcSet: [ /PDF /Text /ImageB /ImageC /ImageI ]
	Shading: none
	Pattern: none
	append dict [ Shading Font XObject ProcSet ExtGState Pattern]
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
		    /Shading [
			Shading: s
		    ]
		    /Pattern [
			Pattern: s
		    ]
		    /ExtGState [
			ExtGState: s
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
	to-string:  func [ obj-list /local counts ][
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
    
    prepare-pdf: func [
	{Returns an object that can be modified to contain a pdf document.
	 Finalize by calling the method toString which will output a string that can be written to 
	 a file and saved as pdf.
	 To see an example of how to use the object, see pdf-lib/test as an example}
    ][
	context [
	    like?: func [
		{Returns true if all values are the same. When comparing referenced objects they are 
		 supposed to be like if references the same object.
		 Traverses all blocks recursevely to all levels.}
		 a 
		 b
		 /local a-names b-names a-val b-val a-pos b-pos x
	    ][
		if :a == :b [ return true ]
		unless (type? :a) = type? :b [ return false ]
		unless block? :a [ a: reduce [ :a ]  b: reduce [ :b ] ]

		loop length? a [
		    a-val: first+ a
		    b-val: first+ b
		    unless (type? :a-val) = type? :b-val [ return false ]
		    switch/default type? :a-val compose [
			(object!) [
			    a-val: third :a-val
			    b-val: third :b-val
			    foreach x [ stream-string: obj-position: string: ] [
				if a-pos: find/skip a-val x 2 [
				    remove/part a-pos 2
				]
				if b-pos: find/skip b-val x 2 [
				    remove/part b-pos 2
				]
			    ]
			    unless like? a-val b-val [ return false ]
			]
			(block!) [
			    unless like? :a-val :b-val [ return false ]
			]
			(function!) [
			    unless all [
				(second :a-val ) = (second :b-val)
				like? (third :a-val )  (third :b-val)
			    ][ return false ]
			]
		    ][
			unless :a-val = :b-val [
			    return false
			]
		    ]
		]
		true
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
			
		xref: make-obj xref-obj!  [ obj-list ]
		trailer: make-obj trailer-dict! [ xref Root ]

		trailer/Size: -1 + length? obj-list

		check
		
	    ]

	    to-string: func [
		/root cat [object!] {The root object (a catalog)}
		/local string
		    xref trailer
	    ][
		if root [ set-root cat ]

		prepare

		string: copy "%PDF-1.6^/%öäüß^/"
		foreach o obj-list [
		    o/obj-position: length? string
		    append string o/to-string obj-list
		]
		string
	    ]

	    make-obj: func [
		{Makes the object and then checks if an identical object already exists in the 
		list of objects. If it does, then return that other, else return the one just created}
		obj [object!] {Object prototype, decides how the specifiation should be treated}
		specification [block!] {A list of something that rather liberally will get parsed}
		/root {Mark that this object is the file's catalog to be referenced as root}
		/local o
	    ][
		o: make obj [ ]
		o/init specification
		if root [ set-root o ]
		foreach x obj-list [
		    if  like? x o [ return x ]
		]
		append obj-list o
		o
	    ]
	]
    ]

    test: func [
	/local
	image xobjs font fonts cont text resource page catalog
	err doc im image2 font2 pages 
    ][
	; --------------------------------------------------------------

	image: xobjs: font: fonts: cont: text: resource: page: catalog: none

	if error? err: try [
	    
	    doc: prepare-pdf

	    image: doc/make-obj image-rgb-stream! [ logo.gif ]

	    im: make image! 2x2
	    poke im 0x0 ivory poke im 1x0 blue poke im 0x1 green poke im 1x1 magenta
	    image2: doc/make-obj image-rgb-stream! [ im ]

	    xobjs: doc/make-obj XObjects-dict! [ logo.gif image pix image2]
	    
	    font: doc/make-obj font-dict!  [ Times-Roman ]
	    font2: doc/make-obj font-dict!  [ Helvetica ]
	    fonts: doc/make-obj fonts-dict! [ Times-Roman font H font2 H2 font ]
	    cont: doc/make-obj base-stream! [
		q 4  w 0 1 0 RG 100 100 m 200 100 l 200 200 l 100 200 l s Q
		q 100 0 0 24 150 150 cm /logo.gif Do Q
		q 50 0 0 50 10x10 cm /pix Do Q
	    ]
	    text: doc/make-obj base-stream! compose [
		BT 0 0 0 rg /Times-Roman 18 Tf 100 100 Td "Hello" Tj ET
		BT 0 0 1 rg /H 18 Tf 200 100 Td "Blue air" Tj ET
		BT 0 0 1 rg /H2 9 Tf 200 80 Td "Finnair" Tj ET
		BT (sky) rg /Times-Roman 10 Tf 150x15 Td (to-string now ) Tj ET
	    ]
	    resource: doc/make-obj resources-dict! [ fonts xobjs ]
	    page: doc/make-obj page-dict! [ cont resource text ]
	    page/set-mediaBox [ 0 0 300 300 ]
	    pages: doc/make-obj pages-dict! [ page ]
	    catalog: doc/make-obj/root catalog-dict! [ pages ]

	    write %newer.pdf doc/to-string
	    true
	] [
	    err: disarm err
	    ? err
	]
    ]
    test-triangles: func [
    ][
	if error? err: try [
	    
	    doc: prepare-pdf

	    ; When decoding the data of the shadings triangle dictionary 
	    ; the coordinates will be transformed (shifted up BitsPerCoordinate -1)
	    ; and the decode will be from negative the same to positive.
	    ; that way there can be negative coordinates below.
	    triangle: doc/make-obj shading-triangles-dict! [
		; flag x y color
		0 100x100  red
		0 200x0    green
		0 255x200  blue
		3 0x100   black ; flag tells which coordinate of last triangle to drop
	    ]
	    cont: doc/make-obj base-stream! compose [
		1 0.1 -0.15 0.9 -50 100 cm
		0 0.5 0.8 RG
		4 w
		/tri sh
		100x100 m
		200x0 l
		255x200 l h
		s
	    ]
	    shades: doc/make-obj shadings-dict! [ /tri triangle ]
	    resource: doc/make-obj resources-dict! [ shades ]
	    page: doc/make-obj page-dict! [ resource cont ]
	    page/set-mediaBox [ 0 0 400 300 ]
	    pages: doc/make-obj pages-dict! [ page ]
	    catalog: doc/make-obj/root catalog-dict! [ pages ]

	    write %triangle.pdf doc/to-string
	    true
	] [
	    err: disarm err
	    ? err
	]
    ]
    test-shading-axial: func [
    ][
	if error? err: try [
	    
	    doc: prepare-pdf

	    fun: doc/make-obj make function-poly-dict! [
		C0: [ 0 0 0 ]
		C1: [ 1 1 0.3]
		N: 1
	    ] []

	    fun2: doc/make-obj function-interp-dict! [
		BitsPerSample: 8
		one-input-dimension 3 [
		    red green blue  mint tan oldrab snow brown coal yellow
		] 
	    ]

	    axial: doc/make-obj shading-axial-dict! [
		Function: fun 
		Domain: [ 0 1 ] 
		Extend: [ true false ]
		from-to 50x0 240x00
	    ]
	    axial2: doc/make-obj shading-axial-dict! [
		Function: fun2
		Domain: [ 0 1 ] 
		Extend: [ false false ]
		from-to 0x100 90x10
	    ]
	    bullet: doc/make-obj shading-radial-dict! [
		Function: fun2
		Domain: [ 0 1 ] 
		Extend: [ false true ]
		from 50x50 0
		to 80x50 35
	    ]


	    shades: doc/make-obj shadings-dict! [ /axi axial /axi2 axial2 /bullet bullet ]

	    pattern: doc/make-obj shading-pattern-dict! [ bullet ]

	    patterns: doc/make-obj patterns-dict! [ /P1 pattern ]

	    resource: doc/make-obj resources-dict! [ shades patterns ]

	    cont: doc/make-obj base-stream! compose [
		q
		    000x100 m
		    100x0 l
		    155x200 l h
		    W n
		    /axi sh
		Q
		0.3 0.3 0.3 rg
		0 0.5 0.8 RG
		4 w
		000x100 m
		100x0 l
		155x200 l h
		S
		q
		    1 0 0 1 70x20 cm
		    q
			0x100 m
			100x0 l
			155x200 l h
			W n
			/axi2 sh
		    Q
		    (violet) RG
		    4 w
		    0x100 m
		    100x0 l
		    155x200 l h
		    S
		Q
		q
		    1 0 0 1 200x20 cm
		    q
			0x0 m
			100x0 l
			100x100 l 
			0x100 l h
			W n
			/bullet sh
		    Q
		    (coal) RG
		    4 w
		    0x0 m
		    100x0 l
		    100x100 l 
		    0x100 l h
		    S
		Q
		1 0 0 1 -50x0 cm
		0.8 G
		/Pattern cs
		/P1 scn
		5 w
		100x100 m
		250x50 l
		50x0 l h
		B
		/Pattern CS ; Here there is an error in evince that does not render this as the pattern
		/P1 SCN ; However ghostscript does
		10 w
		100x0 m
		100x150 l
		S
	    ]

	    page: doc/make-obj page-dict! [ resource cont ]
	    page/set-mediaBox [ 0 0 400 300 ]
	    pages: doc/make-obj pages-dict! [ page ]
	    catalog: doc/make-obj/root catalog-dict! [ pages ]

	    write %shadings.pdf doc/to-string
	    true
	] [
	    err: disarm err
	    ? err
	]
    ]
    test-graphic-state: func [
    ][
	if error? err: try [
	    
	    doc: prepare-pdf

	    extGS: doc/make-obj ext-graphic-state-dict! [ +CA: 0.5 ]
	    extGStates: doc/make-obj extGStates-dict! [ /half-alpha extGS ]

	    resource: doc/make-obj resources-dict! [ extGStates ]

	    cont: doc/make-obj base-stream! compose [
		10 w 
		(black) RG 
		10x30 m 100x30 l s
		(red) RG
		0x0 m 100x100 l s
		(blue) RG
		/half-alpha gs
		100x0 m 0x100 l s
	    ]

	    page: doc/make-obj page-dict! [ resource cont ]
	    page/set-mediaBox [ 0 0 400 300 ]
	    pages: doc/make-obj pages-dict! [ page ]
	    catalog: doc/make-obj/root catalog-dict! [ pages ]

	    write %test-gs.pdf doc/to-string
	    true
	] [
	    err: disarm err
	    ? err
	]
    ]
]


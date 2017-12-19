REBOL [
    title: {Make pdfs out of view objects}
    authour: {Johan Ingvast}
    help: {
	Load library with:
	>> do/args %face-to-pdf-lib.r 'face-to-pdf  
	which exports the function face-to-pdf. Alternatively do 
	>> lib: do %face-to-pdf-lib.r

	Call with one argument being a face object
	>> face-to-pdf face
	alternatively
	>> lib/face-to-pdf face
	
	Example
	>> face-to-pdf-lib/face-to-pdf layout [ field "We are the champions" ]
	In return you get a text stream. Save it to whatever file you want
	>> write/binary %my.pdf face-to-pdf-lib/face-to-pdf layout [ text "This is file my.pdf" ]
	
	One pixel in the face will be one point in the pdf document.

}
    TODO: {
	* Fix so that images not is taken from one document to next
	* Add possibility to have several pages.
	* Add possiblity to set media (A4,letter,...)
	* Clean up, hide scope
	* Fix some compressions
	* Handle gradients
	* Handle the rest of draw commands (arc ...)
	* Make use of font given. (Write font data to pdf)
    }
    DONE: {
	* Handle alpha values
	* Handle images
	* Rewrite printf routines
	* Improve the printing of strings to do proper escapes
    }

    Requires: [ pdf-lib ]

]

context [

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
    

    pdf-lib: do %pdf-lib.r ; Load  the pdf-module


    ; Utility functions
    Z: func [ msg con][ print rejoin [ msg ": " mold con ] con]


    rebol-draw-commands: [
	pen fill-pen 
	line-width
	line-cap line-join line-pattern
	miter miter-bevel round bevel
	butt square round
	nearest bilinear
	box triangle
	line polygon
	circle ellipse arc
	spline 
	curve
	closed
	push
	invert-matrix reset-matrix matrix
	rotate  scale translate scew transformation
	
	arrow
	clip
	anti-alias
	image
	text
	font
	anti-aliased vectorial aliased
	image image-filter
	; Skip the shape dialect for now.
    ]

    ; Make a context that can be used to bind all the keywords to itself. That way any block of draw 
    ; command can be evaluated after being bound to the context
    rebol-draw-binding: copy []
    foreach x rebol-draw-commands [ repend rebol-draw-binding [ to-set-word x to-lit-word x ] ]
    rebol-draw-binding: context rebol-draw-binding

    eval-draw: func [
	"Evalues a block so that all functions are run and variables replaced by its content"
	blk [block!] "The block to evaluate"
    ][
	reduce bind/copy blk rebol-draw-binding
    ]

    draw-commands: context [
	circle: func [ x y rx /xy ry /local dx dy c m ][
	    ry: any [ ry rx ]
	    dx: rx * 4 * ( ( square-root 2 ) - 1 ) / 3 
	    dy: ry * 4 * ( ( square-root 2 ) - 1 ) / 3 
	    reduce [
		x - rx y     'm 
		x - rx y + dy
		x - dx y + ry
		x      y + ry 'c
		x + dx y + ry
		x + rx y + dy
		x + rx y     'c
		x + rx y - dy
		x + dx y - ry
		x      y - ry 'c
		x - dx y - ry
		x - rx y - dy
		x - rx y     'c 'h
	    ]
	]
	arc: 'TBD

	rotate: func [
	    {Rotates the angle alpha (degrees) around (x,y)
	    A: 
		[  ca sa 0 ]
		[ -sa ca 0 ]
		[  tx ty 1 ]

	    x [ x y 1]
	    X*A:
		[ ca*x - sa*y + tx, sa*x+ca*y+ty, 1]
	    [x0,y0] = X0 * A
		x0 = ca*x0-sa+tx
		tx = x0 - ca*x0 + sa*y0
		y0 = sa*x0+ca*y0+ty
		ty = y0-sa*x0-ca*y0}
	    x0 y0 alpha
	    /local ca sa Tx Ty cm Axx
	][
	    ca: cosine alpha
	    sa: sine   alpha
	    Tx: x0 - ( ca * x0 ) + ( sa * y0 )
	    Ty: y0 - ( sa * x0 ) - ( ca * y0 )
	    reduce [ ca sa negate sa ca Tx Ty 'cm]
	]

	translate: func [ dx dy /local cm ][
	    reduce [ 1 0 0 1 dx dy 'cm ]
	]
	scale: func [ 
	    {Scales the angle alpha (degrees) around (x,y)
	    A = 
		[  cx 0  0 ]
		[  0  cy 0 ]
		[  tx ty 1 ]

	    x =  [ x y 1]
	    X*A =
		[ cx*x + tx, +cy*y+ty, 1]
	    [x0,y0] = X0 * A
		x0 = cx*x0+tx
		tx = x0 - cx*x0 = ( 1 - cx ) * x0
		y0 = cy*y0+ty
		ty = y0-cy*y0 ( 1 - cy ) * y0
	    }
	    scalex [number!] {Scale factor}
	    /xy scaley [number!] {Scale x with scalex and y with this}
	    /around x [number!] y [number!] {Scale around [x,y]}
	    /local cm
	][
	    x: any [ x 0 ]
	    y: any [ y 0 ]
	    scaley: any [ scaley scalex ]
	    reduce [ scalex 0 0 scaley 1 - scalex * x 1 - scaley * y 'cm ]
	]
    ]


    ; Make the font in face/font be the default font by using it once
    current-font: make face/font [  ]

    ; The standard Type1 fonts in pdf are:
    ;   Times-Roman, Helvetica, Courier, Symbol,
    ;   Times-Bold, Helvetica-Bold, Courier-Bold,
    ;   ZapfDingbats, Times-Italic, Helvetica-Oblique,
    ;   Courier-Oblique, Times-BoldItalic,
    ;   Helvetica-BoldOblique, Courier-BoldOblique

    if system/version/4 == 4
    [
       current-font/name: "/usr/share/fonts/gnu-free/FreeSans.ttf"
       current-font/size: 12
    ]

    create-unique-name: func [ obj /pre pre-fix /local str ][
	unless pre [ pre-fix: "U-" ]
	str: form checksum/method mold obj 'md5
	clear back tail str
	change/part str pre-fix 2
	to-word str
    ]


    font-list: copy []
    image-list: copy []

    register-font: func [ name /local tmp ][
	if object? name [
	    either all [ string? name/name find name/name "/" ][
		name: copy/part tmp: next find/last name/name "/" any [ find/last tmp "." tail tmp ]
	    ][
		name: name/name
	    ]
	]
	append font-list name
	to-refinement name
    ]

    register-image: func [ image [image!]
	/local name
    ] [
	name: create-unique-name image
	unless find/skip next image-list image 2 [
	    repend  image-list [name image]
	]
	?? name
    ]

    has-alpha: func [ im [
	{Returns none if there is a alpha value not zero}
	image!
    ] ][
	find im/alpha charset [ #"^(01)" - #"^(ff)" ]
    ]

    draw-to-stream: func [
	name [word!]  {Name of the stream object }
	cmd [ block!] {The draw commands to parse}
	f  [object!]  {The face from what to calculate original colours, and size}
	/noregister {Set this to only return a stream, do not register with name}
	/size sz
	/local p s color strea patterns fy-py 
	    render-mode  fnt 
    ][

	fy-py: func [ y ][ ( any [ all [  sz sz/y ] f/size/y ])  - y ]

	fp-pp: func [ p ][ as-pair p/x ( any [ all [  sz sz/y ] f/size/y ])  - p/y ]

	strea: copy [ ]
	patterns: context [
	    ; locals 
	    p: p1: p2: radius: string: pair: none
	    current-pen:
	    current-fill: none
	    current-line-width: none
	    current-line-pattern: none
	    cmds: none

	    ; local functions
	    stroke-aor-fill: does [
		either current-pen
		    [ either current-fill ['B] ['S ] ]
		    [ either current-fill [ 'f] [ 'n ] ]
	    ]
	    ; Patterns
	    line: [
		'line opt [ set p pair! ( repend strea [ p/x fy-py p/y 'm ] ) ]
		      any [ set p pair! ( repend strea [ p/x fy-py p/y 'l ] )]
		(append strea 'S) 
	    ]
	    box: [
		'box set p1 pair! set p2 pair!
		    opt [ set p number! ( print "Warning! Box corner radius is ignored" )]
		    ( repend strea [ fp-pp p1 p2 - p1 * 1x-1 're stroke-aor-fill ] )
	    ]
	    
	    polygon: [
		'polygon opt [ set p pair! ( repend strea [ p/x fy-py p/y 'm ] ) ]
			 any [ set p pair! ( repend strea [ p/x fy-py p/y 'l ] )]
		    (append strea 'h append strea stroke-aor-fill)
	    ]
	    line-width: [
		'line-width set p number! ( current-line-width: p repend strea [ p 'w ] )
	    ]
	    line-pattern: [ 
		'line-pattern  copy current-line-pattern [ none! | any number! ]
	    ]
	    fill-pen:  [
		'fill-pen [
		    set color tuple! (
			current-fill:  color 
			repend strea [ current-fill 'rg ]
		    ) 
		    | 
		    none! ( current-fill: none )
		]
	    ]
	    pen:  [
		'pen [
		    set color tuple! (
			current-pen: color
			repend strea [ current-pen 'RG ]
		    ) 
		    | none! ( current-pen: none )
		]
	    ]
	    circle: [
		[ 'circle | 'ellipse ] set p pair!
		    [ copy radius 1 2 number!  (   if 1 = length? radius [ append radius radius/1 ]  )
			| copy radius pair! ( radius: to-block radius )
		    ]
		    (
			append strea draw-commands/circle/xy p/x fy-py p/y radius/1 radius/2
			append strea stroke-aor-fill
		    )
	    ]
	    translate: [
		'translate set p pair! (
		    append strea draw-commands/translate p/x negate p/y
		)
	    ]
	    scale: [
		'scale copy p 2 number! (
		    append strea draw-commands/scale/xy/around p/1 p/2 0 f/size/y
		)
	    ]
	    rotate: [
		'rotate set p number! (
		    append strea draw-commands/rotate 0 f/size/y negate p
		)
	    ]
	    push: [
		'push set cmds block! 
		(
		    repend strea [ 
			'q ]
		    eval-patterns cmds
		    repend strea [ 'Q
			]
		    set-current-env
		)
	    ]
	    text: [
		'text ( render-mode: 0 )
		    some [ 
			set p pair! ( pair: p )
			|
			set s string! (string: s )
			|
			[ 'anti-aliased | 'vectorial ( render-mode: 'vectorial )| 'aliased ]
		]
		(
		    if render-mode = 'vectorial [
			render-mode:    case [
			    all [current-pen current-fill ][ 2 ]
			    all [ not current-pen current-fill ] [ 0 ]
			    all [ current-pen not current-fill ] [ 1 ]
			    all [ not current-pen  not current-fill ] [ 3 ]
			]
		    ][
			render-mode: 0
		    ]

		    repend strea [
			'q
			'BT
		    ]
		
		    if all [ current-pen render-mode = 0 ][ repend strea [ current-pen  'rg ] ]
		    repend strea [
			register-font current-font current-font/size 'Tf
			render-mode 'Tr
			pair/x fy-py pair/y + current-font/size
			'Td
			string 'Tj
		    ]
		    if all [ render-mode = 0 current-fill ][ repend strea [ current-fill  'rg ] ]
		    repend strea [
			'ET
			'Q
		    ]
		)
	    ]
	    font: [
		'font set fnt object!
		(
		    current-font: fnt
		)
	    ]
	    set-current-env: does [
		if current-pen  [ repend strea [ current-pen 'rg ] ]
		if current-fill [ repend strea [ current-fill 'rg ] ]
		repend strea [ current-line-width 'w ]
	    ]

	    eval-patterns: func [ pattern /local here ][
		
		set-current-env

		unless parse eval-draw pattern [
		    any [ here:
			  line 
			| polygon
			| box
			| line-width
			| line-pattern
			| fill-pen
			| pen
			| circle
			| translate
			| scale
			| rotate
			| push
			| text
			| font
			| skip
		    ]
		] [
		    make error! remold [ "Did not find end of pattern" here  newline "-----------------"]
		]
	    ]
	]

	patterns/current-line-width: 1
	patterns/current-pen: any [ f/color white ]

	patterns/eval-patterns cmd
	
	unless noregister [
	    stream name compose [ 
		dict [
		    /Length none
		]
		stream
		(strea)  ; Remove the space in previous line
		endstream
	    ]
	]
	strea
    ]


    used-fonts: copy []
    font-translations: [
	"helvetica"		Helvetica
	"arial"		Helvetica
	"font-sans-serif"	Helvetica
	"FreeSans"		Helvetica
	"Courier"		Courier
	"font-fixed"	Courier
	"Times"		Times-Roman
	"Times-Roman"	Times-Roman
	"font-serif"	Times-Roman
    ]


    translate-fontname: func [ name [string! word! ] /local new ] [
	if word? name [ name: to-string name ]
	new: any [ select font-translations name to-word name ]
	to-refinement new
    ]

    use-font: func [ name /local use-name tmp ][
	if object? name [
	    either all [ string? name/name find name/name "/" ][
		name: copy/part tmp: next find/last name/name "/" any [ find/last tmp "." tail tmp ]
	    ][
		name: name/name
	    ]
	]
	append used-fonts use-name: translate-fontname name
	use-name
    ]
	

    reduce-fonts: func [] [
	used-fonts: union used-fonts []
    ]


    parse-face: func [
	face [object!]
	/local strea offset n  x y pos edge pane line-info
	    reference fy-py p save-current-font
    ][
	strea: copy []

	fy-py: func [ y ][ face/size/y - y ]

	repend strea [ 0x0 face/size 're 'W 'n ] ; Set clipping
	
	if face/color [ ; background
	    repend strea [
		face/color 'rg
		0 0 face/size 're 'f
	    ]
	]
	if face/image [
	    reference: to-refinement register-image face/image
	    repend strea [
		; Assume scale 'fit
		'q face/size/x 0 0 face/size/y 0 0 'cm 
		reference 'Do
		'Q
	    ]
	]

	if  block? p: face/effect [
	    offset: probe 1x1 * any [
			all [ face/edge face/edge/size ]
			0x0
	    ]
	    while [p: find p 'draw] [
		append strea compose [
		    q
		    ( draw-commands/translate offset/x offset/y )
		    (
			use [ draw-cmds ] [
			    draw-cmds: p/2
			    if word? draw-cmds [ draw-cmds: get draw-cmds ]
			    draw-to-stream/noregister/size
				'anything draw-cmds
				face
				face/size - ( 2x2 * offset )
			]
		    )
		    Q    
		]
		p: skip p  2
	    ]
	]
	if all [ face/text face/font face/font/color not find system/view/screen-face/pane face ] [
	    line-info: make system/view/line-info []
	    n: 0
	    current-font: face/font 
	    while [  textinfo face line-info n ][
		edge: either all [ face/edge face/edge/size ][ 1x1 * face/edge/size ] [ 0x0 ]
		x: line-info/offset/x + edge/x
		y: face/size/y
		    - line-info/offset/y
		    - face/font/size
		    - edge/y
		append strea compose [
		    BT (register-font current-font) (face/font/size) Tf
		    (face/font/color) rg 
		    ( reduce [ x y ] )
		    Td
		    (copy/part line-info/start line-info/num-chars) Tj
		    ET
		]
		n: n + 1
	    ]
	]
	if all [ face/edge face/edge/size face/edge/color ][
	    use [ edge size nw-color se-color ][
		edge: 1x1 * face/edge/size size: 1x1 * face/size
		nw-color: se-color: face/edge/color
		switch face/edge/effect [
		    ibevel [
			nw-color: hsv-to-rgb (rgb-to-hsv face/edge/color) - 0.0.63
			se-color: hsv-to-rgb (rgb-to-hsv face/edge/color) + 0.0.63
		    ]
		    bevel [
			nw-color: hsv-to-rgb (rgb-to-hsv face/edge/color) + 0.0.63
			se-color: hsv-to-rgb (rgb-to-hsv face/edge/color) - 0.0.63
		    ]
		]
		repend strea [
		    red 'RG
		    nw-color 'rg
		    0 0 'm
		    edge 'l
		    edge/x size/y - edge/y 'l
		    size/x - edge/x size/y - edge/y 'l
		    size 'l
		    0 size/y 'l
		    'h  'f
		    se-color 'rg
		    0 0 'm
		    edge 'l
		    size/x - edge/x edge/y 'l
		    size/x - edge/y size/y - edge/y 'l
		    size 'l
		    size/x 0 'l
		    'h 'f
		]
	    ]
	]
	pane: get in face 'pane
	if :pane [
	    unless block? :pane [ pane: reduce [ :pane ] ]
	    foreach p pane [
		case [
		    object? :p [
			pos: as-pair p/offset/x face/size/y - ( p/offset/y + p/size/y)
			append strea 'q
			append strea draw-commands/translate pos/x pos/y
			save-current-font: current-font
			append strea parse-face p
			current-font: save-current-font
			append strea 'Q
		    ]
		    function? :p [ print "Transformation of functional panes not implemented" ]
		    true	    [  print [ "Unknown object in pane!" type? :p ] ]
		]
	    ]
	]
	strea
    ]

    face-to-pdf: func [
	face
	/local
	    f-l
	    fonts
	    font-replacement
	    images
	    image
	    page
	    pages resource
	    doc
	    alpha
	    graph   alpha-name strea
    ][
	; Initialize
	doc: pdf-lib/prepare-pdf
	
	font-list: copy []
	image-list: copy []
	
	; Make content
	strea: parse-face face
	graph: doc/make-obj pdf-lib/base-stream! strea

	; Fonts
	fonts: doc/make-obj pdf-lib/fonts-dict! []
	
	font-list:  unique font-list
	font-replacement: copy []
	foreach f font-list [ append font-replacement translate-fontname f ]
	f-l: copy []
	foreach f unique font-replacement [ repend f-l [ f doc/make-obj pdf-lib/font-dict! reduce [ f ]] ]
	loop  length? font-list [
	    fonts/add-obj  first+ font-list   select f-l first+ font-replacement
	]

	; Handle images
	images: doc/make-obj pdf-lib/XObjects-dict! [ ]
	image-list: unique/skip  image-list 2
	foreach [image-name image-obj ]  image-list [

	    either has-alpha image-obj [
		alpha: doc/make-obj pdf-lib/image-alpha-stream! [ image-obj ]
		alpha-name: to-word join "A" image-name
		images/add-obj alpha-name alpha
	    ][
		alpha: none
	    ]

	    image: doc/make-obj pdf-lib/image-rgb-stream! [ image-obj alpha ]
	    images/add-obj image-name image

	]

	; Register resources
	resource: doc/make-obj pdf-lib/resources-dict! [  ]
	unless empty? images/value-list [ resource/XObject: images ]
	unless empty? fonts/value-list [ resource/Font: fonts ]
	    

	; Create page
	page: doc/make-obj pdf-lib/page-dict! [ graph resource ]
	page/set-mediaBox reduce [ 0x0 face/size ]

	; Create the page
	pages: doc/make-obj pdf-lib/pages-dict! [ page ]

	; Creeate the object holding pages together
	doc/make-obj/root pdf-lib/catalog-dict! [ pages ]
	
	doc/to-string
    ]

    if system/script/args [
	export system/script/args 
    ]
    
] 


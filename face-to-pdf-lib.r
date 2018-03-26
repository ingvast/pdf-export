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

	The clip command has been implemented. However, it does not seem to work properly in Rebol.
	It is however made to reflect what I think should have been done in rebol.

}
    TODO: {
	* Fix so that images not is taken from one document to next
	* Add possibility to have several pages.
	* Add possiblity to set media (A4,letter,...)
	* Clean up, hide scope
	* Fix some compressions
	* Handle gradients
	* Make use of font given. (Write font data to pdf)
	* Handle the rest of draw commands 
	    - arrow
	    - line patterns
	    - fill pen patterns
	    - line join
	    - line cap
	    - shape (or maybe not)
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
    Z: func [ msg con ][ print rejoin [ msg ": " mold con ] con]

    arctan2: func [ y x ][
	case [
	    y < 0 [
		negate arctan2 negate y x
	    ]
	    x < 0 [
		180 - arctan2 y negate x
	    ]
	    x = 0 [
		90
	    ]
	    y < x [
		arctangent y / x
	    ]
	    true [
		90 - arctangent x / y
	    ]
	]
    ]

    reduce-all-but: func [
	{Returns a copy of block which is evaluated except the words in names 
	 which are treated as lited}
	b [block!] {Block to evaluate}
	names [block!] {The names not to evaluate}
	/local 
	    binding
    ][
	binding: copy []
	foreach x names [
	    repend binding [ to-set-word x to-lit-word x]
	]
	binding: make object! binding
	reduce bind/copy b binding
    ]
	;TODO: test this function next the parse of the effect ...

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
	rotate  scale translate skew transformation
	
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
		x + rx y     'm 
		x + rx y + dy
		x + dx y + ry
		x      y + ry 'c
		x - dx y + ry
		x - rx y + dy
		x - rx y     'c
		x - rx y - dy
		x - dx y - ry
		x      y - ry 'c
		x + dx y - ry
		x + rx y - dy
		x + rx y     'c 'h
	    ]
	]
	arc: func [ p R angle1 angle-span
		    /closed
		    /local
		    result
		    parts part-angle
		    d angle
		    angle-next
		    p1x p1y 
		    p2x p2y 
		    p3x p3y 
		    p4x p4y 
	][
	    result: copy/deep [ ps [] arrows [] ]
	    parts: round/ceiling angle-span / 90
	    part-angle: angle-span / parts
	    d:  4 / 3 * tangent part-angle / 4
	    if  closed [ repend result/ps [ p 'm ] ]
	    repend result/ps [ p/x + (R/x * cosine angle1) p/y + (R/y * sine angle1) ]
	    append result/arrows to-pair reduce [ p/x + (R/x * cosine angle1) p/y + (R/y * sine angle1) ]
	    repend result/ps either closed [ 'l ][ 'm] 
	    angle: angle1
	    repeat i parts [
		angle-next: angle + part-angle
		p1x: p/x + (R/x * cosine angle )	p1y: p/y + (R/y * sine angle )
		p4x: p/x + (R/x * cosine angle-next)	p4y: p/y + (R/y * sine angle-next)
		p2x: p1x - (R/x * d * sine angle)	p2y: p1y + (R/y * d * cosine angle )
		p3x: p4x + (R/x * d * sine angle-next)	p3y: p4y - (R/y * d * cosine angle-next)
		repend result/ps [
		    as-pair p2x p2y 
		    as-pair p3x p3y 
		    as-pair p4x p4y 'c
		]
		repend result/arrows [
		    as-pair p2x p2y 
		    as-pair p3x p3y 
		    as-pair p4x p4y 
		]
		angle: angle-next
	    ]
	    if closed [ append result/ps 'h ] 
	    result
	]

	matrix: func [
	    {Tranforms the image with coeffficinents for matrix}
	    M
	    /local 
	][
	    reduce [ M/1 M/2 M/3 M/4 M/5 M/6 'cm]
	]

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
		ty = y0-sa*x0-ca*y0 }
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
	skew: func [ angle ][
	    reduce [ 1 0 tangent angle 1 0 0 'cm ]
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
    triangle-list: copy [ ]

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
	either find/skip image-list name 2 [
	    dbg: name 
	][
	    repend  image-list [name image]
	    prin ["Added name" name ]
	]
	print [ " Handled name " name ]
	name
    ]

    register-triangle: func [ stream ][
	name: create-unique-name/pre stream "T-"
	unless find/skip triangle-list name 2 [
	    repend triangle-list [ name stream ]
	]
	name
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
	/local p s color strea patterns 
	    render-mode  fnt 
    ][
	warning: func [ s ][ print [ "Warning!" s ] ]

	strea: copy [ ]
	patterns: context [
	    ; locals 
	    p: po: p1: p2: radius: string: pair: none
	    matrix: none
	    cmds: none

	    current-pen: copy []
	    current-fill: none
	    current-line-width: none
	    current-line-pattern: copy []
	    current-line-cap: 0
	    current-line-join: 0
	    current-miter-limit: none
	    current-arrow: 0x0

	    path: copy []
	    clear-path: does [ path: copy [] ]
	    add-path: func [ p ] [ append path p ]

	    paint-path: func [
		/no-fill
		/local
		    pattern-count
		    pattern-length
		    offset
		    pattern
	    ][
		if  all[ current-fill not no-fill ] [
		    ; fill it
		    append strea path
		    append strea 'f
		]
		if not empty? current-pen [
		    ; loop thru the stroke colors
		    pattern-count: min length? current-line-pattern length? current-pen
		    either pattern-count < 2 [
			append strea path
			append strea 'S
		    ] [
			; draw with pattern

			;3 6 8
			;***-------++++++++
			;***               ***		 [3 14] 0
			;   -------           ------	 [6 11] -3
			;          ++++++++         ++++++++ [8 9 ] -9
		       ; 
			pattern-length: 0
			 repeat i pattern-count [
			    pattern-length: pattern-length + pick current-line-pattern i 
			]

			offset: pattern-length

			repeat i pattern-count [
			    strip: pick current-line-pattern i
			    if color: pick current-pen i [
				repend strea  [ color 'RG ]
				pattern: reduce [
				    strip pattern-length - strip
				]
				repend strea [ pattern offset 'd ]
				append strea path
				append strea 'S
			    ]
			    offset: offset - strip
			]
		    ]
		]
		clear-path
	    ]
	    draw-forward-arrow: func [
		point [pair!] {where it hits}
		direction [number!] {Direction of pointing}
		thickness [number!] {Thickness of line, also gives size of arrow}
		color	[tuple!] {Color of the line}
		/local arrow
		    r thickness-relation half-point-angle
	    ][
		
		half-point-angle: 15
		ca: cosine direction
		sa: sine direction
		thickness-relation: 10 ; Relation between line thickness and arrow size
		r: thickness-relation ;thickness * thickness-relation
		arrow: reduce [ 
			r * negate cosine half-point-angle
			r * sine half-point-angle
		]
		append strea reduce [
		    'q ca  sa negate sa ca point 'cm ; Translate and rotate
		    color 'rg
		    color 'RG
		    thickness 'w
		    0 'j 30 'M
		    0x0 'm 
		    arrow/1 arrow/2 'l
		    negate r * 0.75 0 'l
		    arrow/1 negate arrow/2 'l
		    'h 'B 'Q
		]
	    ]
	    draw-backward-arrow: func [
		point [pair!] {where it hits}
		direction [number!] {Direction of pointing}
		thickness [number!] {Thickness of line, also gives size of arrow}
		color	[tuple!] {Color of the line}
		/local arrow
		    r thickness-relation half-point-angle
	    ][
		
		half-point-angle: 40
		ca: cosine direction + 180
		sa: sine direction + 180
		thickness-relation: 10 ; Relation between line thickness and arrow size
		r: thickness-relation ;thickness * thickness-relation
		arrow: reduce [ 
			r * negate cosine half-point-angle
			r * sine half-point-angle
		]
		append strea reduce [
		    'q ca  sa negate sa ca point 'cm ; Translate and rotate
		    color 'rg
		    thickness 'w
		    0 'j 30 'M
		    arrow/1 arrow/2 'm
		    0x0 'l 
		    arrow/1 negate arrow/2 'l
		    'S 'Q
		]
	    ]
	    draw-arrows: func [ 
		types [pair!] {What kind of arrows}
		ctrl-points [ block! ] { Control points as if a beizier spline, it uses first and last two points}
		thickness [number!] {Line thickness}
		color [tuple!] {Colors of arrow}
		/local dir1 dir2 angle1 angle2
	    ][
		dir1: ctrl-points/1 - ctrl-points/2 
		angle1: arctan2 dir1/y dir1/x

		dir2: (last ctrl-points) - first skip tail ctrl-points -2
		angle2: arctan2 dir2/y dir2/x

		switch second types [
		    1 [ draw-forward-arrow ctrl-points/1 angle1 thickness color ]
		    2 [ draw-backward-arrow ctrl-points/1 angle1 thickness color ]
		]
		switch first types [
		    1 [ draw-forward-arrow last ctrl-points angle2 thickness color ]
		    2 [ draw-backward-arrow last ctrl-points angle2 thickness color ]
		]
	    ]

	    ; Patterns
	    line: [
		'line  ( pth: copy [] )
		      set po pair! (append pth po)
		      any [ set p pair!
			    (
				add-path reduce [ po/x po/y 'm p/x p/y 'l ]
				po: p
				append pth po
			    )]
		(
		    paint-path/no-fill
		    unless any [ current-arrow = 0x0 empty? current-pen ] [
			use [ len ][
			    len: length? pth
			    if len > 1 [
				;pth: reduce [ pth/1 pth/2 pth/(len - 1) last pth ]
				draw-arrows current-arrow pth current-line-width any current-pen
			    ]
			]
		    ]
		) 
	    ]
	    spline: [
		'spline  (pth: copy [] )
		    integer! 
		    opt [ set p pair! ( add-path reduce [ p/x p/y 'm ] append pth p ) ]
		    any [ set p pair! ( add-path reduce [ p/x p/y 'l ] append pth p ) ]
		    (
			paint-path

			unless any [ current-arrow = 0x0 empty? current-pen ] [
			    use [ len ][
				len: length? pth
				if len > 1 [
				    ;pth: reduce [ pth/1 pth/2 pth/(len - 1) last pth ]
				    draw-arrows  current-arrow pth current-line-width current-pen/1
				]
			    ]
			]
		    )
	    ]
	    box: [
		'box set p1 pair! set p2 pair!
		    opt [ set p number! ( warning "Box corner radius is ignored" )]
		    ( add-path reduce [ p1 p2 - p1 're ] paint-path)
	    ]
	    use [ str p colors ][
		triangle: [
		    'triangle
		    copy p 3 pair!  copy colors 3 tuple! opt decimal!
		    (
			str: reduce [
			    0 p/1 colors/1 
			    0 p/2 colors/2
			    0 p/3 colors/3
			]

			name: register-triangle str
			;add-to-patterns name
			append strea compose [
			    (to-refinement name ) sh
			]
			if not empty? current-pen [
			    set-current-env
			    add-path reduce [
				p/1 'm
				p/2 'l
				p/3 'l
				'h 
			    ]
			    paint-path/no-fill
			]
		    )
		]
	    ]

	    clip: [
		'clip set p1 pair! set p2 pair!
		    ( repend strea [ p1 p2 - p1 're 'W 'n ] )
	    ]
	    
	    polygon: [
		'polygon opt [ set p pair! ( add-path reduce [ p/x p/y 'm ] ) ]
			 any [ set p pair! ( add-path reduce [ p/x p/y 'l ] )]
		    (add-path 'h paint-path)
	    ]
	    circle: [
		[ 'circle | 'ellipse ] set p pair!
		    [ copy radius 1 2 number!  (   if 1 = length? radius [ append radius radius/1 ]  )
			| set radius pair! ( radius: reduce[ radius/x radius/y ] )
		    ]
		    (
			add-path draw-commands/circle/xy p/x p/y radius/1 radius/2
			paint-path
			unless any [ current-arrow = 0x0 empty? current-pen ] [
			    radius: to-pair radius
			    draw-arrows  current-arrow 
				reduce [
				    radius * 1x0 + p radius        + p 
				    radius * 1x-1 + p radius * 1x0 + p 
				]
				current-line-width current-pen/1
			]
		    )
	    ]
	    arc: [ 'arc ( points: copy [] angles: copy [] arg: none)
		    any [ copy p  pair! ( append points p) |
			  copy angle number! ( append angles angle ) |
			  copy arg 'closed 
		    ]
		    (
			pth: either arg [
			    draw-commands/arc/closed
				    first points last points
				    first angles last angles 
			] [
			    draw-commands/arc
				    first points last points
				    first angles last angles
			]
			add-path pth/ps
			paint-path
			unless any [ current-arrow = 0x0 empty? current-pen ] [
			    draw-arrows current-arrow pth/arrows current-line-width any current-pen
			]
		    )
	    ]
	    curve: [ 'curve (pth: copy [])
		[
		    copy p 4 pair!
		    | copy p 3 pair! ( insert at p 2 p/2)
		]
		( 
		    add-path reduce [
			p/1 'm
			p/2 p/3 p/4 'c
		    ]
		    paint-path
		    unless any [ current-arrow = 0x0 empty? current-pen ] [
			draw-arrows  current-arrow p current-line-width any current-pen
		    ]
		)
	    ]
	    translate: [
		'translate set p pair! (
		    append strea draw-commands/translate p/x p/y
		)
	    ]
	    scale: [
		'scale copy p 2 number! (
		    append strea draw-commands/scale/xy/around p/1 p/2 0 0
		)
	    ]
	    rotate: [
		'rotate set p number! (
		    append strea draw-commands/rotate 0 0 p
		)
	    ]
	    skew: [
		'skew set p number! (
		    append strea draw-commands/skew p
		)
	    ]
	    use [ mtrx ][
		matrix: [
		    'matrix set mtrx block! (
			    append strea draw-commands/matrix mtrx
			    )
		]
	    ]
	    push: [
		'push set cmds block! 
		(
		    repend strea [ 
			'q ]
		    set-current-env
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
			    all [not empty? current-pen current-fill ][ 2 ]
			    all [ empty?  current-pen current-fill ] [ 0 ]
			    all [ not empty? current-pen not current-fill ] [ 1 ]
			    all [ empty?  current-pen  not current-fill ] [ 3 ]
			]
		    ][
			render-mode: 0
		    ]

		    repend strea [
			'q
			'BT
			1 0 0 -1 0 2 * pair/2 + current-font/size 'cm
		    ]
		
		    either all [ not empty? current-pen current-pen/1 render-mode = 0 ]
			[ repend strea [ current-pen/1  'rg ] ]
			[ set-current-env ]
		    repend strea [
			register-font current-font current-font/size 'Tf
			render-mode 'Tr
			pair/x pair/y 
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
	    use [ point-list img fail-pattern ][
		image: [
		    'image (point-list: copy [] img: none )
			any [ here:
			    set p pair! ( append point-list p )
			    | set p word! (
				either image? get p [
				    fail-pattern: []
				    img: get p
				][
				    fail-pattern: "slkdj saj dkjajsdflkiewvnndloaweu"
				]
			    ) fail-pattern
			    | set img image!
			] (
			    p: point-list
			    if 4 <= length? p [
				warning "Cannot handle four point image transformation in draw dialect"
				warning "Ignoring last point"
			    ]
			    case [ 
				not img
				[
				    warning "No image found"
				]
				true
				[
				    if empty? p [
					p: copy [ 0x0 ]
				    ; Calculate the transformation matrix
				    ]
				    if 1 == length? p [
					append p img/size + p/1
				    ]
				    if 2 == length? p [
					insert at p 2 as-pair p/2/x p/1/y
				    ]
				    M: copy [ 0 0 0 0 0 0]
				    ; calculate the transformation
				    ; p/1 = T(0x1)
				    ; p/2 = T(1x1)
				    ; p/3 = T(1x0) 
				    ; 
				    ; p/1/x = M/1 * 0 + M/3 * 1 + M/5
				    ; p/1/y = M/2 * 0 + M/4 * 1 + M/6

				    ; p/2/x = M/1 * 1 + M/3 * 1 + M/5
				    ; p/2/y = M/2 * 1 + M/4 * 1 + M/6

				    ; p/3/x = M/1 * 1 + M/3 * 0 + M/5
				    ; p/3/y = M/2 * 1 + M/4 * 0 + M/6

				    ;(2) - (1)
				    ; p/2/x - p/1/x =   M/1
				    ; p/2/y - p/1/y =   M/2
				    M/1: p/2/x - p/1/x
				    M/2: p/2/y - p/1/y
				    ; (3)
				    ; p/3/x = M/1 + M/5
				    ; p/3/y = M/2 + M/6
				    M/5: p/3/x - M/1
				    M/6: p/3/y - M/2
				    ; (1)
				    ; p/1/x = M/3 + M/5
				    ; p/1/y = M/4 + M/6
				    M/3: p/1/x - M/5
				    M/4: p/1/y - M/6

				    reference: to-refinement register-image img
				    append strea compose [
					q
					    (M) cm 
					    (reference) Do
					'Q
				    ]
				]
			    ]
			)
		]
	    ]
	    font: [
		'font set fnt object!
		(
		    current-font: fnt
		)
	    ]
	    line-width: [
		'line-width set p number! ( current-line-width: p repend strea [ p 'w ] )
	    ]
	    line-pattern: [ 
		'line-pattern  copy current-line-pattern any [ none! | number! ]
		(unless any current-line-pattern [
		    current-line-pattern: copy []
		    append strea [ [] 0 d ]
		    ] )
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
		    copy color some [ tuple! | none! ]
		    (
			if all [ 1 = length? color not color/1 ] [ color: copy [] ]
			current-pen: color
			if all[ not empty? current-pen  current-pen/1 ] [ repend strea [ current-pen/1 'RG ] ]
		    ) 
		]
	    ]
	    line-join: [
		'line-join [
		    'miter ( current-line-join: 0 current-miter-limit: 10 )
		    | 'miter-bevel (current-line-join: 0 current-miter-limit: 4 )
		    | 'round (current-line-join: 1 current-miter-limit: none )
		    | 'bevel (current-line-join: 2 current-miter-limit: none )
		]
		( repend strea [ current-line-join 'j ]
		  if current-miter-limit [ repend strea [ current-miter-limit 'M ] ]
		)
	    ]
	    line-cap: [
		'line-cap [
		    'butt ( current-line-cap: 0)
		    | 'round (current-line-cap: 1)
		    | 'square (current-line-cap: 2)
		]
		( repend strea [ current-line-cap 'J] )
	    ]
	    arrow: [ 'arrow
		set current-arrow pair! 
	    ]
	    set-current-env: does [
		if all[ not empty? current-pen current-pen/1 ]  [ repend strea [ current-pen/1 'RG ] ]
		if current-fill [ repend strea [ current-fill 'rg ] ]
		if current-miter-limit [ repend strea [ current-miter-limit 'M ] ]
		repend strea [
		    current-line-width 'w
		    current-line-cap 'J
		    current-line-join 'j
		]
	    ]

	    eval-patterns: func [ pattern /local here ][
		
		set-current-env

		unless parse eval-draw pattern [
		    any [ here:
			  line 
			| spline
			| polygon
			| triangle
			| box
			| line-width
			| line-pattern
			| line-join
			| line-cap
			| fill-pen
			| pen
			| arrow
			| clip
			| circle
			| arc
			| curve
			| image
			| translate
			| scale
			| rotate
			| skew 
			| matrix
			| [ 'reset-matrix | 'invert-matrix ]
			    (warning rejoin [  here/1 {" not implemented}])
			| push
			| text
			| font
			| line-join
			| line-cap
			| skip
		    ]
		] [
		    make error! remold [ "Did not find end of pattern" here  newline "-----------------"]
		]
	    ]
	]

	patterns/current-line-width: 1
	patterns/current-pen: reduce [ any [ all[ f/color inverse-color f/color ] black ] ]
	patterns/current-line-pattern: copy []

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

    inverse-color: func [ color [tuple!] ][
	255.255.255 - color
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
	    reference p save-current-font
    ][
	strea: copy []

	repend strea [ 0x0 face/size 're 'W 'n ] ; Set clipping
	
	if face/color [ ; background
	    repend strea [
		face/color 'rg
		0 0 face/size 're 'f
	    ]
	]
	if image? face/image [
	    reference: to-refinement register-image face/image
	    case [
		find face/effect 'fit [
		    repend strea [
			'q face/size/x 0 0 negate face/size/y 0 face/size/y 'cm 
			reference 'Do
			'Q
		    ]
		]
		find face/effect 'aspect [
		    use [ x-scale y-scale scale ][
			;for full fit scale in x-direction
			x-scale: face/size/x / face/image/size/x
			y-scale: face/size/y / face/image/size/y
			scale: min x-scale y-scale
			repend strea [
			    'q
			    face/image/size/x * scale 0 0 negate face/image/size/y * scale
			    0 face/image/size/y * scale 'cm 
			    reference 'Do
			    'Q
			]
		    ]
		    
		]
		p: find face/effect 'extend [
		    use[ ] [
			print "Extend"
			pos: ext: none
			parse next p [ set pos pair! set ext pair! ]
			pos: any [ pos face/image/size / 2 ]
			ext: any [ ext face/size - face/image/size ] 
			; Pos says which column and row that is to be expanded
			; ext is the number of cols and rows to repeat the column at pos

			x-is: reduce [ 0	pos/x	    pos/x + 1 ]
			y-is: reduce [ 0	pos/y	    pos/y + 1 ]
			x-ps: reduce [ 0	pos/x	    pos/x + ext/x ]
			y-ps: reduce [ 0	pos/y	    pos/y + ext/y ]
			x-isize: reduce [ pos/x       1	       face/image/size/x - pos/x - 1 ]
			y-isize: reduce [ pos/y       1	       face/image/size/y - pos/y - 1 ]
			x-psize: reduce [ pos/x       ext/x       face/image/size/x - pos/x - 1 ]
			y-psize: reduce [ pos/y       ext/y       face/image/size/y - pos/y - 1 ]
			
			repeat i 3 [
			    repeat j 3 [
				ref: to-refinement register-image copy/part
				    at face/image as-pair x-is/:i y-is/:j
				    as-pair x-isize/:i y-isize/:j
				repend strea [
				    'q
					x-psize/:i 0 0 negate y-psize/:j
					x-ps/:i        y-ps/:j + y-psize/:j 'cm 
					ref 'Do
				    'Q
				]
			    ]
			]

			comment [
			    im1: 0x0 
			    im2: pos
			    im3: face/image/size

			    p11tl: 0x0
			    p11lr: pos - 1x1
			    p2tl: pos
			    p2lr: pos 
			    p33tl: pos + 1x1
			    p33lr: face/image/size - 1x1
			    p44tl: face/image/size
			    s11: p2tl - p1tl
			    s21: as-pair p3tl/x - p2tl/x p2tl/y - p1tl/y
			    s31: as-pair p4tl/x - p3tl/x p2tl/y - p1tl/y
			    s12: as-pair p2tl/x - p1tl/x p3tl/y - p2tl/y
			    s22: p3tl - p2tl
			    s13: as-pair p2tl/x - p1tl/x p4tl/y - p3tl/y
			    s13: as-pair p2tl/x - p1tl/x p4tl/y - p3tl/y
			    s23: as-pair p3tl/x - p2tl/x p4tl/y - p3tl/y
			    s33: p44tl - p33tl
			    ; column rad
			    r11: to-refinement register-image copy/part p11tl s11
			    r12: to-refinement register-image copy/part p12tl s12
			    r13: to-refinement register-image copy/part p13tl s13
			    r21: to-refinement register-image copy/part p21tl s21
			    r31: to-refinement register-image copy/part p31tl s31
			    r32: to-refinement register-image copy/part p32tl s32
			    r33: to-refinement register-image copy/part p33tl s33

			    f1: 0x0
			    f2: pos
			    f3: pos + ext
			    f4: im3 + ext

			    p12tl: p12tl
			    p12lr: as-pair p12lr/x		p12lr/y + ext/y
			    p21tl: p21tl
			    p21lr: as-pair p21lr/x + ext/x	p21lr/y
			    p22tl: p22tl
			    p22lr: as-pair p22lr/x + ext/x	p22lr/y + ext/y

			    p13tl: as-pair p13tl/x		p13tl/y + ext/y
			    p13lr: as-pair p13lr/x		p13lr/y + ext/y
			    p31tl: as-pair p31tl/x + ext/x	p31tl/y
			    p31lr: as-pair p31lr/x + ext/x	p31lr/y


			    ; Hence we get the areas
			    ; uppler-left, upper-right lower-left lower-right horizontal vertical
			    ; These are each to become a image of itself and later expanded and put at
			    ; the right place.

			    repend strea [
				'q
				    f2/x  0 0 negate f2/y
				    0 f2/y 'cm 
				    upper-left 'Do
				'Q
				'q
				    f4/x - f3/x - 1 0 0 negate f3/y - f2/y + 1
				    f3/x + 1  f2/y 'cm
				    upper-right 'Do
				'Q
				'q
				    f2/x 0 0 negate f4/y - f3/y - 1
				    0 f4/y 'cm
				    lower-left 'Do
				'Q
				'q
				    f4/x - f3/x - 1 0 0 negate f4/y - f3/y - 1
				    f3/x + 1 f4/y 'cm
				    lower-right 'Do
				'Q
				'q
				    f3/x - f2/x + 1 0 0 negate f2/y
				    f2/x f2/y  'cm
				    upper 'Do
				'Q
				'q
				    f3/x - f2/x + 1 0 0 negate f4/y - f3/y - 1
				    f2/x f4/y 'cm
				    lower 'Do
				'Q
				'q
				    f2/x - f1/x    0 0    negate f3/y - f2/y + 1
				    0 f3/y + 1 'cm
				    left 'Do
				'Q
				'q
				    f4/x - f3/x - 1 0 0 negate f3/y - f2/y + 1
				    f3/x + 1 f3/y + 1 'cm
				    right 'Do
				'Q
				'q
				    f3/x - f2/x + 1     0 0   negate f3/y - f2/y + 1
				    f2/x f3/y + 1 'cm
				    mid 'Do
				'Q

			    ]
			]
		    ]

		]
		true [ ; Scale 1:1
		    repend strea [
			'q face/image/size/x 0 0 negate face/image/size/y 0 face/image/size/y 'cm 
			reference 'Do
			'Q
		    ]
		]
	    ]
	]

	if  block? p: face/effect [
	    offset: 1x1 * any [
			all [ face/edge face/edge/size ]
			0x0
	    ]
	    parse face/effect [
		any [
		    'draw set p skip  (
			if word? p [ p: get p ]
			append strea compose [
			    q
			    ( draw-commands/translate offset/x offset/y )
			    (
				use [ draw-cmds ] [
				    draw-cmds: p
				    if word? draw-cmds [ draw-cmds: get draw-cmds ]
				    draw-to-stream/noregister/size
					'anything draw-cmds
					face
					face/size - ( 2x2 * offset )
				]
			    )
			    Q    
			]   
		    )
		    |
		    [ 'grid 
			set grid-spacing pair!
			set grid-offset opt pair!
			set grid-color opt tuple!
			set grid-thickness opt [ number! | pair! ]
			(
			    grid-thickness: 1x1 * any [ grid-thickness 1 ]
			    repend strea [
				'q
				any [ grid-color 0.0.0 ] 'RG
				grid-thickness/x 'w
			    ]
			    for x 1 + any [ grid-offset/x 0] face/size/x grid-spacing/x [
				repend strea [
				    x 0 'm x face/size/y 'l
				]
			    ]
			    for y 1 + any [ grid-offset/y 0] face/size/y grid-spacing/y [
				repend strea [
				    0 y 'm face/size/x y 'l
				]
			    ]
			    append strea 'S
			)
		    ]
		    |
		    skip
		]
	    ]
	]
	if all [ face/text face/font face/font/color not find system/view/screen-face/pane face ] [
	    line-info: make system/view/line-info []
	    n: 0
	    current-font: face/font 
	    append strea compose [
		BT (register-font current-font) (face/font/size) Tf
	    ]
	    while [  textinfo face line-info n ][
		edge: either all [ face/edge face/edge/size ][ 1x1 * face/edge/size ] [ 0x0 ]
		x: line-info/offset/x + edge/x
		y:  line-info/offset/y + 
		     edge/y +
		     face/font/size 
		append strea compose [
		    ;T (register-font current-font) (face/font/size) Tf
		    1 0 0 -1 0 (2 * y) Tm
		    ;1 0 0 -1 0 (2 * y ) cm
		    (face/font/color) rg 
		    ( reduce [ x y ] )
		    Td
		    (copy/part line-info/start line-info/num-chars) Tj
		    ;ET
		]
		n: n + 1
	    ]
	    append strea 'ET
	]
	if all [ face/edge pair? face/edge/size face/edge/color ][
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
		    size/x 0 'l
		    size/x - edge/x edge/y 'l
		    edge 'l
		    edge/x size/y - edge/y 'l
		    0 size/y 'l
		    'h  'f

		    se-color 'rg
		    size 'm
		    0 size/y 'l
		    edge/x size/y - edge/y 'l
		    size - edge 'l
		    size/x - edge/x edge/y 'l
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
			pos: as-pair p/offset/x p/offset/y
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
	strea: copy []
	repend strea [
	    1 0 0 -1 0 face/size/y
	    'cm
	]

	append strea parse-face face
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

	; Handle patterns
	shadings: doc/make-obj pdf-lib/shadings-dict!  []
	foreach [name shade] triangle-list [
	    shade-obj: doc/make-obj pdf-lib/shading-triangles-dict! shade
	    shadings/add-obj name shade-obj
	]

	; Register resources
	resource: doc/make-obj pdf-lib/resources-dict! [  ]
	unless empty? images/value-list [ resource/XObject: images ]
	unless empty? fonts/value-list [ resource/Font: fonts ]
	unless empty? shadings/value-list [ resource/Shading: shadings ]

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


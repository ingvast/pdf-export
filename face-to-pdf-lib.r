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
	* Alpha values for general graphic
    }
    DONE: {
	* Handle alpha values of images
	* Handle images
	* Rewrite printf routines
	* Improve the printing of strings to do proper escapes
	* Handle the rest of draw commands 
	    - arrow
	    - line patterns
	    - fill pen patterns
	    - line join
	    - line cap
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


    matrix-mult: func [
	{Multiply m1 with m2 given that m1 is given as a list of 
	     [ m1/1 m1/3 m1/5 ]
	     [ m1/2 m1/4 m1/6 ]
	     [ 0    0     1   ]

         So the multiplication is:
	     [ m1/1 m1/3 m1/5 ]    [ m2/1 m2/3 m2/5 ]   
	     [ m1/2 m1/4 m1/6 ]  x [ m2/2 m2/4 m2/6 ]  =
	     [ 0    0     1   ]    [ 0    0     1   ]   

	       [ m1/1*m2/1+m1/3*m2/2  m1/1*m2/3+m1/3*m2/4  m1/1*m2/5+m1/3*m2/6+m1/5 ]
	     = [ m1/2*m2/1+m1/4*m2/2  m1/2*m2/3+m1/4*m2/4  m1/2*m2/5+m1/4*m2/6+m1/6 ]
	       [ 0			0		     1			    ]


	Hence the resulting new list is:
	    [ m1/1*m2/1+m1/3*m2/2  m1/2*m2/1+m1/4*m2/2  m1/1*m2/3+m1/3*m2/4  m1/2*m2/3+m1/4*m2/4  m1/1*m2/5+m1/3*m2/6+m1/5 m1/2*m2/5+m1/4*m2/6+m1/6 ]

	      m1/1*m2/1+m1/3*m2/2  m1/2*m2/1+m1/4*m2/2  m1/1*m2/3+m1/3*m2/4  m1/2*m2/3+m1/4*m2/4  m1/1*m2/5+m1/3*m2/6+m1/5  m1/2*m2/5+m1/4*m2/6+m1/6
	}
	 m1 [block!] {Matrix one}
	 m2 [block!] {Matrix two}
    ][
	    reduce [
		m1/1 * m2/1 + ( m1/3 * m2/2 )
		m1/2 * m2/1 + ( m1/4 * m2/2 )
		m1/1 * m2/3 + ( m1/3 * m2/4 )
		m1/2 * m2/3 + ( m1/4 * m2/4 )
		m1/1 * m2/5 + ( m1/3 * m2/6 ) + m1/5
		m1/2 * m2/5 + ( m1/4 * m2/6 ) + m1/6
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
	pen
	fill-pen 
	    radial conic diamond linear diagonal cubic
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

    matrix-stack:   copy []
    current-matrix: copy [ 1 0 0 1 0 0]
    matrix-pop: does [
	also 
	    last matrix-stack
	    (
		remove back tail matrix-stack
		matrix-stack 
	    )
    ]
    matrix-push: func [ mtrx ][
	append/only matrix-stack copy/part mtrx 6
	matrix-stack
	mtrx
    ]
	

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
	arc: func [ p [pair!] {Center of arc}
		    R [number! pair!] {Radius of arc}
		    angle1	{start angle}
		    angle-span	{Span angle}
		    /closed {Use to make pie}
		    /part {Use to draw line to first point}
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
	    R: R * 1x1
	    parts: round/ceiling angle-span / 90
	    part-angle: angle-span / parts
	    d:  4 / 3 * tangent part-angle / 4
	    if  closed [ repend result/ps [ p 'm ] ]
	    repend result/ps [ p/x + (R/x * cosine angle1) p/y + (R/y * sine angle1) ]
	    append result/arrows to-pair reduce [ p/x + (R/x * cosine angle1) p/y + (R/y * sine angle1) ]
	    repend result/ps either any [ closed part ] [ 'l ][ 'm] 
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

    ; The standard Type1 fonts in pdf are:
    ;   Times-Roman, Helvetica, Courier, Symbol,
    ;   Times-Bold, Helvetica-Bold, Courier-Bold,
    ;   ZapfDingbats, Times-Italic, Helvetica-Oblique,
    ;   Courier-Oblique, Times-BoldItalic,
    ;   Helvetica-BoldOblique, Courier-BoldOblique

    current-font: make face/font [  ]
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


    shading-triangles-list: copy [ ]




    shading-axial-list: copy []
    register-shading-axial: func [ data /local name ][
	name: create-unique-name/pre data "SA-"
	unless find/skip shading-axial-list name 2 [
	    repend shading-axial-list [ name data ]
	]
	name
    ]

    shading-radial-list: copy []
    register-shading-radial: func [ data /local name ][
	name: create-unique-name/pre data "SR-"
	unless find/skip shading-radial-list name 2 [
	    repend shading-radial-list [ name data ]
	]
	name
    ]

    shading-pattern-list: copy []
    register-shading-pattern: func [ data /local name  ][
	name: create-unique-name/pre data "SP-"
	unless find/skip shading-pattern-list name 2 [
	    repend shading-pattern-list [ name data ]
	]
	name
    ]

    fun-interp-list: copy []
    register-fun-interp: func [ data /local name  ][
	name: create-unique-name/pre data "F-"
	unless find/skip fun-interp-list name 2 [
	    repend fun-interp-list [ name data ]
	]
	name
    ]


    has-alpha: func [ 
	{Returns none if there is a alpha value not zero}
	im [image!]
    ][
	find im/alpha charset [ #"^(01)" - #"^(ff)" ]
    ]

    draw-to-stream: func [
	cmd [ block!] {The draw commands to parse}
	face  [object!]  {The face from what to calculate original colours, and size}
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

	    current-pen: reduce [ any [ all[ face/color inverse-color face/color ] black ] ]
	    current-fill: none
	    current-line-width: 1
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
		'box set p1 pair! set p2 pair! set p number! 
		    (
			pth: draw-commands/arc
				    as-pair  p2/x - p  p1/y + p
				    p -90 90
			add-path pth/ps
			pth: draw-commands/arc/part
				    as-pair  p2/x - p  p2/y - p
				    p 0 90
			add-path pth/ps
			pth: draw-commands/arc/part
				    as-pair p1/x + p  p2/y - p
				    p 90 90
			add-path pth/ps
			pth: draw-commands/arc/part
				    as-pair p1/x + p  p1/y + p
				    p 180 90
			add-path pth/ps
			add-path 'h
			paint-path
		    )
		|
		'box set p1 pair! set p2 pair!
		    (
			add-path reduce [ p1 p2 - p1 're ] paint-path
		    )
	    ]
	    use [ stream p colors ][
		triangle: [
		    'triangle
		    copy p 3 pair!  copy colors 3 tuple! opt decimal!
		    (
			stream: reduce [
			    0 p/1 colors/1 
			    0 p/2 colors/2
			    0 p/3 colors/3
			]

			name: to-be-page/register-shading-triangle stream

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
	    use [ mtrx ][
		translate: [
		    'translate set p pair! (
			append strea mtrx: draw-commands/translate p/x p/y
			current-matrix: matrix-mult current-matrix    mtrx
		    )
		]
		scale: [
		    'scale copy p 2 number! (
			append strea mtrx: draw-commands/scale/xy/around p/1 p/2 0 0
			current-matrix: matrix-mult current-matrix    mtrx
		    )
		]
		rotate: [
		    'rotate set p number! (
			append strea mtrx: draw-commands/rotate 0 0 p
			current-matrix: matrix-mult current-matrix    mtrx
		    )
		]
		skew: [
		    'skew set p number! (
			append strea mtrx: draw-commands/skew p
			current-matrix: matrix-mult current-matrix    mtrx
		    )
		]
		matrix: [
		    'matrix set mtrx block! (
			current-matrix: matrix-mult current-matrix  mtrx
			append strea draw-commands/matrix mtrx
		    )
		]
	    ]
	    push: [
		'push set cmds block! 
		(
		    matrix-push current-matrix

		    repend strea [ 'q  ]

		    set-current-env
		    eval-patterns cmds

		    repend strea [ 'Q  ]

		    set-current-env
		    current-matrix: matrix-pop
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
			to-be-page/register-font current-font current-font/size 'Tf
			render-mode 'Tr
			pair/x pair/y 
			'Td
			string 'Tj
		    ]
		    if all [ render-mode = 0 current-fill ][ append strea current-fill ]
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
				warning "Cannot handle four point image transformation in draw dialect. Ignoring last point"
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

				    reference: to-refinement to-be-page/register-image img
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
	    use [
		fun shade
		grad-offset grad-start-rng grad-stop-rng grad-angle
		grad-scale-x grad-scale-y grad-colors
		grad-type
		pattern-name shade-name
	    ][
		fill-pen:  [
		    'fill-pen [
			[
			    set color tuple! (
				current-fill: reduce [  color  'rg ]
				append strea current-fill
			    ) 
			    | 
			    none! ( current-fill: none )
			]
			set grad-type [ 'radial | 'linear ] ; [| 'diamond | 'diagonal | 'cubic | 'conic ]
			set grad-offset pair!
			set grad-start-rng number!
			set grad-stop-rng  number!
			set grad-angle number!
			set grad-scale-x number!
			set grad-scale-y number!
			copy grad-colors some tuple!
			(
			    ; Make the shading at grad-offset
			    ; Set the shading marix to current-matrix and modify it with scale-xy
			    ; Set the current pen value to the shading name

				fun-name: register-fun-interp compose [
				    BitsPerSample: 8
				    one-input-dimension 3 (reduce [ join reduce [ color ]  grad-colors ] )
				]

				switch grad-type [
				    linear [
					shade-name: register-shading-axial compose [
					    Fuction: (to-refinement fun-name )
					    Domain: [ 0 1 ]
					    Extend: [ true true ]
					    from-to
						(grad-offset)
						(
						    (as-pair grad-stop-rng * cosine grad-angle
							   grad-stop-rng * sine grad-angle ) + grad-offset
						)
					]
				    ]
				    radial [
					    shade-name: register-shading-radial compose [
						Fuction: (to-refinement fun-name )
						Domain: [ 0 1 ]
						Extend [ true true ]
						from-to (
						    grad-offset
						    (as-pair grad-stop-rng * cosine grad-angle
						     grad-stop-rng * sine grad-angle ) + grad-offset
						)
					    ]
				    ]
				]

				pattern-name:  register-shading-pattern reduce [ 
				     current-matrix to-refinement shade-name
				]

				current-fill: compose [
				    /Pattern cs
				    (to-refinement pattern-name)  scn
				]
				append strea current-fill
			)
		    ]
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
	    arrow: [
		'arrow
		set current-arrow pair! 
	    ]

	    set-current-env: does [
		if all[ not empty? current-pen current-pen/1 ]  [ repend strea [ current-pen/1 'RG ] ]
		if current-fill [ append strea current-fill  ]
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

	patterns/eval-patterns cmd
	
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
	to-be-page [ object! ] {Object containing the objects for the pdf-documents and list of coming resources.}
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
	    reference: to-refinement to-be-page/register-image face/image
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
		    use[
			pos ext
			x-is y-is x-ps y-ps
			x-isize y-isize
			ref
			origo size
			edge-size
			delta
		    ] [
			pos: ext: none
			parse next p [ set pos pair! set ext pair! ]
			pos: any [ pos face/image/size / 2 ]
			edge-size: any [ all[ face/edge face/edge/size ] 0x0 ]
			ext: any [ ext face/size - face/image/size - (2 * edge-size )] 
			; Pos says which column and row that is to be expanded
			; ext is the number of cols and rows to repeat the column at pos

			origo: edge-size
			size: face/size - ( 2 * edge-size )

			delta: func [ x ][ y: copy [] x: next x forall x [ append y (first x) - first back x ] y ]

			x-is: reduce [ 0    	pos/x	 pos/x + 1  face/image/size/x ]
			y-is: reduce [ 0    	pos/y	 pos/y + 1  face/image/size/x ]

			x-ps: reduce [ x-is/1   x-is/2   x-is/3 + ext/x    x-is/4 + ext/x ]
			y-ps: reduce [ y-is/1   y-is/2   y-is/3 + ext/y    y-is/4 + ext/y ]

			x-isize: delta x-is
			y-isize: delta y-is
			x-psize: delta x-ps
			y-psize: delta y-ps
			
			repeat i 3 [
			    repeat j 3 [
				ref: to-refinement to-be-page/register-image copy/part
				    at face/image as-pair x-is/:i y-is/:j
				    as-pair x-isize/:i y-isize/:j
				repend strea [
				    'q
					x-psize/:i 0 0 negate y-psize/:j
					x-ps/:i + origo/x     y-ps/:j + y-psize/:j + origo/y 'cm 
					ref 'Do
				    'Q
				]
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
			matrix-push current-matrix
			append strea compose [
			    q
			    (
				also
				    mtrx: draw-commands/translate offset/x offset/y 
				    current-matrix: matrix-mult current-matrix mtrx
			    )
				(

				use [ draw-cmds ] [
				    draw-cmds: p
				    if word? draw-cmds [ draw-cmds: get draw-cmds ]
				    also
					draw-to-stream
					    draw-cmds
					    face
				]
			    )
			    Q    
			]   
			current-matrix: matrix-pop
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
			    append strea [ S Q ]
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
		BT (to-be-page/register-font current-font) (face/font/size) Tf
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
			use [ mtrx ][
			    append strea mtrx: draw-commands/translate pos/x pos/y
			    current-matrix: matrix-mult current-matrix mtrx
			]
			save-current-font: current-font
			append strea parse-face p to-be-page
			current-font: save-current-font
			append strea 'Q
			current-matrix: matrix-pop
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
	    font-list
	    images
	    image image-list
	    page
	    pages resource
	    doc
	    alpha
	    graph   alpha-name strea
    ][
	; Initialize

	to-be-page: make object! [
	    doc: pdf-lib/prepare-pdf
	    fonts: copy []
	    images: copy []
	    shades: copy []
	    shading-triangles: copy []

	    register-font: func [ name /local tmp ][
		if object? name [
		    either all [ string? name/name find name/name "/" ][
			name: copy/part tmp: next find/last name/name "/" any [ find/last tmp "." tail tmp ]
		    ][
			name: name/name
		    ]
		]
		append fonts name
		to-refinement name
	    ]

	    register-image: func [ image [image!]
		/local name
	    ] [
		name: create-unique-name image
		either find/skip images name 2 [
		    dbg: name 
		][
		    repend  images [name image]
		]
		name
	    ]
	    register-shading-triangle: func [ stream /local name ][
		name: create-unique-name/pre stream "T-"
		unless find/skip shading-triangles name 2 [
		    repend shading-triangles [ name stream ]
		]
		name
	    ]

	]
	doc: to-be-page/doc

	; Make content
	strea: copy []
	repend strea [
	    1 0 0 -1 0 face/size/y
	    'cm
	]

	append strea parse-face face to-be-page
	
	graph: doc/make-obj pdf-lib/base-stream! strea

	; Fonts
	fonts: none
	unless empty? to-be-page/fonts [
	    fonts: doc/make-obj pdf-lib/fonts-dict! []
	    
	    font-list:  unique to-be-page/fonts
	    font-replacement: copy []
	    foreach f font-list [ append font-replacement translate-fontname f ]
	    f-l: copy []
	    foreach f unique font-replacement [ repend f-l [ f doc/make-obj pdf-lib/font-dict! reduce [ f ]] ]
	    loop  length? font-list [
		fonts/add-obj  first+ font-list   select f-l first+ font-replacement
	    ]
	]

	; Handle images
	images: none
	unless empty? to-be-page/images [
	    images: doc/make-obj pdf-lib/XObjects-dict! [ ]
	    image-list: unique/skip  to-be-page/images 2
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
	]

	; Handle patterns
	shadings: doc/make-obj pdf-lib/shadings-dict!  []

	; Triangles
	foreach [name shade] to-be-page/shading-triangles [
	    shade-obj: doc/make-obj pdf-lib/shading-triangles-dict! shade
	    shadings/add-obj name shade-obj
	]

	; Register resources
	resource: doc/make-obj pdf-lib/resources-dict! [  ]
	if images [ resource/XObject: images ]
	if fonts [ resource/Font: fonts ]
	if shadings [ resource/Shading: shadings ]

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

REBOL [
    Title: {Graph - for plotting data in window}
    purpose: {A tool that displays a diagram and data is added one by one.
	      The diagram is scrolled to the left as new data  comes in}
    author: "Johan Ingvast"

    comment {
	How to organize data: 
	Now:
	    time-points and data-points in obj
	    time-points onedimensional
	    none is not handled
	Request
	    more than one time-point
	    more than one data-point (matched to a time-point series)
	    none in either time or data treated as a hole in line
	I'll start handlinng a none
    }
    loads: printf.r
]
libs: any  [ attempt [ libs ] %./]

prebol-used?: not (#do ['false])
either prebol-used? [
    #include %printf.r
    #do [
    ]
][
    foreach f [ %../printf.r ][ do :f ]
]

graph-lib: context [

font-wish-list: [
    Helvetica
    Arial
    Courier
    Times
    DejaVuSans
    FreeSans
    LiberationSans
]
font-search-dirs: [
    %/usr/share/fonts/
]
    

; Fix a bug in 'round
use [ body head ][
    body: second :round
    head: third :round
    body/2/4/2: 1.0
    round: func head body
]

to-seconds: func [ date-time /local tref secs days ] [
    tref: 1-Jan-1970 
    unless date?  date-time [ poke now/date 4 date-time ]
    days: date-time - tref
    secs: days * 24 + to-decimal date-time/time
]

; Make the font in face/font be the default font by using it once
fnt: make face/font [  ]
if system/version/4 == 4
[
   fnt/name: "/usr/share/fonts/gnu-free/FreeSans.ttf"
]
view/new layout [ box effect[draw [ font fnt text "test" font fnt text "jj" vectorial]]] unview

dbg: func [ v /local s err] [
    while [ "x" <> s: ask "dbg>" ][
	error? try [
	    if  error? err: try [
		do b: bind/copy
		    a: bind/copy to-block s 'system
		    v
	    ] [print disarm err  ]
	]
    ]
]

list-files:  func
[
    {Finds all files in the directory matching the parse expression
    Example:
	to list all rebol files do 
	list-files %./bla/ [ some [ thru ".r" "" ]]
	The last "" so that the block returns success, a bug not to without!!
    }
    dir [file!]
    expr [ block! none!]
    /reverse {Add file when pattern does not match}
    /pars p 
    /local ff rslt
]
[
    unless p [
	p: make object! [ reverse: false ]
    ]
    if reverse [ p/reverse: true ]

    rslt: copy []

    foreach x read dir
    [
	ff: join dir x
	either not dir? ff
	[
	    if xor to-logic p/reverse to-logic any [ not expr parse ff expr  ]
	    [
		append rslt ff
	    ]
	]
	[
	    append rslt list-files/pars ff expr p
	    
	]
    ]
    rslt
] 

render-test: func [
    /local
    f render
    rslt
] [
    rslt: copy[]
    render: func [
	fnt 
    ]
    [
	fn: make face/font [ name: fnt ]
	view/new layout [
	    b: box 200x200 effect[ draw
	    [
		font  fn
		pen black
		text 0x0 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x20 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x40 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x60 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x80 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x100 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x120 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x140 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
		text 0x160 "Johan Ingvast asdf ladskfjaslkjdf laksjdf "
	    ]]
	]
	tic
	loop 1000 [ show b ]
	dt: toc
	append/only rslt reduce [fnt dt ]
	wait 0.5
	unview
    ]

    rslt: list-files font-search-dirs/1 [ any [ thru ".ttf" "" ] ] 

    foreach x rslt [
	render x
    ]
    rslt
]

extremum-all: func [ 
    {Finds the minimum value of all the series}
    a [ series!] {A series of series}
    /max {Finds the maximum instead}
    /min {Default behavior, just for completeness}
    /local ret extr-fun
][
    extr-fun: either max [ :maximum-of ][
    ; There seem to be a bug in minimum-of which returns none if none is in vector
	func [ v [series!] ] [
	    replace v: copy v none 1e308
	    minimum-of v
	]
    ]
    ret: first extr-fun first+ a
    foreach x a [
	unless empty? x [
	    ret: first extr-fun reduce [ ret first extr-fun x ]
	]
    ]
    ret
]

expand: func [
    {Expands every series in x such as [ reduce x/1 reduce x/2 ... ] is returned
    the original series is untouched.}
    x [series!]
    /deep {Recursively expands the series on all levels}
    /local ret t
][
    ret: copy []
    forall x [
	if series? t: first x [
	    if all [ deep series? t ] [ t: expand/deep t ]
	]
	append ret t
    ]
    ret
]

svv/vid-styles/backdrop: make svv/vid-styles/face [ legends: [ backdrop ] ]
svv/vid-styles/blank-face: make svv/vid-styles/blank-face [ legends: [ blank-face ] ]

rgraph: make svv/vid-styles/box [
    type: 'rgraph
    size: 200x100
    color: ivory

    line-width: 2
    line-color: [ blue red green forest pink yellow sky orange cyan beige navy brick violet water wheat]
    grid: none
    tic-size: 4
    tic-color: black
    label-color: black
    max-num-labels: 10
    grid-color: [ none black ]
    grid-line-pattern: [ 3 3 ]
    box-border-width: 1

    min-y: max-y:  none
    min-x: max-x:  none
    limit-max-x: 0
    limit-min-x: -10
    limit-max-y: limit-min-y: 'auto
    drawcmd: []
    graph: x-labels: y-labels: none

    font: make fnt [ color: none ]
    para: make para [ origin: as-pair 0 1000000 ]

    screenresolution-factor: 100
    data-points: 
    time-points: none
    x-offset: does [ last time-points ]
    { Vad som ska visas i tid bestäms av:
	    time-points - raw data
	    x-offset - translation av tidsdata  x = time-points - x-offset
	    limit-min-x - vilket tidsvärde som ska vara längst till vänster i diagramet
	    limit-max-x - slutet på vad som ska visas
    }
    add-data: func [
	x [series!] {In order [time data1 data2 ... ] any of the datapoints may be a series which will be expanded}
	/local sorted-data-points
	length-time-points
    ] [
	x: reduce expand x
	append time-points x/1
	time-points: back select-time-data time-points x-offset + limit-min-x
	length-time-points: length? head time-points
	data-points: head data-points
	while [ not empty? x: next x ]
	[
	    if tail? data-points [ append/only data-points copy [] ] ; add a column
	    append/only first data-points first x
	    ; Set the index of data-points to same distance from last as time-points
	    data-points/1: skip tail data-points/1 (index? time-points) - length-time-points - 1
	    data-points: next data-points
	]
	forall data-points ; no more data to add, fill the rest with none
	[ 
	    append data-points/1 none
	    data-points/1: skip tail data-points/1 (index? time-points) - length-time-points
	]

	data-points: head data-points
    ]

    newdata: func [/local x ] [  
	; sine last now/precise
	x: [0 0]
	x/1: x/1 + 1
	x/2: x/2 + ( (random 10 ) - 6 / 6)
	(sine x/1 * 10 ) + (10 - ( random 21 ) / 50 ) + x/2
    ]
    add-newdata: func [ /local y] [
	    y: newdata
	    if y [
		add-data reduce [ to-seconds now/precise y ]
	    ]
    ]

    select-time-data: func [
	{Returns the sorted block at the point larger or equal than lowest-time}
	data lowest-time
    ] [
	while [ all [ not head? data (first data) > lowest-time  ] ] [ data: skip data -10 ]
	while [ all [ not tail? data (first data) < lowest-time ] ] [ data: next data ]
	data
    ]

    text-size: func [ lbl /x /y /local sz ] [
	text: lbl
	sz: size-text self
	if x [ return sz/x ]
	if y [ return sz/y ]
	sz
    ]
    effect: []
    to-screen-coord: to-draw-coord: none
    low-x: high-x: none
    low-y: high-y: none


    auto-tics-x: auto-tics-y: none
    update-dia: func [
	/force {Execute all even if the axes are the same}
	/local
	    xd yd
	    sr-x sr-y
	    l-x-offset
	    x y
	    line-given
	    strings-x strings-y
	    x-scale y-scale
	    tics-y
    ] [
	either empty? time-points [
	    min-x: -1
	    max-x: 0
	][
	    min-x: ( any minimum-of time-points ) - x-offset
	    max-x: ( any maximum-of time-points ) - x-offset
	]

	if number? limit-min-x [ min-x: limit-min-x ]
	if number? limit-max-x [ max-x: limit-max-x ]

	set [ auto-tics-x strings-x ] get-tics/strings min-x max-x
	if none? strings-x [ strings-x: [] ]

	switch/default limit-min-x [
	    auto [
		low-x: either min-x != max-x [
		     first auto-tics-x
		] [
		    either min-x = 0 [ -1 ] 
		    [ either min-x < 0 [ 1.2 * min-x][ 0.8 * min-x ] ]
		]
	    ]
	    exact [ low-x: min-x ]
	][ low-x: limit-min-x ]

	switch/default limit-max-x [
	    auto [
		high-x: either min-x != max-x [
		     last auto-tics-x
		] [
		    either max-x = 0 [ 1 ] 
		    [ either max-x < 0 [ 0.8 * min-x][ 1.2 * min-x ] ]
		]
	    ]
	    exact [ high-x: max-x ]
	][ high-x: limit-max-x ]

	set [ auto-tics-x strings-x ] get-tics/strings low-x high-x
	if empty? auto-tics-x [
	    low-x: first auto-tics-x
	    high-x: last auto-tics-x
	]

	xd: high-x - low-x

	; y - 
	either any [ empty? data-points empty? data-points/1 ] [
	    min-y: 0
	    max-y: 1
	][
	min-y: extremum-all data-points
	max-y: extremum-all/max data-points
	]


	if number? limit-min-y [ min-y: limit-min-y ]
	if number? limit-max-y [ max-y: limit-max-y ]

	if all [ number? min-y number? max-y ] [

	    set [ auto-tics-y strings-y ] get-tics/strings min-y max-y
	    if none? strings-y [ strings-y: [] ]

	    switch/default limit-min-y [
		auto [
		    low-y: either min-y != max-y [
			 first auto-tics-y
		    ] [
			either min-y = 0 [ -1 ] 
			[ either min-y < 0 [ 1.2 * min-y][ 0.8 * min-y ] ]
		    ]
		]
		exact [ low-y: min-y ]
	    ][ low-y: limit-min-y ]

	    switch/default limit-max-y [
		auto [
		    high-y: either min-y != max-y [
			 last auto-tics-y
		    ] [
			either max-y = 0 [ 1 ] 
			[ either max-y < 0 [ 0.8 * min-y][ 1.2 * min-y ] ]
		    ]
		]
		exact [ high-y: max-y ]
	    ][ high-y: limit-max-y ]

	    set [ auto-tics-y strings-y ] get-tics/strings low-y high-y
	    ;if empty? auto-tics-y [
		low-y: first auto-tics-y
		high-y: last auto-tics-y
	    ;]

	    yd: high-y - low-y

	    ; -------------------
	   ; repend clear drawcmd [ 'pen black 'line-pattern none 'box 0x0 graph/size - 1 ]
	    clear drawcmd

	    if  xd != 0  [

		sr-x: screenresolution-factor * ( graph-precise-size/x - 1 )
		sr-y: screenresolution-factor * ( graph-precise-size/y - 1 )
		; Scale the data so that it fits into the screen 
		x-scale: sr-x / xd
		y-scale: sr-y / yd
		l-x-offset: x-offset
		to-screen-coord: func [x y /local ] [
		    as-pair ( x  - low-x * x-scale) sr-y - ( y - low-y * y-scale )
		]
		to-draw-coord: func [x y] [
		    as-pair x - low-x / xd * graph-precise-size/x   graph-precise-size/y * ( 1 - (y - low-y / yd ))
		]
		
		tics-y: auto-tics-y

		either force [
		    x-labels/draw-tics/strings/force   auto-tics-x strings-x
		    y-labels/draw-tics/strings/force tics-y strings-y
		] [
		    x-labels/draw-tics/strings  auto-tics-x strings-x
		    y-labels/draw-tics/strings tics-y strings-y
		]

		repend drawcmd [ 
		    'translate graph-border-margin
		    'scale 1 / screenresolution-factor 1 / screenresolution-factor
		]
		;repend drawcmd [ 'pen black 'line-pattern none 'box 0x0 graph/size - 1 * screenresolution-factor ]
		repend drawcmd [ 'pen black 'line-pattern none
				 'line-width box-border-width * screenresolution-factor
				 'box to-screen-coord low-x low-y to-screen-coord high-x high-y  ]
		repend drawcmd [ 'line-width line-width * screenresolution-factor ]
		foreach lne data-points [
		    line-given: false
			x: skip time-points (length? time-points) - length? lne
		    foreach y lne [
			either number? y [ 
			    unless line-given [
				repend drawcmd [ 'pen first line-color ]
				append drawcmd [ line ]
				line-given: true
			    ]
			    repend drawcmd [ to-screen-coord (first x) - l-x-offset y ]
			] [
			    line-given: false
			]

			x: next x
		    ]
		    first+ line-color
		    if tail? line-color [ line-color: head line-color ]
		]
		line-color: head line-color
		show self
	    ]
	]
    ]
    fix-float: func [ s /local p][
	parse s [ thru "e" opt [ p: "+" (remove p) :p | "-"] any [ p: "0" (remove p) :p ] ]
	s
    ]

    get-tics: func [ {
	    Returns the ticks suitaable for data in the range [x1,x2]
    If also /strings is set it will return formatted labels as well.
    The labels are:
	x1	    x2		delta-scale tic-scale	label
	0	    1		0.1	    0.5		0.5
	0	    9		1	    5		5
	10	    11		0.1	    0.5		10.5
	10.1	    11.1	0.1	    0.5		10.5
	-10	    10		1	    5		5
	1e5	    3e5		1e4	    5e4		150e3
	1e10	    2e10	1e9	    5e9		1.5e10
	
    let l: log-10 delta-scale
    s: log-10 max abs x1 abs x2
    if s >= 5 then print with exponent
    
    för att skriva gör till ett heltal:
     round n / delta-scale
    om abs s > 5 sätt decimalen efter första siffran och använd exp
    }
	x1 
	x2
	;/method mthd
	/within {If all returned tics should be within x1 and x2}
	/strings {Returns [tics tics-formatted]}
	/local
	    delta delta-scale
	    tics tic-scale
	    sign
	    scale
    ] [
	if any [ none? x1 none? x2 ] [ return reduce [ none none ] ]
	delta: x2 - x1
	if delta = 0 [ return [] ]
	if delta < 0 [ set [ x1 x2 ] reduce [x2 x1 ]  delta: negate delta ]

	; otherwise use the normal tics
	delta-scale: 10 ** round/floor log-10 delta / max-num-labels
	foreach t [ 1 2 5 10 20 50] [
	    tic-scale: t * delta-scale
	    if  delta / tic-scale <= (max-num-labels - 1) [ 
		if t >= 10 [ delta-scale: delta-scale * 10 ]
		break
	    ]
	]

	tics: copy []
	either within [
	    append tics round/to/ceiling x1 tic-scale
	][
	    append tics round/to/floor x1 tic-scale
	]
	until [ 
	    append tics ( last tics ) + tic-scale
	    ( last tics ) >= x2
	]
	unless strings [ return tics ]

	scale: log-10 max abs x1 abs x2

	reduce [ tics map-each x tics [ fix-float sprintf [ "%.4g" x * 1.0 ]  ] ]
    ]
    edge: make face/edge [ size: 0x0 ]
    graph-space-ll: graph-space-ur: 0x0

    graph-precise-offst: graph-precise-size: none
    graph-border-margin: 4x4 ; The room outside the graph itself that the graph pane occupies.

    update-size: func [][
	graph-precise-offset: as-pair graph-space-ll/x graph-space-ur/y 
	graph-precise-size: size - graph-space-ur - graph-space-ll
		    - (2 * any[ all [edge edge/size] 0x0])

	graph/offset: graph-precise-offset - graph-border-margin
	graph/size:  graph-precise-size + ( 2 * graph-border-margin )

	x-labels/offset: as-pair 0 graph-space-ur/y
	x-labels/size: graph-precise-size + graph-space-ll + as-pair graph-space-ur/x 0
	x-labels/effect/draw/translate:  graph-precise-offset - x-labels/offset

	y-labels/offset: 0x0
	y-labels/size: (as-pair graph-space-ll/x + graph-precise-size/x size/y) - any [ all [ edge edge/size ] 0x0 ]
	y-labels/effect/draw/translate: graph-precise-offset - y-labels/offset 
	
    ]

    use [ p ][
	p: self
	graph: make face [
	    color: none
	    edge: none
	    effect: [ draw drawcmd]
	]
	x-labels: make face [
	    color: none
	    edge: none

	    line-cmd: []
	    text-cmd: []
	    effect: compose/deep [ draw [ translate ( graph/offset - offset ) push text-cmd push line-cmd ] ]
	    text-size: func [ lbl /x /y /local sz ] [
		text: lbl
		sz: size-text self
		if x [ return sz/x ]
		if y [ return sz/y ]
		sz
	    ]
	    dir-x: true  
	    old-draw-signature: none
	    draw-tics: func [ 
		tics [ block! ] { The tics to draw }
		/strings label-strings [block!] {A block of strings to be printed at tics}
		/force {Update even if axis has not changed }
		/local
		lbl-size pos lbl tic-val tic-vector grid-vector
		draw-signature
	    ][
		; Do not update if it did  not change
		old-draw-signature: []
		draw-signature: reduce [ tics strings label-strings size ]
		if all [ not force old-draw-signature == draw-signature ] [ 
		    exit
		]
		insert clear old-draw-signature draw-signature

		clear line-cmd
		clear text-cmd
		append text-cmd   [ pen none fill-pen parent-face/label-color font self/font ]

		either dir-x [
		    tic-vector: as-pair 0 parent-face/tic-size 
		    grid-vector:  0x1 * (parent-face/graph-precise-size  - 1)
		][
		    tic-vector: as-pair parent-face/tic-size  0
		    grid-vector:  1x0 * (parent-face/graph-precise-size - 1 )
		]

		tic-val: reduce [ 'line-width screenresolution-factor ]
		repend  tic-val [
		    'pen tic-color 'line 0x0 tic-vector * screenresolution-factor
		    'line
		    grid-vector - tic-vector * screenresolution-factor
		    grid-vector * screenresolution-factor
		]
		if all [ parent-face/grid find parent-face/grid either dir-x ['x] ['y] ]  [
		    append tic-val compose [
			line-pattern (map-each x parent-face/grid-line-pattern [ x * screenresolution-factor ] )
			pen (parent-face/grid-color)
			line 0x0 (grid-vector * screenresolution-factor)
			line-pattern none 
		    ]
		]

		repend line-cmd   [ 'scale 1 / screenresolution-factor 1 / screenresolution-factor ]
		foreach t tics [
		    pos: either dir-x [
			(parent-face/to-screen-coord t t) * 1x0
		    ][
			(parent-face/to-screen-coord t t) * 0x1 
		    ]
		    lbl-size: text-size lbl: either strings [ first+ label-strings ] [ to-string t]

		    repend line-cmd [ 'push reduce [ 'translate pos  'push tic-val ]]

		    pos: pos /  screenresolution-factor
		    repend text-cmd [
			'text  'vectorial
			pos +
			either dir-x [
			    as-pair (lbl-size/x / -2) size/y - lbl-size/y - 1
			][
			    as-pair negate lbl-size/x + 1   negate lbl-size/y / 2
			]
			lbl
		    ]
		]
	    ]
	]

	y-labels: make x-labels [
	    dir-x: false
	    offset: 0x0
	    effect: compose/deep [ draw [ translate ( graph/offset - offset ) push text-cmd push line-cmd ] ]
	]
    ]

    append init [ 
	use [ label-size parent ][
	    parent: self
	    unless block? time-points [time-points: copy []]
	    unless block? data-points [data-points: copy []]
	    label-size: text-size "-00000"
	    graph-space-ur: 5x5	 ; top right
	    graph-space-ll: label-size + as-pair tic-size tic-size 
	    pane: reduce [
		graph: make graph [
		    effect: [ draw drawcmd]
		    parent-face: parent
		]
		x-labels: make x-labels [
		    para: parent/para
		    font: make parent/font []
		    effect: compose/deep [ draw [ translate ( graph/offset - offset ) push text-cmd push line-cmd ] ]
		    parent-face: parent
		]
		y-labels: make y-labels [
		    para: parent/para
		    size: (as-pair parent/graph-space-ll/x + parent/graph/size/x parent/size/y) - parent/edge/size
		    font: make parent/font []
		    effect: compose/deep [ draw [ translate ( graph/offset - offset ) push text-cmd push line-cmd ] ]
		    parent-face: parent
		]
	    ]
	    update-size
	    feel: make feel [
		engage: func [ f action event ][
		    action
		    switch action [
			time [
			    add-newdata 
			    update-dia 
		    ]
			down [ f/action f action ]
		    ]
		]
	    ]
	]
    ]
    words: reduce [
	'grid func [new args][ new/grid: to-string second args next args ]
	'time func [new args] [ new/limit-min-x: negate second args next args ]
	'data func [new args /local ] [
	    args: next args
	    dbg-data: args
	    either function? first args 
		[ new/newdata: first args ]
		[ new/newdata: does first args ]
	    args
	]
	'limits func [ new args][
	    ; set the limits just like they are done in matlab
	    ; with [ min-x max-x min-y max-y ]
	    ; any value can be set to auto
	    ; missing values or none is set to auto
	    new/limit-min-x: any [ args/2/1 'auto ]
	    new/limit-max-x: any [ args/2/2 'auto ]
	    new/limit-min-y: any [ args/2/3 'auto ]
	    new/limit-max-y: any [ args/2/4 'auto ]
	    next args
	]
	'tag func [ new args ] [
	]
    ]
]


graph: make rgraph [
    type: 'graph
    x-offset: 0
    limit-min-x: limit-max-x: 'auto
    append init [
	feel: make svv/vid-styles/box/feel []
	update-dia
    ]
    remove/part find words 'time 2
    words/data: func [ new args /local cnt ] [
	either 3 = length? args [
	    new/time-points: second args
	    args: next args
	][
	    new/time-points: none
	]

	new/data-points: any [ new/data-points copy []]
	either block? first reduce second args [
	    repend new/data-points second args
	] [
	    append/only new/data-points second args
	]
	args: next args

	unless new/time-points [
	    cnt: 0
	    new/time-points: copy []
	    foreach _ first new/data-points [ append new/time-points cnt: cnt + 1 ]
	]
	args
    ]
]


add-style: func [ style-name style-object ] [
    remove/part find svv/vid-styles style-name 2
    repend svv/vid-styles [ style-name style-object]
]

add-style 'rgraph rgraph
add-style 'graph graph


list-fonts: func[ /local f file list fnt-list lay-cmd pos ] [
    base: %/usr/share/fonts
    f: func [ d ] [
	list: remove-each x read dirize d  [ #"." = first x ]
	fnt-list: copy []
	foreach x list [ 
	    append file: dirize copy d x
	    either 'directory = get in info? file 'type [
		f file
	    ] [
		if parse to-string file [ thru ".ttf" ] [
		    print file
		    append fnt-list make fnt [ name: to-string file ]
		]
	    ]
	]
	unless empty? fnt-list [
	    print "-----------------------------------------------------------"
	    lay-cmd: copy/deep [h2 to-string d box white 300x400 effect[draw[scale 2 2 pen none fill-pen black]] #"w" [unview]]
	    pos: 20x0
	    map-each x fnt-list  [
		repend lay-cmd/effect/draw [ 'font x 'text 'vectorial pos to-string first+ list ]
		pos: pos + as-pair 0 x/size
	    ]
	    view layout lay-cmd
	]
    ]
    f base
]

test-rgraph: func[ /local t s r r2 x l1] [
    s: 0
    view layout [
	r: rgraph 500x300 0:0:0.1
	    data [ t: third now/time/precise  reduce [
		sine t * 17
		2 * cosine t * 300
		3 * sine t * 20 
		( s: s - 49.5 + (random 100) s)
	    ] ]
	    time 4
	    grid "xy"
	r2: rgraph 500x300 0:0:0.05
	    data [ t: third now/time/precise reduce [
		( x: sine t * 17 either x > 0 [ x][none] )
		2 * cosine t * 300
		3 * sine t * 20 
		( l1/text: s show l1 s)
	    ] ]
	    limits [ auto 0.1 -5 5]
	    time 20
	    grid "xy"
	l1: text 200
	key #"q" [unview]
    ]
]

test-graph: func [ /local t y1 y2 g1 g2]
[
    t: copy [] repeat i 360 [ append t i ]
    y1: map-each x t [ sine x ]
    y2: map-each x t [ 4 * sine x * 30 ]
    view layout [
	g1: graph 500x300 
	    data  t y1 
	    grid "xy"
	g2: graph 500x300 
	    data  t [ y2 y1 ] 
	    grid "xy"
	key #"q" [unview]
    ]
]

test: func [ /local t  y1 y2 g1 g2]
[
    t: copy [] repeat i 361 [ append t i - 1 ]
    y1: map-each x t [ sine x ]
    y2: map-each x t [ 4 * sine x * 30 ]
    view layout [
	g1: graph 500x300
	    data  t y1 
	g2: graph 500x300 
	    data  t [ y2 y1 ] 
	    grid "xy"
	key #"q" [unview]
	button "+" #"+" [ forall y1 [ change y1 1 + first y1 ] g2/update-dia g1/update-dia show [g1 g2] ]
	button "-" #"-" [ forall y1 [ change y1 -1 + first y1 ] g2/update-dia g1/update-dia show [g1 g2] ]
    ]
]

replace-pane: func [
    old [object!] {The existing one to be replaced}
    new [block! object!] {A view-description or a face object}
    /keep-size  {Copy the size of the old into the new}
][
    if block? new [
	new: 
    ] 
    replace old/parent-face/pane old new
]

]


; vim: sw=4 sts=4 ai cindent

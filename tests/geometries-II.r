REBOL [
]

lib: do %../face-to-pdf-lib.r

;fnt: make face/font [ name: "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf" ]
fnt: make face/font []
;/usr/share/fonts/truetype/liberation

tt: func [ d ][
    view layout [ box sky 500x350 effect[ draw[ push d ]] key #"q" [unview]]
]


dr1: [ pen forest font fnt text 0x0 vectorial "Circle" circle 75x75 50  ]
dr2: [ font fnt text 0x0 vectorial "Arc-open"
	arc 75x45 100x100 30 100
	fill-pen crimson line-width 3
	arc 80x80 70x40 30 100
	line 70x45 80x45 line 75x40 75x50 ]
dr3: [ font fnt text 0x0 vectorial "Arc-closed" arc 75x45 100x100 30 100  closed line 70x45 80x45 line 75x40 75x50 ]

half-crimson: crimson + 0.0.0.128
dr4: [ font fnt text 0x0 vectorial "Arc-open"
	pen coal
	arc 75x75 100x100 122 300
	fill-pen half-crimson line-width 1
	line 70x75 80x75 line 75x70 75x80 ]
dr5: [ font fnt text 0x0 vectorial "Arc-closed" arc 75x75 100x100 30 300  closed line 70x75 80x75 line 75x70 75x80 ]

dr6: [
    font fnt text 0x0 vectorial "Arrows"
    line 10x15 10x45 line 130x15 130x45
    line-width 2
    arrow 1x2
    line 10x20 130x20
    line-width 4
    arrow 1x1
    line 10x30 130x30
    arrow 1x1
    line 10x40 130x40
    circle 75x70 50 30
    ellipse 75x70 50x30
    arc  75x70 25x15 100 200
    arrow 0x0
]
dr7: [
    font fnt text 0x0 vectorial "Spline"
    fill-pen none
    line 15x15 100x15 100x100 15x100 15x75
    pen red
    spline 10 15x15 100x15 100x100 15x100 15x75 50x75 50x90
]
dr8: [
    font fnt text vectorial "Triangle"
    triangle 12x12 120x80 80x130 green red blue
    pen none
    triangle 80x10 30x22 100x30 blue white magenta
    translate 20x0
    triangle 80x10 30x22 100x30 blue white magenta
]
puppy: load %images/puppy.jpg
cat-eye: load %images/cat-eye.jpg

dr9: [
    font fnt text vectorial "Image" 
    image 15x15 cat-eye ;puppy
]
dr10: [
    font fnt text vectorial "Image" 
    ;image 80x5 puppy
    image 80x5 140x50 20x140 5x20 cat-eye
    scale 0.5 0.5
    image puppy 140x50 20x140 5x20 
]

dr11: [
    pen none fill-pen black
    font fnt text 0x0 vectorial "Curve and matrix"
    matrix [ 1 0.1 -0.2 1.4 10 10 ]
    pen green
    fill-pen none
    line-width 3
    line 15x15 100x15 100x100 15x100 
    curve 15x15 100x15 100x100 15x100 
    line-width 1
    pen red fill-pen sky
    curve 25x25 90x25 90x90 25x90 
]

dr12: [
    font fnt text vectorial "Clip Funny in Rebol" 
    fill-pen none pen green line-width 5
    box 20x20 140x140
    line-width 1
    box 80x80 160x160
    clip 80x80 160x160
    fill-pen blue pen red line-width 2
    box 20x20 140x140

]

dr13: [
    font fnt text vectorial "Line caps"
    line-width 6 pen red
    line 10x20 10x70
    line-cap butt
    line 30x20 30x70
    line-cap round
    line 50x20 50x70
    line-cap square
    line 70x20 70x70
    line-cap butt

    translate 80x0
    pen none fill-pen black
    font fnt text vectorial "Line joins"
    fill-pen none
    line-width 10 pen red 
    translate 0x20
    spline 1 10x0 30x30 50x0

    line-join miter
    translate 0x20
    spline 1 10x0 30x30 50x0

    line-join miter-bevel
    translate 0x20
    spline 1 10x0 30x30 50x0

    translate 0x20
    line-join round
    spline 1 10x0 30x30 50x0

    line-join bevel
    translate 0x20
    spline 1 10x0 30x30 50x0

]
dr14: [
    pen none fill-pen black
    font fnt text vectorial "Miter-bevel"
    fill-pen none
    line-join miter-bevel
    line-width 3 pen red 
    spline 1 50x140 75x120 100x140
    spline 1 50x140 75x100 100x140
    spline 1 50x140 75x80 100x140
    spline 1 50x140 75x60 100x140
    spline 1 50x140 75x40 100x140
    spline 1 50x140 75x20 100x140
]
half-red: 255.0.0.128
    
dr15: [
    pen none fill-pen black
    font fnt text vectorial "Line patterns"
    line-pattern 10  20  ; 20   with next argument it coredumps
    pen blue  green
    line 10x20 140x20 140x30
    spline 1 10x30 140x30
    fill-pen snow
    pen red blue
    box 10x40 140x50
    line-pattern none
    line-join round 
    pen black 
    polygon 10x60 70x90 70x60 60x70
    line-pattern 5 10
    pen none brown
    circle 110x80 25

    line-pattern 10  20  ; 20   with next argument it coredumps
    fill-pen snow
    pen half-red blue
    box 10x120 140x140
]
dr16: [
    pen none fill-pen black line-pattern none
    font fnt text vectorial "More arrows"
    pen aqua
    arrow 1x1
    spline 15 10x90 30x110 75x110 90x120 140x80
    pen green
    curve 10x140 30x100 110x150 140x120
    arrow 0x0
]
dr17: [
    pen none fill-pen black line-pattern none
    font fnt text vectorial "box"
    fill-pen none pen beige line-width 1
    box 10x10 100x40 10
]
dr18: [
    pen none fill-pen black line-pattern none
    font fnt text vectorial "Gradients"
    ; fill-pen color type offset start-rng end-rng angle scalex scaley colors ...
    fill-pen        radial 0x0 0         100       10    1      2      blue green red yellow  
    box 0x15 150x50 box 70x0 100x70
    fill-pen blue   linear 10x65 0         50       45    1      1      green red yellow  
    box 0x50 150x90 
    fill-pen blue   linear 10x115 0         50       45    10      10      green red yellow  
    box 0x90 150x130 
]
    

drs: copy []  repeat i 18 [ append drs to-word rejoin [ "dr" i ]]

replace drs 'dr12 []


view-it: func [ drs
    /local
	cols dr idr 
] [
    cols: 6
    dr: copy []
    forall drs [
	idr: copy []
	repeat i cols [
	    unless drs/:i [ break ]
	    repend idr [
		'push drs/:i 'translate 150x0
	    ]
	]
	append dr 'push
	append/only dr idr
	append dr [
	    translate 0x150 
	]

	drs: skip drs cols - 1
    ] 
    view/new/offset foenster: layout [
	text "test av geometrier"
	f: box yellow / 1.5 900x450 effect [
	    draw dr
	    grid 150x150 0x0 2 3 black
	]
	key #"q" [quit]
    ] 0x0

]

if error? err: try [ 
    view-it drs
    write/binary %geometries-II.pdf lib/face-to-pdf f
    none
] [
    trace off
    err: disarm err
    ? err
    make error! {Error somewhere}
]
print "hit escape to get prompt"


wait none


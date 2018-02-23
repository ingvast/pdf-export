REBOL [
]

lib: do %../face-to-pdf-lib.r

fnt: make face/font [ name: "/usr/share/fonts/gnu-free/FreeSans.ttf" ]


dr1: [ font fnt text 0x0 vectorial "Circle" circle 75x75 50  ]
dr2: [ font fnt text 0x0 vectorial "Arc-open"
	arc 75x45 100x100 30 100
	fill-pen crimson line-width 3
	arc 80x80 70x40 30 100
	line 70x45 80x45 line 75x40 75x50 ]
dr3: [ font fnt text 0x0 vectorial "Arc-closed" arc 75x45 100x100 30 100  closed line 70x45 80x45 line 75x40 75x50 ]
dr4: [ font fnt text 0x0 vectorial "Arc-open"
	arc 75x75 100x100 122 300
	fill-pen crimson line-width 1
	line 70x75 80x75 line 75x70 75x80 ]
dr5: [ font fnt text 0x0 vectorial "Arc-closed" arc 75x75 100x100 30 300  closed line 70x75 80x75 line 75x70 75x80 ]

dr6: [
    font fnt text 0x0 vectorial "Arrows"
    line 10x15 10x45 line 130x15 130x45
    line-width 2
    arrow 1x2
    line 10x20 130x20
    arrow 1x1
    line 10x30 130x30
    arrow 2x2
    line 10x40 130x40
    circle 75x70 50 30
    ellipse 75x70 50x30
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
]
puppy: load %/usr/share/pixmaps/faces/puppy.jpg
cat-eye: load %/usr/share/pixmaps/faces/cat-eye.jpg

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
    font fnt text 0x0 vectorial "Curve"
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
    

dr: [
    push [ 
	pen black fill-pen none line-width 1 
	push dr1 translate 150x0 
	push dr2 translate 150x0 
	push dr3 translate 150x0 
	push dr4 translate 150x0 
	push dr5 translate 150x0
	push dr6 translate 150x0 
    ]
    translate 0x150
    push[
	push dr7 translate 150x0 
	push dr8 translate 150x0
	push dr9 translate 150x0
	push dr10 translate 150x0
	push dr11 translate 150x0
	;push dr12 translate 150x0
    ]
    translate 0x150
    push[
	push dr13 translate 150x0
	push dr14 translate 150x0
    ]
]

;dr: [ pen black box 5x10 200x100 scale 0.9 1.1 line 5x10 200x100 ]


view/new/offset layout [ text "test av geometrier"
    f: box yellow * 1.5 900x450 effect [
	draw dr
	grid 150x150 0x0 2 3 black
    ]
    key #"q" [quit]
] 0x0

write %geometries-II.pdf lib/face-to-pdf f


wait none


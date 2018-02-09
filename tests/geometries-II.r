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
    font fnt text vectorial "" 
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
    ]
]

;dr: [ pen black box 5x10 200x100 scale 0.9 1.1 line 5x10 200x100 ]


view/new/offset layout [ text "test av geometrier"
    f: box yellow * 1.5 900x400 effect [ grid 150x150 0x0 2 3 black draw dr ]
    key #"q" [quit]
] 0x0

write %geometries-II.pdf lib/face-to-pdf f


wait none


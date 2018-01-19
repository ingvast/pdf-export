REBOL [
]

lib: do %../face-to-pdf-lib.r

fnt: make face/font [ name: "/usr/share/fonts/gnu-free/FreeSans.ttf" ]


dr1: [ font fnt text 50x10 vectorial "Rotated" box 100x60 200x160 rotate 30 100x100 box 100x60 200x160 ]
dr2: [ font fnt text 50x10 vectorial "Matrix" box 100x60 200x160  matrix [ 1 0 0.1 0.9 0 30 ] box 100x60 200x160 ]
dr3: [ font fnt text 50x10 vectorial "Scale" box 100x60 200x160  matrix [ 0.9 0 0 0.9 0 0 ] box 100x60 200x160 ]
dr4: [ font fnt box 50x10 100x72 text 50x10 vectorial "Text test" ]

dr5: [ font fnt text 50x10 vectorial "Skewed" box 100x60 200x130 skew -50 box 100x60 200x130 ]

dr6: [ font fnt text 20x0 vectorial "Invert matrix" 
	line 50x50 50x150 rotate 30
	line 50x50 50x150 
	]

dr: [ pen black fill-pen none line-width 1 
    push dr1 translate 200x0 
    push dr2 translate 200x0 
    push dr3 translate 200x0
    push dr4 translate 0x100
    push dr5
    reset-matrix translate 0x200
    push dr6
]

;dr: [ pen black box 5x10 200x100 scale 0.9 1.1 line 5x10 200x100 ]


view/new  layout [ text "test av geometrier"
    f: box yellow * 1.5 900x400 effect [ draw dr ]
    key #"q" [quit]
] 

write %geometries.pdf lib/face-to-pdf f

wait none


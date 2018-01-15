REBOL [
]

lib: do %../face-to-pdf-lib.r

long-string: {lorem lipsum j jasdj ljk sadlkj lkdflksdlkjsdfj sdlj sdlkj fjsdjl
REBOL [
]

lib: do %../face-to-pdf-lib.r

fnt: make face/font [ name: "/usr/share/fonts/gnu-free/FreeSans.ttf" ]


dr1: [ font fnt text 50x50 vectorial "Rotated" box 100x100 200x200 rotate 30 100x100 box 100x100 200x200 ]
dr2: [ font fnt text 50x50 vectorial "Matrix" box 100x100 200x200  matrix [ 1 0 0.1 0.9 0 30 ] box 100x100 200x200 ]
dr3: [ font fnt text 50x50 vectorial "Scale" box 100x100 200x200  matrix [ 0.9 0 0 0.9 0 0 ] box 100x100 200x200 ]
dr4: [ font fnt box 50x50 100x72 text 50x50 vectorial "Text test" ]

dr: [ pen black fill-pen green line-width 1 
    push dr1 translate 200x0 
    push dr2 translate 200x0 
    push dr3 translate 200x0
    push dr4
]
}

;dr: [ pen black box 5x10 200x100 scale 0.9 1.1 line 5x10 200x100 ]



view/new f: layout [
    area 400x400 long-string
    across
    button "Quit" #"q" [quit]
    field "Tjossan hejsan"
]

write %objects.pdf lib/face-to-pdf f

wait none




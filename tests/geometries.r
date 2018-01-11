REBOL [
]

lib: do %../face-to-pdf-lib.r


dr1: [ text 50x50 "Rotation" box 100x100 200x200 rotate 30 100x100 box 100x100 200x200 ]
dr2: [ text 50x50 "Matrix" box 100x100 200x200 matrix [1 0 0 1 0.9 0.9]  box 100x100 200x200 ]

dr: [ pen black push dr1 translate 200x0 push dr2 ]


view/new  layout [ f: box 900x400 effect [ draw dr ] ] 

write %geometries.pdf lib/face-to-pdf f

wait 5


REBOL [
]

;lib-dir: join dirize to-rebol-file get-env "BIOSERVO" %tools/rebol/libs
unview/all

do %graph.r

x: []  repeat i 360 [ append x i ]
y: map-each i x [ sine i ]

view/new  layout  [
     panel [
	h1 "Testing exporting graph to pdf" 
	g: graph 400x600 grid 'xy data x y 
    ]
    key #"q" [unview]
]

;do lib-dir/dbg-tools.r

do/args %../face-to-pdf-lib.r 'face-to-pdf 

;show-changed-vars

write/binary %diagtest.pdf face-to-pdf g

halt

;show-changed-vars

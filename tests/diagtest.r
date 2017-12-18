REBOL [
]

lib-dir: join dirize to-rebol-file get-env "BIOSERVO" %tools/rebol/libs

do lib-dir/dbg-tools.r
do %graph.r

show-changed-vars


do/args %../face-to-pdf-lib.r 'face-to-pdf 

show-changed-vars


x: []  repeat i 360 [ append x i ]
y: map-each i x [ sine i ]
view g: layout  [
     panel [
	h1 "Testing exporting graph to pdf" 
	graph 400x600 grid 'xy data x y 
	btn "Close" [unview]
    ]
    key #"q" [unview]
]


write %diagtest.pdf face-to-pdf g

show-changed-vars

REBOL [
]

;lib-dir: join dirize to-rebol-file get-env "BIOSERVO" %tools/rebol/libs

do %graph.r

x: []  repeat i 360 [ append x i ]
y: map-each i x [ sine i ]
view g: layout  [
     panel [
	h1 "Testing exporting graph to pdf" 
	graph 400x600 grid 'xy data x y 
	b: btn "Close" [unview]
	box b/size "Clo" center green
    ]
    key #"q" [unview]
]

;do lib-dir/dbg-tools.r

do/args %../face-to-pdf-lib.r 'face-to-pdf 

;show-changed-vars

write %diagtest.pdf face-to-pdf g

;show-changed-vars

REBOL [
]

;lib-dir: join dirize to-rebol-file get-env "BIOSERVO" %tools/rebol/libs
unview/all

do %graph.r

x: []  repeat i 360 [ append x i ]
y: map-each i x [ sine i ]

view/new  layout  [
      panel [
	h1 "Testing texts to pdf" 
	b: box 400x300 pink effect [
	    draw [
		pen black fill-pen black
		line 20x20 200x20
		text 20x20 "Below first line"
		line 20x120 200x120
		text 20x120 "Below second line"
		line 20x220 200x220
		text 20x220 "Below third line"
		line 20x320 200x320
		text 20x320 "Below fourth line"
	    ]
	]
	p: box 400x300 yellow effect [
	    draw [
		scale 0.7 0.7 translate 20x20 push [
		    pen black fill-pen black
		    line 20x20 90x20
		    text 20x20 "Below first line"
		    line 20x120 90x120
		    text 20x120 vectorial "Below second line,^/vectorial"
		    line 20x220 90x220
		    text 20x220 "Below third line"
		    line 20x320 90x320
		    text 20x320 "Below fourth line"
		]
	    ]
	]
     ]
    key #"q" [unview]
]

;do lib-dir/dbg-tools.r

do/args %../face-to-pdf-lib.r 'face-to-pdf 

;show-changed-vars

write %draw-texts.pdf face-to-pdf p
;write %draw-texts-b.pdf face-to-pdf b

halt

;show-changed-vars

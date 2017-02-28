REBOL [
]

do %create-pdf.r

big-font: make current-font [
    name: "/usr/share/fonts/gnu-free/FreeSans.ttf"
    size: 100
]

view/new  f: layout [
     a: area  green  200x500 wrap effect [
	draw [
	    font current-font
	    pen black
	    text 10x10 "Pen blue fill red"
	    text 10x22 "Normal write"
	    text 10x200  "Vectorial write"
	    font big-font
	    pen blue
	    fill-pen none
	    line-width 2
	    text 50x35 "A"
	    
	    text 50x210 "A" vectorial
	    ;font current-font 
	] ]
	edge [ size: 20x20 color: brown effect: 'bevel]
	font [ name: "times" ]
	field "Dull alksjflasj l loapoppp o hej. piipiip"
]

;f/pane/1/text: system/license
show f

write/binary %test.pdf face-to-pdf f



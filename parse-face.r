REBOL [
]

do %create-pdf.r

view/new  f: layout [
     area "asdfads" green  200x500 wrap effect [
	draw [
	    pen blue
	    fill-pen red
	    font current-font 
	    text 50x50 "Draw text" 
	    line-width 3
	    pen cyan
	    line 50x62 150x62
	] ]
	edge [ size: 20x20 color: brown effect: 'bevel]
	font [ name: "times" ]
	field "Dull alksjflasj l loapoppp o hej. piipiip"
]

f/pane/1/text: system/license
show f

write/binary %test.pdf face-to-pdf f



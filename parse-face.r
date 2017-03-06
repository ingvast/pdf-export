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
	    text 10x10 "Pen (blue) fill )red("
	    text 10x22 "Normal \write"
	    text 0x200  "abcdefghijklmnopqrstuvxyz"
	    text 0x212  "ABCDEFGHIJKLMNOPQRSTUVXYZ"
	    text 0x224  {!"#Â¤%&/()=?@{[]}\,.;:-_*}
	    text 0x236  {<>|@}
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
	btn: btn "OK" #"^w" [univew]
	image logo.gif
]

;f/pane/1/text: system/license
show f

write/binary %test.pdf face-to-pdf f



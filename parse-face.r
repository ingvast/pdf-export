REBOL [
]

context [
    face-to-pdf: do %face-to-pdf-lib.r

    krumelur: load join to-rebol-file get-env "BIOSERVO" %/admin/Logo/090615-krumelur.png

    current-font: face-to-pdf/current-font
    big-font: make current-font [
	name: "/usr/share/fonts/gnu-free/FreeSans.ttf"
	size: 100
    ]
    a: none
    btn: none

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
	    image 100 krumelur
    ;/C:\Users\jin\Documents\BioServo\admin\Logo
    ]

    ;f/pane/1/text: system/license
    show f

    ;write/binary %test.pdf face-to-pdf f

    ; layout [ f2: box 200x200 effect [ draw [ line 100x100 200x100 200x200 c ] ] ]
    write/binary %test.pdf face-to-pdf/face-to-pdf f

    view/new g: layout [
	image 100 krumelur
    ]
    write/binary %krumelur.pdf face-to-pdf/face-to-pdf g

    unview/all
]

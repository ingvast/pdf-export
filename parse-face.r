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
	field "Dull alksjflasj l "
]

f/pane/1/text: {
to-rgb: func [ rgb [tuple!] ][
	reduce [ rgb/1 / 255 rgb/2 / 255 rgb/3 / 255 ]
]
unpair: func [ p [pair!] ][ reduce [ p/1 p/2 ] ]
}
show f

strea: parse-face f

stream 'content compose [
    dict [ /Length none ]
    stream
    (strea)
    endstream
]

o: last objs
o/proc-func

reduce-fonts
create-fonts-resource


face-to-page 'page f [ content ]  'resources 

write %test.pdf compose-file 



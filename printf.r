REBOL
[
    title: "Code to implement printf natively"
]

dbg: [ here: ( print here ) ]

format: func [
    fmt [string!] {Format to print}
    data [ block!] {Block of data to put into fmt}
    /local 
	;o
][
    o: context [
	str: copy ""
	char: none
	
	val: fills: none

	fillchar: #" "
	align-char: #"+"
	n-space: 0
	n-fracts: 8
	fmt-char: none


	digit: charset [ #"0" - #"9" ]

	data-pattern: [
	    ( align-char: #"+" fillchar: #" " )
	    #"%"
	    opt [
		[ copy align-char #"-" ]
		|
		[ copy fillchar #"0"   ]
	    ]
	    copy n-space any digit
	    opt [
		#"."
		    copy n-fracts any digit
		]
	    copy fmt-char [
		#"f"
		| #"g"
		| #"e" 
		| #"d" 
		| #"i" 
		| #"s"
		    (
			n-space: any [ n-space 0 ]
			n-space: to-integer n-space
			val: first+ data
			val: to-string val
			fills: max 0 n-space - length? val
			either align-char == #"+" [
			    insert/dup tail str fillchar  fills
			    append str val
			][
			    append str val
			    insert/dup tail str fillchar  fills
			]
		    )
	    ]
	]
	pattern: [
	    any [ data-pattern | copy char skip ( append str char ) ] 
	]

    ]


    probe  parse/all/case fmt o/pattern 
    probe o

    return o/str
]
	
test-base: func [ fmt dta] [
    print my: format fmt dta
    print std: sprintf join [ fmt ] dta
    either my == std [
	print "OK"
    ][
	print "Fault"
    ]
]
test-string: does [
    fmt: "<%s> <%10s>  <%-10s>  <%010s>"
    dta: ["a" "b" "c" "d"]
    test-base fmt dta
]
test-string

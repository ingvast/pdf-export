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
	n-fracts: 6
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
	    ]
	    (
		n-space: to-integer any [ n-space 0 ]
		n-fracts: to-integer any [ n-fracts 6 ]

		val: first+ data

		val: probe switch fmt-char [
		    "s" [  to-string val ]
		    "f" [ num-to-string-f val n-fracts ]
		]

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
	pattern: [
	    any [ data-pattern | copy char skip ( append str char ) ] 
	]

	num-to-string-f: func [ num n-fracts /local str ][
	    str: copy ""

	    unless num >= 0 [
		append str "-"
		str: next str
		num: negate num
	    ]

	    num: num * ( 10.0 ** n-fracts ) 
	    loop n-fracts [
		frac: mod num 10
		insert str  round/half-ceiling frac
		num: num - frac
		num: num / 10
	    ]
	    insert str #"."
	    until [
		frac: mod num 10
		insert str  round/floor frac
		num: num - frac
		num: num / 10
		num < 1.0
	    ]
	    head str
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

test-f: does [
    fmt: "%f %10f %-10f %4.2f %-10.3f "
    dta: reduce [ pi pi pi pi pi ]
    test-base fmt dta
]

test-string
test-f

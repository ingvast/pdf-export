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
	align-char: none
	n-space: 0
	n-fracts: 6
	fmt-char: none


	digit: charset [ #"0" - #"9" ]

	data-pattern: [
	    ( align-char: fillchar: signchar: none )
	    #"%"
	    opt [
		[ copy align-char #"-" ]
		|
		[ copy fillchar #"0"   ]
		| copy signchar #"+"
	    ]
	    copy n-space any digit
	    opt [
		#"." copy n-fracts any digit
		]
	    copy fmt-char [
		#"f"
		| #"g"
		| #"e" 
		| #"E" 
		| #"d" 
		| #"i" 
		| #"s"
	    ]
	    (
		n-space: to-integer any [ n-space 0 ]
		n-fracts: to-integer any [ n-fracts 6 ]

		val: first+ data
		unless val [
		    make error! "Not enough data to print, number of specifiers larger than data"
		]

		val: switch fmt-char [
		    "s"		[ to-string val ]
		    "d" "i"	[ num-to-string-d abs val ]
		    "f"		[ num-to-string-f abs val n-fracts ]
		    "e" "E"	[ num-to-string-e abs val n-fracts fmt-char  ]
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

	num-to-string-d: func [ num [ integer! ] /local str ] [
	    str: copy ""

	    unless num >= 0 [
		append str "-"
		str: next str
		num: negate num
	    ]
	    until [
		frac: mod num 10
		insert str  round/floor frac
		num: num - frac
		num: num / 10
		num < 1.0
	    ]
	    head str
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
	num-to-string-e: func [
	    num n-fracts modifier
	    /local str  n
	] [
	    str: copy ""
	    n: round/floor log-10 abs num
	    num: num / (10.0 ** n )
	    str: num-to-string-f num  n-fracts
	    append str modifier
	    append str n-fracts
	]
	    


	parse/all/case fmt pattern 
    ]

    return o/str
]
	
test-base: func [ fmt dta] [
    prin my: format fmt dta
    prin std: sprintf join [ fmt ] dta
    either my == std [
	print "-- OK"
    ][
	print "--  Fault"
    ]
]
test-string: does [
    fmt: "<%s> <%10s>  <%-10s>  <%010s> ---"
    dta: ["a" "b" "c" "d"]
    test-base fmt dta
]

test-f: does [
    fmt: "%f %10f %-10f %4.2f %-10.3f %3.8f ---"
    dta: reduce [ pi pi pi pi pi  pi]
    test-base fmt dta
]
test-e: does [
    fmt: "%E %10e %-10E %4.2E %-10.3e %3.8E ---"
    dta: reduce [ pi pi pi pi pi  pi]
    test-base fmt dta
]

test-d: does [
    fmt: "%d  %10d  %-10d %2d^/"
    dta: reduce [ random 1000 random 1000 random 10000  3 ]
    test-base fmt dta
]

test-string
test-f
test-e
test-d


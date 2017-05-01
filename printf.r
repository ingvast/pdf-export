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

	fillchar: #" "
	align-char: #"+"
	n-space: 0
	n-fracts: 8
	fmt-char: none


	digit: charset [ #"0" - #"9" ]

	data-pattern: [
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
		#"f" | #"g" | #"d" | #"i" | #"s"
	    ]
	]
	pattern: [
	    any [ data-pattern | copy char skip ( append str char ) ] 
	]

    ]


    probe  parse/all fmt o/pattern 
    probe o/str

    return o
]
	

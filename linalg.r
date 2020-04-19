REBOL [
    title: "Linear algebra package"
    doc: {
	A simple implementation of a linear algebra package doing the most simple things.
	
	Remember that matrixes are stored as a list of rows and vectors as a list
	}
]

ff-matrix: func [ A ][ new-line/all A on ]

swap-rows: func [ M i1 i2] [ swap at M i1 at M i2 ]
vector-mult: func [ x1 x2 /local s ] [
    s: 0.0
    ;foreach x x1 [ s: s + (  x * first+ x2 ) ]
    repeat i length? x1 [ s: s + ( ( pick x1 i ) * pick x2 i ) ]
    s
]
;vector-sum: func [ v /local sum ] [ sum: 0 forall v [ sum: sum + first v ] sum ]
vector-sum: func [ v /local sum ] [ sum: 0. repeat i length? v [ sum: sum + pick v i ] sum ]

;mult-vector-scalar: func [ v s ][ map-each t v [ t * s ]]
mult-vector-scalar: func [ v s ][ v: copy v repeat i length? v [ poke v i s * pick v i ] v ]

negate-vector: func [ v ][ v: copy v forall v [ v/1: negate v/1 ] v ]
negate-matrix: func [ A ][ A: copy A forall A [ A/1: negate-vector A/1 ] A ]

;add-vector-scalar: func [ v s /local res][  map-each x v [ s + x ] ]
add-vector-scalar: func [ v s ][ v: copy v repeat i length? v [ poke v i s + pick v i ] v ]

;add-vector-vector: func [ v w ][ map-each t v [ t + first+ w ]]
add-vector-vector: func [ v w ][ v: copy v repeat i length? v [ poke v i (pick w i) + pick v i ] v ]

;add-mult-vector-vector: func [ v a1 w a2 ][ map-each t v [ t *  a1 + ( a2 * first+ w )]]
add-mult-vector-vector: func [ v a1 w a2 ][ v: copy v repeat i length? v [ poke v i (a1 * pick v i ) + ( a2 * pick w i ) ] v ]

add-matrix-matrix: func [ A B /local result ][
    result: copy []
    foreach x A [
	append/only result add-vector-vector x first+ B
    ]
]

sub-matrix-matrix: func [ A B /local result ][
    add-matrix-matrix A negate-matrix B
]

sub-matrix-matrix: func [ A B ][
    add-matrix-matrix A negate-matrix B
]

mult-matrix-vector-ol: func [ M x /local n ret ] [
    n: length? M
    ret: make block! n
    foreach y M [
	append ret vector-mult y x
    ]
]
mult-matrix-vector: func [ M x /local n ret ] [
    M: copy M
    repeat i length? M [ poke M i vector-mult pick M i x ]
    M
]
mult-matrix-matrix: func [
    A B
    /A-transposed {Use if first matrix is a transposed version of what it should be}
    /B-transposed {Use if first matrix is a transposed version of what it should be}
    /symmetric {Use if you know the result is symetric, to be implemented}
    /local
	C
][
    n: length? A
    unless B-transposed  [B: transpose-matrix B]
    if A-transposed  [A: transpose-matrix A]
    C: make  block! n
    foreach x B [ append/only C mult-matrix-vector A x ]
    C: transpose-matrix C
]

mult-matrix-scalar: func [ A k /local result ][
    result: copy []
    foreach x A  [
	append/only result mult-vector-scalar x k
    ]
    result
]
	

rand-vector: func [ n /local v ] [ v: make block! n  loop n [ append v ( random 1000. )  - 500. ] v ]

rand-matrix: func [ n /local A ] [
    A: make block! n
    loop n [ append/only A rand-vector n ]
    A
]

mult-add-vectors: func [
    r1 [ block! ] {Row}
    k1  [number!] {multiplicator}
    r2 [ block! ] {Row}
    k2  [number!] {multiplicator}
    /local 
    r n
] [
    r: make block! n: length? r1
    repeat i n [
	append r r1/:i * k1 + ( r2/:i * k2 )
    ]
    r
]
mult-row: func [ r k ] [ map-each x copy r [ x * k ] ]

form-matrix: func [ 'M
    /local
    r ret
] [
    ret: reform [  M ":" ]
    foreach r get M [ repend ret reform [ tab form r newline ] ]
]

get-col: func [
    M { The matrix}
    c {The column index}
    /local
	ret
	n
    ] [
    n: length? M
    ret: make block! n
    foreach x M [ append ret x/:c ]
    ret
]

get-cols: func [
    M { The matrix}
    from {The first column}
    to {The last column}
    /local
	ret
	n
    ] [
    n: length? M
    ret: make block! n
    foreach x M [ append/only ret copy/part at x from to - from + 1 ]
    ret
]

transpose-matrix: func [A /local ret m ] [
    ret: make block! n: length? A/1
    m: length? A
    
    repeat i n [
	append/only ret new-line/all get-col A i off
    ]
    new-line/all ret on
]

inverse-matrix: func [ A /local Ainv ][
    linear-eq-solve A eye length? A
]
determinant-definition: func [
    {Calculates the determinant using the definitioin of such, very time
    consuming and memory hungry}
    A
    /local
	sum B mult n val

] [
    if 1 = n: length? A [ return first first A ]
    mult: 1
    sum: 0
    repeat i n [
	B: copy/deep A
	f: B/:i/1
	remove at B i
	forall B [ remove first B ]
	sum: sum + ( mult * f * determinant B )
	mult: negate mult
    ]
    sum
]

determinant: func [
    A
    /local
][
    A: forward-decomposition/mult A
    d: diag first A
    m: second A forall d [ m: m * first d ]
    m
]

eye: func [ n /local B Bi ] [
    Bi: make block! n
    B: make block! n
    loop  n [ append Bi 0. ]
    loop  n [ append/only B copy Bi ]
    repeat i n [ B/:i/:i: 1. ]
    B
]

diag: func [ A
    /local 
	ret 
] [
    n: length? A
    ret: make block! n
    either block? A/1 [
	repeat i n [ append ret A/:i/:i ]
    ][
	zeros: make block! n loop n [ append zeros 0. ]
	loop n [ append/only ret copy zeros ]
	repeat i n [ ret/:i/:i: A/:i ]
    ]
    ret
]
	

forward-decomposition: func [
    {Does forward decomposition, adds an eye matrix in case A is nxn}

    A [ block! ] 
    /mult

    /local x n row B m
][ 
    A: copy/deep A
    n: length? A
    m: 1

    if n = length? first A [
	B: eye n
	foreach row A [ append row first+ B ]
    ]

    x: make block! n
    ; Forward substitutioin
    repeat i n [
	; Find the row with largest pivot element and move the row to the first row
	for j i + 1 n 1 [
	    if ( abs A/:j/:i ) > abs A/:i/:i [ m: negate m swap-rows A i j ]
	]
	; Now we should have the row with the best diagonal on row i
	; 
	d-element: negate A/:i/:i

	for j i + 1 n 1 [
	    A/:j:   mult-add-vectors	A/:j	    1
					A/:i	    A/:j/:i / d-element
	    A/:j/:i: 0. ; In case there are numerical rests
	]
    ]
    either mult [ reduce [ A m ] ] [ A ]
]

linear-eq-solve: func [
    {Solves the linear equation y = A x 
     y = [ y/1 y/2 ... y/n ]
     A = [ [ A11 A12 ... A1n ] [ A21 A22 ... A2n ] ... [1An An2 ... Ann] ]
     x = [ x/1 x/2 ... x/n ]
    }

    A [ block! ] { Block of size n x n }
    y [ block! ] { Block of size n }

    /local x n row
][ 
    A: copy/deep A
    foreach row A [ append row first+ y ]
    A: forward-decomposition A
    n: length? A
    ; Backward substitution
    ; print {Backward substitution}
    for i n 1 -1 [
	;Normalize row i
	; print [ "pre normalize row" i  "multiplied with" 1 / A/:i/:i ] print form-matrix A
	row: A/:i: mult-row A/:i    1 / A/:i/:i
	; print [ "Normalized row" i ] print form-matrix A


	repeat j i - 1 [
	    A/:j: mult-add-vectors A/:j 1 row negate A/:j/:i
	    ; print [ "Reduced row" j ] print form-matrix A
	]
    ]
    either block? y/1 [
	get-col A n + 1 
    ][
	get-cols A n + 1  length? A/1
    ]
]



; Tests
; Linear algebra
if all [value? 'debug-linalg debug-linalg ] [
    A: [    [ 1 2 ]
	    [ 2 3 ] 
       ]
    x-solved: [ 2 3 ]
    y: mult-matrix-vector A x-solved

    print form-matrix A
    print form-matrix y

    x: linear-eq-solve  A y
    print form-matrix x
    print either x = x-solved [ {Solved correctly} ] [ {Not a correct solution} ]

    A: rand-matrix 8
    x-solve: rand-vector 8
    y: mult-matrix-vector A x-solve
    x: linear-eq-solve A y
    print form-matrix x-solve
    print form-matrix x
    print either x = x-solved [ {Solved correctly} ] [ {Not a correct solution} ]

    print [ {\n\t\Determinant\n
	}]
    A: [ [ 1 1 ] [ 2 2] ]
    print [ "Determinant of \n" form-matrix A ]
    det: determinant A
    print [ "is" det ]
    either det = 0 [ print "OK" ] [ print "Error!" ]

    A: [ [ 1 1 5 ] [ 2 2 7 ]  [ 14 14 49 ] ]
    print [ "Determinant of " form-matrix A ]
    det: determinant A
    print [ "is" det ]
    either det = 0 [ print "OK" ] [ print "Error!" ]

    A: transpose-matrix [ [ 1 1 5 ] [ 2 2 7 ]  [ 14 14 49 ] ]
    print [ "Determinant of " form-matrix A ]
    det: determinant A
    print [ "is" det ]
    either det = 0 [ print "OK" ] [ print "Error!" ]

    A: [ [ 1 1 5 ] [ 20 2 7 ]  [ 14 14 49 ] ]
    print [ "Determinant of " form-matrix A ]
    det: determinant A
    print [ "is" det ]
    either det != 0 [ print "OK" ] [ print "Error!" ]
]
; vim: ai sw=4 sts=4

REBOL [
]

obj-list: copy []

document: [
    Fonts: [ font1 font2 .... ]
    Images: [ image1 image2 ]
    Pages: [
	Page: [
	    Resources: [
		Font: [ 
		    /font1 /font1
		    /font2 /font2
		]
		XObject: [
		    /image1 N 0 R
		    /image2 N 0 R
		]
	    ]
	    Content: 
	]
    ]
]

base-obj!: make object! [
    Head: does [ [ obj-id 0 obj ] ] ;Head should print the first line of object
    register: does [
	append obj-list self
	obj-id: length? obj-list
    ]

    dict: [
    ]

    obj-id: none
    string: ""
    to-string: does [
	use [ val ][
	    foreach field dict [
		val: get in self field
		append string val ; Execute function if necessary
	    ]
	]
    ]
]

base-stream!: make base-obj! [
    append dict 'Length
]


pages-dict!: make base-obj! [
    Type: 'Pages
    append dict [ Kids Count ]
    Parent: 
    Kids: none
    Count: does [length? Kids ]
]

page-dict!: make base-obj! [
    Type: 'Page
    Parent:
    Resourses:
    MediaBox:
    Content:
    append dict [ Parent Resourses MediaBox Content ]
]

font-dict!: make base-obj! [
    Type: /Font
    Subtype: /Type1
    BaseFont: none
]

fonts-dict!: make object! [
    dict: []
]

resources-dict!: make base-obj! [
    Font: none
    XObject: none
    ProcSet: [ /PDF /Text /ImageB /ImageC /ImageI ]
    append dict [ Font XObject ProcSet ]
]


catalog-dict!: make base-obj! [
    Type: /Catalog
    Pages:  []
    dict: [ Type Pages ]
]

trailer-dict!: make base-obj! [
    Head: does [ ["trailer" ] ]
    Size: 
    Root:
    Info: 
    ID: 
	none
    dict: [ Size Root ID Info ]
]
    

# pdf-export Library for exporting view faces to pdf

## Usage
### Quick start
Create the face to export
```
view vface: layout [
    h1 "Export this"
    bo: box 200x200 effect [
	draw [
	    pen black line-width 3
	    circle 100x100 75
	]
    ]
]
```
Load the library
`lib: do %face-to-pdf-lib.r`

Export to pdf
```
write %vface.pdf lib/face-to-pdf vface
```
You can export any face such as `bo` in the example.

Writing more than one page is not yet implemented.

## Exceptions, known bugs

### File related
* Only PDF standard fonts are used
  There is a conversion table in `face-to-pdf-lib/font-translations` that can be used to
  translate the font used in view int the correpsonding pdf font.
* When using draw without setting a drawing color, REBOL automatically chooses some color different from 
  the background.  That transformation is not right.
* Each PDF file only contain one page with one face.
* The size of the PDF is set to the size of the face.
* No compression is done, so large images will result in large files.

### Effects related
* None of the image processing commands (`invert`, `luma`, `contrast` ... ) are implemented.
* Tiling is not implemented.
* `merge`, `clip` and `crop` are not implemented.
* The gradient commands `gradcol` and `gradmul` are not implemented.  `gradient` is.
* Algorithmic shapes related commands `cross`, `oval` and `round` are not implemented.
* `shadow` is not implemented. (partly becauyse I cannot figure out what it does).

### Draw related
* The draw pen cannot be an image
* Images can have linear transformations, so the general method of setting all four corners of an image
  does not render correctly.
* Spline not implemented
* Nothing from  Shape subdialect is implemented



## File overview

The library is contained in mainly two files.  `pdf-lib.r` and `face-to-pdf-lib.r` where
the latter calls the former.
`pdf-lib.r` is for handling the pdf structure, creating objects, keeping track of their relations .. 
`face-to-pdf.r` extracts the information from view and is responsible for filling the structure given
by `pdf-lib.r`.

Test files are found under `test` directory. Simply execute them from a rebol prompt and they should 
show some graphics and leave a pdf fil


## External libraries used
  * `printf.r` from the rebol script library. Thanks to Jamie and Ladislav.


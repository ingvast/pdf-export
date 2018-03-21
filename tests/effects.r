REBOL [
       ]
lib: do %../face-to-pdf-lib.r
fnt: make face/font [ name: "/usr/share/fonts/gnu-free/FreeSans.ttf" ]
print "Images"


puppy: load %/usr/share/pixmaps/faces/puppy.jpg
cat-eye: load %/usr/share/pixmaps/faces/cat-eye.jpg

view/new f: layout [
    box puppy edge[ size: 2x2 color: black ]
    box cat-eye 150x50 effect[draw[pen red line-width 3 line 10x10 50x200 180x50] ] edge[ size: 2x2 color: black ]
    box cat-eye 150x50 effect [ aspect ]  edge[ size: 2x2 color: black ]
    across
    box puppy 50x150 effect [ aspect ]  edge[ size: 2x2 color: black ]
    
    below
    btn "Wow"  100x25  help "Detta is help"

    box 150x150 puppy effect [ extend ] 
    
    key #"q" [ unview ]
]

write %effects.pdf lib/face-to-pdf f
wait none

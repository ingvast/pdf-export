REBOL [
       ]
lib: do %../face-to-pdf-lib.r
fnt: make face/font [ name: "/usr/share/fonts/gnu-free/FreeSans.ttf" ]
print "Images"


puppy: load %/usr/share/pixmaps/faces/puppy.jpg
cat-eye: load %/usr/share/pixmaps/faces/cat-eye.jpg

special: make image! 4x4
n: 1
foreach c reduce [
    red	    blue    green   green * 0.6
    blue    blue    blue    blue * 0.6
    magenta blue    cyan    cyan * 0.6
    magenta blue    cyan    cyan * 0.6
][ poke special n c n: n + 1]

view/new f: layout [
    backdrop red * 0.8
    space 1x1
    box puppy edge[ size: 2x2 color: black ]
    box cat-eye 150x50 effect[draw[pen red line-width 3 line 10x10 50x200 180x50] ] edge[ size: 2x2 color: black ]
    box cat-eye 150x50 effect [ aspect ]  edge[ size: 2x2 color: black ]
    across
    box puppy 50x150 effect [ aspect ]  edge[ size: 2x2 color: black ]
    
    below
    btn "Wows"  100x25  help "Detta is help"

    box 150x150 puppy effect [ extend ] 
    image 50x50 special
    box 50x50 special effect [ extend 1x1 ]  edge [ size: 5x2 color: black ]
    box 50x50 red
    
    
    key #"q" [ unview ]
]

write %effects.pdf lib/face-to-pdf f
wait none

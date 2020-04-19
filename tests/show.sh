#!/bin/bash
name=$1
rm -f  $name.png
gs -dNOPAUSE -dBATCH -sOutputFile=$name.png -sDEVICE=png48 $name.pdf 

display $name.png

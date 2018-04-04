#!/bin/bash
name=$1
gs -dNOPAUSE -dBATCH -sOutputFile=$name.png -sDEVICE=png48 $name.pdf 

display $1.png

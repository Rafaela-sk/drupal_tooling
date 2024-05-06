#!/bin/bash

echo "configure generated icons using module Metatag:Favicon"
echo "Metatag module can also be used to set title of homepage"
echo ""

src="rafaela_favicon.svg"

list="16 32 96 192 60 72 76 114 120 144 152 180 57"

for size in ${list}
do
   inkscape -o favicon-${size}x${size}.png -w ${size} -h ${size} ${src}
done

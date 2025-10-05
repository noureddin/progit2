#!/bin/bash

input="KacstOne.ttf"
output="${input%.*}-subset"
range=20,21,28,29,3A,ab,bb,60c,61b,61f,621-63a,640-652,660-669,66a,67e,2026
# all imlaai arabic letters including tatweel, the five ascii ():!., all tashkeel,
# arabic question mark and semicolon and comma and percentage sign, ٠ to ٩,
# ellipsis, letter peh, guillemets, and ascii space

# # uncomment this to review the included character set
# grep ^range= "${BASH_SOURCE[0]}" | perl -mcharnames -ne '
#   s/range=//; s/\s+$//;          # remove prefix and suffix
#   s/[0-9a-fA-F]+/"0x$&"/gee;     # convert to decimal (easier processing)
#   s/(\d+)-(\d+)/join " ", $1..$2/ge;  # expand ranges
#   printf "U+%04X  %s\n", $_, charnames::viacode($_)
#     for split / *, *| +/;
# '

if ! [ -e "$input" ]; then
  >&2 printf 'Error: Input file does not exists: %s\n' "$input"
  >&2 printf 'Hint: Maybe you are not in the res/ directory?\n'
  exit 2
fi

pyftsubset "$input" --output-file="$output".woff2 --layout-features=* --flavor=woff2 --unicodes=$range
pyftsubset "$input" --output-file="$output".woff  --layout-features=* --flavor=woff  --unicodes=$range --with-zopfli


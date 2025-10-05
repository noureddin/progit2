#!/bin/bash

shopt -s globstar  # expand /**/ to any number of dirs

PROD=true
# run `make switch`, `make switch_debug`, or `make switch_production` at the commandline to toggle
# set PROD to false to produce all chapters; set it to true to produce only the complete chapters.
# the "complete chapters" are those whose title starts with ✨ or ✅ or ⛲. (check TRANSLATION_NOTES.asc).
# also PROD=false enables live-reloading, and removes the "fixme" marks.

perl='perl -CDAS -Mutf8'

# preprocessing
$perl -pe '
  ## copy figures titles to their alt-text
  if (/^\.(\S.*)$/) {
    $potenially_title = $1
      =~ s/"`/“/gr =~ s/`"/”/gr;
      # not processed by asciidocter in the alt-text
    $i = 0;
  }
  elsif (/^image::/ && $potenially_title && $i == 1) {
    s/\[.*\]/[$potenially_title]/;
    $potenially_title = "";
  }
  else {
    ++$i;
  }
  ##
  ## for the Amiri font {
  ## break the كتا and كتل ligatures in Amiri
  # s X ك(ت[ال]) Xك\N{ZERO WIDTH JOINER}$1Xgx;
  ## break the مر and مز ligatures in Amiri
  # s X (\b|[اأإآدذرزو])م([رز]) X$1م\N{ZERO WIDTH JOINER}$2Xgx;
  ## except when inside a code block or an inline-code
  ## by convention: it is only used as a placeholder (between « and » then)
  # s X «أم\N{ZERO WIDTH JOINER}ر» X«أمر»Xgx;
  ## }
  ## for the KacstOne font {
  s X ([بتثنى]\N{ARABIC SHADDA}) ق X$1\N{ARABIC TATWEEL}قXgx;
  ## }
  ## process NBSP & NNBSP
  s/\Q{مس}\E/\N{NO-BREAK SPACE}/g;
  s/\Q{مسر}\E/\N{NARROW NO-BREAK SPACE}/g;
' -i **/*.asc

# update arabic names of git commands
# (copying them from C-git-commands.asc to E-arabic-reference.asc)
ARABIC_COMMANDS="$($perl -ne '
  my ($en, $ar) = /^==+ git (.*) \((.*)\)/;
  if ($en) {
    print "$en  : $ar",
      ($en =~ /reset|revert|restore/) ? " ({re_cmds})" : "",
      ($en =~ /push|^pull|fetch/) ? " ({pull_cmds})" : "",
      ($en =~ /commit|checkout/) ? " ({co_cmds})" : "",
      "\n"
  }
' C-git-commands.asc | sort -i)"
$perl -ne '
    $bgn = / BEGIN ARABIC GIT COMMANDS /;
    $end =   / END ARABIC GIT COMMANDS /;
    print unless $bgn..$end;  # do not change outside the range
    print if $bgn || $end;    # do not change the range limits
    if ($bgn) {               # replace its inside with the following
      print "'"${ARABIC_COMMANDS//"/\\"}"'\n"
    }
' -i E-arabic-reference.asc

# create, or clean, the output directory
OUT=docs
if [ -d "$OUT" ]; then
  rm -rf "$OUT"/[^_]* "$OUT"/_?*
  # remove everything but the underscore file, which is used for live-reloading
elif [ -e "$OUT" ]; then
  rm -f "$OUT"
  mkdir -p "$OUT"
else
  mkdir -p "$OUT"
fi

# update resources (except pdf)
[ -d v ] && rsync -a v "$OUT"  # used for debugging
mkdir -p "$OUT"/res;    cp --link res/*        "$OUT"/res/
mkdir -p "$OUT"/images; cp --link images/*.png "$OUT"/images/

# copy (potentially old) pdfs
for i in a4 a5; do
  if [ -e $i.pdf ]; then
    cp --link $i.pdf docs/progit2-ar-$i.pdf
  elif [ -e $i-.pdf ]; then  # no bookmarks
    >&2 printf '\e[33mPDF %s.pdf not found but %s-.pdf (without the in-viewer ToC) is found\e[m\n' $i $i
    cp --link $i-.pdf docs/progit2-ar-$i.pdf
  fi
done

# build the single-page book, or the contributors list only
if $PROD; then
  bundle exec rake book:build_html
  mv -f progit.html "$OUT"/progit-all.html
  # that output path is hard-coded in .postprocess.pl
else
  bundle exec rake book/contributors.txt
fi

# build the multipage book
MULTI_OPTS=(
  -a multipage-level=2
  -a sectnums
)
bundle exec asciidoctor-multipage -D "$OUT" progit.asc "${MULTI_OPTS[@]}"

# post-processing

# combine both single-page & multipage books with an introductory text, and various, minor fixes to both

mv "$OUT"/progit.html "$OUT"/index.html

$PROD && prod=1 || prod=0
exec $perl .postprocess.pl "$OUT" $prod

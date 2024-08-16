#!/bin/bash

shopt -s globstar  # expand /**/ to any number of dirs

PROD=true
# set PROD to false to produce all chapters; set it to true to produce only the complete chapters.
# the "complete chapters" are those whose title starts with ✨ or ✅ or ⛲. (check TRANSLATION_NOTES.asc).
# also PROD=false enables live-reloading, and removes the "fixme" marks.

perl='perl -CDAS -Mutf8'

# preprocessing
$perl -pe '
  # copy figures titles to their alt-text
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
  # break the كتا and كتل ligatures in Amiri
  s X ك(ت[ال]) X ك\N{ZERO WIDTH JOINER}$1 Xgx;
  # process NBSP & NNBSP
  s/\Q{مس}\E/\N{NO-BREAK SPACE}/g;
  s/\Q{مسر}\E/\N{NARROW NO-BREAK SPACE}/g;
' -i **/*.asc

# update arabic names of git commands
# (copying them from C-git-commands.asc to E-arabic-reference.asc)
ARABIC_COMMANDS="$($perl -ne 'print "$1  : $2\n" if /^==+ git (.*) \((.*)\)/' C-git-commands.asc | sort -i)"
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
OUT=docs  # must not contain spaces or any special characters
if [ -d $OUT ]; then
  rm -rf $OUT/[^_]* $OUT/_?*
  # remove everything except '$OUT/_', which is used for live-reloading
elif [ -e $OUT ]; then
  rm -f $OUT
  mkdir -p $OUT
else
  mkdir -p $OUT
fi

# update resources (except pdf)
mkdir -p $OUT/res; cp --link res/* $OUT/res/
mkdir -p $OUT/images; cp --link images/*.png $OUT/images/

# build the single-page book, or the contributors list only
if $PROD; then
  bundle exec rake book:build_html
  SINGLE=progit.html
else
  bundle exec rake book/contributors.txt
  SINGLE=
fi

# the pdf books
if [ -e progit2-ar-a4.pdf ] && [ -e progit2-ar-a5.pdf ]; then
  cp --link progit2-ar-a[45].pdf $OUT/
else
  printf '\e[1;93mWarning: the PDF books do not exist\e[m\n'
fi

# build the multipage book
bundle exec asciidoctor-multipage -D $OUT progit.asc

# post-processing

remove="$(mktemp)"

for htmlfile in $SINGLE $OUT/*.html; do
  $perl -M'5; my $PROD="'"$PROD"'"eq"true"; my $remove="'"$remove"'"; my $htmlfile="'$htmlfile'"' -wpE '
    ## curly double-quotes
    s/&#8220;/\N{LEFT-TO-RIGHT EMBEDDING}$&/g; s/&#8221;/$&\N{POP DIRECTIONAL FORMATTING}/g;
    ## {عر} and {نه} inside code
    s/\{عر\}/&#x202b;/g;
    s/\{نه\}/&#x202c;/g;
    ## mark Arabic quotes as Arabic when they are preceded by English; does not work
    # s|(</code>(?:</a>)?)(»)|$1&#x61C;$2|g;
    # s|([A-Za-z](?:<[^<>]+>)*)([»«])|$1&#x61c;$2|g;
    ## "fixme"
    if ($PROD) {
      s| *FIXME||g;
    }
    else {
      s| *FIXME|<span style="position:absolute; right:-1em;color:red"><sup style="margin-right:-1em; font-weight:bold; font-family:mono !important">FIX</sup><sub style="font-weight:bold; font-family:mono !important">ME</sub></span>|g;
    }
    ##
    if (m|<pre class="highlight">|) { $HiLi = 1 }
    if (m|</pre>|) { $HiLi = 0 }
    if ($HiLi) { s@(?<!#)##(#[^#].*?)(?=<|$)@<span class="comment-in-code">$1</span>@g }
    ##
    if (m|rel="stylesheet"|) { $_ = "" }
    if (m|<style>|) { $Style = 1 }
    if (m|</style>|) { $Style = 0; $_ = "" }
    if ($Style) { $_ = "" }
    if (m|</head>|) {
      $_ = qq|<link rel=stylesheet type=text/css href="res/style.css">\n</head>\n|;
    }
    ##
    if (/(.* class="title">)(Figure|Table) (\d+)[.] (.*)/) {
      my ($before, $type, $n, $after) = ($1, $2, $3, $4);
      $n =~ tr[0-9][٠-٩];
      $type = $type eq "Figure"? "شكل" : $type eq "Table"? "جدول" : next;
      $_ = "$before$type\N{NARROW NO-BREAK SPACE}$n. $after";
    }
    ##
    my $STATUS_STYLE = $PROD ? "" : "<style>h2, h3 { margin-right: -1.25em }</style>";
    ## enclose body in a div, for background
    if (m|<body|)   { $_ .= qq|<div id="body">$STATUS_STYLE| }
    if (m|</body>|) { $_ = q|</div></body>| }
    ## asciidoctor-multipage navigation
    if (m|<div class="paragraph nav-footer">|) { $nav_footer = 1 }
    if (m|</div>|) { $nav_footer = 0 }
    if ($nav_footer && m|<p>|) {
      s/Previous:/السابق:/g;
      s/Next:/التالي:/g;
      s/Up:/البداية:/g;
      # swap arrows
      s/←/\0/g;
      s/→/←/g;
      s/\0/→/g;
    }
    ## multipage toc title
    s|<div id="toctitle">Table of Contents</div>|<div id="toctitle">فهرس المحتويات</div>|g;
    ##
    ## fix appendices titles, and numbers, and number the chapters
    BEGIN { @n = qw[ الأول الثاني الثالث الرابع الخامس السادس السابع الثامن التاسع العاشر ] }
    s,((?:<h2 id="ch([0-9]{2})-[^<>]*>|href="#?ch([0-9]{2})-[^#"_]*">(?:<span[^>]*>)?)(?:[➖❌✋⏳✨✅⛲] )?),$1الباب $n[($2 // $3) - 1]: ,g;
    s,(<h2 id="([A-Z])-[^<>]*>|href="#?([A-Z])-[^#"]*">(?:<span[^>]*>)?)Appendix .: ((?:[➖❌✋⏳✨✅⛲] )?),$1$4الملحق $n[ord($2 // $3) - ord("A")]: ,g;
    # s, (<a[^<>]*>)ال(باب|ملحق) \S+: , $2 $1,g;  # simplify chapters titles in body text (that initial space excludes toc & nav)
    s, (<a[^<>]*>)(?:[➖❌✋⏳✨✅⛲] )?ال(باب|ملحق) \S+: , $1,g;  # actually, remove additions in body links; they only affect h2 not sections or figures
    if ($PROD) {
      ## remove incomplete chapters, part one
      # warn "$htmlfile: $_\n" if m|<h2[^<>]*>[^✨✅⛲<>]+<|;
      if (m|<h2[^<>]*>[^✨✅⛲<>]+<|) {
        if ($htmlfile =~ m|/|) {  # if multipage file, remove it
          open my $f, ">>", $remove; print { $f } "$htmlfile\n";
        }
        else {  # if the single-page file
          $UNNEEDED = 1;
        }
      }
      elsif (m|<h2[^<>]*>|) {
        $UNNEEDED = 0;
      }
      ## remove all status icons
      s/[➖❌✋⏳✨✅⛲] //g;
      $_ = "" if $UNNEEDED;
    }
    else {
      if (/^(?:<li>|<p>→|<h[23])/) {  # toc or nav
          # | <a[ ]href="(?: (?:ch|[A-Z]) [0-9]+- [^"#<>]+ )? [#]? [^"#<>]* ">
        ## add ➖ to the empty chapter and section titles
        s{( <h[23][^<>]*>             # a chapter/section header
          | <a[ ]href="[^":]*">       # or a link to a chapter/section
          )                           # $1
          ([^❌✋⏳✨✅⛲<>]+<)       # $2: the title
        }{$1➖ $2}gx
      }
      else {
        ## remove status icons from all links except the toc & nav
        next if /^<li><a|^<p>→/;
        s{(<a href="[^"]*">)[➖❌✋⏳✨✅⛲] }{$1}g;
      }
    }
    ' -i "$htmlfile"
done

if $PROD; then

# remove incomplete chapters, part two: multipage nav-footer
# ASSUMPTION: first chapter (prefaces) and last chapter (an appendix) both exist
#   (this is also assumed when removing chapters from the single-page file)
$perl -M'5; my $OUT="'$OUT'"' -E '
  sub slurp { local $/; open my $fh, "<", $_[0]; return scalar <$fh> }
  # all chapters
  my @ch = slurp("progit.asc") =~ /^include::((?:ch[0-9]+|[A-Z])[^\n]+)[.]asc\[\]/gm;
  # chapters to remove
  open my $fh, "<", "'"$remove"'";
  my %RM = map { chomp; s|^$OUT/||r =~ s|[.]html$||r => undef } <$fh>;
  my @rm = map { exists $RM{$_} ? 1 : undef } @ch;
  # mapping the nav-footer links of the removed chapters
  my %title;
  my %name_map = map { $ch[$_] => $_ } 0..$#ch;
  my %prev_map;
  my %next_map;
  for my $i (0..$#ch) {
    if ($rm[$i]) {
      for my $j (reverse 0..$i-1) { if (!$rm[$j]) { $prev_map{$i} = $j; last } }
      for my $j (     $i+1..$#ch) { if (!$rm[$j]) { $next_map{$i} = $j; last } }
    }
    else {
      ($title{$i}) = slurp("$OUT/$ch[$i].html") =~ /<h2[^<>]*>(.*?)</;
    }
  }
  for my $htmlfile (<$OUT/*.html>) {
    my $html = slurp $htmlfile;
    if ($html =~ m|^<p>→[^<>]*<a href="([^<>"]*)[.]html"[^<>]*>[^<>]*<|m && exists $RM{$1}) {
      my $i = $prev_map{$name_map{$1}};
      # say "repl $1 with $i == $ch[$i]";
      $html =~ s|^(<p>→[^<>]*<a href=")[^<>"]*[.]html("[^<>]*>)[^<>]*(<)|$1$ch[$i].html$2$title{$i}$3|m;
    }
    if ($html =~ m|<a href="([^<>"]*)[.]html"[^<>]*>[^<>]*</a>[^<>]*←</p>$|m && exists $RM{$1}) {
      my $i = $next_map{$name_map{$1}};
      # say "repl $1 with $i == $ch[$i]";
      $html =~ s|(<a href=")[^<>"]*[.]html("[^<>]*>)[^<>]*(</a>[^<>]*←</p>)$|$1$ch[$i].html$2$title{$i}$3|m;
    }
    open my $fh, ">", $htmlfile;
    print { $fh } $html;
  }
'

BASE='(?:'"$($perl -pe 's,.*/,,; s,^,\\Q,; s,$,\\E,; $. == 1 || s,^,|,; s,\n,,' $remove)"')'
BASEBASE="${BASE//.html/}"

# remove incomplete chapters, part three: all the remaining links (incl. the toc)

# multipage files: strike out the links to the removed chapters
$perl -pe 's{<a[^<>]* href="'"$BASE"'[^<>"]*"[^<>]*>(.*?)</a>}{<s>$1</s>}g' -i $OUT/*.html

# single-page file:
$PROD &&
$perl -pe '
  # strike out the chapters from the toc
  s{<a[^<>]* href="#'"$BASEBASE"'">(.*?)</a>}{<s>$1</s>}g;
  # strike out the sections of the removed chapters from the toc
  if (/^<li><s>/../^<\/li>/) {
    if (/^<li><a href="#(\w+)"/a) {
      $x{$1} = undef;
    }
    # remove the sections of the removed chapters from the toc
    print if /^<li><s>|^<\/li>/; $_ = "";
  }
  else {
    s{<a href="#([^#"<>]*)">(.*?)</a>}{
      exists $x{$1} ? "<s>$2</s>" : $&
    }ge
  }
' -i progit.html

# remove incomplete chapters, part four: remove their now-inaccessible files from the multipage book
rm -f $(cat "$remove")

fi  # if $PROD

rm -f "$remove"

# combine both single-page & multipage books with an introductory text, and various, minor fixes to both

# move the single-page book to be in $OUT/
$PROD &&
mv -f progit.html $OUT/progit-all.html

# remove the second toc from the multipage home page and add informational text instead.
# and make it the home page, and update all the links to it
{ $perl -ne 'print; exit if /<div id="content">/' $OUT/progit.html
  $perl -ne 'print if /<div class="paragraph nav-footer">/..0' $OUT/progit.html
} |
$perl -pe '
BEGIN { $preintro = do { local $/; open my $f, "-|", "asciidoctor preintro.asc --embedded --out-file=-"; scalar <$f> } }
s{<div id="toctitle">فهرس المحتويات</div>}{<div style="padding:1em"></div>};
s{<p><span class="toc-root toc-current"><a href="progit.html">[^<>]+</a></span></p>(<ul class="sectlevel1">)}
{$preintro$1};
' > $OUT/index.html
rm -f $OUT/progit.html
$perl -pe 's/"progit.html"/"index.html"/g' -i $OUT/*.html

if $PROD; then

# add a link to the home page to the single-page book, in the same shape as the multipage book
$perl -pe '
s{<ul class="sectlevel1">}{<p><span class="toc-root"><a href="index.html">احترف Git</a></span></p>$&}
' -i $OUT/progit-all.html
# fix the header & metadata (authors, revision) of the multipage book pages
REV="$($perl -ne 'print if /"rev/; exit if /"revdate"/' $OUT/progit-all.html)"
$perl -pe '
s{<meta name="author".*}{<meta name="author" content="Scott Chacon, Ben Straub">};
s{<span id="author" class="author">Scott Chacon</span><br>}{$&
<span id="author2" class="author">Ben Straub</span><br>
'"$REV"'};
s{^<span id="author2" class="author">Ben Straub</span><br>\n}{};
' -i $OUT/[^p]*.html

fi  # if $PROD

# fix the <title> of multipage chapters, and make the title say "احترف جت" instead of "احترف Git"
for ch in $OUT/[^pi]*.html $OUT/introduction.html; do
  title="$($perl -ne 'print $1 if /<h2[^<>]*>([^<>]*)</' "$ch")"
  $perl -pe 's/<title>.*</<title>'"$title"' | احترف جت</' -i "$ch"
done

# fix the date of last build, and the favicon
date="$(date --utc -Is)"
date="${date/T/ }"
date="${date/+00:00/ +0000}"
date="2024-08-16 12:00:00 +0000"  # slow down the change in time, to reduce the diffs
dateonly="${date%% *}"
# favicon='<link rel="icon" type="image/png" sizes="72x72" href="res/favicon-72x72.png">'
# favicon="$favicon\n${favicon//72/16}"
favicon='<link rel="icon" type="image/png" sizes="16x16" href="res/fav16.png">'
$perl -pe '
s{^<title>}{'"$favicon"'\n$&};
s{^<span id="revdate">.*?</span>$}
  {<span id="revdate">'"$dateonly"'</span>};
s<^Last updated [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}$>
  <Last updated '"$date"'>;
' -i $OUT/*.html

# enable live-reloading if non-PROD
if $PROD; then
  rm -f $OUT/_
else

for f in $OUT/*.html; do
  printf '%s\n' '<script>(async function () {
    function num_or (val, def) {
      const n = +val
      return isNaN(n) ? def : n
    }
    //
    // https://stackoverflow.com/a/49856524
    function savePos (y) {
      localStorage.setItem("scrollY", num_or(y, window.scrollY))
    }
    function loadPos () {
      window.scrollTo(0, num_or(localStorage.getItem("scrollY"), 0))
      localStorage.setItem("scrollY", 0)
    }
    window.addEventListener("load", loadPos, false)
    window.addEventListener("scroll", savePos, false)
    //
    // https://stackoverflow.com/a/64918704
    async function check_underscore () { return (await fetch("_")).ok }
    let underscore = await check_underscore()
    //
    setInterval(function () {
      check_underscore().then((v) => {
        if (underscore !== v) {
          savePos()
          location.reload()
        }
      })
    }, 5000)
  })()</script>' >> "$f"
done

if [ -e $OUT/_ ]; then
  rm -f $OUT/_
else
  touch $OUT/_
fi

fi  # if $PROD, for live reloading

for i in $OUT/*.html; do
cat <<'END_OF_TEXT' >> "$i"
<script>onbeforeprint = function () {
  document.querySelectorAll('div.imageblock').forEach(blk => {
    blk.outerHTML = '<figure>' + blk.outerHTML + '</figure>'
  })
}</script>
END_OF_TEXT
done


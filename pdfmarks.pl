#!/usr/bin/env perl

# add pdf bookmark (in-viewer table of contents)

# preamble and utils {{{
use v5.16; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use constant PDFMARK_FILE => '_pdfmark';

use Encode qw[ encode ];

sub openfile { my ($mode, $fpath) = @_;
  state $modes = {qw[
    r reading  w writing   a appending
    < reading  > writing  >> appending
    r+ read-writing  w+ write-reading   a+ read-appending
    +< read-writing  +> write-reading  +>> read-appending
  ]};
  # description of modes (adapted from fopen(3) and open(2)):
  #   r  <   := read-only
  #   w  >   := write-only + create + trunc
  #   a  >>  := write-only + create + append
  #   r+ +<  := read+write
  #   w+ +>  := read+write + create + trunc
  #   a+ +>> := read+write + create + append
  # legend:
  #   append := each write() writes to the end of file.
  #   create := the file is created if it doesn't exist.
  #   trunc  := the file is cleared on opening.
  my @caller = caller; my $trace = "at $caller[1] line $caller[2]";
  my $mode_desc = $modes->{$mode =~ s/b//gr};  # binary (b) is irrelevant and ignored on POSIX systems
  defined $mode_desc or die "bad open mode '$mode' for «$fpath», $trace\n";
  open my $f, $mode, $fpath or die "Couldn’t open «$fpath» for $mode_desc: $!, $trace\n";
  return $f;
}

# }}}

# encode_title() & add_pdf_bookmarks() {{{

sub encode_title {  # https://stackoverflow.com/a/72736506
  return $_[0] =~ s/^/\x{FEFF}/r
  =~ s/./join "", map { sprintf "%02X", $_ } unpack "W*", encode("UTF-16BE", $&);/gre
  =~ s/.*/<$&>/r;
}

sub add_pdf_bookmarks { my ($in, $out) = @_;

# acquire page number and viewbox of all named destinations {{{
my %dest;
open my $inmarks, "-|", "extractpdfmark '$in'";
while (<$inmarks>) {
  # example named destination:
    # [ /Dest (heading-name) /Page 10 /View [/XYZ 0 0 0] /DEST pdfmark
  if (m|/Dest \(([^()]+)\) (/Page \S+ /View \[[^\[\]]+\]) /|) {
    $dest{$1} = $2;
  }
}
close $inmarks;
# }}}

# acquire all headings and their titles, ids (named destination), and hierarchy {{{
my @toc;
my $htmlall = openfile "<", "docs/progit-all.html";
while (<$htmlall>) {
  if (/<h([1-6]) id="(\p{ASCII}+)">(.*?)<\/h.>/) {
    my ($n, $i, $t) = ($1, $2, $3); $n -= 2;  # $n = 0 for chapters, 1 for sections, and so on
    next unless exists $dest{$i};
    $t =~ s/<br>(?:&emsp;)?/ /g;
    $t =~ s/(?:(?:[٠-٩]+|أ|ب|ج|د|ه\N{ZERO WIDTH JOINER})،\N{NBSP})+//;
    $t = "\N{RIGHT-TO-LEFT EMBEDDING}$t\N{POP DIRECTIONAL FORMATTING}";
    # printf STDERR "%s\e[2m%s\e[22m %s\n", "\e[30;48;5;240m> \e[m"x$n, $i, $t;
    if ($n == 0) {
      push @toc, [ $i, $t, [] ];
    }
    elsif ($n == 1) {
      push @{$toc[$#toc][2]}, [ $i, $t, [] ];
    }
    # elsif ($n == 2) {
    #   my $sec = $toc[$#toc][2];
    #   push @{$sec->[$#{$sec}][2]}, [ $i, $t, [] ];
    # }
    # subsections and lower are ignored
  }
}
close $htmlall;
# }}}

# # debug: print all @toc {{{
# state $__indent = " "x2 . "\e[2;7m>\e[m ";
# for my $e (@toc) {
#   printf "\e[2m%s\e[22m %s\n", $e->[0], $e->[1];
#   my @c = @{$e->[2]};
#   for my $e (@c) {
#     printf "%s\e[2m%s\e[22m %s\n", $__indent, $e->[0], $e->[1];
#     # my @s = @{$e->[2]};
#     # for my $e (@s) {
#     #   printf "%s\e[2m%s\e[22m %s\n", $__indent x 2, $e->[0], $e->[1];
#     # }
#   }
# }
# # }}}
# exit;

# pdfmarks: output the hierarchy in pdfmark format, with the Page/View instead of a named destination {{{
my $outmarks = openfile ">", PDFMARK_FILE;
#
# show in-viewer toc on opening
printf { $outmarks } "[ /PageMode /UseOutlines /DOCVIEW pdfmark\n";  # not writable with exiftool
#
for my $e (@toc) {
  my @c = @{$e->[2]};
  my $count = @c > 0 ? '/Count '.scalar(@c) : '';
  my $t = encode_title $e->[1];
  printf { $outmarks } "[ /Title $t $dest{$e->[0]} $count /OUT pdfmark\n";
  for my $e (@c) {
    my @s = @{$e->[2]};
    my $count = @s > 0 ? '/Count '.scalar(@s) : '';
    my $t = encode_title $e->[1];
    printf { $outmarks } "[ /Title $t $dest{$e->[0]} $count /OUT pdfmark\n";
    # for my $e (@s) {
    #   my $t = encode_title $e->[1];
    #   printf { $outmarks } "[ /Title $t $dest{$e->[0]} /OUT pdfmark\n";
    # }
  }
}
close $outmarks;
# }}}

# combine that data with the pdf; this command is from extractpdfmark man-page {{{
if (!$out) { die "No output path is given for '$in'\n"; return 1 }
return if 0 != system(qw[ gs -q -dBATCH -dNOPAUSE -sDEVICE=pdfwrite
  -dPDFDontUseFontObjectNum -dPrinted=false ],
  '-sOutputFile='.$out, $in, PDFMARK_FILE);
unlink PDFMARK_FILE;
# }}}

# metadata {{{
# 1. copy original metadata (gs removes some of them)
# 2. remove the metadata added by gs (and by exiftool)
# 3. add document title
return 0 == system("exiftool", "-tagsFromFile", $in,
  "-Title=احترف جت - Pro Git 2 Arabic",  # note: no inner quotes
  "-DocumentID=", "-XMPToolkit=",
  "-overwrite_original", "-quiet", $out);
# }}}

}

# }}}

# main {{{

add_pdf_bookmarks $ARGV[0] => $ARGV[1];
# add_pdf_bookmarks 'a5-.pdf' => 'a5.pdf';
# add_pdf_bookmarks 'a4-.pdf' => 'a4.pdf';

# vim: set foldmethod=marker foldmarker={{{,}}} :

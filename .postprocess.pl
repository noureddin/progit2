#!/usr/bin/env perl
## preamble & intro {{{
## vim: set foldmethod=marker foldmarker={{{,}}} :
use v5.14; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];

# these are defined in their place in a BEGIN block
use vars qw[ %dark_imgs %fixed_illustrations ];

my $outdir = shift;
die "expected a directory as the first argument to $0; given: $outdir\n"
  unless -d $outdir;
$outdir =~ s,/$,,;

my $prod = !!shift;
# 0 (including '0') or '' is false, anything else is true

my %rmbase;  # basenames of chapters/sections to remove if $prod; needed for the single-page book
my %remove;  # same as $rmbase but with ".html" at the end of every key; needed for the multi-page book
sub record_remove { my ($basename) = @_;  # only called from the single-page book
  $rmbase{$basename} = undef;
  $remove{"$basename.html"} = undef;
  if ($basename !~ /^ch[0-9]+-|^[A-E]-/) {
    # a section needs more work to strike-out links to subsections in the single-page book
    open my $fh, '<', "$outdir/$basename.html";
    while (my $ln = <$fh>) {
      if ($ln =~ /<h[4-6] id="([^"ء-ي]+)"/) {
        # if an id contains an Arabic letter, it's not referenced anywhere, thus safe to be ignored
        $rmbase{$1} = undef;
      }
    }
    close $fh;
  }
  unlink "$outdir/$basename.html";
}

# my $preintro = `asciidoctor preintro.asc --embedded --out-file=-`;
my $preintro = do {
  local $/; open my $f, '<', 'preintro.md'; my $h = scalar <$f>;
  join "\n", map {
      /^- /  # a list
      ? qq[<div class="ulist tight">\n<ul class="tight">\n]
        . (join "\n", map s|^- (.*)$|<li>\n<p>$1</p>\n</li>|r, split /\n/)
        . qq[\n</ul>\n</div>]
      : qq[<div class="paragraph">\n<p>$_</p>\n</div>]
    } split /\n\n+|\n*\Z/, $h =~ s|\[(.*?)\]\((.*?)\)|<a href="$2">$1</a>|gr;
} . "\n";

## }}}

my $html_all = "$outdir/progit-all.html";
my $html_idx = "$outdir/index.html";

## arabize chapter/section numbering and dates {{{

sub ar { $_[0] =~ tr[0-9.][٠-٩٫]r }
my @n = qw[ الأول الثاني الثالث الرابع الخامس السادس السابع الثامن التاسع العاشر ];
my %apx = qw{  A أ  B ب  C ج  D د  E ه‍  };  # for appendices; the last arabic letter has ZWJ

sub ardate { ar($_[0] =~ s/([0-9]{4})-([0-9]{2})-([0-9]{2})/$3-$2-$1/gr) =~ s|-|&thinsp;&ndash;&thinsp;|gr }

my $body_link = qr/(?<!<li>)   (?<!Next:\h) (?<!Previous:\h) (?<!Up:\h) /x;
my $fnav_link = qr/(?<!<li>)(?:(?<=Next:\h)|(?<=Previous:\h)|(?<=Up:\h))/;

my %toctitles;
sub fixnavnum {  # called before striking out removed sections
  # add section numbers to all (including the will-be-removed) sections in the nav_footer
  s|:\xa0<a\ href="(\#([^"]+)      )">(.*?)</a>|:\xa0<a href="$1">@{[ $toctitles{$2} // $3 ]}</a>|gx;
  s|:\xa0<a\ href="(  ([^"]+)\.html)">(.*?)</a>|:\xa0<a href="$1">@{[ $toctitles{$2} // $3 ]}</a>|gx;
}

sub ar_chapsectnums {  # modifies $_ in place

  s{( <li><a\ href=[^>]*>(?:<span[^>]*>)?  # toc
    | <h[234]\ id="[^"]+">        # headings in body
    | $fnav_link <a\ href=[^>]*>  # links in nav_footer
    )
    (?: [0-9]+\.                  # chapters (h1)
      | Appendix\s+[A-Z]+:        # appendices
      | [0-9]+\.(?:[0-9]+\.){2,}  # chapter subsections (h3+)
      |  [A-Z]\.(?:[0-9]+\.){2,}  # appendix subsections
    ) \s+
  }{$1}gx;  # remove all prefixed numbers/names; they are added localized next; except for subsections which are unneeded

  # arabize chapter and appendix numbers with words
  # note: chapters are off by one, for the intro.

  # chapters
  s{(<li><a href="#?ch([0-9]{2})-[^"]*">(?:<span[^>]*>)?(?:[➖❌✋⏳✨✅⛲] )?+(?!الباب ال))}
   {$1الباب $n[$2 - 1]: }g;  # toc
  s{(<h2 id="ch([0-9]{2})-[^"]*">(?:[➖❌✋⏳✨✅⛲] )?+)(?!الباب ال)}
   {$1الباب $n[$2 - 1]:<br>}g;  # headings in body
  s{$fnav_link(<a href="#?ch([0-9]{2})-[^"]*">(?:[➖❌✋⏳✨✅⛲] )?+(?!الباب ال))}
   {$1الباب $n[$2 - 1]: }g;  # links in nav_footer
  s{(?<!باب )(?<!: )$body_link(<a href="#?ch([0-9]{2})-[^"#]*">)}
   {باب $1}g;  # links in body: add باب before the link
  # appendices
  s{(<li><a href="#?([A-E])-[^"]*">(?:<span[^>]*>)?(?:[➖❌✋⏳✨✅⛲] )?+(?!الملحق ال))}
   {$1الملحق $n[ord($2) - ord('A')]: }g;  # toc
  s{(<h2 id="([A-E])-[^"]*">(?:[➖❌✋⏳✨✅⛲] )?+(?!الملحق ال))}
   {$1الملحق $n[ord($2) - ord('A')]:<br>}g;  # headings in body
  s{$fnav_link(<a href="#?([A-E])-[^"]*">(?:[➖❌✋⏳✨✅⛲] )?+(?!الملحق ال))}
   {$1الملحق $n[ord($2) - ord('A')]: }g;  # links in nav_footer
  s{(?<!ملحق )$body_link(<a href="#?([A-E])-[^"#]*">)}
   {ملحق $1}g;  # links in body

  # arabize section numbers in h3 and toc (they are not used in the body) and put status icons before the numbers

  # note: Amiri has a huge arabic comma compared to the numbers, and the period is even larger.
  # note: we add a (nonbreakable) space after the arabic comma to fix their direction.

  # chapter sections
  s{(<h. [^>]*>|href=[^>]*><span[^>]*>)([0-9]+)\.([0-9]+)\.\s+((?:[➖❌✋⏳✨✅⛲] )?)}{  # bold, not Amiri -> ok
    "$1$4".(join"\N{ARABIC COMMA}\N{NBSP}",ar($2-1),ar($3),"")
  }ge;
  s{(href=[^>]*>)([0-9]+)\.([0-9]+)\.\s+((?:[➖❌✋⏳✨✅⛲] )?)}{  # not-bold: Amiri -> make comma small
    "$1$4".(join"<small>\N{ARABIC COMMA}</small>\N{NBSP}",ar($2-1),ar($3),"")
  }ge;
  # appendix sections
  s{(<h. [^>]*>|href=[^>]*><span[^>]*>)([A-E]+)\.([0-9]+)\.\s+((?:[➖❌✋⏳✨✅⛲] )?)}{  # bold, not Amiri -> ok
    "$1$4".(join"\N{ARABIC COMMA}\N{NBSP}",$apx{$2},ar($3),"")
  }ge;
  s{(href=[^>]*>)([A-E]+)\.([0-9]+)\.\s+((?:[➖❌✋⏳✨✅⛲] )?)}{  # not-bold: Amiri -> make comma small
    "$1$4".(join"<small>\N{ARABIC COMMA}</small>\N{NBSP}",$apx{$2},ar($3),"")
  }ge;

}

## }}}

## favicons & fixme & status_style {{{

my $fixme = $prod ? '' : <<'END_OF_HTML' =~ s/\A\s+|\s+\Z|\h*\n\h*//gr;
  <span style="position:absolute; right:-1em;color:red">
    <sup style="margin-right:-1em; font-weight:bold; font-family:mono !important">FIX</sup>
    <sub style="font-weight:bold; font-family:mono !important">ME</sub>
  </span>
END_OF_HTML

my $favicons = <<'END_OF_HTML' =~ s/^ +//mgr;
  <link rel="icon" type="image/png" sizes="72x72" href="res/fav72.png">
  <link rel="icon" type="image/png" sizes="32x32" href="res/fav32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="res/fav16.png">
  <link rel="icon" type="image/svg+xml" sizes="any" href="res/fav.svg">
  <!-- favicon is based on Git Logo by Jason Long (CC-BY 3.0); https://git-scm.com/downloads/logos -->
END_OF_HTML

my $status_style = $prod ? '' : '<style>h2, h3 { margin-right: -1.25em; text-indent: 1.25em hanging }</style>';

## }}}

## corresponding English pages {{{

my %augmented_src_of = (  # English pages that are split in Arabic (chapter intros, and chapter-like sections)
  # chapter intros
  "ch01-getting-started" => "Getting-Started-About-Version-Control",
  "ch02-git-basics-chapter" => "Git-Basics-Getting-a-Git-Repository",
  "ch03-git-branching" => "Git-Branching-Branches-in-a-Nutshell",
  "ch04-git-on-the-server" => "Git-on-the-Server-The-Protocols",
  "ch05-distributed-git" => "Distributed-Git-Distributed-Workflows",
  "ch06-github" => "GitHub-Account-Setup-and-Configuration",
  "ch07-git-tools" => "Git-Tools-Revision-Selection",
  "ch08-customizing-git" => "Customizing-Git-Git-Configuration",
  "ch09-git-and-other-systems" => "Git-and-Other-Systems-Git-as-a-Client",
  "ch10-git-internals" => "Git-Internals-Plumbing-and-Porcelain",
  "A-git-in-other-environments" => "Appendix-A:-Git-in-Other-Environments-Graphical-Interfaces",
  "B-embedding-git-in-your-applications" => "Appendix-B:-Embedding-Git-in-your-Applications-Command-line-Git",
  "C-git-commands" => "Appendix-C:-Git-Commands-Setup-and-Config",
  # Ch5: Distributed-Git > Contributing-to-a-Project augmentation
    "contributing_project" => "Distributed-Git-Contributing-to-a-Project",
    (map { $_ => s|^|Distributed-Git-Contributing-to-a-Project#|r }
      qw[ commit_guidelines private_team private_managed_team public_project project_over_email summary-contrib ]),
  # Ch5: Distributed-Git > Maintaining-a-Project augmentation
    "maintaining-project-intro" => "Distributed-Git-Maintaining-a-Project",
    (map { $_ => s|^|Distributed-Git-Maintaining-a-Project#|r }
      qw[ patches_from_email checking_out_remotes what_is_introduced ]),
    "maintaining-project-integrating" => "Distributed-Git-Maintaining-a-Project#integrating_contributed_work",
    "maintaining-project-releasing" => "Distributed-Git-Maintaining-a-Project#tagging_releases",
  #
  # "chapter-like sections" are too big to keep on a single page,
  #   and their subsections are more-or-less standalone.
  # `bash .we t file.asc` shows how many translatable words (except code, links, index entries)
  #   in the file (regradless of whether translated or not); full code producing the candidate list:
  #  `for f in book/*/*/*.asc; do w=$(bash .we t $f); if [ $w -gt 3000 ]; then echo $w $f; fi; done | sort -nr`)
  # strong candidates (larger first), with their state of translation:
  #   4694 book/05-distributed-git/sections/contributing.asc (DONE)
  #   4124 book/06-github/sections/2-contributing.asc (STARTED)
  #   4046 book/05-distributed-git/sections/maintaining.asc (DONE)
  #   3900 book/07-git-tools/sections/submodules.asc
  # weak candidates:
  #   3378 book/06-github/sections/3-maintaining.asc (STARTED)
  #   3154 book/07-git-tools/sections/advanced-merging.asc
  #   3134 book/09-git-and-other-scms/sections/client-p4.asc
);

my %exact_src_of = (
  # ch01
  "about-vc" => "Getting-Started-About-Version-Control",
  "git-history" => "Getting-Started-A-Short-History-of-Git",
  "what_is_git_section" => "Getting-Started-What-is-Git%3F",
  "git-cmdline" => "Getting-Started-The-Command-Line",
  "installing-git" => "Getting-Started-Installing-Git",
  "first_time" => "Getting-Started-First-Time-Git-Setup",
  "git_help" => "Getting-Started-Getting-Help",
  "summary-01" => "Getting-Started-Summary",
  # ch02
  "getting_a_repo" => "Git-Basics-Getting-a-Git-Repository",
  "recording-changes" => "Git-Basics-Recording-Changes-to-the-Repository",
  "viewing_history" => "Git-Basics-Viewing-the-Commit-History",
  "undoing" => "Git-Basics-Undoing-Things",
  "remote_repos" => "Git-Basics-Working-with-Remotes",
  "git_tagging" => "Git-Basics-Tagging",
  "git_aliases" => "Git-Basics-Git-Aliases",
  "summary-02" => "Git-Basics-Summary",
  # ch03
  "git_branches_overview" => "Git-Branching-Branches-in-a-Nutshell",
  "basic-branching-merging" => "Git-Branching-Basic-Branching-and-Merging",
  "branch_management" => "Git-Branching-Branch-Management",
  "branching-workflows" => "Git-Branching-Branching-Workflows",
  "remote_branches" => "Git-Branching-Remote-Branches",
  "rebasing" => "Git-Branching-Rebasing",
  "summary-03" => "Git-Branching-Summary",
  # ch04
  "protocols" => "Git-on-the-Server-The-Protocols",
  "getting_git_on_a_server" => "Git-on-the-Server-Getting-Git-on-a-Server",
  "generate_ssh_key" => "Git-on-the-Server-Generating-Your-SSH-Public-Key",
  "setting_up_server" => "Git-on-the-Server-Setting-Up-the-Server",
  "git-daemon" => "Git-on-the-Server-Git-Daemon",
  "smart-http" => "Git-on-the-Server-Smart-HTTP",
  "gitweb-section" => "Git-on-the-Server-GitWeb",
  "gitlab" => "Git-on-the-Server-GitLab",
  "hosted-git" => "Git-on-the-Server-Third-Party-Hosted-Options",
  "summary-04" => "Git-on-the-Server-Summary",
  # ch05
  "distributed-workflows" => "Distributed-Git-Distributed-Workflows",
  # "contributing_project" => "Distributed-Git-Contributing-to-a-Project",  # NOTE: augmented
  # "maintaining-project" => "Distributed-Git-Maintaining-a-Project",  # NOTE: augmented
  "summary-05" => "Distributed-Git-Summary",
  # ch06
  "github-account" => "GitHub-Account-Setup-and-Configuration",
  "github-contrib" => "GitHub-Contributing-to-a-Project",
  "maintaining_gh_project" => "GitHub-Maintaining-a-Project",
  "ch06-github_orgs" => "GitHub-Managing-an-organization",
  "github-scripting" => "GitHub-Scripting-GitHub",
  "summary-06" => "GitHub-Summary",
  # ch07
  "revision_selection" => "Git-Tools-Revision-Selection",
  "interactive_staging" => "Git-Tools-Interactive-Staging",
  "git_stashing" => "Git-Tools-Stashing-and-Cleaning",
  "signing" => "Git-Tools-Signing-Your-Work",
  "searching" => "Git-Tools-Searching",
  "rewriting_history" => "Git-Tools-Rewriting-History",
  "git_reset" => "Git-Tools-Reset-Demystified",
  "advanced_merging" => "Git-Tools-Advanced-Merging",
  "ref_rerere" => "Git-Tools-Rerere",
  "debugging-with-git" => "Git-Tools-Debugging-with-Git",
  "git_submodules" => "Git-Tools-Submodules",
  "bundling" => "Git-Tools-Bundling",
  "replace" => "Git-Tools-Replace",
  "credential_caching" => "Git-Tools-Credential-Storage",
  "summary-07" => "Git-Tools-Summary",
  # ch08
  "git_config" => "Customizing-Git-Git-Configuration",
  "git-attributes" => "Customizing-Git-Git-Attributes",
  "git_hooks" => "Customizing-Git-Git-Hooks",
  "an_example_git_enforced_policy" => "Customizing-Git-An-Example-Git-Enforced-Policy",
  "summary-08" => "Customizing-Git-Summary",
  # ch09
  "git-as-client" => "Git-and-Other-Systems-Git-as-a-Client",
  "migrating" => "Git-and-Other-Systems-Migrating-to-Git",
  "summary-09" => "Git-and-Other-Systems-Summary",
  # ch10
  "plumbing_porcelain" => "Git-Internals-Plumbing-and-Porcelain",
  "objects" => "Git-Internals-Git-Objects",
  "git_refs" => "Git-Internals-Git-References",
  "packfiles" => "Git-Internals-Packfiles",
  "refspec" => "Git-Internals-The-Refspec",
  "transfer-protocols" => "Git-Internals-Transfer-Protocols",
  "maintenance-recovery" => "Git-Internals-Maintenance-and-Data-Recovery",
  "envvars" => "Git-Internals-Environment-Variables",
  "summary-10" => "Git-Internals-Summary",
  # apA
  "guis" => "Appendix-A:-Git-in-Other-Environments-Graphical-Interfaces",
  "git-vs" => "Appendix-A:-Git-in-Other-Environments-Git-in-Visual-Studio",
  "git-vscode" => "Appendix-A:-Git-in-Other-Environments-Git-in-Visual-Studio-Code",
  "git-jetbrains" => "Appendix-A:-Git-in-Other-Environments-Git-in-IntelliJ-/-PyCharm-/-WebStorm-/-PhpStorm-/-RubyMine",
  "git-sublime" => "Appendix-A:-Git-in-Other-Environments-Git-in-Sublime-Text",
  "git-bash" => "Appendix-A:-Git-in-Other-Environments-Git-in-Bash",
  "git-zsh" => "Appendix-A:-Git-in-Other-Environments-Git-in-Zsh",
  "git_powershell" => "Appendix-A:-Git-in-Other-Environments-Git-in-PowerShell",
  "summary-A" => "Appendix-A:-Git-in-Other-Environments-Summary",
  # apB
  "git-cli" => "Appendix-B:-Embedding-Git-in-your-Applications-Command-line-Git",
  "libgit2" => "Appendix-B:-Embedding-Git-in-your-Applications-Libgit2",
  "jgit" => "Appendix-B:-Embedding-Git-in-your-Applications-JGit",
  "go-git" => "Appendix-B:-Embedding-Git-in-your-Applications-go-git",
  "dulwich" => "Appendix-B:-Embedding-Git-in-your-Applications-Dulwich",
  # apC
  "commands-setup-config" => "Appendix-C:-Git-Commands-Setup-and-Config",
  "commands-getting-creating-projects" => "Appendix-C:-Git-Commands-Getting-and-Creating-Projects",
  "commands-basic-snapshotting" => "Appendix-C:-Git-Commands-Basic-Snapshotting",
  "commands-branching-merging" => "Appendix-C:-Git-Commands-Branching-and-Merging",
  "commands-sharing-updating-projects" => "Appendix-C:-Git-Commands-Sharing-and-Updating-Projects",
  "commands-inspection-comparison" => "Appendix-C:-Git-Commands-Inspection-and-Comparison",
  "commands-debugging" => "Appendix-C:-Git-Commands-Debugging",
  "commands-patching" => "Appendix-C:-Git-Commands-Patching",
  "commands-email" => "Appendix-C:-Git-Commands-Email",
  "commands-external-systems" => "Appendix-C:-Git-Commands-External-Systems",
  "commands-administration" => "Appendix-C:-Git-Commands-Administration",
  "commmands-plumbing" => "Appendix-C:-Git-Commands-Plumbing-Commands",
);

use constant EN_SRC_BGN => qq[<p>⊕\xa0<span class="english-source"><a href="https://git-scm.com/book/en/v2/];
use constant EN_SRC_SAM => '">الأصل الإنجليزي</a>';  # if the English page has the same content
use constant EN_SRC_MOR => EN_SRC_SAM . ' (بزيادة موجودة في صفحات عربية أخرى)';  # if the English page has more content
use constant EN_SRC_END => '</span></p>';

sub english_source { my ($basename) = @_;
  return EN_SRC_BGN .     $exact_src_of{$basename} . EN_SRC_SAM . EN_SRC_END if exists     $exact_src_of{$basename};
  return EN_SRC_BGN . $augmented_src_of{$basename} . EN_SRC_MOR . EN_SRC_END if exists $augmented_src_of{$basename};
  return ""  # if has no corresponding page
}

## }}}

## improve printing; enable live-reloading if non-prod {{{
# trigger updating the page at the end of the processing
END {
  if ($prod) { unlink "$outdir/_" }
  else {
    if (-e "$outdir/_") { unlink "$outdir/_" }
    else { open my $fp, '>', "$outdir/_" }  # equiv to touch; auto-closes
  }
}

my $javascript = $prod ? '' : <<'END_OF_JAVASCRIPT' =~ s/^  //mgr;  # live-reloading
  (async function () {
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
  })()
END_OF_JAVASCRIPT

$javascript .= <<'END_OF_JAVASCRIPT' =~ s/\n\Z//r =~ s/^  //mgr;  # improve printing
  onbeforeprint = function () {

    // https://css-tricks.com/better-line-breaks-for-long-urls/
    const format_url = function (url) {  // Insert line break opportunities into a URL
      // Split the URL into an array to distinguish double slashes from single slashes
      // And format the strings on either side of double slashes separately
      return url.split('//').map(str =>
        // Insert a word break opportunity after a colon
        str.replace(/(?<after>:)/giu, '$1<wbr>')
          // Before a single slash, tilde, period, comma, hyphen, underline, question mark, number sign, or percent symbol
          .replace(/(?<before>[/~.,\-_?#%])/giu, '<wbr>$1')
          // Before and after an equals sign or ampersand
          .replace(/(?<beforeAndAfter>[=&])/giu, '<wbr>$1<wbr>')
        // Reconnect the strings with word break opportunities after double slashes
        ).join('//<wbr>')
    }

    document.querySelectorAll('a[href]').forEach(a => {
      const href = a.getAttribute('href')
      if (!href.startsWith('#')      // not an internal link in the single-page book
        && href.indexOf('/') !== -1  // not an internal link in the multi-page book
        && href !== a.innerHTML      // not an (external) literal link
      ) {
        const h = document.createElement('span')
        h.className = 'href'
        h.innerHTML = ' \u27e8الرابط: <span dir="ltr">' + format_url(href) + '</span>\u27e9'
        a.appendChild(h)
      }
      else if (href === a.innerHTML) {
        a.innerHTML = format_url(href)  // to allow line breaks (this probably should be allowed on the web too?)
      }
    })

    document.querySelectorAll('div.imageblock').forEach(blk => {
      blk.outerHTML = '<figure>' + blk.outerHTML + '</figure>'
    })

    document.querySelector('.toc-root').innerHTML = '<b>احترف جت</b>'  // remove '(البوابة)', and make it just a (bold) title, not a link
  }

  onafterprint = function () {  // undo most of what we did in onbeforeprint, so the reader can continue reading the Web page after printing

    document.querySelectorAll('a[href] > span.href').forEach(h => h.remove())
    document.querySelectorAll('a[href]').forEach(a => { if (a.innerHTML.match(/<wbr>/)) { a.innerHTML = a.innerHTML.replace(/<wbr>/g, '') } })

    // // probably this is fine?
    // document.querySelectorAll('div.imageblock').forEach(blk => {
    //   blk.outerHTML = '<figure>' + blk.outerHTML + '</figure>'
    // })

    document.querySelector('.toc-root').innerHTML = '<a href="index.html">احترف جت (البوابة)</a>'
  }

END_OF_JAVASCRIPT

## }}}

## process the singlepage book (if $prod)  {{{
# copy the author & revision details and the entire 2-level toc
# and remove the incomplete chapters and sections
my @TOC;
my $ALLTOC;
my $REV;
my %chaptitles;
if ($prod) {
  my $all;
  my $ignore = 0;  # for toc
  my $needed = 1;  # for body
  my $wantch = 0;  # like $needed but for chapters only
  my ($ch, $sec);  # number the sections in alltoc
  my ($thissec, $subsec);  # re-introduce subsection numbers (currently in progit-all.html only)
  my %secnum;
  open my $fh, '<', $html_all;
  while (<$fh>) {
    if (/<div class="details">/../<\/div>/) {
      if (!m|</?div|) {
        s/<span id="author"/المؤلفان:&nbsp;$&/;
        s/version ([0-9.]+),/"الإصدارة: ".ar($1)." &ndash;"/e;
        s/<span id="revdate">.*/"بتاريخ:&nbsp;".ardate($&)."."/e;
        $REV .= $_;
      }
    }
    if (/<ul class="sectlevel1">/../<\/div>/) {
      if ($ignore && /<ul class="sectlevel2"/../<\/ul>/) {  # ignore the entire chapter
        if (/<a href="#([^"]+)">/) {
          record_remove($1);
          # link the next "Previous" link in the nav_footer to the chapter (not its last section)
          $toctitles{$1} = $chaptitles{$ch};
        }
        next;
      }
      if (/<a href="#([^"]+)">/) {
        my $url = $1;
        #
        # number the sections
        my $is_chapter = $url =~ /^(?:ch([0-9]+)|([A-E]))-/;
        if ($is_chapter) {
          $sec = 0;
          $ch = $1 // $2;
          if ($ch =~ /[0-9]/) { $ch += 1 }  # a workaround for a workaround '^_^
        }
        else {
          ++$sec;
        }
        if (defined $ch && $sec != 0) {
          $secnum{$url} = "$ch.$sec.";
          s/">/">$secnum{$url} /;
        }
        ar_chapsectnums;  # modifies $_ in place
        my ($title) = m|">(.*?)</a|;
        $title =~ s/[➖❌✋⏳✨✅⛲] //g;
        $toctitles{$url} = $title;  # needed to fix the nav_footer numbers in links
        $chaptitles{$ch} = $title if defined $ch && $sec == 0;  # needed for nav_footer for the next page if the entire chapter is removed
        #
        if ($is_chapter) {
          if (($ignore = /[➖❌✋]/ || /^[^➖❌✋⏳✨✅⛲]+$/)) {  # an incomplete chapter (or no status icon at all)
            record_remove($url)
          }
        }
        elsif (($ignore = /[➖❌⏳✋]/ || /^[^➖❌✋⏳✨✅⛲]+$/)) {  # an incomplete section (or no status icon at all)
          record_remove($url)
        }
        s/[➖❌✋⏳✨✅⛲] //g;  # remove all status icons from the toc
        s{<a.*?</a>}{<s>$title</s>}g if $ignore;
        #
        push @TOC, [$url, $title] if /<a/;  # not removed
      }
      $ALLTOC .= s/href="#([^"]*)"/href="$1.html"/r
        unless /<\/div>/;
    }
    if (/<h([23]) id="([^"]+)">/) {
      $needed = !exists $rmbase{$2};
      $wantch = $needed if $1 eq '2';  # a chapter
    }
    if ($needed) {
      s/[➖❌✋⏳✨✅⛲] //g;  # remove all status icons
      # add section numbers
      if (/<h3 id="([^"]+)">/ && exists $secnum{$1}) {
        my $id = $1;
        s/">/">$secnum{$id} /;
      }
      # arabize headings and links
      ar_chapsectnums;  # modifies $_ in place
      # re-introduce subsection numbers
      if (/<h3/) {
        $subsec = 0;
        ($thissec) = /">([٠-٩أبجده]+\N{ZWJ}?\N{ARABIC COMMA}\xa0[٠-٩]+\N{ARABIC COMMA}\xa0)/;
      }
      if (/<h4/) {
        ++$subsec;
        s/(">)/$1$thissec@{[ ar($subsec) ]}\N{ARABIC COMMA}\xa0/;  # add subsection numbers
      }
      # strike out removed links
      s{<a href="#([^"]+)">(.*?)</a>}{ exists $rmbase{$1} ? "<s>$2</s>" : $& }ge;
      #
      $all .= $_;
    }
    elsif ($wantch && /<h3/) {  # a removed section in a non-removed chapter
      s/[➖❌✋⏳✨✅⛲] //g;  # remove all status icons
      # add section numbers
      if (/<h3 id="([^"]+)">/ && exists $secnum{$1}) {
        my $id = $1;
        s/">/">$secnum{$id} /;
      }
      # arabize headings and links
      ar_chapsectnums;  # modifies $_ in place
      #
      m|(<h3[^>]*>)(.*?)(</h3>)|;
      $all .= qq[$1<s class="rmhead">$2</s>$3\n</div>\n<div class="sect2">\n];
      # notice: last section (summary) always exists in a non-removed chapter
    }
  }
  open $fh, '>', $html_all;
  print { $fh } $all;
  close $fh;
}  ## }}}

sub find_prev_page { return find_next_page($_[0], 1) }
sub find_next_page { my ($start, $wantprev) = @_;
  my $found;
  for my $t ($wantprev ? reverse @TOC : @TOC) {
    my ($basename, $title) = @$t;
    if ($basename eq $start) { $found = 1 }
    elsif ($found && -e "$outdir/$basename.html") {
      return qq[<a href="$basename.html">$title</a>];
    }
  }
  die "couldn't find a non-removed page ".($wantprev ? "before" : "after").": $start\n";
}

##############################################################

for my $fpath (<$outdir/*.html>) {
  open my $fh, '<', $fpath;
  my $buf = '';
  my $title = '';

  ############################################################

  # maintaining state between lines
  my $nav_footer;
  my $HiLi;
  my $Style;
  my $toc;
  my $idx_toc;
  my $idx_details;
  my $chaptoc;

  my $chapidx = $fpath =~ m,/ch[0-9]|/[A-E]|/frontmatter,;
  my %statuses;

  while (<$fh>) {

    s/(<h3 [^<>]*>.*?)(—.*)/$1<br>&emsp;$2/;  # sections of the chapter-like sections

    if ($chapidx && /<div class="ulist">/) {
      s/">/ chaptoc">/;
      $chaptoc = 1;  # list of sections inside this chapter, after its intro
    }
    if ($chaptoc && m|<ul>|)  { s|<ul>|<ol>| }
    if ($chaptoc && m|</ul>|) { s|</ul>|</ol>|; $chaptoc = 0 }

    s/"progit.html"/"index.html"/g;  # update all the links to the homepage
    s/(?<=\Q<a href="index.html">\E)احترف Git(?=\Q<\E)/احترف جت/;

    if (!$prod && $chapidx && /<li><a href="([^"]+)">/) {
      my $url = $1;
      if (/([➖❌✋⏳✨✅⛲])/) {
        my $status = $1;
        if ($url !~ /^ch[0-9]+-|^[A-E]-|^frontmatter/) {
          $statuses{$url} = $status;
        }
      }
      else {
        s/">\S+ /$&➖ /;
      }
    }

    if ($prod) {
      s/[➖❌✋⏳✨✅⛲] //g;  # remove all status icons
    }
    else {
      s/(?<!<li>)(<a [^<>]*>)[➖❌✋⏳✨✅⛲] /$1/g;  # remove all status icons except in headings or in toc
      if ($chaptoc) {  # add status icon to the chaptoc
        s|<a href="([^"]+)">|$&@{[ $statuses{$1} // '➖' ]} |;
      }
    }

    ar_chapsectnums;  # modifies $_ in place

    s|^<html lang="en">|<html lang="ar" dir="rtl">|;

    fixnavnum;  # add section numbers; modifies $_ in place

    # strike out the links to the removed chapters and sections
    s{<a href="([^"#]+)(?:#[^"]+)?">(.*?)</a>}{ exists $remove{$1} ? "<s>$2</s>" : $& }ge;

    ## curly double-quotes
    s/&#8220;/\N{LEFT-TO-RIGHT EMBEDDING}$&/g; s/&#8221;/$&\N{POP DIRECTIONAL FORMATTING}/g;
    ## {عر} and {نه} inside code
    s/\{عر\}/&#x202b;/g;
    s/\{نه\}/&#x202c;/g;
    ## mark Arabic quotes as Arabic when they are preceded by English; does not work
    # s|(</code>(?:</a>)?)(»)|$1&#x61C;$2|g;
    # s|([A-Za-z](?:<[^<>]+>)*)([»«])|$1&#x61c;$2|g;

    s| *FIXME|$fixme|g;

    if (m|<pre class="highlight">|) { $HiLi = 1 }
    if (m|</pre>|) { $HiLi = 0 }
    if ($HiLi) { s@(?<!#)##(#[^#].*?)(?=<|$)@<span class="comment-in-code">$1</span>@g }

    if (m|rel="stylesheet"|) { $_ = "" }
    if (m|<style>|) { $Style = 1 }
    if (m|</style>|) { $Style = 0; $_ = "" }
    if ($Style) { $_ = "" }
    if (m|</head>|) {
      $_ = qq|<link rel=stylesheet type=text/css href="res/style.css">\n</head>\n|;
    }

    ## enclose body in a div, for background
    if (m|<body|)   { $_ .= qq|<div id="body">$status_style\n| }
    if (m|</body>|) { $_ = qq|</div>\n</body>| }

    s{(?=</body>)}{<script>$javascript</script>};

    s{(?=^<title>)}{$favicons};

    ## get the title, and wrap the multipage toc in <details>/<summary> {{{
    $toc //= "start";
    if ($fpath ne $html_idx && $fpath ne $html_all) {
      if ($toc eq "start" && s|<div id="toc" class="toc">|$&<details>|) { $toc = "inside" }
      if ($toc eq "inside") { s|<div id="toctitle">.*|<summary>$&</summary>| }
      if ($toc eq "inside" && m|</ul>|) { $toc = "almostend" }
      if ($toc eq "almostend" && m|</div>|) { s|</div>|</details>\n$&|; $toc = "end" }
      ##
      # find the first heading, and remove status icons, chapter (word) numbers, and section numbers
      if ($title eq '' && m{
        <h[23][^>]*> (?:[➖❌✋⏳✨✅⛲]\h+)?
        (?: الباب \h+ \w+: <br> | الملحق \h+ \w+: <br>
          | [٠-٩أبجده]+ \N{ZWJ}? \N{ARABIC COMMA} \xa0
                 [٠-٩]+          \N{ARABIC COMMA} \xa0 
        )? \s* (.*?) </h
      }x) {
        # remove arabic vowel marks & escape slashes & unbreak the lines of chapter-like sections' sections
        $title = $1 =~ s,/,\\/,gr =~ s/[\x{64b}-\x{652}]//gr =~ s/<br>&emsp;/ /gr;
      }
    }  ## }}}

    ## arabize figure and table names and numbers {{{
    if (/(.* class="title">)(Figure|Table) (\d+)[.] (.*)/) {
      my ($before, $type, $n, $after) = ($1, $2, $3, $4);
      $type = $type eq "Figure"? "شكل" : $type eq "Table"? "جدول" : next;
      $_ = "$before$type\N{NARROW NO-BREAK SPACE}" . ar($n) . ". $after";
    }  # }}}

    ## nav_footer: multipage navigation {{{
    if (m|<div class="paragraph nav-footer">|) {
      $nav_footer = 1;
    }
    if (m|</div>|) { $nav_footer = 0 }
    if ($nav_footer && m|<p>|) {
      my ($basename) = $fpath =~ m,$outdir/(.*)\.html,;
      # I can use multipage-nav-*-label attributes to change these,
      # but I would still need to reverse the arrows, so why bother.
      # I also split them into lines, and link to the corresponding English section.
      # and... I actually re-structure it a bit -- it's a slipperly slope; once you can, you don't stop tweaking.
      s/Previous:/السابق:/g;
      s/Next:/التالي:/g;
      # skip crossed out pages if $prod (thus @TOC is filled)
      s{(التالي:\h)(<s>.*?</s>)}{ "<strong>$1</strong><small>$2</small>&emsp;".find_next_page($basename) }e;
      s{(السابق:\h)(<s>.*?</s>)}{ "<strong>$1</strong><small>$2</small>&emsp;".find_prev_page($basename) }e;
      s{(?<!>)التالي:\h}{<strong>$&</strong>};
      s{(?<!>)السابق:\h}{<strong>$&</strong>};
      # enforce the presence of "⌂ Home" on all pages, and remove "↑ Up: [Homepage]" on chapter pages
      # remove prefix name (but not the prefix icon) on the Home & Up links
      s/(?:↑\xa0Up:|⌂\xa0Home:)\xa0<a href="index.html">.*?</⌂\xa0<a href="index.html"><strong>البوابة<\/strong></g;
      s/Up:\xa0//g;  # the chapters/appendices has a prefix name
      # swap arrows
      s/←/\0/g;
      s/→/←/g;
      s/\0/→/g;
      # split into lines
      s/\xa0[|] /<\/p>\n<p>/g;
      # add the corresponding English page, if exists
      s|(?=<p><strong>التالي:\h)|english_source($basename)|e;
    }
    ## }}}

    s|<div id="toctitle">Table of Contents</div>|<div id="toctitle">فهرس المحتويات</div>|g;

    ## adjust images for darkmode: {{{
    ## 1. most images are illustrations (have their svg alongside the png)
    ## 2. most other images are bright screenshots
    ##    both of these kinds are basically inverted while keeping the hue
    ## 3. a few screenshot images are dark enough to not need inverting,
    ##    or inverting will make them look bad. these are the %dark_imgs.
    ##    they may contain illustrations too (eg, lr-branches-2).
    BEGIN { our %dark_imgs = map { +"images/$_.png" => undef } qw[
      lr-branches-2
      signup
      avatar-crop
      git-diff-check
      git-fusion-boot
      jb
      git-bash
      zsh-prompt-trimmed
      zsh-oh-my
      posh-git
    ]; our %fixed_illustrations = map { +"images/$_.png" => undef } qw[
      advance-master-fixed
    ] }
    s{<img src="([^"]*)"}{
      my $src = $1;
      exists $dark_imgs{$src}
        ? qq[<img class="_dark" src="$src"]
      : exists $fixed_illustrations{$src} || -e ($src =~ s/\.png$/.svg/r)  # is an illustration
        ? qq[<img src="$src"]
        : qq[<img class="_bright" src="$src"]
    }ge;
    ## }}}

    ## fix author & rev metadata {{{
    s{<meta name="author".*}{<meta name="author" content="Scott Chacon, Ben Straub">};

    s<^(Last updated [0-9]{4}-[0-9]{2}-[0-9]{2}) [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}$>
      <$1 12:00:00 +0000>;

    if ($REV && $fpath ne $html_all) {
      if (!defined $idx_details) {
        $idx_details = 'before';
      }
      elsif ($idx_details eq 'before' && /<div class="details">/) {
        $_ .= $REV;
        $idx_details = 'inside';
      }
      elsif ($idx_details eq 'inside') {
        if (m|</div>|) {
          $idx_details = 'after';
        }
        else {
          $_ = '';
        }
      }
    }
    ## }}}

    ## copy the entire 2-level toc from the single page into the homepage {{{
    if ($ALLTOC && $fpath eq $html_idx) {
      if (!defined $idx_toc) {
        $idx_toc = 'before';
      }
      elsif ($idx_toc eq 'before' && /<ul class="sectlevel1">/) {
        $_ = $ALLTOC;
        $idx_toc = 'inside';
      }
      elsif ($idx_toc eq 'inside') {
        if (/<\/div>/) {
          $idx_toc = 'after';
        }
        else {
          $_ = '';
        }
      }
    }  # }}}

    ## remove the second toc from the homepage and add informational text instead {{{
    if ($fpath eq $html_idx) {
      next  # remove what's inside but not the delimiter lines themselves
        if (/<div id="content">/ ..  /<div class="paragraph nav-footer">/)
        && !/<div id="content">/ && !/<div class="paragraph nav-footer">/;
      #
      s|(<div class="paragraph nav-footer")(>)|$1 style="border:none"$2|;  # remove the added border-top
      #
      s{<div id="toctitle">.*?</div>\n}{};
      s{<div id="toc" class="toc">}{<div style="padding:1em"></div>\n$preintro$&};
      # add homepage as the current page in toc;
      # needed only for the homepage (others have it),
      # and needed only in prod (b/c the toc is copied from the singlepage book, which doesn't have it)
      s{^(?=<ul class="sectlevel1">)}
       {<p><span class="toc-root toc-current"><a href="index.html">احترف جت</a></span></p>};
    }  ## }}}

    ## homepage link in toc {{{
    if ($fpath eq $html_all) {
      # add a link to the homepage to the single-page book, in the same shape as the multipage book
      # with the word "homepage" added in arabic, to distinguish it.
      s{(?=<ul class="sectlevel1">)}
       {<p><span class="toc-root"><a href="index.html">احترف جت (البوابة)</a></span></p>\n};
    }
    else {
      ## reduce margin-bottom of the homepage in toc in all pages except in the progit-all page
      s/(<p)(><span class="toc-root)/$1 class="toc-root-para"$2/;
    }
    ## }}}

    # slow down the diffs and arabize the version/update lines
    s/(<span id="revdate">).*?(<\/span>)/$1.ardate('2025-10-24').".$2"/e;
    # s/^Last updated [0-9]{4}-[0-9]{2}-[0-9]{2} 12:00:00 \+0000$/Last updated 2025-10-24 12:00:00 +0000/;
    s/^Last updated [0-9]{4}-[0-9]{2}-[0-9]{2} 12:00:00 \+0000$/"آخر تحديث: ٢٤-١٠-٢٠٢٥" =~ s|-|&thinsp;&ndash;&thinsp;|gr/e;

    if ($fpath eq $html_all) {
      # add an <hr> before section headings (sect2) in docs/progit-all.html
      # except for the very first one (the pseudo-chapter that contains the prefaces & intro).
      state $first_sect_is_seen = 0;
      if (m|^<div class="sect2">$|) {
        if (!$first_sect_is_seen) {
          $first_sect_is_seen = 1;
        }
        else {
          $_ = qq[<hr class="hrsect2">\n$_];
        }
      }
    }

    $buf .= $_;
  }
  open $fh, '>', $fpath;
  $title = $title . ($title ? ' | ' : '') . 'احترف جت';  # instead of "احترف Git"
  $buf =~ s{(?<=<title>).*(?=</title>)}{$title};
  print { $fh } $buf, "\n";
  close $fh;
}


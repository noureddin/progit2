#!/usr/bin/env python3
# vim: foldmethod=marker foldmarker={{{,}}}

import re
import os
import sys
import shutil
import subprocess

from PyQt5.QtGui import *
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *

class Stats:

    @classmethod
    def arabic_words(cls, filename):
        return subprocess.getoutput(f"bash .we a {filename}")

    @classmethod
    def translatable_words(cls, filename):
        return subprocess.getoutput(f"bash .we t {filename}")

    FILENAME_TO_GLOB_RE = re.compile(r' book/ ([^-]+) -[^/]+ /sections/ (.*) ', re.X)

    @classmethod
    def short_filename(cls, filename):
        """Coverts the long filename to a glob that expands only that file."""
        if '/sections' not in filename:  # already short enough
            return filename
        else:
            (ch, sec) = cls.FILENAME_TO_GLOB_RE.search(filename).groups()
            return f'book/{ch}-*/*/{sec}'


def Regex(r):
    return QRegularExpression(r, QRegularExpression.MultilineOption
                               | QRegularExpression.ExtendedPatternSyntaxOption
                               | QRegularExpression.UseUnicodePropertiesOption)

EDITOR_FONT_FAMILY = 'Noto Sans Mono, Noto Sans Arabic'
# EDITOR_FONT_FAMILY = 'Source Code Pro, Kawkab Mono'
# EDITOR_FONT_FAMILY = 'Comic Mono'
EDITOR_FONT_SIZE_VALUE = 16
EDITOR_FONT_SIZE_UNIT = 'pt'

# LIST_FONT_FAMILY = EDITOR_FONT_FAMILY
LIST_FONT_FAMILY = 'Source Code Pro' #, Kawkab Mono'
LIST_FONT_SIZE_VALUE = 12
LIST_FONT_SIZE_UNIT = 'pt'

title_filename = [  # {{{
    ['Readme', 'README.asc'],
    ['-Make', '.realmake.sh'],
    ['-Abbr', 'abbr.asc'],
    ['-License', 'LICENSE.asc'],
    ['-Index', 'index.asc'],
    ['-Translate', 'TRANSLATION_NOTES.asc'],
    ['-Status', 'status.json'],
    ['ProGit', 'progit.asc'],
    # ['-TOC', 'book/toc.asc'],
    ['-Terms', 'D-terms.asc'],
    ['-Arabic', 'E-arabic-reference.asc'],
    ['-License', 'book/license.asc'],
    ['-Pre-Intro', 'preintro.asc'],
    ['-Pre Trans', 'book/preface_translator.asc'],
    ['-Pre Sch', 'book/preface_schacon.asc'],
    ['-Pre Ben', 'book/preface_ben.asc'],
    ['-Dedication', 'book/dedication.asc'],
    ['-Contrib', 'book/contributors.asc'],
    ['-Intro', 'book/introduction.asc'],
    ['1 Start', 'ch01-getting-started.asc'],
    ['-About VC', 'book/01-introduction/sections/about-version-control.asc'],
    ['-History', 'book/01-introduction/sections/history.asc'],
    ['-What is Git', 'book/01-introduction/sections/what-is-git.asc'],
    ['-Cmdline', 'book/01-introduction/sections/command-line.asc'],
    ['-Install', 'book/01-introduction/sections/installing.asc'],
    ['-Setup', 'book/01-introduction/sections/first-time-setup.asc'],
    ['-Help', 'book/01-introduction/sections/help.asc'],
    ['2 Basics', 'ch02-git-basics-chapter.asc'],
    ['-Get Repo', 'book/02-git-basics/sections/getting-a-repository.asc'],
    ['-Record', 'book/02-git-basics/sections/recording-changes.asc'],
    ['-History', 'book/02-git-basics/sections/viewing-history.asc'],
    ['-Undo', 'book/02-git-basics/sections/undoing.asc'],
    ['-Remotes', 'book/02-git-basics/sections/remotes.asc'],
    ['-Tagging', 'book/02-git-basics/sections/tagging.asc'],
    ['-Aliases', 'book/02-git-basics/sections/aliases.asc'],
    ['3 Branching', 'ch03-git-branching.asc'],
    ['-Nutshell', 'book/03-git-branching/sections/nutshell.asc'],
    ['-Basics', 'book/03-git-branching/sections/basic-branching-and-merging.asc'],
    ['-Mangement', 'book/03-git-branching/sections/branch-management.asc'],
    ['-Workflows', 'book/03-git-branching/sections/workflows.asc'],
    ['-Remote', 'book/03-git-branching/sections/remote-branches.asc'],
    ['-Rebasing', 'book/03-git-branching/sections/rebasing.asc'],
    ['4 Server', 'ch04-git-on-the-server.asc'],
    ['-Protocols', 'book/04-git-server/sections/protocols.asc'],
    ['-On Server', 'book/04-git-server/sections/git-on-a-server.asc'],
    ['-SSH Keys', 'book/04-git-server/sections/generating-ssh-key.asc'],
    ['-Setup', 'book/04-git-server/sections/setting-up-server.asc'],
    ['-Daemon', 'book/04-git-server/sections/git-daemon.asc'],
    ['-Smart HTTP', 'book/04-git-server/sections/smart-http.asc'],
    ['-GitWeb', 'book/04-git-server/sections/gitweb.asc'],
    ['-GitLab', 'book/04-git-server/sections/gitlab.asc'],
    ['-Hosted', 'book/04-git-server/sections/hosted.asc'],
    ['5 Distributed', 'ch05-distributed-git.asc'],
    ['-Workflow', 'book/05-distributed-git/sections/distributed-workflows.asc'],
    ['-Contrib', 'book/05-distributed-git/sections/contributing.asc'],
    ['-Maintain', 'book/05-distributed-git/sections/maintaining.asc'],
    ['6 GitHub', 'ch06-github.asc'],
    ['-Account', 'book/06-github/sections/1-setting-up-account.asc'],
    ['-Contrib', 'book/06-github/sections/2-contributing.asc'],
    ['-Maintain', 'book/06-github/sections/3-maintaining.asc'],
    ['-Org', 'book/06-github/sections/4-managing-organization.asc'],
    ['-Script', 'book/06-github/sections/5-scripting.asc'],
    ['7 Tools', 'ch07-git-tools.asc'],
    ['-Rev Select', 'book/07-git-tools/sections/revision-selection.asc'],
    ['-IA Stage', 'book/07-git-tools/sections/interactive-staging.asc'],
    ['-Stash', 'book/07-git-tools/sections/stashing-cleaning.asc'],
    ['-Sign', 'book/07-git-tools/sections/signing.asc'],
    ['-Search', 'book/07-git-tools/sections/searching.asc'],
    ['-Re Hist', 'book/07-git-tools/sections/rewriting-history.asc'],
    ['-Reset', 'book/07-git-tools/sections/reset.asc'],
    ['-Adv Merge', 'book/07-git-tools/sections/advanced-merging.asc'],
    ['--Subtree', 'book/07-git-tools/sections/subtree-merges.asc'],
    ['-Rerere', 'book/07-git-tools/sections/rerere.asc'],
    ['-Debug', 'book/07-git-tools/sections/debugging.asc'],
    ['-Submod', 'book/07-git-tools/sections/submodules.asc'],
    ['-Bundle', 'book/07-git-tools/sections/bundling.asc'],
    ['-Replace', 'book/07-git-tools/sections/replace.asc'],
    ['-Credential', 'book/07-git-tools/sections/credentials.asc'],
    ['8 Customizing', 'ch08-customizing-git.asc'],
    ['-Conf', 'book/08-customizing-git/sections/config.asc'],
    ['-Attrib', 'book/08-customizing-git/sections/attributes.asc'],
    ['-Hook', 'book/08-customizing-git/sections/hooks.asc'],
    ['-Policy', 'book/08-customizing-git/sections/policy.asc'],
    ['9 Other Systems', 'ch09-git-and-other-systems.asc'],
    ['-cl svn', 'book/09-git-and-other-scms/sections/client-svn.asc'],
    ['-cl hg', 'book/09-git-and-other-scms/sections/client-hg.asc'],
    ['-cl p4', 'book/09-git-and-other-scms/sections/client-p4.asc'],
    ['-imp svn', 'book/09-git-and-other-scms/sections/import-svn.asc'],
    ['-imp hg', 'book/09-git-and-other-scms/sections/import-hg.asc'],
    ['-imp p4', 'book/09-git-and-other-scms/sections/import-p4.asc'],
    ['-imp custom', 'book/09-git-and-other-scms/sections/import-custom.asc'],
    ['X Internals', 'ch10-git-internals.asc'],
    ['-Plumb', 'book/10-git-internals/sections/plumbing-porcelain.asc'],
    ['-Obj', 'book/10-git-internals/sections/objects.asc'],
    ['-Ref', 'book/10-git-internals/sections/refs.asc'],
    ['-Pack', 'book/10-git-internals/sections/packfiles.asc'],
    ['-Refspec', 'book/10-git-internals/sections/refspec.asc'],
    ['-Proto', 'book/10-git-internals/sections/transfer-protocols.asc'],
    ['-Maintain', 'book/10-git-internals/sections/maintenance.asc'],
    ['-Env', 'book/10-git-internals/sections/environment.asc'],
    ['A Environments', 'A-git-in-other-environments.asc'],
    ['-GUI', 'book/A-git-in-other-environments/sections/guis.asc'],
    ['-VS', 'book/A-git-in-other-environments/sections/visualstudio.asc'],
    ['-VSCode', 'book/A-git-in-other-environments/sections/visualstudiocode.asc'],
    ['-JB', 'book/A-git-in-other-environments/sections/jetbrainsides.asc'],
    ['-Sublime', 'book/A-git-in-other-environments/sections/sublimetext.asc'],
    ['-Bash', 'book/A-git-in-other-environments/sections/bash.asc'],
    ['-Zsh', 'book/A-git-in-other-environments/sections/zsh.asc'],
    ['-PS', 'book/A-git-in-other-environments/sections/powershell.asc'],
    ['B Embedding', 'B-embedding-git-in-your-applications.asc'],
    ['-Cmdline', 'book/B-embedding-git/sections/command-line.asc'],
    ['-libgit2', 'book/B-embedding-git/sections/libgit2.asc'],
    ['-JGit', 'book/B-embedding-git/sections/jgit.asc'],
    ['-go-git', 'book/B-embedding-git/sections/go-git.asc'],
    ['-Dulwich', 'book/B-embedding-git/sections/dulwich.asc'],
    ['C Commands', 'C-git-commands.asc'],
]
title_filename = [ [t,f] for t,f in title_filename if t != '-' ]  # remove '-' items
sec_prefix = re.compile('^-')
sub_prefix = re.compile('^--')
INDENT = '\N{EM SPACE}\N{EM SPACE}'
DBL_INDENT = INDENT + INDENT
def title_to_view(t):
    return sec_prefix.sub(INDENT, sub_prefix.sub(DBL_INDENT, t))

titles = []
index_of_filename = {}; i = 0
for t,f in title_filename:
    item = QListWidgetItem(title_to_view(t))
    item.setData(Qt.UserRole, f)
    titles.append(item)
    index_of_filename[f] = i; i += 1

lastposition = { f:0 for t,f in title_filename }
# }}}


# Syntax Highlighting {{{
# https://wiki.python.org/moin/PyQt/Python%20syntax%20highlighting

def format(color, style=''):
    """Return a QTextCharFormat with the given attributes."""
    _color = QColor(color)
    # _color.setNamedColor(color)
    _format = QTextCharFormat()
    if color: _format.setForeground(_color)
    if 'm' in style: _format.setFont(QFont('mono'))
    if 'b' in style: _format.setFontWeight(QFont.Bold)
    if 'i' in style: _format.setFontItalic(True)
    return _format

# gruvbox dark - https://github.com/morhetz/gruvbox
COLORS = {
    'bg':       '#282828',
    'bg1':      '#3c3836',
    'bg2':      '#504945',
    'bg3':      '#665c54',
    'bg4':      '#7c6f64',
    'fg':       '#ebdbb2',
    'fg2':      '#d5c4a1',
    'red':      '#cc241d',
    'red2':     '#fb4934',
    'green':    '#98971a',
    'green2':   '#b8bb26',
    'green3':   '#b8bb26',
    'green4':   '#79740e',
    'yellow':   '#d79921',
    'yellow2':  '#fabd2f',
    'blue':     '#458588',
    'blue2':    '#83a598',
    'purple':   '#b16286',
    'aqua':     '#689d6a',
    'gray':     '#a89984',
    'gray2':    '#928374',
    'orange':   '#d65d0e',
}

if 'light' in sys.argv:
        # gruvbox light - https://github.com/morhetz/gruvbox
        COLORS = {
            'bg':       '#fbf1c7',
            'bg1':      '#ebdbb2',
            'bg2':      '#d5c4a1',
            'bg3':      '#bdae93',
            'bg4':      '#a89984',
            'fg':       '#3c3836',
            'fg2':      '#504945',
            'red':      '#cc241d',
            'red2':     '#9d0006',
            'green':    '#98971a',
            'green2':   '#79740e',
            'green3':   '#79740e',
            'green4':   '#b8bb26',
            'yellow':   '#d79921',
            'yellow2':  '#b57614',
            'blue':     '#458588',
            'blue2':    '#076778',
            'purple':   '#b16286',
            'aqua':     '#689d6a',
            'gray':     '#7c6f64',
            'gray2':    '#928374',
            'orange':   '#d65d0e',
        }

DIRECTIVES = r'(^ifdef::[^\[]*(?=\[) | ^(?:include|image|link)::(?=.*\[) | (?:image:|link:)(?=[^ \t\n]+\[) )'

LINKS = r'( (?:[^ \t\n]*/)+[^ \t\n]* (?=\[) | (?: (?<=^image::) | (?<=^include::) | (?<=image:) | (?<=link:) ) [^ \t\n]+ (?=\[) | https?:[^ \t\n]+ )'

HEADING = r'( ^=+ [ \t]+.*)'

QUOTES = r'( ^>+ [ \t]*.*)'

LISTS = r'^( [.*]+[ \t]+ )'

MERGEMARKS = r'^( <{7} [ ].* | ={7} | >{7} [ ].* )$'

ABBR           = r'                        ( \{ [^{}]+ \}  )'
# ABBR_INHEAD    = r'    ^[ \t]* =+ [ \t] .* ( \{ [^{}]+ \}  )'
# ABBR_INCOMMENT = r' (?<!http:|ttps:) // .* ( \{ [^{}]+ \}  )'

# COMMENT = r' (?<!http:|ttps:|.git:|file:|.ssh:) (// .*) '
COMMENT = r' (?<!:) (// .*) '

ENTITY = r'&[#A-Za-z0-9]+;'

REFERENCES = '( \({3} [^()]+ \){3} )'

def format_rule(regex, color, style=''):
    return (re.compile(regex, re.M | re.X), format(COLORS[color], style))

TEXT_STATE = -1

# first elem is the state, and it must be binary-exclusive with each other: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, and so on.
MULTILINE_PRE = [
    (1, *format_rule('^====$',  'orange',    )),  # admn
]
MULTILINE_POST = [
    (2, *format_rule('^----$',  'aqua',   'm')),  # code
    (4, *format_rule('^\+{3}$', 'purple', 'm')),  # pass
    (8, *format_rule('^////$',  'gray',   'i')),  # cmnt
]

BOLD = r'(?:(?<!\\)(?<=\W)|^) (\*) ([^<>]*?) (?<!\\)(\*) (?:(?=\W)|$)'; FREE_BOLD = r'(?<!\\)(\*\*) ([^<>]*?) (?<!\\)(\*\*)'
ITAL = r'(?:(?<!\\)(?<=\W)|^) ( _) ([^<>]*?) (?<!\\)( _) (?:(?=\W)|$)'; FREE_ITAL = r'(?<!\\)( _ _) ([^<>]*?) (?<!\\)( _ _)'
MONO = r'(?:(?<!\\)(?<=\W)|^) ((?<!")`) (?:[^<>]|<[^<>]*?>)*? (?<!\\)(`(?!")) (?:(?=\W)|$)'; FREE_MONO = r'(?<!\\)( ` `) ([^<>]*?) (?<!\\)( ` `)'
# TODO: setFontFixedPitch()?

CROSSREF = '(<<) (.*?) (>>)'

CONCEAL_FMT = QTextCharFormat()
_f = QFont()
_f.setPointSizeF(0.1)
CONCEAL_FMT.setFont(_f)

def R(r): return re.compile(r, re.X | re.U)
def F(c,s=''): return format(COLORS[c], s)

COMMENT_FMT = F('gray', 'i')

BRACKETS = r' ( \[+ ) ( [^\[\]]* ) ( \]+ )'
BRACES   = r' ( \{+ ) ( [^{}]*   ) ( \}+ )'

INLINE_FMT = [
    [[R(BRACKETS)],           [F('gray2'),  COMMENT_FMT], [F('yellow2'),  COMMENT_FMT]],
    [[R(BRACES)],             [F('gray2'), F('bg3', 'i')], [F('green2'),   F('green4', 'i')]],
    [[R(CROSSREF)],           [F('blue', 'm'), F('bg3', 'i')], [F('blue2', 'm'),   F('green4', 'i')]],
    [[R(BOLD), R(FREE_BOLD)], [CONCEAL_FMT, CONCEAL_FMT], [F('fg', 'b'), F('gray', 'bi')]],
    # [[R(MONO), R(FREE_MONO)], [CONCEAL_FMT, CONCEAL_FMT], [F('fg', 'm'), F('gray', 'mi')]],
    [[R(ITAL), R(FREE_ITAL)], [CONCEAL_FMT, CONCEAL_FMT], [F('fg', 'i'), F('gray', '')]],
]

COMMENT_RE = re.compile(COMMENT, re.X)

RULES = list(map(lambda e: format_rule(*e), [
    [HEADING,               'red',     'b'  ], # heading
    [COMMENT,               'gray',    'i'  ], # comment - XXX: multiline unsupported
    [r'(^:.*)',             'yellow',       ], # abbr
    # [ABBR_INHEAD,           'red2',   'b'  ],
    # [ABBR_INCOMMENT,        'gray2',   'i'  ],
    [ENTITY,                'yellow',       ],
    [LINKS,                 'blue',         ],
    [DIRECTIVES,            'green',        ],
    [REFERENCES,            'bg3',          ],
    [LISTS,                 'red2',         ],
    ['FIXME',               'red2',    'bi' ],
    [r'(^\..*)',            'yellow',  'i'  ],
    [MERGEMARKS,            'red2',    'b'  ], # this doesn't show?
    [QUOTES,                'aqua',         ],
]))

nbsp_format = QTextCharFormat()
nbsp_format.setBackground(QColor(COLORS['yellow']))
RULES.append((re.compile('\N{NO-BREAK SPACE}'), nbsp_format))

class AsciiDocHighlighter (QSyntaxHighlighter):
    """Syntax highlighter for the AsciiDoc language."""
    def __init__(self, parent: QTextDocument) -> None:
        super().__init__(parent)

    def highlightBlock(self, text):
        """Apply syntax highlighting to the given block (line) of text."""
        for multi in MULTILINE_PRE:
            self.highlight_multiline(text, *multi)
        def idx_len(span): return span[0], span[1] - span[0]
        for expr, fmt in RULES:
            for match in expr.finditer(text):
                index, length = idx_len(match.span(1) if match.groups() else match.span())
                self.setFormat(index, length, fmt)
        for exprs, out_fmts, in_fmts in INLINE_FMT:
            for expr in exprs:
                for match in expr.finditer(text):
                    cmnt = COMMENT_RE.search(text)
                    if cmnt and match.span()[0] > cmnt.span()[0]:  # in comment; use second fmt
                        # self.setFormat(*idx_len(match.span(1)), out_fmts[1])
                        self.setFormat(*idx_len(match.span(2)),  in_fmts[1])
                        # self.setFormat(*idx_len(match.span(3)), out_fmts[1])
                    else:
                        # self.setFormat(*idx_len(match.span(1)), out_fmts[0])
                        self.setFormat(*idx_len(match.span(2)),  in_fmts[0])
                        # self.setFormat(*idx_len(match.span(3)), out_fmts[0])
        for multi in MULTILINE_POST:
            self.highlight_multiline(text, *multi)

    # # a failed attempt to support nested blocks, like Ch03/Management
    # def highlight_multiline(self, text, state, delim, fmt):
    #     prevState = self.previousBlockState()
    #     if delim.search(text):
    #         self.setCurrentBlockState(prevState ^ state)
    #         self.setFormat(0, len(text), fmt)
    #     elif prevState & state:
    #         self.setCurrentBlockState(state)
    #         self.setFormat(0, len(text), fmt)

    def highlight_multiline(self, text, state, delim, fmt):
        if delim.search(text):
            if self.previousBlockState() != state:
                self.setCurrentBlockState(state)
            else:
                self.setCurrentBlockState(TEXT_STATE)
            self.setFormat(0, len(text), fmt)
        elif self.previousBlockState() == state:
            self.setCurrentBlockState(state)
            self.setFormat(0, len(text), fmt)

# }}}


class MyMainWindow(QMainWindow):

    def updateStyle(self):
        self.setStyleSheet(f"""
            QTextEdit, QListWidget {{ color: {COLORS['fg']}; background: {COLORS['bg']} }}
            QTextEdit {{ font-family: '{EDITOR_FONT_FAMILY}'; font-size: {EDITOR_FONT_SIZE_VALUE}{EDITOR_FONT_SIZE_UNIT} }}
            QListWidget {{ font-family: '{LIST_FONT_FAMILY}'; font-size: {LIST_FONT_SIZE_VALUE}{LIST_FONT_SIZE_UNIT} }}
            """)

    def zoomIn(self):
        global EDITOR_FONT_SIZE_VALUE
        EDITOR_FONT_SIZE_VALUE += 1
        print(EDITOR_FONT_SIZE_VALUE)
        self.updateStyle()

    def zoomOut(self):
        global EDITOR_FONT_SIZE_VALUE
        EDITOR_FONT_SIZE_VALUE -= 1
        print(EDITOR_FONT_SIZE_VALUE)
        self.updateStyle()

    def toggleSidePane(self):
        if self.list.isVisible():
            self.list.hide()
        else:
            self.list.show()

    def __init__(self, builder, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.builder = builder
        self.filename = None
        self.list = QListWidget()
        for t in titles: self.list.addItem(t)
        self.list.itemActivated.connect(lambda item: self.__onactivate(item))
        # self.edit = QPlainTextEdit()
        self.edit = QTextEdit()
        # self.edit.setAlignment(Qt.AlignLeading)
        self.updateStyle()
        self.hi = AsciiDocHighlighter(self.edit.document())
        self.cent = QSplitter(self)
        self.cent.addWidget(self.list)
        self.finder = QLineEdit()
        self.finder.hide()
        self.finder.textChanged.connect(self._find)
        self.finder.setStyleSheet(f"color: {COLORS['fg2']}; background: {COLORS['bg3']}")
        vbox = QVBoxLayout()
        vbox.setContentsMargins(0,0,0,0)
        vbox.addWidget(self.edit)
        vbox.addWidget(self.finder)
        self.wvbox = QWidget()
        self.wvbox.setLayout(vbox)
        # cent.addWidget(self.edit)
        self.cent.addWidget(self.wvbox)
        self.cent.setStretchFactor(0, 1)
        self.cent.setStretchFactor(1, 3)
        self.setCentralWidget(self.cent)

        self.edit.cursorPositionChanged.connect(lambda: self.hilightCurrentLine())
        self.hilightCurrentLine()

        def __because_python():
            self.changed = True
        self.edit.textChanged.connect(__because_python)

        self.lastFile = None

        # update all titles to reflect status
        for t,f in title_filename:
            self.load(f)
        self.load(title_filename[0][1])

        for key, act in [
                ('Esc',              lambda: (self.save(), self.build(), self.hi.rehighlight())),
                ('Ctrl+S',           lambda: (self.save(), self.build(), self.hi.rehighlight())),
                ('F1',               lambda: self.cycleThruStatuses()),
                ('Ctrl+/',           lambda: self.toggleComment()),
                ('Ctrl+Up',          lambda: self.moveCursor(QTextCursor.PreviousBlock)),
                ('Ctrl+Down',        lambda: self.moveCursor(QTextCursor.NextBlock)),
                ('Ctrl+Space',       lambda: self.prepareForTranslation()),
                ('Ctrl+Shift+Space', lambda: self.prepareForTranslationByCopy()),
                ('Ctrl+O',           lambda: self.openLineBelow()),
                ('Ctrl+Shift+O',     lambda: self.openLineAbove()),
                ('Ctrl+6',           lambda: self.goToLastFile()),
                ('Ctrl+F',           lambda: self.toggleFind()),
                ('F3',               lambda: self.findNext()),
                ('Shift+F3',         lambda: self.findPrev()),
                ('F8',               lambda: self.copyCurrentFullLine()),
                ('Ctrl++',           lambda: self.zoomIn()),
                ('Ctrl+-',           lambda: self.zoomOut()),
                ('Ctrl+Shift+f',     lambda: self.toggleSidePane()),
                (Qt.CTRL+Qt.Key_PageUp,      lambda: self.prevFile()),
                (Qt.CTRL+Qt.Key_PageDown,    lambda: self.nextFile()),
                # ('Ctrl+Shift+C',   lambda: self.copyBigWord()),
                # ('Ctrl+Shift+V',   lambda: self.pasteBigWord()),
        ]:
            QShortcut(QKeySequence(key), self).activated.connect(act)

        # oldevent = self.edit.keyPressEvent
        # def newevent(s, e):
        #     if e.matches(QKeySequence.Copy) and not e.textCursor().hasSelection():
        #         # select the whole line
        #         cursor = s.textCursor()
        #         cursor.movePosition(QTextCursor.StartOfBlock)
        #         cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
        #         text = cursor.selectedText()
        #         QGuiApplication.clipboard().setText(text)
        #     else:
        #         oldevent(s, e)
        # self.edit.keyPressEvent = lambda e: newevent(self.edit, e)


    def copyCurrentFullLine(self):
        cursor = self.edit.textCursor()
        cursor.movePosition(QTextCursor.StartOfBlock)
        cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
        text = cursor.selectedText()
        QGuiApplication.clipboard().setText(text)

    def _highlight_search(self, cursor):
        return  # no longer needed as we use normal selection
        # sel = QTextEdit.ExtraSelection()
        # sel.format.setBackground(QColor(COLORS['bg2']))
        # sel.cursor = cursor
        # self.edit.setExtraSelections([sel])

    def _find(self, txt, *flags, start=None):  # connected to self.finder.textChanged
        # start = start if start else self.edit.textCursor()
        # foundcursor = self.edit.document().find(txt, start, *flags)
        if start is not None:
            foundcursor = self.edit.document().find(txt, start)
        else:
            foundcursor = self.edit.document().find(txt)
        if foundcursor.isNull():
            return
        self._highlight_search(foundcursor)
        self.edit.setTextCursor(foundcursor)

    def findNext(self):
        self._find(self.finder.text(), start=self.edit.textCursor())

    def findPrev(self):
        self._find(self.finder.text(), QTextDocument.FindBackward)

    def toggleFind(self):
        if self.finder.isVisible() and self.finder.hasFocus():
            self.finder.hide()
            self.edit.setFocus(True)
        else:
            self.finder.show()
            self.finder.setFocus(True)

    def copy(self):
        if self.edit.textCursor().hasSelection():
            text = self.edit.textCursor().selectedText()
        else:  # select the whole line
            cursor = self.edit.textCursor()
            cursor.movePosition(QTextCursor.StartOfBlock)
            cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
            text = cursor.selectedText()
        QGuiApplication.clipboard().setText(text)
        # copy:  QGuiApplication.clipboard().setText(text)
        # paste: QGuiApplication.clipboard().text()

    def openLineBelow(self):
        self.moveCursor(QTextCursor.EndOfBlock)
        self.edit.textCursor().insertText('\n')

    def openLineAbove(self):
        self.moveCursor(QTextCursor.StartOfBlock)
        self.edit.textCursor().insertText('\n')
        self.moveCursor(QTextCursor.PreviousBlock)

    def goToLastFile(self):
        if self.lastFile is None: return
        self.load(self.lastFile)

    def nextFile(self):
        i = (index_of_filename[self.filename] + 1) % len(title_filename)
        self.load(title_filename[i][1])

    def prevFile(self):
        self.load(title_filename[ index_of_filename[self.filename] - 1 ][1])

    PREFIX_RE = Regex(
        r''' ^( [ \t]+
              | =+[ \t]
              | >+[ \t]*
              | \.
              | [1-9][0-9]*\.[ \t]
              | [.*-]+[ \t]+
              | image::.*?\[
              ) [^ \t\n]+ ''')
    SUFFIX_RE = Regex(r'( (?: [(]{3} .*? [)]{3} )+ )$')

    def prepareForTranslationByCopy(self):
        # make all these changes a single operation (one Ctrl-Z undoes them all)
        self.edit.textCursor().beginEditBlock()
        # copy the line
        cursor = self.edit.textCursor()
        cursor.movePosition(QTextCursor.StartOfBlock)
        cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
        text = cursor.selectedText()
        # comments the current line; assumes it's not commented (FIXME)
        self.toggleComment()
        # makes the current physical line (block) entirely visible
        self.moveCursor(QTextCursor.EndOfBlock)
        self.edit.ensureCursorVisible()
        # open a newline before
        self.moveCursor(QTextCursor.StartOfBlock)
        self.edit.textCursor().clearSelection()
        self.edit.textCursor().insertText('\n')
        self.moveCursor(QTextCursor.PreviousBlock)
        # insert the original line
        self.edit.textCursor().insertText(text)
        # end of changes
        self.edit.textCursor().endEditBlock()

    def prepareForTranslation(self):
        # make all these changes a single operation (one Ctrl-Z undoes them all)
        self.edit.textCursor().beginEditBlock()
        # get the prefix (equals for a heading or a dot for a title)
        line = self.getCurrentLine()
        match = self.PREFIX_RE.match(line)
        prefix = match.captured(1) if match.hasMatch() else ''
        # get the suffix (triple parethenses)
        match = self.SUFFIX_RE.match(line)
        suffix = match.captured(1) if match.hasMatch() else ''
        if prefix.startswith('image::'):
            suffix = ']' + suffix
        # comments the current line; assumes it's not commented (FIXME)
        self.toggleComment()
        # makes the current physical line (block) entirely visible
        self.moveCursor(QTextCursor.EndOfBlock)
        self.edit.ensureCursorVisible()
        # open a newline before
        self.moveCursor(QTextCursor.StartOfBlock)
        self.edit.textCursor().clearSelection()
        self.edit.textCursor().insertText('\n')
        self.moveCursor(QTextCursor.PreviousBlock)
        # insert the prefix
        self.edit.textCursor().insertText(prefix)
        self.moveCursor(QTextCursor.EndOfBlock)
        # insert the suffix without moving the cursor
        cursor = self.edit.textCursor()
        pos = cursor.position()
        self.edit.textCursor().insertText(suffix)
        cursor.setPosition(pos)
        self.edit.setTextCursor(cursor)
        # end of changes
        self.edit.textCursor().endEditBlock()

    def moveCursor(self, movement):
        cursor = self.edit.textCursor()
        cursor.movePosition(movement)
        self.edit.setTextCursor(cursor)

    def hilightCurrentLine(self):
        sels = []
        def newSelection():
            sel = QTextEdit.ExtraSelection()
            lineColor = QColor(COLORS['bg1'])
            sel.format.setBackground(lineColor)
            sel.format.setProperty(QTextFormat.FullWidthSelection, True)
            sel.cursor = self.edit.textCursor()
            sel.cursor.clearSelection()
            return sel
        sel = newSelection()
        sel.cursor.movePosition(QTextCursor.StartOfBlock)
        # sel.cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
        sel.cursor.movePosition(QTextCursor.NextBlock, QTextCursor.KeepAnchor)
        sels.append(sel)
        self.edit.setExtraSelections(sels)

    def getCurrentLine(self):  # a physical line is called a block in Qt
        return self.edit.textCursor().block().text()
        # cursor = self.edit.textCursor()
        # cursor.movePosition(QTextCursor.StartOfBlock)
        # cursor.movePosition(QTextCursor.EndOfBlock, QTextCursor.KeepAnchor)
        # return cursor.selectedText()

    TITLE_RE = Regex(r' ^[.] \S+')
    HEADING_RE = Regex(r' ^(=+) [ \t]+ \S+')
    HEADING_STATUSES = ['❌', '✋', '⏳', '✨', '✅']
    HEADING_STATUS_RE = Regex(r' ^=+ [ \t]+ ([⛲' + ''.join(HEADING_STATUSES) + r']) [ \t]+ \S+')

    EMPTY_STATUS = '➖'

    # TITLE_HEADING_STATUSES_RE = re.compile(r'([ \t]+[' + ''.join(HEADING_STATUSES) + r'])$')
    TITLE_HEADING_STATUSES_RE = Regex('^(\s*)([⛲' + EMPTY_STATUS + ''.join(HEADING_STATUSES) + ']?)(.*)$')

    def updateTitle(self, status=None):
        if status is None:
            status = self.getStatusFromFile(self.filename)
        title = self.current_item.text()
        if status == '':
            status = self.EMPTY_STATUS
        (_, prespace, current_status, basic_title) = self.TITLE_HEADING_STATUSES_RE.match(title).capturedTexts()
        new_title = prespace + status + basic_title
        self.current_item.setText(new_title)

    def getStatusFromFile(self, filename):
        with open(filename) as f:
            for line in f:
                head = self.HEADING_RE.match(line)
                if head.hasMatch():
                    status = self.HEADING_STATUS_RE.match(line)
                    return status.captured(1) if status.hasMatch() else ''
            return ''

    def cycleThruStatuses(self):
        # the current heading between statuses in HEADING_STATUSES
        line = self.getCurrentLine()
        head = self.HEADING_RE.match(line)
        if not head.hasMatch():
            return
        status = self.HEADING_STATUS_RE.match(line)
        cursor = self.edit.textCursor()
        cursor.movePosition(QTextCursor.StartOfBlock)
        cursor.movePosition(QTextCursor.NextWord)
        if not status.hasMatch():  # no status; inserting the first
            newstatus = self.HEADING_STATUSES[0]
            cursor.insertText(newstatus+' ')
        elif status.captured(1) == self.HEADING_STATUSES[-1]:  # the last status; removing it
            newstatus = ''
            cursor.movePosition(QTextCursor.NextWord, QTextCursor.KeepAnchor)
            cursor.removeSelectedText()
        else: # replacing the current status with the next one
            cursor.movePosition(QTextCursor.NextWord, QTextCursor.KeepAnchor)
            getnext = False
            for s in self.HEADING_STATUSES:
                if getnext:
                    newstatus = s
                    cursor.insertText(s+' ')
                    break
                if status.captured(1) == s:
                    getnext = True
        self.updateTitle(newstatus if cursor.position() < 1024 else None)  # somewhere in the beginning of the file

    COMMENTED_LINE_RE = Regex(r'^ \s* (//[ ])')

    def toggleComment(self):
        line = self.getCurrentLine()
        cmnt = self.COMMENTED_LINE_RE.match(line)
        cursor = self.edit.textCursor()
        if cmnt.hasMatch():
            start = cursor.block().position() + cmnt.capturedStart(1)
            end = cursor.block().position() + cmnt.capturedEnd()
            cursor.setPosition(start)
            cursor.setPosition(end, QTextCursor.KeepAnchor)
            cursor.removeSelectedText()
        else:
            cursor.movePosition(QTextCursor.StartOfBlock)
            # cursor.movePosition(QTextCursor.StartOfWord)  # skip identation
            cursor.insertText('// ')

    def build(self):
        self.builder.done.connect(lambda: self.updateWindowTitle(False))
        self.builder.start()
        self.updateWindowTitle(True)

    def updateWindowTitle(self, building=False):
        b = '⏳ ' if building else ''
        a = Stats.arabic_words(self.filename)
        t = Stats.translatable_words(self.filename)
        n = Stats.short_filename(self.filename)
        self.setWindowTitle(f'{b}{n} — {a}/{t}')
        # self.setWindowTitle(f'{a}/{t} — {n}')

    EMPTY_HEADING_RE = re.compile('^(===?[ \t])(?!['+EMPTY_STATUS+''.join(HEADING_STATUSES)+'])', re.M)
    EMPTY_STATUS_HEADING_RE = re.compile('^(===?[ \t])'+EMPTY_STATUS+' ', re.M)

    def load_filter(self, content):
        # return self.EMPTY_STATUS_HEADING_RE.sub(r'\1', content
        return (content
                .replace('\N{NO-BREAK SPACE}', '{مس}')
                .replace('\N{NARROW NO-BREAK SPACE}', '{مسر}')
            )

    def save_filter(self, content):
        # return self.EMPTY_HEADING_RE.sub(r'\1'+self.EMPTY_STATUS+' ', content
        # return self.EMPTY_STATUS_HEADING_RE.sub(r'\1', content
        return (content
                .replace('{مس}', '\N{NO-BREAK SPACE}')
                .replace('{مسر}', '\N{NARROW NO-BREAK SPACE}')
            )

    def save(self):
        if not self.filename: return
        if not self.changed: return
        towrite = self.save_filter(self.edit.toPlainText())
        with open(self.filename, encoding='utf-8') as f:
            if towrite == f.read():
                return
        with open(self.filename, 'w', encoding='utf-8') as f:
            f.write(towrite)
        self.changed = False

    def saveCursorPosition(self):
        if not self.filename: return
        lastposition[self.filename] = self.edit.textCursor().position()

    def loadCursorPosition(self):
        if not self.filename: return
        cursor = self.edit.textCursor()
        cursor.setPosition(lastposition[self.filename])
        self.edit.setTextCursor(cursor)

    def load(self, filename):
        if self.filename:
            self.save()
            self.build()
            self.saveCursorPosition()
        self.lastFile = self.filename
        self.filename = filename
        with open(filename, encoding='utf-8') as f:
            self.edit.setPlainText(self.load_filter(f.read()))
        self.hi.rehighlight()
        self.changed = False
        self.list.setCurrentItem(self.list.item(index_of_filename[filename]))
        self.current_item = self.list.selectedItems()[0]
        self.updateTitle()
        self.updateWindowTitle()
        self.loadCursorPosition()

    def __onactivate(self, item):
        self.load(item.data(Qt.UserRole))

    def closeEvent(self, ev):
        self.save()
        self.build()


class Builder(QThread) :

    done = pyqtSignal()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.force = True

    MAKE = ['make']

    def run(self):
        need, self.force = self.force, False
        if not need:  # ...yet
            proc = subprocess.Popen([*Builder.MAKE, '-q'])
            if proc.wait():  # need making
                need = True
        if need:
            proc = subprocess.Popen(Builder.MAKE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            proc.wait()
            self.done.emit()


app = QApplication(sys.argv)

b = Builder(); b.start()

w = MyMainWindow(builder=b)
availableGeometry = w.screen().availableGeometry()
w.resize(availableGeometry.width() // 3, 2 * availableGeometry.height() // 3)
w.move((availableGeometry.width() - w.width()) // 2,
       (availableGeometry.height() - w.height()) // 2)

for f in sys.argv[1:]:
    if f != 'light':
        w.load(f)
        break

w.show()

app.exit(app.exec())


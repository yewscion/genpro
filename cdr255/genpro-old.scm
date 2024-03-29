(define-module (cdr255 genpro)
  :use-module (ice-9 ftw)           ; For Filesystem Access.
  :use-module (ice-9 textual-ports) ; For Writing to Files.
  :use-module (srfi srfi-19)        ; For Dates.
  :use-module (cdr255 userlib)      ; Utility Functions.
  :use-module (ice-9 popen)         ; Pipes
  :export (make-project
           compile-project
           hash-meta-info
           clean-project
           create-metadata-file
           create-projectile-file
           build-file-name
           run-java-jarfile))

(define (hash-meta-info bib
                        pro
                        aut
                        sch
                        sec
                        prf
                        dat
                        ann
                        jav
                        jll)
  "Takes the project's metadata and turns it into a ten-element hash table.

This is a CALCULATION.

Arguments
=========

BIB <string>: Filepath to the biblatex bibliography You are using.

PRO <string>: Title of the project or paper.

AUT <string>: Name of the Author(s).

SCH <string>: Name of the School/Organization the paper was published under.

SEC <string>: The section, website, or journal that the paper was written for.

PRF <string>: Professor's Name (if Applicable).

DAT <string>: Canonical date of the paper in YYYY-MM-DD format (ISO8601 brief).

ANN <bool>:   Are we making an annotated bibliography?

JAV <bool>:   Are we including a java component?

JLL <<list> of <strings>>: A list of filenames/paths to include as libraries,
                           under the /lib folder of the project.

Returns
=======

An 8 Parameter <hash-table> with the following keys: 

'bibliography <string>, from BIB. 
'project <string>, from PRO. Stored in Title Case.
'author <string>, from AUT.
'school <string>, from SCH.
'section <string>, from SEC.
'professor <string>, from PRF.
'date <srfi-19 date>, from DAT. Time set to all zeros, offset to local timezone.
'annotated-bibliography <bool>, from ANN.
'java-project <bool>, from JAV.
'java-local-libraries <<list> of <strings>, from JLL.

Impurities
==========

None.
"
  (let ((table (make-hash-table 10)))
    (hashq-create-handle! table 'bibliography bib)
    (hashq-create-handle! table 'project pro)
    (hashq-create-handle! table 'author aut)
    (hashq-create-handle! table 'school sch)
    (hashq-create-handle! table 'section sec)
    (hashq-create-handle! table 'professor prf)
    (hashq-create-handle! table 'date (string->date dat "~Y-~m-~d"))
    (hashq-create-handle! table 'annotated-bibliography ann)
    (hashq-create-handle! table 'java-project? jav)
    (hashq-create-handle! table 'java-local-libraries jll)
    table))

(define (sanitize-string string)
  "Cleans a string up, removing characters that may be undesirable or problematic.

This is a CALCULATION.

Arguments
=========

STRING <string>: The string to be cleaned up, in its unaltered state.

Returns
=======

A <string> that has been transformed by replacing characters with safer 
alternatives.

Impurities
==========

None.
"
  (string-map (lambda (x) (cond ((or
                                  (eq? #\! x)
                                  (eq? #\: x)
                                  (eq? #\, x)
                                  (eq? #\; x)
                                  (eq? #\' x)
                                  (eq? #\[ x)
                                  (eq? #\{ x)
                                  (eq? #\] x)
                                  (eq? #\} x)
                                  (eq? #\= x))
                                 #\_)
                                ((eq? #\space x)
                                 #\-)
                                (else x))) string))

(define (build-file-name meta-info)
  "Builds a filename (sans extension) from our meta-info data structure.

This is a CALCULATION.
Arguments
=========

META-INFO <hash-table>: A Ten-Parameter Hash table with the keys 
                        'date <srfi-19 date>, 'section <string>, 
                        'annotated-bibliography, and 'project <string>.

Returns
=======

A <string> of the format \"date.section.project-name\", with only 
the part of the section before the colon included.

Impurities
==========

None.
"
  (string-downcase
   (sanitize-string (string-append
                     (date->string
                      (cdr (hashq-get-handle meta-info 'date)) "~1")
                     "."
                     (car (string-split
                           (cdr (hashq-get-handle meta-info 'section)) #\:))
                     "."
                     (cdr (hashq-get-handle meta-info 'project))
                     (if (cdr (hashq-get-handle meta-info 'annotated-bibliography))
                         (string-append "-annotated-bibliography")
                         "")))))

(define (build-meta-file-content bibliography
                                 title
                                 author
                                 school
                                 section
                                 professor
                                 due-date)
  "Builds the actual content of the meta.tex file for a latex project.

This is a CALCULATION.

Arguments
=========

BIBLIOGRAPHY <string>: The filepath to the project's bibliography.

TITLE <string>: The title of the paper.

AUTHOR <string>: The author(s) of the paper.

SCHOOL <string>: The school/organization for the paper.

SECTION <string>: The section/project/journal for the paper.

PROFESSOR <string>: The professor that assigned the paper (if applicable).

DUE-DATE <string: The canonical date of the paper, in YYYY-MM-DD format.

Returns
=======

A <string> that represents the contents of the meta.tex file for the project.

Impurities
==========

None.
"
  (string-append "\\newcommand{\\localbibliography}{\\string"
                 bibliography
                 "}\n\\newcommand{\\localtitle}{"
                 title
                 "}\n\\newcommand{\\localauthor}{"
                 author
                 "}\n\\newcommand{\\localschool}{"
                 school
                 "}\n\\newcommand{\\localsection}{"
                 section
                 "}\n\\newcommand{\\localprofessor}{"
                 professor
                 "}\n\\newcommand{\\localduedate}{"
                 due-date
                 "}\n\n% Generated with the wrapper script.\n"))

(define (build-meta-file meta-info)
  "Build the meta.tex file from the meta-info data structure.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of the meta.tex file for this project.

Impurities
==========

None.
"
  (build-meta-file-content (cdr (hashq-get-handle
                                 meta-info 'bibliography))
                           (cdr (hashq-get-handle meta-info 'project))
                           (cdr (hashq-get-handle meta-info 'author))
                           (cdr (hashq-get-handle meta-info 'school))
                           (cdr (hashq-get-handle meta-info 'section))
                           (cdr (hashq-get-handle meta-info 'professor))
                           (date->string (cdr (hashq-get-handle meta-info 'date)) "~1")))

(define (build-preamble-file meta-info)
  "Dumps my standard preamble.tex out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of preamble.tex.

Impurities
==========

None.
"
  (string-append
   "\\usepackage{lwarp}\n"
   "\\CSSFilename{https://cdr255.com/css/lwarp-cdr255.css}\n"
   "\\usepackage{geometry}\n"
   "\\geometry{\n"
   "  letterpaper,\n"
   "  left=1in,\n"
   "  right=1in,\n"
   "  top=1in,\n"
   "  bottom=1in}\n"
   "\\usepackage{etoolbox}\n"
   "\\usepackage{fancyhdr}\n"
   "\\pagestyle{fancy}\n"
   "\\lhead{}\n"
   "\\chead{}\n"
   "\\rhead{\\thepage}\n"
   "\\lfoot{}\n"
   "\\cfoot{}\n"
   "\\rfoot{}\n"
   "\\renewcommand{\\headrulewidth}{0pt}\n"
   "\\usepackage[american]{babel}\n"
   "\\usepackage{xpatch}\n"
   "\\usepackage[backend=biber,"
   "style=apa,"
   (if (cdr (hashq-get-handle meta-info 'annotated-bibliography))
       (string-append "annotation=true,")
       (string-append "annotation=false,"))
   "loadfiles=true]{biblatex}\n"
   "\\usepackage[]{setspace}\n"
   "\\usepackage{indentfirst}\n"
   "\\usepackage{fontspec}\n"
   "\\setmainfont{TeXGyreTermes}\n"
   "\\newfontfamily{\\freemono}{FreeMono.otf}[Path = "
   (shell-output-to-string
    "fc-list | grep FreeMono.otf | sed 's/:.*//g;s/\\/[A-z.]*$/\\//;1q'")
   "]\n\\newfontfamily{\\unifont}{unifont.ttf}[Path = "
   (shell-output-to-string
    "fc-list | grep unifont.ttf | sed 's/:.*//g;s/\\/[A-z.]*$/\\//;1q'")
   "]\n\\appto{\\bibsetup}{\\raggedright}\n"
   "\\bibliography{\\localbibliography}\n"
   "\\DeclareLanguageMapping{american}{american-apa}\n"
   "\\setlength{\\parindent}{4em}\n"
   "\\usepackage{titlesec}\n"
   "\\titleformat{\\section}\n"
   "  {\\centering\\normalfont\\normalsize\\bfseries}{\\thesection.}{1em}{}\n"
   "\\titleformat{\\subsection}\n"
   "  {\\normalfont\\normalsize\\itshape}{\\thesubsection.}{1em}{}\n"
   "\\titleformat{\\subsubsection}\n"
   "  {\\normalfont\\normalsize\\itshape}{\\thesubsubsection.}{1em}{}\n"
   "\\usepackage{graphicx}\n"
   "\\graphicspath{ {./images/} }\n"
   "\\usepackage{caption}\n"
   "\\input{colors}\n"
   "\\usepackage{hyperref}\n"
   "\\hypersetup{colorlinks  = true, % Swap these two if You \n"
   "            %hidelinks   = false,  % Don't want links to be obvious.\n"
   "             linkcolor   = href-link,\n"
   "             filecolor   = href-file,\n"
   "             urlcolor    = href-url, \n"
   "             anchorcolor = href-anchor,\n"
   "             citecolor   = href-cite,\n"
   "             menucolor   = href-menu,\n"
   "             runcolor    = href-run,\n"
   "             linktoc     = all,\n"
   "             pdftitle    = \\localtitle,\n"
   "             pdfauthor   = \\localauthor,\n"
   "            %pdfsubject  = key topic,  % Metadata not supported by\n"
   "            %pdfkeywords = key words,  % Genpro yet.\n"
   "}\n"
   "\\usepackage[noabbrev]{cleveref}\n"
   "\\usepackage{fancyvrb}\n"
   "\\input{listings}\n"
   "\\usepackage{minted}\n"
   "\\usepackage{datetime2}\n"
   "\\usepackage{luamplib}\n"
   "\\mplibtextextlabel{enable}\n"
   "\\everymplib{input metauml;}\n"
   "\\mplibforcehmode\n"
   "\\usepackage{mflogo}\n"
   "\\usepackage{csquotes}\n"
   "\\renewcommand\\labelitemi{\\bullet}\n"
   "\\renewcommand\\labelitemii{\\cdot}\n"
   "\\renewcommand\\labelitemiii{\\circ}\n"
   "\\AtBeginEnvironment{appendices}{\\crefalias{section}{appendix}}\n"
   "\\newcommand{\\hlabel}{\\phantomsection\\label}\n"
   "\\newcommand{\\noteheader}{ \\\\ \\frenchspacing{}\\textit{Note.}\\nonfrenchspacing{}\\doublespacing{} }\n"
   "\\newcommand{\\figuretitle}[1]{\\caption[]{ \\\\~\\\\ \\textit{#1}}}\n\n"
   "\\doublespacing\n"
   "\\DeclareCaptionLabelSeparator*{spaced}{\\\\[2ex]}\n"
   "\\captionsetup[table]{labelsep=none,labelfont=bf,justification=raggedright,\n"
   "  singlelinecheck=false}\n"
   "\\captionsetup[figure]{labelsep=none,labelfont=bf,justification=raggedright,\n"
   "  singlelinecheck=false}\n"

   "\n% Generated with genpro.\n"))

(define (build-listings-file meta-info)
  "Dumps my standard listings.tex out as a <string>."
  (string-append
   "\\usepackage[procnames]{listings}\n"
   "\n"
   "\\makeatletter\n"
   "\\lst@InputCatcodes\n"
   "\\def\\lst@DefEC{%\n"
   " \\lst@CCECUse \\lst@ProcessLetter\n"
   "  ^^80^^81^^82^^83^^84^^85^^86^^87^^88^^89^^8a^^8b^^8c^^8d^^8e^^8f%\n"
   "  ^^90^^91^^92^^93^^94^^95^^96^^97^^98^^99^^9a^^9b^^9c^^9d^^9e^^9f%\n"
   "  ^^a0^^a1^^a2^^a3^^a4^^a5^^a6^^a7^^a8^^a9^^aa^^ab^^ac^^ad^^ae^^af%\n"
   "  ^^b0^^b1^^b2^^b3^^b4^^b5^^b6^^b7^^b8^^b9^^ba^^bb^^bc^^bd^^be^^bf%\n"
   "  ^^c0^^c1^^c2^^c3^^c4^^c5^^c6^^c7^^c8^^c9^^ca^^cb^^cc^^cd^^ce^^cf%\n"
   "  ^^d0^^d1^^d2^^d3^^d4^^d5^^d6^^d7^^d8^^d9^^da^^db^^dc^^dd^^de^^df%\n"
   "  ^^e0^^e1^^e2^^e3^^e4^^e5^^e6^^e7^^e8^^e9^^ea^^eb^^ec^^ed^^ee^^ef%\n"
   "  ^^f0^^f1^^f2^^f3^^f4^^f5^^f6^^f7^^f8^^f9^^fa^^fb^^fc^^fd^^fe^^ff%\n"
   "  ^^^^20ac^^^^0153^^^^0152%\n"
   "  ^^^^20a7^^^^2190^^^^2191^^^^2192^^^^2193^^^^2206^^^^2207^^^^220a%\n"
   "  ^^^^2218^^^^2228^^^^2229^^^^222a^^^^2235^^^^223c^^^^2260^^^^2261%\n"
   "  ^^^^2262^^^^2264^^^^2265^^^^2282^^^^2283^^^^2296^^^^22a2^^^^22a3%\n"
   "  ^^^^22a4^^^^22a5^^^^22c4^^^^2308^^^^230a^^^^2336^^^^2337^^^^2339%\n"
   "  ^^^^233b^^^^233d^^^^233f^^^^2340^^^^2342^^^^2347^^^^2348^^^^2349%\n"
   "  ^^^^234b^^^^234e^^^^2350^^^^2352^^^^2355^^^^2357^^^^2359^^^^235d%\n"
   "  ^^^^235e^^^^235f^^^^2361^^^^2362^^^^2363^^^^2364^^^^2365^^^^2368%\n"
   "  ^^^^236a^^^^236b^^^^236c^^^^2371^^^^2372^^^^2373^^^^2374^^^^2375%\n"
   "  ^^^^2377^^^^2378^^^^237a^^^^2395^^^^25af^^^^25ca^^^^25cb%\n"
   "  ^^00}\n"
   "\\lst@RestoreCatcodes\n"
   "\\makeatother\n"
   "\n"
   "\\lstdefinelanguage{apl}\n"
   "{\n"
   "extendedchars=true,\n"
   "sensitive=True,\n"
   "breakatwhitespace=false,\n"
   "otherkeywords={},\n"
   "morekeywords= [2]{', (, ), +, \\,, -, ., /, :, ;, <, =, >, ?, [, ], \n"
   "\\\\, _, ¨, ¯, ×, ÷, ←, ↑, →, ↓, ∆, ∇, ∘, ∣, ∧, ∨, \n"
   "∩, ∪, ∼, ≠, ≤, ≥, ≬, ⊂, ⊃, ⌈, ⌊, ⊤, ⊥, ⋆, ⌶, ⌷, \n"
   "⌸, ⌹, ⌺, ⌻, ⌼, ⌽, ⌾, ⌿, ⍀, ⍁, ⍂, ⍃, ⍄, ⍅, ⍆, ⍇, \n"
   "⍈, ⍉, ⍊, ⍋, ⍌, ⍍, ⍎, ⍏, ⍐, ⍑, ⍒, ⍓, ⍔, ⍕, ⍖, ⍗, \n"
   "⍘, ⍙, ⍚, ⍛, ⍜, ⍞, ⍟, ⍠, ⍡, ⍢, ⍣, ⍤, ⍥, ⍦, ⍧, \n"
   "⍨, ⍩, ⍪, ⍫, ⍬, ⍭, ⍮, ⍯, ⍰, ⍱, ⍲, ⍳, ⍴, ⍵, ⍶, ⍷, \n"
   "⍸, ⍹, ⍺, ⎕, ○, *},\n"
   "alsoletter={/,-,*,|,\\\\,\\,},\n"
   "morecomment=[l]{⍝},\n"
   "morecomment=[l]{\\#},\n"
   "morestring=[b]\",\n"
   "morestring=[b]',\n"
   "moreprocnamekeys={∇}\n"
   "}[keywords, comments, strings, procnames]\n"
   "\n"
   "\\lstset{%\n"
   "  basicstyle=\\freemono\\small,\n"
   "  keywordstyle=[2]\\color{code-keyword},\n"
   "  procnamestyle=\\color{code-variable},\n"
   "  % identifierstyle=,\n"
   "  commentstyle=\\slshape\\color{code-comment}, % no slanted shape in APL385\n"
   "  stringstyle=\\ttfamily\\color{code-string},\n"
   "  showstringspaces=false,\n"
   "  % frame=single,\n"
   "  % framesep=1pt,\n"
   "  % framerule=0.8pt,\n"
   "  breaklines=true,      % break long code lines\n"
   "  breakindent=0pt\n"
   "}\n"))

(define (build-colors-file meta-info)
  ""
  (string-append
   " \\usepackage[html]{xcolor}\n"
   "% CDR Colors\n"
   "\\definecolor{cdr-black}{HTML}{2d3743}\n"
   "\\definecolor{cdr-cyan}{HTML}{34cae2}\n"
   "\\definecolor{cdr-orange}{HTML}{e67128}\n"
   "\\definecolor{cdr-green}{HTML}{338f86}\n"
   "\\definecolor{cdr-magenta}{HTML}{ee7ae7}\n"
   "\\definecolor{cdr-red}{HTML}{ff4242}\n"
   "\\definecolor{cdr-white}{HTML}{e1e1e0}\n"
   "\\definecolor{cdr-yellow}{HTML}{ffad29}\n"
   "\n"
   "% HrefColors\n"
   "\\definecolor{href-link}{HTML}{03872d}\n"
   "\\definecolor{href-file}{HTML}{032d87}\n"
   "\\definecolor{href-url}{HTML}{032d87}\n"
   "\\definecolor{href-cite}{HTML}{2d0387}\n"
   "\\definecolor{href-anchor}{HTML}{87032d}\n"
   "\\definecolor{href-menu}{HTML}{03872d}\n"
   "\\definecolor{href-run}{HTML}{87032d}\n"
   "\n"
   "% CodeColors\n"
   "\n"
   "% Pygments Xcode Theme:\n"
   "% =====================\n"
   "% Keywords A90D91\n"
   "% Comments 177500\n"
   "% Variable 3F6E75\n"
   "% String C41A16\n"
   "% Constant 1C01CE\n"
   "\\definecolor{code-comment}{HTML}{177500}\n"
   "\\definecolor{code-keyword}{HTML}{a90d91}\n"
   "\\definecolor{code-variable}{HTML}{3f6e75}\n"
   "\\definecolor{code-string}{HTML}{c41a16}\n"
   "\\definecolor{code-constant}{HTML}{1c01ce}\n"
   "\n"))

(define (build-main-file meta-info)
  "Dumps my standard main.tex out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of main.tex.

Impurities
==========

None.
"
  (string-append
   "% This is main.tex\n"
   "\\documentclass[12pt, american]{report}\n"
   "\\input{meta}\n"
   "\\input{preamble}\n"
   "\\begin{document}\n"
   "\\pagenumbering{arabic}\n"
   "\\setlength{\\headheight}{14.49998pt}\n"
   "\\addtolength{\\topmargin}{-2.49998pt}\n"
   "\\input{title-page}\n"
   "\\newpage\n"
   "\\section*{\\localtitle{}}\n"
   "% For /just/ figures, comment out the following five lines --\n"
   "\\input{content}\n"
   "\\newpage\n"
   "\\section*{References}\n"
   "\\printbibliography[heading=none]\n"
   "\\newpage\n"
   "% -----------------------------------------------------------\n"
   "\\input{figures}\n"
   "\\end{document}"))

(define (build-title-file meta-info)
  "Dumps my standard title-page.tex out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of title-page.tex.

Impurities
==========

None.
"
  (string-append
   "\\begin{center}\n"
   "  \\vspace*{5cm}\n"
   "  \\textbf{\\localtitle}\\\\\n"
   "  \\vspace{\\baselineskip}\n"
   "  \\localauthor\\\\\n"
   "  \\localschool\\\\\n"
   "  \\localsection\\\\\n"
   "  \\localprofessor\\\\\n"
   "  \\localduedate\n"
   "\\end{center}\n"))
(define* (build-java-file meta-info #:optional (java-file-string genpro-java-file))
  "Dumps my standard, blank Implementation.java out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of Implementation.java.

Impurities
==========

None.
"
  java-file-string)
(define* (build-java-package-info-file meta-info #:optional (java-file-string
                                                             genpro-java-pkginfo))
  "Dumps my standard, blank Implementation.java out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of Implementation.java.

Impurities
==========

None.
"
  java-file-string)
(define (build-metapost-file meta-info)
  "Dumps my standard figure.mp out as a <string>.

This is a CALCULATION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

A <string> representing the contents of figure.mp.

Impurities
==========

None.
"
  genpro-metapost-file)

(define (make-file meta-info file-name string-function)
  "Creates a file based on supplied arguments. Pre-existing files will be 
overwritten.

This is an ACTION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

FILE-NAME <string>: The name of the file to create.

STRING-FUNCTION <function>: A generator function for the contents of the file.

Returns
=======

<undefined> on success. Errors on errors.

Impurities
==========

Creates the file FILE-NAME in the current directory and fills it with the output
of STRING-FUNCTION called with META-INFO as its only argument.
"
  (call-with-output-file file-name
    (lambda (port)
      (put-string port
                  (apply string-function
                         (list meta-info))))))

(define (make-project meta-info)
  "Creates the files needed for a latex project.

This is an ACTION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======

<undefined> on success, errors on errors.

Impurities
==========

Creates the following files, symlinks, and directories, overwriting them if they
exist:

./src/
./src/main.tex
./src/meta.tex
./src/preamble.tex
./src/title-page.tex
./content.tex
./src/content.tex => ../content.tex
./src/.metadata -> ../.metadata
./src/assignment/
./src/assignment/Implementation.java
./src/figure.mp"
  (let ((name (build-file-name meta-info))
        (java-component (cdr (hashq-get-handle meta-info 'java-project?))))
    (if (not (file-exists? "./src"))
        (mkdir "./src"))
    (make-file meta-info "./src/main.tex" build-main-file)
    (make-file meta-info "./src/meta.tex" build-meta-file)
    (make-file meta-info "./src/preamble.tex" build-preamble-file)
    (make-file meta-info "./src/title-page.tex" build-title-file)
    (make-file meta-info "./src/listings.tex" build-listings-file)
    (make-file meta-info "./src/colors.tex" build-colors-file)
    (system "touch content.tex")
    (system "touch figures.tex")
    (system "touch .assignment")
    (symlink "../.metadata" "./src/.metadata")
    (symlink "../content.tex" "./src/content.tex")
    (symlink "../figures.tex" "./src/figures.tex")
    (chdir "src/")
    (if java-component
        (begin
          (if (not (file-exists? "./assignment"))
              (begin
                (mkdir "./assignment")
                (make-file meta-info "./assignment/Implementation.java"
                           build-java-file)
                (make-file meta-info "./assignment/package-info.java"
                           build-java-package-info-file)))
          (if (not (file-exists? "./doc"))
              (mkdir ".doc/"))
          (system (string-append "touch "
                                 name
                                 ".java.zip"))))
    (make-file meta-info "./figure.mp"
               build-metapost-file)
    (symlink "./main.tex" (string-append "./" name ".tex"))
    (run-lualatex name)
    (system (string-append "lwarpmk html"))
    (copy-file (string-append name ".pdf") (string-append "../" name ".pdf"))
    (delete-file (string-append name ".pdf"))
    (symlink (string-append "../" name ".pdf") (string-append name ".pdf"))
    (copy-file (string-append name ".html") (string-append "../" name ".html"))
    (delete-file (string-append name ".html"))
    (symlink (string-append "../" name ".html") (string-append name ".html"))
    (chdir "../")))

(define (run-lualatex name)
  "Runs the lualatex program with some sensible defaults, specifying a jobname 
based on the project.

This is an ACTION.

Arguments
=========

NAME <string>: The jobname for lualatex.

Returns
=======

<undefined> on success, errors on errors.

Impurities
==========

Calls the program \"lualatex\" on the file \"main.tex\" in the current 
directory, to create (among other intermediary files) a PDF document. Can be
UNSAFE if contents of \"main.tex\" are unknown: arbitrary code can be executed.
"
  (system (string-append "lualatex --output-format pdf --jobname="
                         name
                         " --shell-escape main.tex")))
(define (compile-java-component name meta-info)
"Compile the Java component of the project.

This is an ACTION.

Arguments
=========
NAME <string>: The name of the project.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."  
(if (and (file-exists? "./assignment/Implementation.java")
         (cdr (hashq-get-handle meta-info 'java-project?)))
    (let* ((list-of-libs (caddr (hashq-get-handle meta-info
                                                  'java-local-libraries)))
           (project-classpath
            (if (eq? '() list-of-libs)
                "."
                (generate-classpath-includes list-of-libs)))
           (javadoc-classpath
            (string-append
             "..:"
             project-classpath)))
        (system "rm -rfv assignment/*.redacted.*")
        (display "Compiling the Java Component…\n")
        (chdir "doc/")
        (system
         (string-append
          "javadoc -private -cp "
          javadoc-classpath
          " assignment"))
        (chdir "..")
        (system (string-append
                 "javac -cp "
                 project-classpath
                 " assignment/*.java"))
        (system (string-append "jar -v -c -f "
                               name
                               ".jar -e assignment.Implementation "
                               "assignment/"))
        (compile-java-redact-javadoc "assignment/Implementation.java")
        (system (generate-java-zipfile-command name list-of-libs)))
      (display (string-append "Java Compilation Requested, but no "
                              "file found or .metadata says it shouldn't"
                              " be…\nSkipping…\n"))))
(define (compile-metapost-component)
"Compile the Metapost component of the project.

This is an ACTION.

Arguments
=========
None.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."
  (if (file-exists? "figure.mp")
      (begin
        (display "Compiling the Metapost Component…\n")
        (system "mpost figure.mp"))
      (display (string-append "Metapost Compilation Requested, but no "
                              "file found…\nSkipping…\n"))))

(define (compile-lualatex-setup name)
  "Clears old temporary files and does an initial compile of the PDF and HTML
components of the project.

This is an ACTION.

Arguments
=========
NAME <string>: The name of the project.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."  
  (system (string-append "lwarpmk clean"))
  (system (string-append "lwarpmk cleanlimages"))
  (run-lualatex name)
  (system (string-append "lwarpmk again"))
  (system (string-append "lwarpmk html")))

(define (compile-biber-component name)
"Compile the Biber (references) component of the project.

This is an ACTION.

Arguments
=========
NAME <string>: The name of the project.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."  
  (system (string-append "biber " name))
  (system (string-append "biber " name "_html")))

(define (compile-pdf-component name)
"Compile the PDF component of the project.

This is an ACTION.

Arguments
=========
NAME <string>: The name of the project.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."
  (run-lualatex name))

(define (compile-html-component)
"Compile the HTML component of the project, including images.

This is an ACTION.

Arguments
=========
None.

Returns
=======
Undefined.

Impurities
==========
Runs system commands that change various files."
  (system (string-append "lwarpmk again"))
  (system (string-append "lwarpmk html"))
  (system (string-append "lwarpmk limages")))


(define* (compile-project meta-info
                          #:optional
                          (pdf #t)
                          (html #t)
                          (java #t)
                          (metapost #t)
                          (text #t))
  "Compiles the LaTeX project in the ./src/ directory, assuming the 
\"main.tex\" file exists.

This is an ACTION.

Arguments
=========

META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>
PDF <boolean>: Does the user want PDF Compilation?
HTML <boolean>: Does the user want HTML Compilation?
JAVA <boolean>: Does the user want JAVA Compilation?
METAPOST <boolean>: Does the user want METAPOST Compilation?

Returns
=======

<undefined> on success, errors on errors.

Impurities
==========

Runs system commands in this order:

lualatex
lwarpmk
biber
biber
lualatex
lualatex
lwarpmk

Which creates a large number of intermediary files, but ideally creates NAME.pdf
and NAME_html.html from main.tex.
"
  (let ((name (build-file-name meta-info))
        (list-of-libs (caddr (hashq-get-handle meta-info 'java-local-libraries))))
    (chdir "src")
    (if (and java
             (cdr (hashq-get-handle meta-info 'java-project?)))
        (compile-java-component name meta-info))
    (if metapost
        (compile-metapost-component))
    (if (or pdf html)
        (begin
          (compile-lualatex-setup name)
          (compile-biber-component name)))
    (if pdf
        (compile-pdf-component name))
    (if html
        (compile-html-component))
    (if text
        (compile-text-component name))
    (chdir "..")))


(define genpro-java-file
  "package assignment;
import java.util.Scanner;
import java.lang.StringBuilder;
import java.lang.RuntimeException;
/**
 * <p>A One-Line Description of the Purpose of this Class in Active
 * Voice.</p>
 *
 * <p>A Longer Description of the thought process behind this code.</p>
 *
 */
public class Implementation {
    /**
     * <p>Default, empty constructor.</p>
     *
     * <p>This is a <strong>CALCULATION</strong>.
     *
     * <p><strong>Impurities:</strong> None.</p>
     *
     */
    Implementation() {
    }
    // Personal Exception Type for bad Strings gained from User Input.
    /**
     * <p>An exception for when user input is impermissable.</p>
     *
     * <p>Basically a <code>RuntimeException</code>, but named differently
     * for more readable code.</p>
     *
     */
    private static class InvalidInputException extends RuntimeException {
        /**
         * <p>Creates an error specifying invalid input from the user.</p>
         *
         * <p>This is a <strong>CALCULATION</strong>.
         
         * <p><em>Impurities:</em> None.</p>
         * @param errorMessage the message to display to the user.
         * @param error the actual throwable error object, for root cause
         * investigation.
         */
        private InvalidInputException(String errorMessage, Throwable error) {
            super(errorMessage, error);
        }
    }
    /**
     * <p>The message we'll use to indicate that empty input was
     * received.</p>
     */
    private static String emptyInputMessage =
        \"Please Enter Something, Input Input is not Allowed.\";
    /**
     * <p>A pre-built, generic InvalidInputException meant for when empty
     *  user input is supplied.</p>
     */
    private static InvalidInputException emptyInput =
        new InvalidInputException(emptyInputMessage, null);
    /**
     * <p>Gets input from the supplied <code>Scanner</code>, ensuring it is
     * not empty.</p>
     *
     * <p>This is an <strong>ACTION</strong>.
     *
     * <p><em>Impurities:</em> IO.</p>
     *
     * @param scanner what to use for getting the input.
     * @return The supplied input, once it is not empty.
     * @throws InvalidInputException if empty input is supplied.
     *
     */
    private static String getRawInput(Scanner scanner)
        throws InvalidInputException {
        String result = \"\";
        while (result == \"\") {
           try {
                result = scanner.next();
                if (result.equals(\"\")) {
                    throw emptyInput;
                }
            } catch (InvalidInputException e) {
                System.out.println(\"ERROR: \" + e.getMessage());
            }
        }
        return result;
    }
    /**
     * <p>A pre-defined <code>Scanner</code> object for use in main, which
     * accepts input up to a newline as <code>next()</code>.</p>
     */
    private static Scanner scanner = new Scanner(System.in)
        .useDelimiter(\"\\n\");
    /**
     * <p>A pre-defined <code>StringBuilder</code> object for use in
     * main.</p>
     */    
    private static StringBuilder stringBuilder = new StringBuilder();
    /**
     * <p>Runs the Actual Assignment.</p>
     *
     * <p>This is an <strong>ACTION</strong>.
     *
     * <p><strong>Impurities:</strong> IO.</p>
     *
     * @param args arguments from the CLI.
     */
    public static void main(String args[]) {
        stringBuilder.append(getRawInput(scanner));
        System.out.println(stringBuilder.toString());
    }
}\n")

(define genpro-metapost-file
  "prologues := 3;
outputtemplate := \"%j-%c.mps\";
string metauml_defaultFont;
string metauml_defaultFontOblique;
string metauml_defaultFontBold;
string metauml_defaultFontBoldOblique;
metauml_defaultFont := \"texnansi-qtmr\";
metauml_defaultFontOblique  := \"texnansi-qtmri\";
metauml_defaultFontBold  := \"texnansi-qtmb\";
metauml_defaultFontBoldOblique  := \"texnansi-qtmbi\";
input metauml;
def U primary s = if string s: decode(s) fi enddef;
vardef decode(expr given) = 
    save a, i, s, out; string s, out; numeric a, i;
    out = \"\"; i=0;
    forever:
        s := substring (i, incr i) of given; 
        a := ASCII s;
        if a < 128: 
        elseif a = 194: 
            s := substring (i, incr i) of given;
        elseif a = 195: 
            s := char (64 + ASCII substring (i, incr i) of given);
        else: 
            s := \"?\";
        fi
        out := out & s;
        exitif i >= length given;
    endfor
    out
enddef;
beginfig(1);
  Activity.A(U\"«Create» <>\");
  drawObjects(A);
endfig;
end.
")

(define genpro-java-pkginfo
  "/**
 * This package is meant to implement Assignment 00 of CSC00.
 *
 * <p>The original Assignment Given was:</p>
 *
 * <pre>Your first assignment is to get to know the team of learners with
 * whom you will be working. Please introduce yourself in this discussion
 * forum. Focus your introduction on areas you feel are relevant to your work
 * in the course but, give your introduction a personal touch as well.
 *
 * Also, share your location, your career aspirations, and any personal
 * experiences or knowledge that relates to this course. You may also post a
 * picture of yourself.
 *
 * What experience and interest do you have in computer programming? How
 * might the knowledge and skills associated with this course support your
 * career goals or life aspirations?</pre>
 *
 * @since 15.0
 * @author yewscion
 * @version 1.0
 */
package assignment;")

(define (generate-java-zipfile-command name list-of-libs)
"Generates a shell command for creating a zipfile of the java component of a project.

This is a CALCULATION.

Arguments
=========
NAME<string>: A <string> of the format \"date.section.project-name\",
with only the part of the section before the colon included.

Returns
=======
A <string> that can be used to generate a distributable zipfile of the java
component of a project.

Impurities
==========
None."
  (let ((zipcmd " zip -9 -r -v ")
        (files (string-append " assignment/*.java "
                              name
                              ".jar doc/ "
                              (if (not (eq? '() list-of-libs))
                                  (string-join
                                   (map (lambda (x)
                                          (string-append
                                           "../lib/"
                                           x))
                                        list-of-libs)
                                   " "
                                   'infix)
                                  "")))
        (tmpdir (string-append " " name ".java/ "))
        (zipname (string-append " " name ".java.zip "))
        (wipname (string-append name "-wip.zip ")))
    
    (string-append
     zipcmd
     wipname
     files
     "&& mkdir -pv"
     tmpdir
     "&& cd"
     tmpdir
     "&& unzip ../"
     wipname
     "&& cd .. && rm"
     zipname
     "&&"
     zipcmd
     zipname
     tmpdir
     "&& rm -rf "
     wipname
     tmpdir)))

(define default-metadata-contents
  (string-append
   ";;; -*- scheme -*-\n"
   ";;; This is the metadata file for genpro projects.\n"
   ";;;\n"
   ";;; Replace the default values with the ones appropriate for Your\n"
   ";;; project.\n"
   "(define project-metadata-file-info\n"
   "'((title \"Project Title\")\n"
   "  (author \"Christopher Rodriguez\")\n"
   "  (bibliography \"~/Documents/biblio/main.bib\")\n"
   "  (school \"Colorado State University Global\")\n"
   "  (section \"Some Class: Some Title of Class\")\n"
   "  (professor \"Dr. Some Professor\")\n"
   "  (date \""
   (date->string (current-date) "~1")
   "\")\n"
   "  (annotated-bibliography? #false)\n"
   "  (java-project? #true)\n"
   "  (java-local-libraries '())))\n"))

(define (create-metadata-file)
  "Create the default .metadata file for a new project.

This is an ACTION.

Arguments
=========
None.

Returns
=======
Unspecified.

Impurities
==========
I/O, creates file on local filesystem."
  (dump-string-to-file ".metadata" default-metadata-contents)
  (display
   (string-append
    "Created the .metadata file with defaults.\n\nPlease"
    " edit those and then run the script again.\n")))

(define (create-projectile-file)
"Create the default .projectile file for a new project.

Arguments
=========
None.

Returns
=======
Unspecified.

Impurities
==========
I/O, creates file on local filesystem."
  (dump-string-to-file ".projectile" ";;; Generated with Genpro.")
  (display
   (string-append
    "Created a .projectile file, for use with projectile in GNU Emacs.\n\n"
    "Projectile is Ready to Go.\n")))

(define (clean-project metainfo)
"Recreate a clean version of a project, preserving commonly edited files.

This is an ACTION.

Arguments
=========
META-INFO <hash-table>: A 8 element data structure with the following keys:

                        'bibliography <string>
                        'project <string>
                        'author <string>
                        'school <string>
                        'section <string>
                        'professor <string>
                        'date <srfi-19 date>
                        'annotated-bibliography <bool>

Returns
=======
Unspecified.

Impurities
==========
I/O, File Deletion and Creation, Relies On and Changes System State."
  
  (if (and (file-exists? "content.tex")
           (file-exists? ".metadata"))
      (let ((content (slurp-file-as-string "content.tex"))
            (figures (slurp-file-as-string "figures.tex"))
            (metadata (slurp-file-as-string ".metadata"))
            (assignment (slurp-file-as-string ".assignment"))
            (projectile (slurp-file-as-string ".projectile"))
            (metapost (slurp-file-as-string "src/figure.mp")))
        (system "find . -maxdepth 2 -not -path \"*assignment*\" -exec rm -fv {} \\;")
        (dump-string-as-file-if-bound metadata ".metadata")
        (dump-string-as-file-if-bound assignment ".assignment")
        (dump-string-as-file-if-bound projectile ".projectile")
        (make-project metainfo)
        (dump-string-as-file-if-bound content "content.tex")
        (dump-string-as-file-if-bound figures "figures.tex")
        (dump-string-as-file-if-bound metapost "src/figure.mp")
        (compile-project metainfo)
        (display "Genpro Project Cleaned and Rebuild Complete.\n"))
  (display (string-append "This doesn't seem like a Genpro project…\n"
                          "Not cleaning anything.\n"))))
(define (compile-java-redact-javadoc filename)
"Remove any and all JavaDoc comments from the file at FILENAME.

This is an ACTION.

Arguments
=========
FILENAME<string>: The name (and possibly path) of the file to alter.

Returns
=======
Undefined.

Impurities
==========
File I/O."
  (let ((result (add-section-to-filename "redacted" filename))
        (contents (get-file-as-string filename)))
    (if (not contents)
        (display (string-append "Could not modify "
                                filename
                                "; are You sure it exists?"))
        (dump-string-to-file
         result
         (remove-c-multiline-comments-from-string contents)))))

(define (run-java-jarfile meta-info)
 "Execute the Runnable Jarfile created by this project.

This is an ACTION.

Arguments
=========
META-INFO <hash-table>: A Ten-Parameter Hash table with the keys 
                        'date <srfi-19 date>, 'section <string>, 
                        'annotated-bibliography, and 'project <string>.

Returns
=======
Undefined.

Impurities
==========
Runs an external tool on files on disk, I/O."
 (let ((project-name (build-file-name meta-info))
       (classpath (generate-classpath-includes
                   (caddr (hashq-get-handle meta-info 'java-local-libraries)))))
   (display (string-append "Running src/"
                           project-name
                           ".jar with included libraries…\n"))
   (if (file-exists? (string-append "src/"
                                    project-name
                                    ".jar"))
       (system (string-append "java -cp "
                              classpath
                              " -jar src/"
                              project-name
                              ".jar"))
       (display (string-append "Please clean project: \"./src/"
                               project-name
                               ".jar\" is missing.\n")))))

(define (compile-text-component filename)
  "Dumps a text-mode representation of the HTML version of the project to
disk.

This is an ACTION.

Arguments
=========
FILENAME<string>: The name (and possibly path) of the HTML file to use as a
base.

Returns
=======
Undefined.

Impurities
==========
Runs an external tool on files on disk, I/O."

  (system (string-append "lynx --dump "
                         filename
                         ".html > "
                         filename
                         ".txt")))

(define (generate-classpath-includes list-of-libs)
  "Generates the argument for the javadoc cp flag.

This is a CALCULATION.

Arguments
=========

LIST-OF-LIBS <<list> of <strings>>: A list of files to include, which reside
in the ../../lib directory.

Returns
=======

A <string> meant to be used as an argument to the -cp flag of javadoc.

Impurities
==========
None."
  (if (> (length list-of-libs) 0)
      (string-append
       "..:"
       (string-join
        (map
         (lambda (x)
           (string-append
            "../../lib/"
            x))
         list-of-libs)
        ":"
        'infix))
      "."))

(define (slurp-file-as-string file)
  "If FILE refers to an existing file, dump its contents as a <string>.

This is an ACTION.

Arguments
=========

FILE <string>: The filename in question.

Returns
=======

If the file exists, the contents thereof as a <string>. If not, <false>.

Impurities
==========
File I/O, relies on filesystem state.
"
  (if (file-exists? file)
                      (call-with-input-file
                          file
                        get-string-all)
                      #f))

(define (dump-string-as-file-if-bound string file)
  "If STRING is not <false>, dump its value to FILE.

This is an ACTION.

Arguments
=========

STRING <string>: The string we are trying to dump to disk.

FILE <string>: The file name we will dump STRING to, if it exists.

Returns
=======

<undefined>


Impurities
==========
Solely used for Side Effects; File I/O.
"
  (if string
      (dump-string-to-file file
                           string)))
        

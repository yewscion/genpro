(define-module (cdr255 genpro)
  :use-module (ice-9 ftw)           ; For Filesystem Access.
  :use-module (ice-9 textual-ports) ; For Writing to Files.
  :use-module (srfi srfi-19)        ; For Dates.
  :export (make-project
           compile-project
           hash-meta-info))

(define (hash-meta-info bib
                        pro
                        aut
                        sch
                        sec
                        prf
                        dat
                        ann)
  "Takes the project's metadata and turns it into a seven-element hash table.

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

Impurities
==========

None.
"
  (let ((table (make-hash-table 8)))
    (hashq-create-handle! table 'bibliography bib)
    (hashq-create-handle! table 'project pro)
    (hashq-create-handle! table 'author aut)
    (hashq-create-handle! table 'school sch)
    (hashq-create-handle! table 'section sec)
    (hashq-create-handle! table 'professor prf)
    (hashq-create-handle! table 'date (string->date dat "~Y-~m-~d"))
    (hashq-create-handle! table 'annotated-bibliography ann)
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

META-INFO <hash-table>: A Seven-Parameter Hash table with the keys 
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
   "\\usepackage[mathjax]{lwarp}\n"
   "\\CSSFilename{https://cdr255.com/css/lwarp-cdr255.css}\n"
   "\\usepackage{geometry}\n"
   "\\geometry{\n"
   "  letterpaper,\n"
   "  left=1in,\n"
   "  right=1in,\n"
   "  top=1in,\n"
   "  bottom=1in}\n"
   "\\usepackage{etoolbox}\n"
   "\\patchcmd{\\titlepage}\n"
   "  {\\thispagestyle{empty}}\n"
   "  {\\thispagestyle{fancy}}\n"
   "  {}\n"
   "  {}\n"
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
   "\\usepackage[doublespacing]{setspace}\n"
   "\\usepackage{indentfirst}\n"
   "\\usepackage{fontspec}\n"
   "\\setmainfont{TeXGyreTermes}\n"
   "\\appto{\\bibsetup}{\\raggedright}\n"
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
   "\\usepackage[nomarkers]{endfloat}\n"
   "\\usepackage[noabbrev]{cleveref}\n"
   "\\usepackage{fancyvrb}\n"
   "\\usepackage{color}\n"
   "\\usepackage{listings}\n"
   "\\usepackage{minted}\n"
   "\\usepackage{datetime2}\n"
   "\\usepackage{csquotes}\n"
   "\n% Generated with genpro.\n"))

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
   "\\documentclass[12pt, american]{article}\n"
   "\\input{meta}\n"
   "\\input{preamble}\n"
   "\\begin{document}\n"
   "\\setlength{\\headheight}{14.49998pt}\n"
   "\\addtolength{\\topmargin}{-2.49998pt}\n"
   "\\input{title-page}\n"
   "\\section*{\\localtitle{}}\n"
   "\\input{content}\n"
   "\\newpage\n"
   "\\printbibliography\n"
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
   "\\begin{titlepage}\n"
   "  \\begin{center}\n"
   "    \\vspace*{5cm}\n"
   "    \\textbf{\\localtitle}\\\\\n"
   "    \\vspace{\\baselineskip}\n"
   "    \\localauthor\\\\\n"
   "    \\localschool\\\\\n"
   "    \\localsection\\\\\n"
   "    \\localprofessor\\\\\n"
   "    \\localduedate\n"
   "  \\end{center}\n"
   "\\end{titlepage}\n"
   "\\setcounter{page}{2}"))

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
./out/
./src/main.tex
./src/meta.tex
./src/preamble.tex
./src/title-page.tex
./content.tex
./src/content.tex => ../content.tex
./src/.metainfo -> ../.metainfo"
  (let ((name (build-file-name meta-info)))
    (mkdir "./src")
    (mkdir "./out")
    (make-file meta-info "./src/main.tex" build-main-file)
    (make-file meta-info "./src/meta.tex" build-meta-file)
    (make-file meta-info "./src/preamble.tex" build-preamble-file)
    (make-file meta-info "./src/title-page.tex" build-title-file)
    (system "touch content.tex")
    (symlink "../.metainfo" "./src/.metainfo")
    (symlink "../content.tex" "./src/content.tex")
    (chdir "src/")
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

(define (compile-project meta-info)
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
  (chdir "src")
  (let ((name (build-file-name meta-info)))
    (run-lualatex name)
    (system (string-append "lwarpmk again"))
    (system (string-append "lwarpmk html"))
    (system (string-append "biber " name))
    (system (string-append "biber " name "_html"))
    (run-lualatex name)
    (run-lualatex name)
    (system (string-append "lwarpmk again"))
    (system (string-append "lwarpmk html")))
  (chdir ".."))

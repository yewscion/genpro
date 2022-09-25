(define-module (cdr255 genpro)
  :use-module (ice-9 ftw)           ; For Filesystem Access.
  :use-module (ice-9 textual-ports) ; For Writing to Files.
  :use-module (srfi srfi-19)        ; For Dates.
  :use-module (cdr255 userlib)      ; Utility Functions.
  :export (make-project
           compile-project
           hash-meta-info
           clean-project
           create-metadata-file
           create-projectile-file))

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
   "\\usepackage[html]{xcolor}\n"
   "\\definecolor{color-link}{HTML}{03872d}\n"
   "\\definecolor{color-file}{HTML}{032d87}\n"
   "\\definecolor{color-url}{HTML}{032d87}\n"
   "\\definecolor{color-cite}{HTML}{2d0387}\n"
   "\\definecolor{color-anchor}{HTML}{87032d}\n"
   "\\definecolor{color-menu}{HTML}{03872d}\n"
   "\\definecolor{color-run}{HTML}{87032d}\n"
   "\\usepackage{hyperref}\n"
   "\\hypersetup{colorlinks  = true, % Swap these two if You \n"
   "            %hidelinks   = false,  % Don't want links to be obvious.\n"
   "             linkcolor   = color-link,\n"
   "             filecolor   = color-file,\n"
   "             urlcolor    = color-url, \n"
   "             anchorcolor = color-anchor,\n"
   "             citecolor   = color-cite,\n"
   "             menucolor   = color-menu,\n"
   "             runcolor    = color-run,\n"
   "             linktoc     = all,\n"
   "             pdftitle    = \\localtitle,\n"
   "             pdfauthor   = \\localauthor,\n"
   "            %pdfsubject  = key topic,  % Metadata not supported by\n"
   "            %pdfkeywords = key words,  % Genpro yet.\n"
   "}\n"
   "\\usepackage[noabbrev]{cleveref}\n"
   "\\usepackage{fancyvrb}\n"
   "\\usepackage{color}\n"
   "\\usepackage{listings}\n"
   "\\usepackage{minted}\n"
   "\\usepackage{datetime2}\n"
   "\\usepackage{luamplib}\n"
   "\\mplibtextextlabel{enable}\n"
   "\\everymplib{input metauml;}\n"
   "\\mplibforcehmode\n"
   "\\usepackage{csquotes}\n"
   "\\renewcommand\\labelitemi{\\bullet}\n"
   "\\renewcommand\\labelitemii{\\cdot}\n"
   "\\renewcommand\\labelitemiii{\\circ}\n"
   "\\AtBeginEnvironment{appendices}{\\crefalias{section}{appendix}}\n"
   "\\newcommand{\\hlabel}{\\phantomsection\\label}\n"
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
   "\\input{content}\n"
   "\\newpage\n"
   "\\section*{References}\n"
   "\\printbibliography[heading=none]\n"
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
  (let ((name (build-file-name meta-info)))
    (mkdir "./src")
    (make-file meta-info "./src/main.tex" build-main-file)
    (make-file meta-info "./src/meta.tex" build-meta-file)
    (make-file meta-info "./src/preamble.tex" build-preamble-file)
    (make-file meta-info "./src/title-page.tex" build-title-file)
    (system "touch content.tex")
    (symlink "../.metadata" "./src/.metadata")
    (symlink "../content.tex" "./src/content.tex")
    (chdir "src/")
    (mkdir "./assignment")
    (make-file meta-info "./assignment/Implementation.java"
               build-java-file)
    (make-file meta-info "./assignment/package-info.java"
               build-java-package-info-file)
    (mkdir "doc/")
    (system (string-append "touch "
                           name
                           ".java.zip"))
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
(define (compile-java-component name)
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
  (if (file-exists? "./assignment/Implementation.java")
      (begin
        (system "rm -rfv assignment/*.redacted.*")
        (display "Compiling the Java Component…\n")
        (chdir "doc/")
        (system "javadoc -cp .. assignment")
        (chdir "..")
        (system "javac assignment/*.java")
        (compile-java-redact-javadoc "assignment/Implementation.java")
        (system (string-append "jar -v -c -f "
                               name
                               ".jar -e assignment.Implementation "
                               "assignment/"))
        (system (generate-java-zipfile-command name)))
      (display (string-append "Java Compilation Requested, but no "
                              "file found…\nSkipping…\n"))))
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
                          (metapost #t))
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
  (let ((name (build-file-name meta-info)))
    (chdir "src")
    (if java
        (compile-java-component name))
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

(define (generate-java-zipfile-command name)
"Generates a shell command for creating a zipfile of the java component of a project.

This is a CALCULATION.

Arguments
=========
NAME <string>: The name of the project.

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
                              ".jar doc/ "))
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
   "  (annotated-bibliography? #false)))\n"))

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
      (let ((content (call-with-input-file "content.tex" get-string-all))
            (metadata (call-with-input-file ".metadata" get-string-all))
            (java (if (file-exists? "src/assignment/Implementation.java")
                      (call-with-input-file
                          "src/assignment/Implementation.java"
                        get-string-all)
                      #f))
            (pkginfo (if (file-exists? "src/assignment/package-info.java")
                         (call-with-input-file
                             "src/assignment/package-info.java"
                           get-string-all)
                         #f))
            (metapost (if (file-exists? "src/figure.mp")
                          (call-with-input-file
                              "src/figure.mp"
                            get-string-all)
                          #f)))
        (system "rm -rfv *")
        (dump-string-to-file ".metadata" metadata)
        (make-project metainfo)
        (dump-string-to-file "content.tex" content)
        (if java
            (dump-string-to-file "src/assignment/Implementation.java"
                          java))
        (if pkginfo
            (dump-string-to-file "src/assignment/package-info.java"
                          pkginfo))
        (if metapost
            (dump-string-to-file "src/figure.mp"
                          metapost))
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

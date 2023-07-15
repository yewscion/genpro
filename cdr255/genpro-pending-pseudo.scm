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

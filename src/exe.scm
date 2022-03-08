#!/usr/bin/env -S guile -e main -s
-e main -s
!#
(use-modules (cdr255 genpro)
             (ice-9 getopt-long))

(define option-spec
  '((version (single-char #\v) (value #f))
    (generate (single-char #\g) (value #f))
    (publish (single-char #\p) (value #f))))

(define (main args)
  (let* ((options (getopt-long args option-spec))
         (version (option-ref options 'version #f))
         (generate (option-ref options 'generate #f))
         (publish (option-ref options 'publish #f)))
    (unless (file-exists? ".metadata")
      (call-with-output-file ".metadata"
        (lambda (port)
          (put-string port
                      ";;; -*- scheme -*-
;;; This is the metadata file for genpro projects.
;;;
;;; Replace the default values with the ones appropriate for Your
;;; project.
(define project-metadata-file-info
'((title \"Project Title\")
  (author \"Christopher Rodriguez\")
  (bibliography \"~/Documents/biblio/main.bib\")
  (school \"Colorado State University Global\")
  (section \"Some Class: Some Title of Class\")
  (professor \"Dr. Some Professor\")
  (date \"2022-03-08\")))")))
      (display
       (string-append "Created the .metadata file with defaults.\n\nPlease edit "
                      "those and then run the script again.\n"))
      (quit))
    (load "./.metadata")
    (define meta-info
      (hash-meta-info (cadr (assoc 'bibliography
                                   project-metadata-file-info))
                      (cadr (assoc 'title
                                   project-metadata-file-info))
                      (cadr (assoc 'author
                                   project-metadata-file-info))
                      (cadr (assoc 'school
                                   project-metadata-file-info))
                      (cadr (assoc 'section
                                   project-metadata-file-info))
                      (cadr (assoc 'professor
                                   project-metadata-file-info))
                      (cadr (assoc 'date
                                   project-metadata-file-info))))
    (cond (version (display "genpro v0.0.1\n"))
          (generate (display "Generate Flag!\n")
                    (make-project meta-info))
          (publish (display "Publish Flag!\n")
                   (compile-project meta-info))
          (else (display-help)))))

(define (display-help)
  (display (string-append
            "Usage: genpro -g || -p \n\n"
            
            "Explanation of Options:\n\n"
            
            "  -g: Generate a new set of latex files based on the\n"
            "      contents of the .metadata file.\n"
            "  -p: Publish the project (run lualatex and biber on\n"
            "      main.tex)\n\n"

            "This program is entirely written in GNU Guile Scheme,\n"
            "and You are welcome to change it how You see fit.\n\n"

            "Guile Online Help: <https://www.gnu.org/software/guile/>\n"
            "Local Online Help: 'info guile'\n")))

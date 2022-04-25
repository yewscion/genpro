#!/usr/bin/env -S guile -e main -s
-e main -s
!#
(use-modules (cdr255 genpro)
             (ice-9 getopt-long)   ; For CLI Options and Flags.
             (ice-9 ftw)           ; For Filesystem Access.
             (ice-9 textual-ports) ; For Writing to Files.
             (srfi srfi-19)        ; For Dates.
)

(define option-spec
  '((version (single-char #\v) (value #f))
    (help (single-char #\h) (value #f))
    (generate (single-char #\g) (value #f))
    (publish (single-char #\p) (value #f))
    (no-projectile (single-char #\n) (value #f))
    (no-metadata (single-char #\N) (value #f))))

(define default-metadata-contents
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
  (date \"2022-03-08\")))")
  

(define (main args)
  (let* ((options (getopt-long args option-spec))
         (version (option-ref options 'version #f))
         (generate (option-ref options 'generate #f))
         (publish (option-ref options 'publish #f))
         (skip-metadata (option-ref options 'no-metadata #f))
         (skip-projectile (option-ref options 'no-projectile #f))
         (help (option-ref options 'help #f)))
    (cond (help (display-help))
          (version (display "genpro v0.0.2\n"))
          (not (or (file-exists? ".metadata") skip-metadata))
          ((call-with-output-file ".metadata"
             (lambda (port)
               (put-string port
                           default-metadata-contents)))
           (unless (or (file-exists? ".projectile") skip-projectile)
             (call-with-output-file ".projectile"
               (lambda (port)
                 (put-string port
                             ";;; Generated with Genpro."))))
           (display
            (string-append "Created the .metadata file with defaults.\n\nPlease"
                           " edit those and then run the script again.\n"))
           (quit))
          (else
           ((eval-string (call-with-input-file ".metadata"
                          (lambda (port)
                            (get-string-all port))))
            (let ((meta-info
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
                                                project-metadata-file-info)))))
              (cond (generate (make-project meta-info))
                    (publish (compile-project meta-info))
                    (else (display-help)))))))))

(define (display-help)
  (display (string-append
            "Usage: genpro -g || -p \n\n"
            
            "Explanation of Options:\n\n"
            
            "  -g/--generate:      Generate a new set of latex files based on\n"
            "                      the contents of the .metadata file.\n"
            "  -p/--publish:       Publish the project (run lualatex,\n"
            "                      lwarpmk, and biber on src/main.tex)\n"
            "  -n/--no-projectile: Skip making a .projectile file on\n"
            "                      generate.\n"
            "  -N/--no-metadata:   Skip making a .metadata file if it doesn't\n"
            "                      already exist.\n\n"

            "This program is entirely written in GNU Guile Scheme,\n"
            "and You are welcome to change it how You see fit.\n\n"

            "Guile Online Help: <https://www.gnu.org/software/guile/>\n"
            "Local Online Help: 'info guile'\n")))

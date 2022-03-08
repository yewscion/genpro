(define-module (cdr255 genpro)
  :use-module (ice-9 ftw)           ; For Filesystem Access.
  :use-module (ice-9 textual-ports) ; For Writing to Files.
  :use-module (srfi srfi-19)        ; For Dates.
  :export (genpro))

(define (say-hello)
  (display "Hello World!\n"))

(define (genpro)
  (say-hello))

(hall-description
  (name "genpro")
  (prefix "")
  (version "0.1.0")
  (author "Christopher Rodriguez")
  (copyright (2022))
  (synopsis "Project Manager for Research Projects.")
  (description
   (string-append
    "This project was born from a need to write a lot of papers for "
    "school very quickly. I wanted a standardized way to not only "
    "define the projects, but also run the more repetetive actions "
    " (`lualatex`, `biber`) on them. What I originally wrote to do "
    "this eventually became `genpro`."))
  (home-page "https://sr.ht/~yewscion/genpro/")
  (license agpl3+)
  (dependencies (list pkg-config
                          guile-3.0
                          autoconf
                          automake
                          biber
                          python-pygments
                          texlive-biblatex
                          texlive-biblatex-apa
                          texlive-capt-of
                          texlive-csquotes
                          texlive-etoolbox
                          texlive-fontspec
                          texlive-generic-etexcmds
                          texlive-generic-gettitlestring
                          texlive-generic-ifptex
                          texlive-generic-iftex
                          texlive-generic-xstring
                          texlive-ifmtarg
                          texlive-kpathsea
                          texlive-latex-catchfile
                          texlive-latex-cleveref
                          texlive-latex-comment
                          texlive-latex-datetime2
                          texlive-latex-datetime2-english
                          texlive-latex-endfloat
                          texlive-latex-environ
                          texlive-latex-everyhook
                          texlive-latex-fancyhdr
                          texlive-latex-fancyvrb
                          texlive-latex-float
                          texlive-latex-framed
                          texlive-latex-fvextra
                          texlive-latex-geometry
                          texlive-latex-ifplatform
                          texlive-latex-kvoptions
                          texlive-latex-letltxmacro
                          texlive-latex-lineno
                          texlive-latex-lwarp
                          texlive-latex-minted
                          texlive-latex-newfloat
                          texlive-latex-newunicodechar
                          texlive-latex-pdftexcmds
                          texlive-latex-printlen
                          texlive-latex-refcount
                          texlive-latex-setspace
                          texlive-latex-titlesec
                          texlive-latex-trimspaces
                          texlive-latex-upquote
                          texlive-latex-xkeyval
                          texlive-latex-xpatch
                          texlive-libkpathsea
                          texlive-listings
                          texlive-lm
                          texlive-luaotfload
                          texlive-svn-prov
                          texlive-tex-gyre
                          texlive-tracklang
                          texlive-varwidth
                          texlive-xcolor
                          texlive-xifthen))
  (files (libraries
          ((directory "cdr255"
           ((scheme-file "genpro")))))
         (tests ((directory "tests" ((scheme-file "tests")))))
         (programs ((directory "bin" ((in-file "genpro")))))
         (documentation
          ((directory "doc" ((texi-file "genpro")))
           (text-file "NEWS")
           (text-file "AUTHORS")
           (org-file "README")
           (symlink "Changelog" "ChangeLog")
           (symlink "LICENSE" "COPYING")
           (text-file "NEWS")
           (text-file "DEPENDENCIES")))
         (infrastructure
           ((scheme-file "guix")
            (text-file ".gitignore")
            (scheme-file "hall")
            (directory "m4" ((m4-file "tar-edited")))
            (in-file "pre-inst-env")
            (autoconf-file "configure")
            (automake-file "Makefile")))))

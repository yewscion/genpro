(use-modules
 (guix packages)
 (cdr255 tex)
 (cdr255 yewscion)
 (gnu packages pkg-config)
 (gnu packages autotools)
 (gnu packages guile)
 (gnu packages guile-xyz)
 (gnu packages pdf)
 (gnu packages tex)
 (gnu packages texinfo)
 (gnu packages python-xyz)
 (guix download)
 (guix build-system gnu)
 ((guix licenses) #:prefix license:)
 (guix utils)
 (guix store)
 (guix gexp))
(package
 (name "genpro")
 (version "1.0.0")
 (source (local-file "./genpro-1.0.0.tar.bz2"))
 (build-system gnu-build-system)
 (arguments
  `(#:tests? #f))
 (propagated-inputs (list
                     guile-3.0
                     texlive-base
                     guile-cdr255
                     guile-raw-strings
                     texinfo))
 (native-inputs (list
                 pkg-config
                 guile-3.0
                 autoconf
                 automake
                 biber
                 python-pygments
                 texlive-base
                 texlive-biblatex
                 texlive-biblatex-apa
                 texlive-bin
                 texlive-capt-of
                 texlive-csquotes
                 texlive-dvips
                 texlive-etoolbox
                 texlive-fontspec
                 texlive-etexcmds
                 texlive-gettitlestring
                 texlive-generic-ifptex
                 texlive-iftex
                 texlive-xstring
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
                 texlive-fancyhdr
                 texlive-fancyvrb
                 texlive-latex-float
                 texlive-latex-framed
                 texlive-latex-fvextra
                 texlive-latex-geometry
                 texlive-latex-ifplatform
                 texlive-kvoptions
                 texlive-letltxmacro
                 texlive-latex-lineno
                 texlive-latex-lwarp
                 texlive-latex-minted
                 texlive-latex-newfloat
                 texlive-latex-newunicodechar
                 texlive-pdftexcmds
                 texlive-latex-printlen
                 texlive-refcount
                 texlive-latex-setspace
                 texlive-titlesec
                 texlive-latex-trimspaces
                 texlive-latex-upquote
                 texlive-latex-xkeyval
                 texlive-latex-xpatch
                 texlive-libkpathsea
                 texlive-listings
                 texlive-lm
                 texlive-luaotfload
                 texlive-mflogo
                 texlive-svn-prov
                 texlive-tex-gyre
                 texlive-tracklang
                 texlive-varwidth
                 texlive-xcolor
                 texlive-xifthen))
 (synopsis "Generate and Publish LaTeX files.")
 (description
  (string-append
   "Tool to consistently create and work with LaTeX projects."))
 (home-page "https://git.sr.ht/~yewscion/genpro")
 (license license:agpl3+))


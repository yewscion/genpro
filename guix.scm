(use-modules
 (guix packages)
 (cdr255 tex)
 (cdr255 yewscion)
 (gnu packages pkg-config)
 (gnu packages autotools)
 (gnu packages guile)
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
 (version "0.5.0")
 (source (local-file "./genpro-0.5.0.tar.bz2"))
 (build-system gnu-build-system)
 (arguments
  `(#:tests? #f))
 (propagated-inputs (list
                     guile-3.0
                     texlive-base
                     guile-cdr255
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


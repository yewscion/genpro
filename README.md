

# The `genpro` Project

**A Project Manager for Research Projects.**

*README Last Updated: 2022-06-20 (W25) 22:34:28 GMT*

This project was born from a need to write a lot of papers for school very
quickly. I wanted a standardized way to not only define the projects, but also
run the more repetetive actions (`lualatex`, `biber`) on them. What I originally
wrote to do this eventually became `genpro`.


# Installation


## GNU Guix

If You use [GNU Guix](https://guix.gnu.org/), this package 
is on [my channel](https://sr.ht/~yewscion/yewscion-guix-channel/). 

Once You have it set up, You can just run:

    guix pull
    guix install genpro

If You just want to try it out, You can use Guix Shell instead:

    guix shell genpro bash --pure

And if You'd rather just try it out without my channel, You can clone this
repo and then do:

    cd genpro
    guix shell -f guix.scm bash --pure

This'll create a profile with **just** this project in it, to mess around with.


## Source

If You don't want to use [GNU Guix](https://guix.gnu.org/),
You can clone this repo and install it in the normal way:

    git clone https://git.sr.ht/~yewscion/genpro
    cd genpro
    ./configure
    make
    make check
    make install

If You don't want to use git, or would rather stick with an
actual release, then see the tagged releases for some tarballs
of the source.

The needed dependencies are tracked in the DEPENDENCIES.txt file
to support this use case.


# Usage

Full usage is documented in the `doc/genpro.info` file. Here are
only generic instructions.

Once `genpro` in installed, You should be able to access all of
its exported functionsin guile by using its modules:

    (use-modules ( main))
    (library-info) ;; I include this in all my libraries

Any binaries or scripts will be available in Your `$PATH`. A list of these
is maintained in the info file. They all also have the `--help=` flag, so
if You prefer learning that way, that is also available.

In an empty directory, run the program once to generate the `.metadata` and
`.projectile` files with some defaults.

    genpro

Edit the defaults inside of `.metadata`, then run with the `-g` or `--generate`
flag to generate the files needed.

    genpro -g

Write Your paper in `content.tex` and then publish it with the `-p` or
`--publish` flag.

    genpro -p

This will create both `PDF` and `HTML` output for the paper You've written,
allowing it to be shared or hosted as needed for the assignment.


# Contributing

Pull Requests are welcome, as are bugfixes and extensions. Please open
issues as needed. If You contribute a feature, needs to be tests and
documentation.

Development is expected to be done using [GNU Guix](https://guix.gnu.org/).
If You have `guix` set up, You should be able to enter a development
environment with the following:

    cd genpro
    guix shell -D -f guix.scm bash --pure

If You've made changes without the above precautions, those changes will
need to be confirmed to work in the above environment before merge.


# License

The `genpro` project and all associated files are ©2022 Christopher
Rodriguez, butlicensed to the public at large under the terms of the:

[GNU AGPL3.0+](https://www.gnu.org/licenses/agpl-3.0.html) license.

Please see the `LICENSE` file and the above link for more information.


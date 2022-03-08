# genpro

Generate and publish LaTeX projects.

## Installation

There are a couple ways to install this package.

### GNU Guix

If You use [GNU Guix][a], this package is on [my channel][b]. Once You have it
set up, You can just run:

```
guix pull
guix install genpro
```

### Source

If You don't want to use [GNU Guix][a], You can clone this repo and install it
Yourself.

### Prerequisites

- [GNU Guile][guile]
- [lualatex][lua]
- [biber][bib]
- [pygmentize][pyg]

## Usage

In an empty directory, run the program once to generate a `.metadata` file with
some defaults.

```bash
genpro
```

Edit these defaults, then run with the -g flag to generate the files needed.

```bash
genpro -g
```

Write Your paper in `content.tex` and then publish it with the -p flag.

```bash
genpro -p
```

## Contributing
Pull Requests are welcome, as are bugfixes and extensions. Please open
issues as needed. If You contribute a feature, needs to be tests and
documentation.

## License
[AGPL-3.0][c]

[a]: https://guix.gnu.org/
[b]: https://sr.ht/~yewscion/yewscion-guix-channel/
[c]: https://choosealicense.com/licenses/agpl-3.0/
[guile]: https://www.gnu.org/software/guile/
[lua]: http://www.luatex.org/
[bib]: http://biblatex-biber.sourceforge.net/
[pyg]: https://pygments.org/

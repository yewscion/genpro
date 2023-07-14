# ################################################################################

# # Set Up Java Variables
# JAVAC = @JAVA_CC@
# JAVAC_OPTS = @JAVA_CC_OPTS@
# JAVADOC = @JAVADOC@
# JAR = @JAR@
# MYJAVAPKG = @MYJAVAPKG@
# MYJAVADIR = $(builddir)/share/java
# MYJAVAPKGDIR = $(MYJAVADIR)/$(MYJAVAPKG)
# javadir = $(datadir)/java
# ################################################################################

# Set Up Guile Variables

GUILE_WARNINGS = -Wunbound-variable -Warity-mismatch -Wformat

## Directory for Uncompiled Guile Modules
moddir=$(prefix)/share/guile/site/$(GUILE_EFFECTIVE_VERSION)

## Directory for Compiled Guile Modules
godir=$(libdir)/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache

## Same as above, but for transient Compiled Guile Modules
ccachedir=$(libdir)/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache

## Handle substitution of fully-expanded Guile Autoconf variables.
do_subst = $(SED)					\
  -e 's,[@]GUILE[@],$(GUILE),g'				\
  -e 's,[@]guilemoduledir[@],$(guilemoduledir),g'	\
  -e 's,[@]guileobjectdir[@],$(guileobjectdir),g'	\
  -e 's,[@]localedir[@],$(localedir),g'

## Handle Special Build Reqs
SUFFIXES = .scm .go
.scm.go:
	$(AM_V_GEN)$(top_builddir)/pre-inst-env $(GUILE_TOOLS) compile $(GUILE_WARNINGS) -o "$@" "$<"

################################################################################

# Set Up Other Variables

## Enable local m4 cache
ACLOCAL_AMFLAGS = -I m4

## Documentation Compilation
info_TEXINFOS = doc/genpro.texi

## Extra Files for Distribution
EXTRA_DIST =  LICENSE \
              COPYING \
              NEWS \
              AUTHORS \
              README.org \
              README.md \
              Changelog \
              ChangeLog \
              COPYING \
              m4/tar-edited.m4 \
              guix.scm \
              pre-inst-env.in \
              doc/version.texi.in \
              doc/fdl-1.3.texi \
	      bootstrap \
              configure.ac \
              Makefile.am \
	      cdr255/genpro.scm.in \
	      cdr255/genpro-templates.scm.in

## Cleaning Up

### Clean Up Compiled Guile Modules
clean-go:
	-$(RM) $(GOBJECTS)
.PHONY: clean-go

### Filelist for make clean
CLEANFILES =					\
  $(GOBJECTS)					\
  $(TESTS:tests/%.scm=%.log)
################################################################################
# Define Inputs

## Define Java files (PREFIX: JAVAFILE)
# JAVAFILEFOO = $(srcdir)/java.java
# JAVASOURCES = $(JAVAFILEFOO)


## Define Guile files
GUILESOURCES = $(builddir)/cdr255/genpro.scm \
	       $(builddir)/cdr255/genpro-templates.scm

## Don't Distribute, Don't Install
nodist_noinst_SCRIPTS = pre-inst-env
################################################################################

# Define Outputs

## Scripts that are not compiled
bin_SCRIPTS = $(builddir)/bin/genpro

## Jarfiles and Classes
# java_DATA = foo

## Compiled Guile Modules (foo.go)
GOBJECTS = $(GUILESOURCES:%.scm=%.go)

## These are the actual Modules to Install, with directory structures intact
## (nobase). They are tied to the appropriate dir above.
nobase_mod_DATA = $(GUILESOURCES) $(NOCOMPSOURCES)
nobase_go_DATA = $(GOBJECTS)

## Make sure source files are installed first, so that the mtime of
## installed compiled files is greater than that of installed source
## files.  See
## <http://lists.gnu.org/archive/html/guile-devel/2010-07/msg00125.html>
## for details.
guile_install_go_files = install-nobase_goDATA
$(guile_install_go_files): install-nobase_modDATA

## Symlinks Go Here, along with other end-of-install changes
# install-data-hook:

## Sources and Extras
# EXTRA_DIST += $(JAVASOURCES) $(GUILESOURCES) $(NOCOMP_SOURCES)
EXTRA_DIST += $(GUILESOURCES) $(NOCOMP_SOURCES)
################################################################################

# Added Jobs


################################################################################

# # Tests (Not Working Right Now, as \$\(srcdir\) is not allowed.).
# TESTS = tests/tests.scm

# TEST_EXTENSIONS = .scm
# SCM_LOG_DRIVER =                                \
#   $(top_builddir)/pre-inst-env                  \
#   $(GUILE) --no-auto-compile -e main            \
#       $(top_srcdir)/build-aux/test-driver.scm

# # Tell 'build-aux/test-driver.scm' to display only source file names,
# # not indivdual test names.
# AM_SCM_LOG_DRIVER_FLAGS = --brief=yes

# AM_SCM_LOG_FLAGS = --no-auto-compile -L "$(top_srcdir)"

# AM_TESTS_ENVIRONMENT = abs_top_srcdir="$(abs_top_srcdir)"

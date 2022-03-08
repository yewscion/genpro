include guile.am

SOURCES =				\
cdr255/genpro.scm

EXTRA_DIST =				\
README.md				\
bootstrap				\
pre-inst-env.in				\
bin/genpro.scm

bin_SCRIPTS =				\
genpro

TESTS=run-tests

#MOSTLYCLEANFILES +=                    

CLEANFILES +=                           \
genpro                        \
cdr255/genpro.scm     \
genpro

DISTCLEANFILES =                        \
config.status                           \
config.log                              \
Makefile                                \
run-tests                               \
basic-tests.log

#MAINTAINERCLEANFILES +=

genpro: src/exe.scm
		sed -e 's,#!\/usr\/bin\/env -S guile -e main -s,\#!$(GUILE) \\,g' \
	 < $(srcdir)/src/exe.scm > ./genpro
	chmod +x genpro

cdr255/genpro.scm:
	mkdir -pv cdr255/
	cat < $(srcdir)/src/main.scm \
	> cdr255/genpro.scm

run-tests:
		sed -e 's,#!\/usr\/bin\/env -S guile -e main -s,\#!$(GUILE) \\,g' \
	< $(srcdir)/test/maintests.scm \
	> run-tests
	chmod +x run-tests
	guile -C ./ ./run-tests

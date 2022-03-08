dnl Process this file with autoconf
AC_INIT([genpro],
        [0.0.1],
        [yewscion@gmail.com],
        [genpro-0.0.1.tar.gz],
        [https://sr.ht/~yewscion/genpro])

AC_CONFIG_SRCDIR([genpro.org])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

GUILE_PKG([3.0])
GUILE_PROGS
if test "x$GUILD" = "x"; then
   AC_MSG_ERROR(['guild' binary not found;
   please check Your guile installation.])
fi
GUILE_SITE_DIR

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env], [chmod +x pre-inst-env])
AC_OUTPUT

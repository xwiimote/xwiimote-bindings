#
# xwiimote-bindings - configure
# Written by David Herrmann, 2013
# Dedicated to the Public Domain
#

AC_PREREQ(2.68)

AC_INIT([xwiimote-bindings],
        [1],
        [http://github.com/dvdhrm/xwiimote-bindings/issues],
        [xwiimote-bindings],
        [http://github.com/dvdhrm/xwiimote-bindings])
AC_CONFIG_SRCDIR([./autogen.sh])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADER(config.h)
AC_USE_SYSTEM_EXTENSIONS
AC_SYS_LARGEFILE
AC_CANONICAL_HOST

AM_INIT_AUTOMAKE([foreign 1.11 subdir-objects dist-xz no-dist-gzip tar-pax -Wall -Werror -Wno-portability])
AM_SILENT_RULES([yes])

AC_PROG_CC
AC_PROG_CC_C99
AM_PROG_CC_C_O
AC_PROG_LN_S
m4_ifdef([AM_PROG_AR], [AM_PROG_AR])

LT_PREREQ(2.2)
LT_INIT

PKG_CHECK_MODULES([XWIIMOTE], [libxwiimote])
XWIIMOTE_INCLUDEDIR=`$PKG_CONFIG --variable=includedir libxwiimote`
AC_SUBST([XWIIMOTE_INCLUDEDIR])
XWIIMOTE_LIBDIR=`$PKG_CONFIG --variable=libdir libxwiimote`
AC_SUBST([XWIIMOTE_LIBDIR])
AC_SUBST(XWIIMOTE_CFLAGS)
AC_SUBST(XWIIMOTE_LIBS)
AC_SUBST(XWIIMOTE_INCLUDEDIR)
AC_SUBST(XWIIMOTE_LIBDIR)

AC_CHECK_PROG([SWIG], [swig], [swig])
if test ! "x$SWIG" = "xswig" ; then
        AC_ERROR([swig not found])
fi

AM_PATH_PYTHON(, [have_python="yes"], [have_python="no"])
AM_CONDITIONAL(HAVE_PYTHON, test "x$have_python" = "xyes")

have_perl="no"
AC_PATH_PROG([PERL], [perl], ["no"])
if test ! "x$perl" = "xno" ; then
        have_perl="yes"
fi
AM_CONDITIONAL(HAVE_PERL, test "x$have_perl" = "xyes")

#
# Write configuration
#

AC_CONFIG_FILES([Makefile
                 python/setup.py
                 perl/Makefile.PL])
AC_OUTPUT

AC_MSG_NOTICE([Build configuration:

               prefix: $prefix
          exec-prefix: $exec_prefix
               libdir: $libdir
           includedir: $includedir

       python binding: $have_python
         perl binding: $have_perl

        Run "${MAKE-make}" to start compilation process])

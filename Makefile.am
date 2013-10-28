#
# xwiimote-bindings - makefile
# Written by David Herrmann, 2013
# Dedicated to the Public Domain
#

#
# miscellaneous
#

ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}
AM_MAKEFLAGS = --no-print-directory
AUTOMAKE_OPTIONS = color-tests
SUBDIRS = .
.DELETE_ON_ERROR:
MOSTLYCLEANFILES =
CLEANFILES =

#
# Distribution includes
#

EXTRA_DIST = \
	autogen.sh \
	README \
	COPYING \
	LICENSE \
	binding_api.txt \
	src/xwiimote.i \
	python/setup.py.in \
	perl/Makefile.PL.in

#
# python bindings
#

if HAVE_PYTHON

MOSTLYCLEANFILES += python/installed_files.log

all-local-python: _xwiimote.so

$(builddir)/%_wrap.c %.py: $(srcdir)/src/xwiimote.i
	$(SWIG) -python -o $(builddir)/xwiimote_wrap.c $(srcdir)/src/xwiimote.i

_%.so: $(builddir)/%_wrap.c
	$(PYTHON) python/setup.py build_ext

clean-local-python:
	-@rm -vfr xwiimote.py xwiimote_wrap.c ./build/

install-exec-hook-python: $(builddir)/xwiimote_wrap.c
	if test -n "$(DESTDIR)"; then\
		$(PYTHON) python/setup.py install --root=$(DESTDIR) --prefix=$(prefix) --record=@top_builddir@/python/installed_files.log; \
	else \
		$(PYTHON) python/setup.py install --prefix=$(prefix) --record=@top_builddir@/python/installed_files.log; \
	fi

uninstall-hook-python:
	cat @top_builddir@/python/installed_files.log \
	  | awk '{print "$(DESTDIR)"$$1}' | xargs rm -vf

else # HAVE_PYTHON

install-exec-hook-python:

uninstall-hook-python:

all-local-python:

clean-local-python:

endif # HAVE_PYTHON

#
# perl bindings
#

if HAVE_PERL

CLEANFILES += \
	$(builddir)/perl/perl_wrap.c \
	$(builddir)/perl/xwiimote.pm \
	$(builddir)/perl/xwiimote.bs \
	$(builddir)/perl/xwiimote.so

all-local-perl: $(builddir)/perl/xwiimote.so

$(builddir)/perl/perl_wrap.c: $(srcdir)/src/xwiimote.i
	$(SWIG) -perl -module xwiimote -o $@ $(srcdir)/src/xwiimote.i

$(builddir)/perl/Makefile.perl: $(builddir)/perl/Makefile.PL
	cd $(builddir)/perl && $(PERL) Makefile.PL PREFIX=$(prefix) MAKEFILE=Makefile.perl

$(builddir)/perl/xwiimote.so: $(builddir)/perl/perl_wrap.c $(builddir)/perl/Makefile.perl
	cd $(builddir)/perl && $(MAKE) -f Makefile.perl

install-exec-hook-perl: $(builddir)/perl/Makefile.perl
	cd $(builddir)/perl && $(MAKE) -f Makefile.perl install

uninstall-hook-perl: $(builddir)/perl/Makefile.perl
	cd $(builddir)/perl && $(MAKE) -f Makefile.perl uninstall

clean-local-perl:
	cd $(builddir)/perl && if test -f Makefile.perl ; then $(MAKE) -f Makefile.perl realclean; fi

else # HAVE_PERL

install-exec-hook-perl:

uninstall-hook-perl:

all-local-perl:

clean-local-perl:

endif # HAVE_PERL

#
# global rules
#

install-exec-hook: install-exec-hook-python install-exec-hook-perl

uninstall-hook: uninstall-hook-python uninstall-hook-perl

all-local: all-local-python all-local-perl

clean-local: clean-local-python clean-local-perl

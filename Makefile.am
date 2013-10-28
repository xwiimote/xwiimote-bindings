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
	python/setup.py.in

#
# python bindings
#

if HAVE_PYTHON

MOSTLYCLEANFILES += python/installed_files.log

all-local: _xwiimote.so

$(builddir)/%_wrap.c %.py: $(srcdir)/src/xwiimote.i
	$(SWIG) -python -o $(builddir)/xwiimote_wrap.c $(srcdir)/src/xwiimote.i

_%.so: $(builddir)/%_wrap.c
	$(PYTHON) python/setup.py build_ext

clean-local:
	-@rm -vfr xwiimote.py xwiimote_wrap.c ./build/

install-exec-hook: $(builddir)/xwiimote_wrap.c
	if test -n "$(DESTDIR)"; then\
		$(PYTHON) python/setup.py install --root=$(DESTDIR) --prefix=$(prefix) --record=@top_builddir@/python/installed_files.log; \
	else \
		$(PYTHON) python/setup.py install --prefix=$(prefix) --record=@top_builddir@/python/installed_files.log; \
	fi

uninstall-hook:
	cat @top_builddir@/python/installed_files.log \
	  | awk '{print "$(DESTDIR)"$$1}' | xargs rm -vf

endif # HAVE_PYTHON

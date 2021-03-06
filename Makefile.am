
# AUTOMAKE_OPTIONS = foreign # Conflicts with libMesh options
AUTOMAKE_OPTIONS = gnu
ACLOCAL_AMFLAGS  = -I m4 -I m4/autoconf-submodule

SUBDIRS          = src test
EXTRA_DIST       = COPYING

# Tools in the auxiliary directory

AUX_DIST         = build-aux/install-sh
AUX_DIST        += build-aux/missing
AUX_DIST        += build-aux/config.guess
AUX_DIST        += build-aux/config.sub
AUX_DIST        += build-aux/depcomp
AUX_DIST        += build-aux/ltmain.sh

# Support for pkgconfig
pkgconfigdir   = $(libdir)/pkgconfig
pkgconfig_DATA = timpi.pc

# Support for timpi-config in $(exec_prefix)/bin
timpi_configdir      = $(exec_prefix)/bin
timpi_config_SCRIPTS = bin/timpi-config
#
# support top-level 'make test_headers'
test_headers:
	@cd $(top_builddir)/src && $(MAKE) test_headers


# Support 'make install prefix=/other/path' with pkgconfig
install-data-hook:
	@if (test "x$(prefix)" != "x@prefix@"); then \
	  oldprefix="@prefix@" ; \
	  newprefix="$(prefix)" ; \
	  cd $(DESTDIR)$(libdir)/pkgconfig ; \
	  for genfile in $(pkgconfig_DATA) $(DESTDIR)$(prefix)/bin/timpi-config; do \
	  echo " " ; \
	    echo " *** replacing $$oldprefix" ; \
	    echo " ***      with $$newprefix" ; \
	    echo " *** in generated file $$genfile" ; \
	    echo " " ; \
	    cd $(DESTDIR)$(prefix) && cat $$genfile | $(SED) "s,$$oldprefix,$$newprefix,g" > $$genfile.replaced ; \
	    cd $(DESTDIR)$(prefix) && mv $$genfile.replaced $$genfile ; \
          done ; \
	fi
	cat $(DESTDIR)$(timpi_configdir)/timpi-config | $(SED) "s/has_been_installed=no/has_been_installed=yes/g" > $(DESTDIR)$(timpi_configdir)/timpi-config.installed
	mv $(DESTDIR)$(timpi_configdir)/timpi-config.installed $(DESTDIR)$(timpi_configdir)/timpi-config && chmod +x $(DESTDIR)$(timpi_configdir)/timpi-config

# Additional files to be deleted by 'make distclean'
DISTCLEANFILES  = _configs.sed
DISTCLEANFILES += src/utilities/include/timpi/timpi_config.h

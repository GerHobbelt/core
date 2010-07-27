#
# $Id$
#

# ---------------------------------------------------------------
# Copyright 2007 Przemyslaw Czerpak (druzus/at/priv.onet.pl),
# Harbour-WinCE cross build RPM spec file
#
# See COPYING for licensing terms.
# ---------------------------------------------------------------

######################################################################
## Definitions.
######################################################################

%define name      harbour-wce
%define version   2.1.0
%define releasen  beta2
%define hb_pref   hbce
%define hb_host   harbour-project.org
%define readme    README.RPM

# Workaround for the problem of /usr/bin/strip not handling PE binaries.
%define hb_ccpath /opt/mingw32ce/bin
%define hb_ccpref arm-wince-mingw32ce-
%define __strip   %{hb_ccpath}/%{hb_ccpref}strip
%define __objdump %{hb_ccpath}/%{hb_ccpref}objdump

######################################################################
## Preamble.
######################################################################

Summary:        Free software Clipper compatible compiler
Summary(pl):    Darmowy kompilator kompatybilny z j�zykiem Clipper.
Name:           %{name}
Version:        %{version}
Release:        %{releasen}
License:        GPL (plus exception)
Group:          Development/Languages
Vendor:         %{hb_host}
URL:            http://%{hb_host}/
Source:         harbour-%{version}.src.tar.gz
Packager:       Przemys�aw Czerpak (druzus/at/priv.onet.pl)
BuildPrereq:    gcc binutils bash
Requires:       gcc binutils bash sh-utils cegcc-mingw32ce harbour = %{?epoch:%{epoch}:}%{version}-%{release}
Provides:       %{name}
BuildRoot:      /tmp/%{name}-%{version}-root

%define         _noautoreq    'libharbour.*'

%description
Harbour is a CA-Cl*pper compatible compiler for multiple platforms. This
package includes a compiler, pre-processor, header files, virtual machine
and libraries for creating WinCE application in Linux box using MinGW-CE
GCC port.

%description -l pl
Harbour to kompatybilny z j�zykiem CA-Cl*pper kompilator rozwijany na
wielu r�nych platformach. Ten pakiet zawiera kompilator, preprocesor,
zbiory nag��wkowe, wirtualn+ maszyn� oraz biblioteki pozwalaj+ce na
tworzenie aplikacji dla WinCE-PocketPC przy u�yciu MinGW-CE GCC.


######################################################################
## Preperation.
######################################################################

%prep
%setup -c harbour
rm -fR $RPM_BUILD_ROOT

######################################################################
## Build.
######################################################################

%build

#export HB_BUILD_PARTS=compiler
export HB_BUILD_CONTRIBS=no
export HB_PLATFORM=linux
export HB_COMPILER=gcc
make %{?_smp_mflags}
unset HB_COMPILER
unset HB_BUILD_CONTRIBS

export HB_BUILD_PARTS=lib
export HB_PLATFORM=wce

export HB_BIN_COMPILE="$(pwd)/bin/linux/gcc"
export CC_HB_USER_PRGFLAGS="-undef:.ARCH. -D__PLATFORM__WINDOWS -D__PLATFORM__WINCE"

make %{?_smp_mflags}

######################################################################
## Install.
######################################################################

%install

# Install harbour itself.

export HB_BUILD_PARTS=lib
export HB_PLATFORM=wce
unset HB_COMPILER

export HB_BIN_COMPILE="$(pwd)/bin/linux/gcc"

export CC_HB_USER_PRGFLAGS="-undef:.ARCH. -D__PLATFORM__WINDOWS -D__PLATFORM__WINCE"

export HB_BIN_INSTALL=%{_bindir}
export HB_INC_INSTALL=%{_includedir}/%{name}
export HB_LIB_INSTALL=%{_libdir}/%{name}
export HB_DYN_INSTALL=${HB_LIB_INSTALL}

export _DEFAULT_BIN_DIR=$HB_BIN_INSTALL
export _DEFAULT_INC_DIR=$HB_INC_INSTALL
export _DEFAULT_LIB_DIR=$HB_LIB_INSTALL
export HB_BIN_INSTALL=$RPM_BUILD_ROOT/$HB_BIN_INSTALL
export HB_INC_INSTALL=$RPM_BUILD_ROOT/$HB_INC_INSTALL
export HB_LIB_INSTALL=$RPM_BUILD_ROOT/$HB_LIB_INSTALL
export HB_DYN_INSTALL=${HB_LIB_INSTALL}
export HB_BUILD_STRIP=lib

mkdir -p $HB_BIN_INSTALL

make install %{?_smp_mflags}

# remove unused files
rm -fR ${HB_BIN_INSTALL}/{harbour,hbpp,hbmk2,hbrun,hbi18n,hbtest}.exe

# Create a README file for people using this RPM.
cat > doc/%{readme} <<EOF
This RPM distribution of Harbour includes extra commands to make compiling
and linking with Harbour a little easier.It includes hbmk2 to build
projects easily.

hbmk2 tries to produce an executable from your .prg file. It's similar
to cl.bat from the CA-Cl*pper distribution.

All these scripts accept command line switches:
-o<outputfilename>      # output file name
-static                 # link with static Harbour libs
-fullstatic             # link with all static libs
-shared                 # link with shared libs (default)
-mt                     # link with multi-thread libs
-gt<hbgt>               # link with <hbgt> GT driver, can be repeated to
                        # link with more GTs. The first one will be
                        #      the default at runtime
-xbgtk                  # link with xbgtk library (xBase GTK+ interface)
-hwgui                  # link with HWGUI library (GTK+ interface)
-l<libname>             # link with <libname> library
-L<libpath>             # additional path to search for libraries
-[no]strip              # strip (no strip) binaries
-main=<main_func>       # set the name of main program function/procedure.
                        # if not set then 'MAIN' is used or if it doesn't
                        # exist the name of first public function/procedure
                        # in first linked object module (link)

An example compile/link session looks like:
----------------------------------------------------------------------
druzus@uran:~/tmp$ cat foo.prg
function main()
? "Hello, World!"
return nil

druzus@uran:~/tmp$ hbmk2 foo
Harbour 2.1.0beta1 (Rev. 14701)
Copyright (c) 1999-2010, http://harbour-project.org/
Compiling 'foo.prg'...
Lines 5, Functions/Procedures 2
Generating C source output to 'foo.c'... Done.

druzus@uran:~/tmp$ ls -l foo
-rwxrwxr-x    1 druzus   druzus       3824 maj 17 02:46 foo
----------------------------------------------------------------------

I hope this RPM is useful. Have fun with Harbour.

Przemyslaw Czerpak (druzus/at/priv.onet.pl)
EOF

######################################################################
## Post install
######################################################################
#%post lib
#/sbin/ldconfig

######################################################################
## Post uninstall
######################################################################
#%postun lib
#/sbin/ldconfig

######################################################################
## Clean.
######################################################################

%clean
rm -fR $RPM_BUILD_ROOT

######################################################################
## File list.
######################################################################

%files
%defattr(-,root,root,755)
%doc doc/%{readme}

%{_bindir}/%{hb_pref}-mkdyn
%{_bindir}/hbmk2

%defattr(644,root,root,755)
%dir %{_includedir}/%{name}
%{_includedir}/%{name}/*
%dir %{_libdir}/%{name}
%{_libdir}/%{name}/*.a

%defattr(755,root,root,755)
%{_libdir}/%{name}/*.dll

######################################################################
## Spec file Changelog.
######################################################################

%changelog
* Thu Oct 23 2007 Przemyslaw Czerpak (druzus/at/priv.onet.pl)
- initial release
# set up environment for other makefiles

CONFIG_SITE =
export CONFIG_SITE

BASE_DIR    := $(shell pwd)
-include $(BASE_DIR)/config

# default platform...
PLATFORM    ?= tripledragon

# coolstream is the pariah here -- everything is different...
ifneq ($(PLATFORM), coolstream)

# good platforms use the open sourced libstb-hal...
USE_STB_HAL ?= yes
# ...and the neutrino-multiplatform edition
FLAVOUR     ?= neutrino-mp

ifeq ($(PLATFORM), tripledragon)
ifneq ($(TD_COMPILER), old)
# name it differently to avoid subtleties...
TARGET      ?= powerpc-405n-linux-gnu
TD_COMPILER ?= new
else
# TD_COMPILER == old
TARGET      ?= powerpc-405-linux-gnu
endif
BOXARCH     ?= powerpc
endif # tripledragon

ifeq ($(PLATFORM), spark)
TARGET      ?= sh4-linux
BOXARCH     ?= sh4
endif # spark

ifeq ($(PLATFORM), azbox)
TARGET      ?= mipsel-unknown-linux-gnu
BOXARCH     ?= mipsel
endif

else  # coolstream
USE_STB_HAL ?= no
TARGET      ?= arm-cx2450x-linux-gnueabi
FLAVOUR     ?= neutrino-mp
BOXARCH     ?= arm
# manage default used kernel version, is now 2.6.34.13
ifeq ($(CSKVERSION),)
CSKVERSION	= 2.6.34.13
endif
CSKVERSION_FULL = $(CSKVERSION)
endif

ifneq ($(GIT_PROTOCOL), http)
GITORIOUS ?= git://gitorious.org
COOLSTREAM_DE ?= git://coolstreamtech.de
else
GITORIOUS ?= https://git.gitorious.org
endif

WHOAMI      := $(shell id -un)
MAINTAINER  ?= $(shell getent passwd $(WHOAMI)|awk -F: '{print $$5}')

## needed for the old Tripledragon crosstool
# crosstool puts "...-glibc-2.3.6-tls" configs still into "...-glibc-2.3.6"
CROSS_BUILD_VER = gcc-3.4.5-glibc-2.3.6-tls
CROSS_BUILD_DIR = $(CROSS_BUILD_VER:-tls=)

ARCHIVE      = $(BASE_DIR)/download
PATCHES      = $(BASE_DIR)/archive-patches
BUILD_TMP    = $(BASE_DIR)/build_tmp
D            = $(BASE_DIR)/deps
# backwards compatibility
DEPDIR       = $(D)

CCACHE       = /usr/bin/ccache
HOSTPREFIX   = $(BASE_DIR)/host
TARGETPREFIX = $(BASE_DIR)/root
PKGPREFIX    = $(BUILD_TMP)/pkg
FROOTFS      = $(BASE_DIR)/root-flash
SOURCE_DIR   = $(BASE_DIR)/source
PLUGIN_DIR   = $(SOURCE_DIR)/neutrino-hd-plugins
MAKE_DIR     = $(BASE_DIR)/make
CONTROL_DIR  = $(BASE_DIR)/pkgs/control
PACKAGE_DIR  = $(BASE_DIR)/pkgs/opkg
SCRIPTS      = $(BASE_DIR)/scripts/target

CROSS_BASE   = $(BASE_DIR)/cross
ifneq ($(PLATFORM)-$(TD_COMPILER), tripledragon-old)
CROSS_DIR   ?= $(CROSS_BASE)
else
# old crosstool compatibility
CROSS_DIR   ?= $(CROSS_BASE)/$(CROSS_BUILD_DIR)/$(TARGET)
endif

BUILD       ?= $(shell /usr/share/libtool/config.guess 2>/dev/null || /usr/share/libtool/config/config.guess)

TARGETLIB       = $(TARGETPREFIX)/lib
TARGET_CFOPTFLAG= -Os
TARGET_CFLAGS   = -pipe $(TARGET_CFOPTFLAG) -g -I$(TARGETPREFIX)/include
TARGET_CPPFLAGS = $(TARGET_CFLAGS)
TARGET_CXXFLAGS = $(TARGET_CFLAGS)
TARGET_LDFLAGS  = -Wl,-O1 -L$(TARGETLIB)
LD_FLAGS        = $(TARGET_LDFLAGS)

VPATH = $(D)

ifeq ("$(FLAVOUR)", "neutrino-hd-tripledragon")
N_HD_SOURCE ?= $(SOURCE_DIR)/neutrino-hd-td
NEUTRINO_PKG = neutrino-hd
else
N_HD_SOURCE ?= $(SOURCE_DIR)/$(FLAVOUR)
NEUTRINO_PKG = $(FLAVOUR)
endif

# append */sbin for those not having sbin in their path. We need it.
PATH := $(HOSTPREFIX)/bin:$(CROSS_DIR)/bin:$(PATH):/sbin:/usr/sbin:/usr/local/sbin

PKG_CONFIG = $(HOSTPREFIX)/bin/$(TARGET)-pkg-config
PKG_CONFIG_PATH = $(TARGETPREFIX)/lib/pkgconfig

# helper-"functions":
REWRITE_LIBTOOL = sed -i "s,^libdir=.*,libdir='$(TARGETLIB)'," $(TARGETLIB)
REWRITE_PKGCONF = sed -i "s,^prefix=.*,prefix='$(TARGETPREFIX)',"
REWRITE_LIBTOOL_OPT = sed -i "s,^libdir=.*,libdir='$(TARGETPREFIX)/opt/pkg/lib'," $(TARGETPREFIX)/opt/pkg/lib
REWRITE_PKGCONF_OPT = sed -i "s,^prefix=.*,prefix='$(TARGETPREFIX)/opt/pkg',"

# unpack tarballs, clean up
UNTAR = tar -C $(BUILD_TMP) -xf $(ARCHIVE)
REMOVE = rm -rf $(BUILD_TMP)
PATCH = patch -p1 -i $(PATCHES)
# wget tarballs into archive directory
WGET = wget -t3 -T10 -c -P $(ARCHIVE)

CONFIGURE_OPTS = \
	--build=$(BUILD) --host=$(TARGET)

BUILDENV = \
	CFLAGS="$(TARGET_CFLAGS)" \
	CPPFLAGS="$(TARGET_CPPFLAGS)" \
	CXXFLAGS="$(TARGET_CXXFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH)

CONFIGURE = \
	test -f ./configure || ./autogen.sh && \
	$(BUILDENV) \
	./configure $(CONFIGURE_OPTS)

# coolstream
CSSVN_URL = http://www.coolstreamtech.de/coolstream_public_svn
CSSVN_CMD = svn --username coolstream --password coolstream --no-auth-cache
# ---------

ifeq ($(PLATFORM), tripledragon)
else
SVN   ?= $(CSSVN_CMD)
SVNCO ?= $(SVN) co $(CSSVN_URL)
endif

# shortcuts
# coolstream
SVN_TP_LIBS = $(SOURCE_DIR)/svn/THIRDPARTY/libraries
SVN_TP_APPS = $(SOURCE_DIR)/svn/THIRDPARTY/applications
# ----------
TD_SVN = $(SOURCE_DIR)/tdsvn

OPKG_SH_ENV  = PACKAGE_DIR=$(PACKAGE_DIR)
OPKG_SH_ENV += STRIP=$(TARGET)-strip
OPKG_SH_ENV += MAINTAINER="$(MAINTAINER)"
OPKG_SH_ENV += ARCH=$(BOXARCH)
OPKG_SH_ENV += SOURCE=$(PKGPREFIX)
OPKG_SH_ENV += BUILD_TMP=$(BUILD_TMP)
OPKG_SH = $(OPKG_SH_ENV) opkg.sh

UNCOOL_GIT    = $(SOURCE_DIR)/uncool
UNCOOL_KVER  ?= $(CSKVERSION)
UNCOOL_FLAVOUR ?= nevis
UNCOOL_KVER_FULL = $(UNCOOL_KVER)-$(UNCOOL_FLAVOUR)
UNCOOL_DRVBASE = $(UNCOOL_GIT)/cst-public-drivers/$(UNCOOL_FLAVOUR)
# svn to check out from obsolete SVN
UNCOOL_SOURCE?= git
ifneq ($(UNCOOL_SOURCE), git)
UNCOOL_LIBCS  = $(SVN_TP_LIBS)/libcs/libcoolstream-mt.so
UNCOOL_LIBNXP = $(SVN_TP_LIBS)/libnxp/libnxp.so
UNCOOL_DRIVER = $(SOURCE_DIR)/svn/COOLSTREAM/$(UNCOOL_KVER_FULL)
else
UNCOOL_LIBCS  = $(UNCOOL_DRVBASE)/libs/libcoolstream-mt.so
UNCOOL_LIBNXP = $(UNCOOL_DRVBASE)/libs/libnxp.so
UNCOOL_LIBCA  = $(UNCOOL_DRVBASE)/libs/libca-sc.so
UNCOOL_DRIVER = $(UNCOOL_DRVBASE)/drivers/$(UNCOOL_KVER_FULL)
endif
UNCOOL_LIBS   = $(UNCOOL_LIBCS) $(UNCOOL_LIBNXP) $(UNCOOL_LIBCA)

## for spark TDT git repos...
ifeq ($(TDT_REPO), "pinky")
# this one seems to be more recent, but is a bit "chaotic" ...
TDT_GIT ?= $(GITORIOUS)/~pinky1981/open-duckbox-project-sh4/pingulux-git.git
TDT_SRC ?= $(SOURCE_DIR)/pingulux-git
else
# ... but this one is not specific to SPARK boxes.
TDT_GIT ?= $(GITORIOUS)/open-duckbox-project-sh4/tdt.git
TDT_SRC ?= $(SOURCE_DIR)/tdt
endif

######### default to non-verbose builds for most packages...
V ?= 0
export V

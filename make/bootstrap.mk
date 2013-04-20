# makefile to build crosstool

BOOTSTRAP  = targetprefix $(BUILD_TMP) $(CROSS_BASE) $(HOSTPREFIX)/bin includes-and-libs
BOOTSTRAP += $(TARGETPREFIX)/lib/libc.so.6
BOOTSTRAP += $(HOSTPREFIX)/bin/opkg.sh $(HOSTPREFIX)/bin/opkg-chksvn.sh
BOOTSTRAP += $(HOSTPREFIX)/bin/opkg-gitdescribe.sh
BOOTSTRAP += $(HOSTPREFIX)/bin/opkg-find-requires.sh $(HOSTPREFIX)/bin/opkg-find-provides.sh
BOOTSTRAP += $(HOSTPREFIX)/bin/opkg-module-deps.sh
BOOTSTRAP += $(HOSTPREFIX)/bin/get-git-archive.sh
BOOTSTRAP += pkg-config

ifeq ($(PLATFORM), tripledragon)
BOOTSTRAP += directfb-includes-and-libs td-modules
PLAT_INCS  = $(TARGETPREFIX)/include/hardware/xp/xp_osd_user.h
endif
ifeq ($(PLATFORM), coolstream)
BOOTSTRAP += $(HOSTPREFIX)/bin/opkg-controlver-from-svn.sh
BOOTSTRAP += cs-modules $(TARGETPREFIX)/sbin/ldconfig
PLAT_LIBS  = $(TARGETPREFIX)/lib/libca-sc.so $(TARGETPREFIX)/lib/libnxp.so $(TARGETPREFIX)/lib/libcoolstream-mt.so
PLAT_LIBS += $(TARGETPREFIX)/lib/libca-sc.so
PLAT_INCS  = $(TARGETPREFIX)/lib/firmware
endif
ifeq ($(PLATFORM), spark)
BOOTSTRAP += $(STL_ARCHIVE)
BOOTSTRAP += $(HOSTPREFIX)/bin/unpack-rpm.sh
endif

bootstrap: $(BOOTSTRAP)

targetprefix:
	@PATH=$(PATH):$(CROSS_DIR)/bin && \
	if ! type -p $(TARGET)-gcc >/dev/null 2>&1; then \
		echo;echo "$(TARGET)-gcc not found in PATH or \$$CROSS_DIR/bin"; \
		echo "=> please check your setup. Maybe you need to 'make crosstool'."; echo; \
		false; \
	fi
	mkdir -p $(TARGETPREFIX)
	mkdir -p $(TARGETPREFIX)/bin
	mkdir -p $(TARGETPREFIX)/include
	mkdir -p $(PKG_CONFIG_PATH)
	make skeleton

$(TARGETPREFIX):
	@echo "**********************************************************************"
	@echo "TARGETPREFIX does not exist. You probably need to run 'make bootstrap'"
	@echo "**********************************************************************"
	@echo ""
	@false

$(HOSTPREFIX):
	mkdir $@

$(STL_ARCHIVE):
	mkdir $@

$(HOSTPREFIX)/bin: $(HOSTPREFIX)
	mkdir $@

$(HOSTPREFIX)/bin/unpack%.sh \
$(HOSTPREFIX)/bin/get%.sh \
$(HOSTPREFIX)/bin/opkg%sh: | $(HOSTPREFIX)/bin
	ln -sf $(BASE_DIR)/scripts/$(shell basename $@) $(HOSTPREFIX)/bin

$(BUILD_TMP):
	mkdir -p $(BUILD_TMP)

$(CROSS_BASE):
	mkdir -p $(CROSS_BASE)

$(TARGETPREFIX)/include/coolstream: $(SOURCE_DIR)/svn/CROSSENVIROMENT/coolstream | $(TARGETPREFIX)
	mkdir -p $@
	cp -a $(SOURCE_DIR)/svn/CROSSENVIROMENT/coolstream/* $@/

$(TARGETPREFIX)/lib/libnxp.so: $(UNCOOL_LIBNXP) | $(TARGETPREFIX)
	cp -a $(UNCOOL_LIBNXP) $@

$(TARGETPREFIX)/lib/libca-sc.so: $(UNCOOL_LIBCA) | $(TARGETPREFIX)
	cp -a $(UNCOOL_LIBCA) $@

$(TARGETPREFIX)/lib/libcoolstream%.so: $(UNCOOL_LIBCS) | $(TARGETPREFIX)
	cp -a $(UNCOOL_LIBCS) $@

$(TARGETPREFIX)/lib/firmware: | $(TARGETPREFIX)
	mkdir -p $@
	cp -a $(UNCOOL_DRVBASE)/firmware/* $@/

$(TARGETPREFIX)/lib/modules/$(UNCOOL_KVER_FULL): | $(TARGETPREFIX)
	mkdir -p $@/extra
	cp -a $(UNCOOL_DRIVER)/* $@/extra/

$(PKGPREFIX)/lib/modules/2.6.12 \
$(TARGETPREFIX)/lib/modules/2.6.12: | $(TARGETPREFIX) $(TD_SVN)/ARMAS
	mkdir $(subst /2.6.12,,$@) # fail if no bootstrap has been done
	cp -a "$(TD_SVN)/ARMAS/filesystem-skeleton/lib/modules/2.6.12" $(subst 2.6.12,,$@)
	find $@ -name .svn -type d -print0 | xargs --no-run-if-empty -0 rm -rf

$(TARGETPREFIX)/lib/libc.so.6: $(TARGETPREFIX)
	# stlinux RPM puts libstdc++ into /usr/lib...
	if test -e $(CROSS_DIR)/$(TARGET)/sys-root/usr/lib/libstdc++.so; then \
		cp -a $(CROSS_DIR)/$(TARGET)/sys-root/usr/lib/libstdc++.s*[!y] $(TARGETPREFIX)/lib; \
	fi
	if test -e $(CROSS_DIR)/$(TARGET)/sys-root/lib; then \
		cp -a $(CROSS_DIR)/$(TARGET)/sys-root/lib/*so* $(TARGETPREFIX)/lib; \
	else \
		cp -a $(CROSS_DIR)/$(TARGET)/lib/*so* $(TARGETPREFIX)/lib; \
	fi

$(TD_SVN)/ARMAS:
	@echo
	@echo "Tripledragon SVN is not yet checked out?"
	@echo "Run 'make preqs' to fix that..."
	@echo
	@false

includes-and-libs: $(PLAT_LIBS) $(PLAT_INCS)

ifeq ($(PLATFORM), coolstream)
cs-modules: $(TARGETPREFIX)/lib/modules/$(UNCOOL_KVER_FULL)
endif

ifeq ($(PLATFORM), tripledragon)
td-modules: $(TARGETPREFIX)/lib/modules/2.6.12

$(TARGETPREFIX)/include/hardware/xp/xp_osd_user.h: $(TARGETPREFIX) $(TD_SVN)/ARMAS
	@echo ' ============================================================================== '
	@echo "    Preparing to copy crosstool and supporting files to required directories"
	@echo ' ============================================================================== '
	tar --exclude='*/.svn' -cC $(TD_SVN)/ARMAS/cross-enivroment-build/stb/include/ hardware | \
		tar -vxC $(TARGETPREFIX)/include/
	cp -a $(PATCHES)/tripledragon/xp_osd_user.h $(TARGETPREFIX)/include/hardware/xp/

$(PKGPREFIX)/stb/lib/directfb-0.9.24 \
$(TARGETPREFIX)/stb/lib/directfb-0.9.24: $(TARGETPREFIX) $(TD_SVN)/ARMAS
	tar --exclude='*/.svn' -cC $(TD_SVN)/ARMAS/filesystem-skeleton stb/lib/directfb-0.9.24 | \
		tar -vxC $(subst /stb/lib/directfb-0.9.24,,$@)
	ln -sf ../../lib/libjpeg.so.62 $(subst /directfb-0.9.24,,$@)/libjpeg.so.62

$(TARGETPREFIX)/include/directfb: $(TARGETPREFIX) $(TD_SVN)/ARMAS
	tar --exclude='*/.svn' -cC $(TD_SVN)/ARMAS/cross-enivroment-build/stb include/directfb | \
		tar -vxC $(TARGETPREFIX)/

directfb-includes-and-libs: $(TARGETPREFIX)/stb/lib/directfb-0.9.24 $(TARGETPREFIX)/include/directfb $(TD_SVN)/ARMAS
	cp -a $(TD_SVN)/ARMAS/cross-enivroment-build/stb/lib/pkgconfig/directfb.pc $(PKG_CONFIG_PATH)/
	cp -a $(TD_SVN)/ARMAS/cross-enivroment-build/stb/lib/pkgconfig/direct.pc   $(PKG_CONFIG_PATH)/
	cp -a $(TD_SVN)/ARMAS/cross-enivroment-build/stb/lib/pkgconfig/fusion.pc   $(PKG_CONFIG_PATH)/
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/directfb.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/direct.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fusion.pc
	cp -av $(TD_SVN)/ARMAS/filesystem-skeleton/stb/lib/libdirect* $(TARGETPREFIX)/lib/
	cp -av $(TD_SVN)/ARMAS/filesystem-skeleton/stb/lib/libfusion* $(TARGETPREFIX)/lib/
	ln -sf libdirect-0.9.so.24   $(TARGETPREFIX)/lib/libdirect.so
	ln -sf libfusion-0.9.so.24   $(TARGETPREFIX)/lib/libfusion.so
	ln -sf libdirectfb-0.9.so.24 $(TARGETPREFIX)/lib/libdirectfb.so
	mkdir -p $(TARGETPREFIX)/etc
	cp -a $(SCRIPTS)/directfbrc-td $(TARGETPREFIX)/etc/directfbrc

# PLATFORM = tripledagon
endif


# helper target to create ccache links (make sure to have ccache installed in /usr/bin ;)

ccache: $(HOSTPREFIX)/bin
	ln -sf $(CCACHE) $(HOSTPREFIX)/bin/cc
	ln -sf $(CCACHE) $(HOSTPREFIX)/bin/gcc
	ln -sf $(CCACHE) $(HOSTPREFIX)/bin/g++
	ln -sf $(CCACHE) $(HOSTPREFIX)/bin/$(TARGET)-gcc
	ln -sf $(CCACHE) $(HOSTPREFIX)/bin/$(TARGET)-g++

ldconfig: $(TARGETPREFIX)/sbin/ldconfig
$(TARGETPREFIX)/sbin/ldconfig: | $(TARGETPREFIX)
	@if test -e $(CROSS_DIR)/$(TARGET)/sys-root/sbin/ldconfig; then \
		cp -a $(CROSS_DIR)/$(TARGET)/sys-root/sbin/ldconfig $@; \
		mkdir -p $(TARGETPREFIX)/etc; \
		touch $(TARGETPREFIX)/etc/ld.so.conf; \
	elif test -e $(CROSS_DIR)/$(TARGET)/sbin/ldconfig; then \
		cp -a $(CROSS_DIR)/$(TARGET)/sbin/ldconfig $@; \
		mkdir -p $(TARGETPREFIX)/etc; \
		touch $(TARGETPREFIX)/etc/ld.so.conf; \
	else \
		# triggers on crosstool-0.43 built Tripledragon toolchain ; \
		echo "====================================================="; \
		echo "Your toolchain did not build ldconfig for the target."; \
		echo "This is not an error, just a hint."; \
		echo "====================================================="; \
	fi

pkg-config-preqs:
	@PATH=$(subst $(HOSTPREFIX)/bin:,,$(PATH)); \
		if ! pkg-config --exists glib-2.0; then \
			echo "pkg-config and glib2-devel packages are needed for building cross-pkg-config."; false; \
		fi

pkg-config: $(HOSTPREFIX)/bin/pkg-config
$(HOSTPREFIX)/bin/pkg-config: $(ARCHIVE)/pkg-config-$(PKGCONFIG_VER).tar.gz | $(HOSTPREFIX)/bin pkg-config-preqs
	$(UNTAR)/pkg-config-$(PKGCONFIG_VER).tar.gz
	set -e; cd $(BUILD_TMP)/pkg-config-$(PKGCONFIG_VER); \
		./configure --with-pc_path=$(PKG_CONFIG_PATH); \
		$(MAKE); \
		cp -a pkg-config $(HOSTPREFIX)/bin
	ln -sf pkg-config $(HOSTPREFIX)/bin/$(TARGET)-pkg-config
	$(REMOVE)/pkg-config-$(PKGCONFIG_VER)

# hack to make sure they are always copied
PHONY += $(TARGETPREFIX)/lib/modules/$(UNCOOL_KVER_FULL)
PHONY += $(TARGETPREFIX)/include/coolstream
PHONY += $(TARGETPREFIX)/lib/libnxp.so
PHONY += $(TARGETPREFIX)/lib/libcoolstream.so
PHONY += $(TARGETPREFIX)/lib/firmware
PHONY += ccache crosstool includes-and-libs cs-modules targetprefix bootstrap

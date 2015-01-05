# Makefile to build Extras

$(D)/cdparanoia: $(ARCHIVE)/cdparanoia-III-10.2.src.tgz | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/cdparanoia-III-10.2.src.tgz
	set -e; cd $(BUILD_TMP)/cdparanoia-III-10.2; \
		$(CONFIGURE) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--exec-prefix=$(PKGPREFIX) \
			--includedir=$(TARGETPREFIX)/include \
			--mandir=$(BUILD_TMP)/.remove \
			; \
		# parallel make yields different binaries for every build, so disable it \
		$(MAKE) -j 1 ; \
		make install
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	rm $(PKGPREFIX)/lib/*.a $(PKGPREFIX)/lib/*.so
	PKG_VER=10.2 $(OPKG_SH) $(CONTROL_DIR)/cdparanoia
	$(REMOVE)/cdparanoia-III-10.2 $(BUILD_TMP)/.remove $(PKGPREFIX)
	touch $@

$(D)/cddfs: $(ARCHIVE)/cddfs-0.2.tar.gz fuse cdparanoia | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/cddfs-0.2.tar.gz
	mkdir $(PKGPREFIX) $(PKGPREFIX)/bin
	$(TARGET)-gcc \
		$(TARGET_CFLAGS) -g -Wall -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DFUSE_USE_VERSION=22 \
		$(TARGET_LDFLAGS) -lpthread -lfuse -lcdda_paranoia -lcdda_interface \
		-fsigned-char \
		-o $(PKGPREFIX)/bin/cddfs $(BUILD_TMP)/cddfs-0.2/cddfs.c
	PKG_VER=0.2 $(OPKG_SH) $(CONTROL_DIR)/cddfs
	$(REMOVE)/cddfs-0.2 $(PKGPREFIX)
	touch $@

$(D)/dvdreadfs: $(ARCHIVE)/dvdreadfs.tar fuse libdvdread | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	mkdir -p $(BUILD_TMP)/dvdreadfs $(PKGPREFIX)/bin
	tar -C $(BUILD_TMP)/dvdreadfs -xf $(ARCHIVE)/dvdreadfs.tar
	cd $(BUILD_TMP)/dvdreadfs && $(PATCH)/dvdreadfs-seife.diff
	$(TARGET)-gcc \
		$(TARGET_CFLAGS) -DFUSE_USE_VERSION=26 -D_FILE_OFFSET_BITS=64 -DFORCE_SINGLE_THREAD=1 \
		$(TARGET_LDFLAGS) -lfuse -ldvdread \
		-o $(PKGPREFIX)/bin/dvdreadfs $(BUILD_TMP)/dvdreadfs/dvdreadfs.c
	install -D -m 755 $(SCRIPTS)/dvdreadfs.init $(PKGPREFIX)/etc/init.d/dvdreadfs
	ln -sf dvdreadfs $(PKGPREFIX)/etc/init.d/S80dvdreadfs
	ln -sf dvdreadfs $(PKGPREFIX)/etc/init.d/K20dvdreadfs
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	PKG_VER=0.0 $(OPKG_SH) $(CONTROL_DIR)/dvdreadfs
	$(REMOVE)/dvdreadfs $(PKGPREFIX)
	touch $@

$(D)/djmount: $(ARCHIVE)/djmount-$(DJMOUNT_VER).tar.gz fuse | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/djmount-$(DJMOUNT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/djmount-$(DJMOUNT_VER); \
		$(PATCH)/djmount-0.71.diff; \
		./configure -C \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix=/opt/pkg \
			--with-fuse-prefix=$(TARGETPREFIX) \
			; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	install -D -m 755 $(SCRIPTS)/djmount.init $(PKGPREFIX)/opt/pkg/etc/init.d/djmount
	ln -sf djmount $(PKGPREFIX)/opt/pkg/etc/init.d/S80djmount
	ln -sf djmount $(PKGPREFIX)/opt/pkg/etc/init.d/K20djmount
	PKG_VER=$(DJMOUNT_VER) \
		PKG_DEP="libfuse.so.2, fuse" \
		PKG_PROV=" " \
		$(OPKG_SH) $(CONTROL_DIR)/djmount
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REMOVE)/djmount-$(DJMOUNT_VER) $(PKGPREFIX)
	touch $@

$(D)/evtest: $(ARCHIVE)/evtest_1.29.orig.tar.bz2
	$(UNTAR)/evtest_1.29.orig.tar.bz2
	set -e; cd $(BUILD_TMP)/evtest-1.29; \
		$(PATCH)/evtest-1.29-old-kernel.diff; \
		$(CONFIGURE) --prefix= \
			; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/evtest-1.29
	touch $@

$(D)/libdvdcss: $(ARCHIVE)/libdvdcss-$(DVDCSS_VER).tar.bz2 | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libdvdcss-$(DVDCSS_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libdvdcss-$(DVDCSS_VER); \
		$(CONFIGURE) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdvdcss.pc
	$(REWRITE_LIBTOOL)/libdvdcss.la
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libdvdcss.so.* $(PKGPREFIX)/lib
	PKG_VER=$(DVDCSS_VER) $(OPKG_SH) $(CONTROL_DIR)/libdvdcss
	$(REMOVE)/libdvdcss-$(DVDCSS_VER) $(PKGPREFIX)
	touch $@

$(D)/libdvdread: $(ARCHIVE)/libdvdread-4.1.3.tar.bz2 | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libdvdread-4.1.3.tar.bz2
	set -e; cd $(BUILD_TMP)/libdvdread-4.1.3; \
		$(CONFIGURE) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dvdread.pc
	$(REWRITE_LIBTOOL)/libdvdread.la
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libdvdread.so.* $(PKGPREFIX)/lib
	PKG_VER=4.1.3 $(OPKG_SH) $(CONTROL_DIR)/libdvdread
	$(REMOVE)/libdvdread-4.1.3 $(PKGPREFIX)
	touch $@

# should be in archives.mk...
$(SOURCE_DIR)/tvheadend-seife:
	set -e; cd $(SOURCE_DIR); \
		git clone git://github.com/seife/tvheadend.git tvheadend-seife

$(D)/tvheadend: $(SOURCE_DIR)/tvheadend-seife openssl
	$(REMOVE)/tvheadend $(PKGPREFIX)
	cp -a $(SOURCE_DIR)/tvheadend-seife $(BUILD_TMP)/tvheadend
ifeq ($(PLATFORM), spark)
	set -e; cd $(BUILD_TMP)/tvheadend; \
		$(PATCH)/tvheadend-sh4.diff
endif
	set -e; cd $(BUILD_TMP)/tvheadend; \
		$(BUILDENV) CC=$(TARGET)-gcc \
			./configure  --prefix= --arch=sh4 --cpu=sh4 \
			; \
		$(MAKE) DESTDIR=$(PKGPREFIX) install
	rm -rf $(PKGPREFIX)/share/man $(PKGPREFIX)/share/tvheadend/docs
	PKG_VER=3.5.git \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/tvheadend
	touch $@

# this rule is ugly, but will do for now
arduino-serlcd: | $(TARGETPREFIX)
	set -e; if [ -d $(BUILD_TMP)/arduino-serlcd ]; \
		then cd $(BUILD_TMP)/arduino-serlcd; git pull; \
		else cd $(BUILD_TMP); git clone $(GITORIOUS)/seife/arduino-serlcd.git; \
		fi
	set -e; cd $(BUILD_TMP)/arduino-serlcd; \
		make CC=$(TARGET)-gcc; \
		cp arduino_serlcd_test $(TARGETPREFIX)/bin


$(D)/links: $(ARCHIVE)/links-$(LINKS-VER).tar.bz2 $(D)/directfb | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/links-$(LINKS-VER).tar.bz2
	set -e; cd $(BUILD_TMP)/links-$(LINKS-VER); \
		$(PATCH)/links-2.3pre1.diff; \
		export CC=$(TARGET)-gcc; \
		export SYSROOT=$(TARGETPREFIX); \
		$(CONFIGURE) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--mandir=$(BUILD_TMP)/.remove \
			--without-svgalib \
			--without-x \
			--without-libtiff \
			--enable-graphics \
			--enable-javascript; \
		$(MAKE); \
		DESTDIR=$(PKGPREFIX) make install prefix=$(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/tuxbox/plugins $(PKGPREFIX)/var/tuxbox/config/links
	mv $(PKGPREFIX)/bin/links $(PKGPREFIX)/lib/tuxbox/plugins/links.so
	rmdir $(PKGPREFIX)/bin
	echo "name=Links web browser"	 > $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "desc=Web Browser"		>> $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "type=2"			>> $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "needfb=1"			>> $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "needrc=1"			>> $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "needoffsets=1"		>> $(PKGPREFIX)/lib/tuxbox/plugins/links.cfg
	echo "bookmarkcount=0"		 > $(PKGPREFIX)/var/tuxbox/config/bookmarks
	touch $(PKGPREFIX)/var/tuxbox/config/links/links.his
	cp -a $(SCRIPTS)/bookmarks.html $(SCRIPTS)/tables.tar.gz $(PKGPREFIX)/var/tuxbox/config/links
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(OPKG_SH) $(CONTROL_DIR)/links
	$(REMOVE)/links-$(LINKS-VER) $(BUILD_TMP)/.remove $(PKGPREFIX)
	touch $@

QT_BUILD = $(BUILD_TMP)/qt-everywhere-opensource-src-$(QT-VER)
QT_CONF = $(QT_BUILD)/mkspecs/qws/linux-cx2450x-g++/
$(D)/qt: $(ARCHIVE)/qt-everywhere-opensource-src-$(QT-VER).tar.gz $(D)/directfb | $(TARGETPREFIX)
	$(UNTAR)/qt-everywhere-opensource-src-$(QT-VER).tar.gz
	mkdir $(QT_CONF)
	echo "include(../../common/g++.conf)"		 > $(QT_CONF)/qmake.conf
	echo "include(../../common/linux.conf)"		>> $(QT_CONF)/qmake.conf
	echo "include(../../common/qws.conf)"		>> $(QT_CONF)/qmake.conf
	echo "# modifications to g++.conf"			>> $(QT_CONF)/qmake.conf
	echo "QMAKE_CC         = $(TARGET)-gcc"		>> $(QT_CONF)/qmake.conf
	echo "QMAKE_CXX        = $(TARGET)-g++"		>> $(QT_CONF)/qmake.conf
	echo "QMAKE_LINK       = $(TARGET)-g++"		>> $(QT_CONF)/qmake.conf
	echo "QMAKE_LINK_SHLIB = $(TARGET)-g++"		>> $(QT_CONF)/qmake.conf
	echo "# modifications to linux.conf"		>> $(QT_CONF)/qmake.conf
	echo "QMAKE_AR         = $(TARGET)-ar cqs"	>> $(QT_CONF)/qmake.conf
	echo "QMAKE_OBJCOPY    = $(TARGET)-objcopy"	>> $(QT_CONF)/qmake.conf
	echo "QMAKE_STRIP      = $(TARGET)-strip"	>> $(QT_CONF)/qmake.conf
	echo "# for directfb"						>> $(QT_CONF)/qmake.conf
	echo "QT_CFLAGS_DIRECTFB = -I$(TARGETPREFIX)/include/directfb -D_REENTRANT"		>> $(QT_CONF)/qmake.conf
	echo "QT_LIBS_DIRECTFB   = -L$(TARGETPREFIX)/lib/ -ldirect -ldirectfb -lfusion"	>> $(QT_CONF)/qmake.conf
	echo "QT_DEFINES_DIRECTFB = QT_NO_DIRECTFB_PREALLOCATED"						>> $(QT_CONF)/qmake.conf
	echo ""												>> $(QT_CONF)/qmake.conf
	echo "load(qt_config)"								>> $(QT_CONF)/qmake.conf
	echo '#include "../../linux-g++/qplatformdefs.h"'	> $(QT_CONF)/qplatformdefs.h
	set -e; cd $(QT_BUILD); \
		sed -i 's/OPT_CONFIRM_LICENSE=no/OPT_CONFIRM_LICENSE=yes/' configure; \
		./configure \
			-embedded arm \
			-silent \
			-platform qws/linux-x86-g++ \
			-xplatform qws/linux-cx2450x-g++ \
			-prefix /opt/qt \
			-no-rpath \
			-release \
			-shared \
			-no-fast \
			-largefile \
			-exceptions \
			-no-accessibility \
			-no-stl \
			-qt-sql-sqlite \
			-no-qt3support \
			-qt-zlib \
			-qt-gif \
			-no-libtiff \
			-qt-libpng \
			-no-libmng \
			-qt-libjpeg \
			-qt-freetype \
			-continue \
			-no-nis \
			-no-cups \
			-no-iconv \
			-no-pch \
			-no-dbus \
			-no-separate-debug-info \
			-no-mmx \
			-no-3dnow \
			-no-sse \
			-no-sse2 \
			-optimized-qmake \
			-no-xmlpatterns \
			-multimedia \
			-audio-backend \
			-no-phonon \
			-no-phonon-backend \
			-no-openssl \
			-no-gtkstyle \
			-svg \
			-webkit \
			-no-javascript-jit \
			-no-script \
			-no-scripttools \
			-no-declarative \
			-opensource \
			-no-opengl \
			-no-openvg \
			-no-xshape \
			-no-xsync \
			-no-xinerama \
			-no-xcursor \
			-no-xfixes \
			-no-xrandr \
			-no-xrender \
			-no-mitshm \
			-no-fontconfig \
			-no-xinput \
			-no-xkb \
			-qt-kbd-linuxinput \
			-qt-mouse-pc \
			-qt-gfx-linuxfb \
			-plugin-gfx-directfb \
			-no-glib; \
		$(MAKE); \
		$(MAKE) INSTALL_ROOT=$(TARGETPREFIX) install
	mv $(TARGETPREFIX)/opt/qt/bin/* $(HOSTPREFIX)/bin/
	install -m 0755 -D $(SCRIPTS)/browser.sh $(TARGETPREFIX)/bin/browser.sh
	$(REMOVE)/links-$(QT-VER) $(BUILD_TMP)/.remove $(PKGPREFIX)
	touch $@

$(DEPDIR)/nbench: $(ARCHIVE)/nbench-byte-$(NBENCH_BYTE-VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/nbench-byte-$(NBENCH_BYTE-VER).tar.gz
	set -e; cd $(BUILD_TMP)/nbench-byte-$(NBENCH_BYTE-VER); \
		$(PATCH)/nbench-byte-2.2.3-crossfix.diff; \
		printf "#!/bin/sh\necho 4\n" > pointer; chmod 0755 pointer; \
		$(BUILDENV) make CC=$(TARGET)-gcc; \
		mkdir -p $(TARGETPREFIX)/opt/nbench-byte; \
		printf '#!/bin/sh\ncd /opt/nbench-byte\n./nbench $$@\n' > nbench-run.sh; \
		chmod 0755 nbench-run.sh; \
		cp -a nbench nbench-run.sh *DAT $(TARGETPREFIX)/opt/nbench-byte
	$(REMOVE)/nbench-byte-$(NBENCH_BYTE-VER)
	touch $@

$(D)/libupnp: $(ARCHIVE)/libupnp-$(LIBUPNP_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/libupnp-$(LIBUPNP_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libupnp-$(LIBUPNP_VER); \
		$(CONFIGURE) --prefix=; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libupnp.pc
	$(REWRITE_LIBTOOL)/libixml.la
	$(REWRITE_LIBTOOL)/libthreadutil.la
	$(REWRITE_LIBTOOL)/libupnp.la
	cd $(PKGPREFIX); \
		rm -r include lib/pkgconfig lib/*a lib/*.so
	PKG_VER=$(LIBUPNP_VER) PKG_AUTOREQPROV=1 \
		$(OPKG_SH) $(CONTROL_DIR)/libupnp
	$(REMOVE)/libupnp-$(LIBUPNP_VER) $(PKGPREFIX)
	touch $@

$(ARCHIVE)/libdlna-hg.tar.bz2: | find-hg
	est -e; cd $(BUILD_TMP); \
		hg clone http://hg.geexbox.org/libdlna libdlna-hg; \
		tar cvpjf $@ --exclude='*/.hg' libdlna-hg
	$(REMOVE)/libdlna-hg

$(D)/libdlna: $(ARCHIVE)/libdlna-hg.tar.bz2 $(D)/ffmpeg $(D)/libupnp | $(TARGETPREFIX)
	$(UNTAR)/libdlna-hg.tar.bz2
	set -e; cd $(BUILD_TMP)/libdlna-hg; \
		$(PATCH)/libdlna-fix-build.diff; \
		$(BUILDENV) \
		./configure --cross-compile --cross-prefix=$(TARGET)- \
			--disable-sqlite --prefix=/opt/pkg; \
		touch src/TAGS src/tags; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	mv $(PKGPREFIX)/opt/pkg/lib/pkgconfig/libdlna.pc $(PKG_CONFIG_PATH)/
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	sed -i 's/PREFIX/prefix/g' $(PKG_CONFIG_PATH)/libdlna.pc
	$(REWRITE_PKGCONF_OPT) $(PKG_CONFIG_PATH)/libdlna.pc
	cd $(PKGPREFIX)/opt/pkg && \
		rm -r include lib/pkgconfig lib/*.so
	$(OPKG_SH) $(CONTROL_DIR)/libdlna
	$(REMOVE)/libdlna-hg $(PKGPREFIX)
	touch $@

$(D)/nano: $(ARCHIVE)/nano-$(NANO_VER).tar.gz libncurses | $(TARGETPREFIX)
	$(UNTAR)/nano-$(NANO_VER).tar.gz
	set -e; cd $(BUILD_TMP)/nano-$(NANO_VER); \
		$(BUILDENV) ./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix= ; \
		$(MAKE) CPPFLAGS+="-I$(TARGETPREFIX)/include/ncurses" install DESTDIR=$(PKGPREFIX)
	mv -v $(PKGPREFIX)/bin/$(TARGET)-nano $(PKGPREFIX)/bin/nano
	rm -rf $(PKGPREFIX)/share/man
	rm -rf $(PKGPREFIX)/share/locale
	rm -rf $(PKGPREFIX)/share/nano/man-html
	rm -rf $(PKGPREFIX)/share/info
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)/; \
	PKG_VER=$(NANO_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
	$(OPKG_SH) $(CONTROL_DIR)/nano
	$(REMOVE)/nano-$(NANO_VER) $(PKGPREFIX)
	touch $@

$(ARCHIVE)/ushare-1.1a.r469.tar.bz2: | find-hg
	set -e; cd $(BUILD_TMP); \
		hg clone -u 469 http://hg.geexbox.org/ushare ushare-1.1a.r469; \
		tar cvpjf $@ --exclude='*/.hg' ushare-1.1a.r469
	$(REMOVE)/ushare-hg

$(D)/ushare: $(ARCHIVE)/ushare-1.1a.r469.tar.bz2 libupnp | $(TARGETPREFIX)
	$(UNTAR)/ushare-1.1a.r469.tar.bz2
	set -e; cd $(BUILD_TMP)/ushare-1.1a.r469; \
		sed -i 's/__DATE__/"for $(PLATFORM)"/' src/ctrl_telnet.c; \
		$(PATCH)/ushare-new-upnp.diff; \
		$(BUILDENV) \
		./configure --cross-compile --cross-prefix=$(TARGET)- \
			--prefix=; \
		echo "mandir=/.remove" >> config.mak; \
		test -e src/config.h || ln -s ../config.h src/; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	install -D -m 0755 $(SCRIPTS)/ushare.init $(PKGPREFIX)/etc/init.d/ushare
	ln -s ushare $(PKGPREFIX)/etc/init.d/S99ushare # start late, so that drives are mounted
	ln -s ushare $(PKGPREFIX)/etc/init.d/K01ushare # stop early...
	rm -rf $(PKGPREFIX)/.remove
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	PKG_VER=1.1a.r469 PKG_AUTOREQPROV=1 \
		$(OPKG_SH) $(CONTROL_DIR)/ushare
	$(REMOVE)/ushare-1.1a.r469 $(PKGPREFIX)
	touch $@

$(D)/dropbear: $(ARCHIVE)/dropbear-$(DROPBEAR-VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/dropbear-$(DROPBEAR-VER).tar.bz2
	set -e; cd $(BUILD_TMP)/dropbear-$(DROPBEAR-VER); \
		$(PATCH)/dropbear-0.52-allow-empty-password-for-key-login.diff; \
		$(PATCH)/dropbear-0.53-opt-pkg-prefix.diff; \
		$(BUILDENV) CFLAGS="$(TARGET_CFLAGS) -DDSS_PRIV_FILENAME=\"\\\"/opt/pkg/etc/dropbear/dropbear_dss_host_key\\\"\" -DRSA_PRIV_FILENAME=\"\\\"/opt/pkg/etc/dropbear/dropbear_rsa_host_key\\\"\"" \
			 ./configure $(CONFIGURE_OPTS) --prefix=/opt/pkg; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" SCPPROGRESS=1; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" install DESTDIR=$(PKGPREFIX)
	install -D -m 0755 $(SCRIPTS)/dropbear.init $(PKGPREFIX)/opt/pkg/etc/init.d/dropbear
	install -d -m 0755 $(PKGPREFIX)/opt/pkg/etc/dropbear
	ln -sf dropbear $(PKGPREFIX)/opt/pkg/etc/init.d/S60dropbear
	ln -sf dropbear $(PKGPREFIX)/opt/pkg/etc/init.d/K60dropbear
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(OPKG_SH) $(CONTROL_DIR)/dropbear
	$(REMOVE)/dropbear-$(DROPBEAR-VER) $(PKGPREFIX)
	touch $@

$(DEPDIR)/opkg: $(ARCHIVE)/opkg-$(OPKG_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/opkg-$(OPKG_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/opkg-$(OPKG_VER); \
		autoreconf -v --install; \
		echo ac_cv_func_realloc_0_nonnull=yes >> config.cache; \
		$(CONFIGURE) \
		--prefix= \
		--build=$(BUILD) \
		--host=$(TARGET) \
		--disable-curl \
		--disable-gpg \
		--disable-shared \
		--config-cache \
		--with-opkglibdir=/var/lib \
		--mandir=$(BUILD_TMP)/.remove; \
		$(MAKE) all exec_prefix=; \
		make install prefix=$(PKGPREFIX); \
		make distclean; \
		./configure \
		--prefix= \
		--disable-curl \
		--disable-gpg \
		--disable-shared \
		--with-opkglibdir=/var/lib; \
		$(MAKE) all; \
		cp -a src/opkg-cl $(HOSTPREFIX)/bin
	install -d -m 0755 $(PKGPREFIX)/var/lib/opkg
	install -d -m 0755 $(PKGPREFIX)/etc/opkg
	ln -s opkg-cl $(PKGPREFIX)/bin/opkg # convenience symlink
	echo "# example config file, copy to opkg.conf and edit" > $(PKGPREFIX)/etc/opkg/opkg.conf.example
	echo "src server http://server/dist/$(PLATFORM)" >> $(PKGPREFIX)/etc/opkg/opkg.conf.example
	echo "# add an optional cache directory, important if not enough flash memory is available!" >> $(PKGPREFIX)/etc/opkg/opkg.conf.example
	echo "# directory must exist before executing of opkg" >> $(PKGPREFIX)/etc/opkg/opkg.conf.example
	echo "option cache /tmp/media/sda1/.opkg" >> $(PKGPREFIX)/etc/opkg/opkg.conf.example
	$(REMOVE)/opkg-$(OPKG_VER) $(PKGPREFIX)/.remove
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libopkg.pc
	rm -rf $(PKGPREFIX)/lib $(PKGPREFIX)/include
	PKG_VER=$(OPKG_VER) $(OPKG_SH) $(CONTROL_DIR)/opkg
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/libffi: $(D)/libffi-$(LIBFFI_VER)
	touch $@
$(D)/libffi-$(LIBFFI_VER): $(ARCHIVE)/libffi-$(LIBFFI_VER).tar.gz
	$(UNTAR)/libffi-$(LIBFFI_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libffi-$(LIBFFI_VER); \
		$(CONFIGURE) \
			--prefix= \
			--includedir=/include \
			--mandir=/.remove \
			--infodir=/.remove; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	cp -a $(PKGPREFIX)/lib $(TARGETPREFIX)/
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libffi.pc
	$(REWRITE_LIBTOOL)/libffi.la
	rm -rf $(PKGPREFIX)/lib/libffi-* $(PKGPREFIX)/lib/pkgconfig
	rm $(PKGPREFIX)/lib/libffi.{so,la,a}
	PKG_VER=$(LIBFFI_VER) \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/libffi
	$(REMOVE)/libffi-$(LIBFFI_VER) $(PKGPREFIX)
	touch $@

######
# build glib-tools for the host, for build systems that don't have those
# installed already.
# TODO: check if we this built glib-genmarshal is new enough for the glib
#       version we're trying to build
######
$(HOSTPREFIX)/bin/glib-genmarshal \
$(HOSTPREFIX)/bin/glib-compile-resources: | $(HOSTPREFIX)/bin
	$(UNTAR)/glib-$(GLIB_VER).tar.xz
	set -e; cd $(BUILD_TMP)/glib-$(GLIB_VER); \
		export PKG_CONFIG=/usr/bin/pkg-config; \
		./configure \
			--disable-gtk-doc \
			--disable-gtk-doc-html \
			--enable-static=yes \
			--enable-shared=no \
			--prefix=`pwd`/out \
			; \
		$(MAKE) install ; \
		cp -a out/bin/glib-* $(HOSTPREFIX)/bin
	$(REMOVE)/glib-$(GLIB_VER)

#http://www.dbox2world.net/board293-coolstream-hd1/board314-coolstream-development/9363-idee-midnight-commander/
$(D)/libglib: $(D)/libglib-$(GLIB_VER)
$(D)/libglib-$(GLIB_VER): $(ARCHIVE)/glib-$(GLIB_VER).tar.xz $(D)/zlib $(D)/libffi | $(TARGETPREFIX)
	$(REMOVE)/glib-$(GLIB_VER) $(PKGPREFIX)
	$(UNTAR)/glib-$(GLIB_VER).tar.xz
	set -e; cd $(BUILD_TMP)/glib-$(GLIB_VER); \
		$(PATCH)/glib-2.32.4-crosscompile-fix.diff; \
		autoreconf -fi; \
		echo "ac_cv_func_posix_getpwuid_r=yes" > config.cache; \
		echo "ac_cv_func_posix_getgrgid_r=ys" >> config.cache; \
		echo "glib_cv_stack_grows=no" >> config.cache; \
		echo "glib_cv_uscore=no" >> config.cache; \
		$(BUILDENV) \
		./configure \
			--cache-file=config.cache \
			--disable-gtk-doc \
			--disable-modular_tests \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--with-html-dir=/.remove \
			--mandir=/.remove \
			--prefix=/opt/pkg;\
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	set -e; cd $(PKGPREFIX)/opt/pkg/lib/pkgconfig; for i in *; do \
		mv $$i $(PKG_CONFIG_PATH); $(REWRITE_PKGCONF_OPT) $(PKG_CONFIG_PATH)/$$i; done
	rm -rf $(PKGPREFIX)/opt/pkg/share/locale # who needs localization?
	rm $(PKGPREFIX)/opt/pkg/bin/glib-mkenums # no perl available on the box
	sed -i "s,^libdir=.*,libdir='$(TARGETPREFIX)/opt/pkg/lib'," $(PKGPREFIX)/opt/pkg/lib/*.la
	sed -i '/^dependency_libs=/{ s#/opt/pkg/lib#$(TARGETPREFIX)/opt/pkg/lib#g }' $(PKGPREFIX)/opt/pkg/lib/*.la
	rm $(PKGPREFIX)/opt/pkg/bin/gdbus
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	cd $(PKGPREFIX)/opt/pkg && \
		rm -rf include lib/*.so lib/*.la share lib/gdbus-2.0 \
		bin/gtester-report bin/glib-* bin/gdbus-codegen
	rmdir $(PKGPREFIX)/opt/pkg/lib/pkgconfig
	PKG_VER=$(GLIB_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/libglib
	$(REMOVE)/glib-$(GLIB_VER) $(PKGPREFIX)
	touch $@

#Libxslt is the XSLT C library developed for the GNOME project. XSLT itself is a an XML language to define transformation for XML
$(D)/libxslt: libxslt-$(LIBXLST_VER)
	touch $@
$(D)/libxslt-$(LIBXLST_VER): libxml2 $(ARCHIVE)/libxslt-$(LIBXLST_VER).tar.gz | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libxslt-$(LIBXLST_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libxslt-$(LIBXLST_VER) && \
		$(CONFIGURE) \
			--prefix= \
			--enable-shared \
			--disable-static \
			--datarootdir=/.remove \
			--without-crypto \
			--without-python \
		$(MAKE) ; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/lib/libxslt.* $(TARGETPREFIX)/lib/libexslt.* $(PKGPREFIX)/lib
	rm -rf $(TARGETPREFIX)/.remove
	$(REWRITE_LIBTOOL)/libexslt.la
	$(REWRITE_LIBTOOL)/libxslt.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libexslt.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libxslt.pc
	rm -rf $(TARGETPREFIX)/lib/libxslt-plugins/
	rm -rf $(TARGETPREFIX)/lib/xml2Conf.sh
	rm -rf $(TARGETPREFIX)/lib/xsltConf.sh
	rm -rf $(TARGETPREFIX)/bin/xml2-config
	rm -rf $(TARGETPREFIX)/bin/xslt-config
	PKG_VER=$(LIBXLST_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/libxslt
	$(REMOVE)/libxslt-$(LIBXLST_VER)
	touch $@

# libxml2
$(D)/libxml2: libxml2-$(LIBXML2_VER)
	touch $@
$(D)/libxml2-$(LIBXML2_VER): $(D)/zlib $(ARCHIVE)/libxml2-$(LIBXML2_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libxml2-$(LIBXML2_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libxml2-$(LIBXML2_VER); \
		$(CONFIGURE)  \
			--prefix= \
			--enable-shared \
			--disable-static \
			--datarootdir=/.remove \
			--without-python \
			--without-debug \
			--without-sax1 \
			--without-legacy \
			--without-catalog \
			--without-docbook \
			--without-lzma \
			--without-schematron && \
		$(MAKE) ; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	#cd $(PKGPREFIX)/share
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	ln -sf ./libxml2/libxml $(TARGETPREFIX)/include/libxml
	mv $(TARGETPREFIX)/bin/xml2-config $(HOSTPREFIX)/bin
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libxml-2.0.pc $(HOSTPREFIX)/bin/xml2-config
	sed -i 's/^\(Libs:.*\)/\1 -lz/' $(PKG_CONFIG_PATH)/libxml-2.0.pc
	$(REWRITE_LIBTOOL)/libxml2.la
	cd $(PKGPREFIX); rm -rf [^l]* lib/*[^0-9]
	PKG_VER=$(LIBXML2_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/libxml2
	$(REMOVE)/libxml2-$(LIBXML2_VER) $(PKGPREFIX)
	touch $@

$(D)/mc: $(ARCHIVE)/mc-$(MC-VER).tar.gz $(D)/libglib $(D)/libncurses | $(TARGETPREFIX) find-autopoint
	$(UNTAR)/mc-$(MC-VER).tar.gz
	set -e; cd $(BUILD_TMP)/mc-$(MC-VER); \
		$(PATCH)/mc-4.6.2.diff; \
		autoreconf -fi; \
		$(BUILDENV) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CONFIG_SHELL=/bin/bash \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/opt/pkg \
			--without-gpm-mouse \
			--with-screen=ncurses \
			--mandir=/.remove \
			--without-x; \
			$(CC) -o src/man2hlp src/man2hlp.c; \
			$(BUILDENV) $(MAKE) all; \
			make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	rm -rf $(PKGPREFIX)/opt/pkg/share/locale # who needs localization?
	rm $(PKGPREFIX)/opt/pkg/share/mc/mc.h*.* # mc.hint.*, mc.hlp.*
	PKG_VER=$(MC-VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/mc
	$(REMOVE)/mc-$(MC-VER) $(PKGPREFIX)
	touch $@

$(D)/sg3-utils: $(ARCHIVE)/sg3_utils-$(SG3_UTILS-VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/sg3_utils-$(SG3_UTILS-VER).tar.bz2
	rm -rf $(PKGPREFIX)
	set -e; cd $(BUILD_TMP)/sg3_utils-$(SG3_UTILS-VER); \
		$(CONFIGURE) --prefix= --mandir=/.remove; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove $(BUILD_TMP)/pkg-tmp
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(REWRITE_LIBTOOL)/libsgutils2.la
	rm -r $(PKGPREFIX)/lib $(PKGPREFIX)/include $(PKGPREFIX)/bin/sg_start
	PKG_VER=$(SG3_UTILS-VER) $(OPKG_SH) $(CONTROL_DIR)/sg3_utils/addon
	rm -r $(PKGPREFIX)/*
	mkdir $(PKGPREFIX)/lib $(PKGPREFIX)/bin
	cp -a $(TARGETPREFIX)/lib/libsgutils2.so.2* $(PKGPREFIX)/lib
	cp -a $(TARGETPREFIX)/bin/sg_start          $(PKGPREFIX)/bin
	PKG_VER=$(SG3_UTILS-VER) $(OPKG_SH) $(CONTROL_DIR)/sg3_utils/base
	$(REMOVE)/sg3_utils-$(SG3_UTILS-VER) $(PKGPREFIX)
	touch $@

$(D)/streamripper: $(ARCHIVE)/streamripper-1.64.6.tar.gz libglib libogg libvorbisidec | $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/streamripper-1.64.6.tar.gz
	set -e; cd $(BUILD_TMP)/streamripper-1.64.6; \
		$(PATCH)/streamripper-1.64.6-use-tremor.diff; \
		$(CONFIGURE) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--includedir=$(TARGETPREFIX)/include \
			; \
		$(MAKE)  ; \
		make install DESTDIR=$(PKGPREFIX)
	rm -R $(PKGPREFIX)/share
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	PKG_VER=1.64.6 \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/streamripper
	$(REMOVE)/streamripper-1.64.6 $(PKGPREFIX)
	touch $@

# the following libs are built static only for now, as they
# have only one user (lcd4linux) yet => no opkg package yet, either.
# libiconv libusb libusb-compat libgd2
$(D)/libiconv: $(ARCHIVE)/libiconv-$(ICONV-VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/libiconv-$(ICONV-VER).tar.gz
	set -e; cd $(BUILD_TMP)/libiconv-$(ICONV-VER); \
		$(CONFIGURE) --target=$(TARGET) --enable-static --disable-shared \
			--prefix= --datarootdir=/.remove --bindir=/.remove ; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	rm -rf $(TARGETPREFIX)/.remove
	rm -rf $(TARGETPREFIX)/lib/preloadable_libiconv.so
	$(REWRITE_LIBTOOL)/libiconv.la
	$(REMOVE)/libiconv-$(ICONV-VER)
	touch $@

$(D)/libusb: $(ARCHIVE)/libusb-$(USB_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/libusb-$(USB_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libusb-$(USB_VER); \
		$(CONFIGURE) --prefix= --enable-static --disable-shared ; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_LIBTOOL)/libusb-1.0.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libusb-1.0.pc
	$(REMOVE)/libusb-$(USB_VER)
	touch $@

$(D)/libusb-compat: $(ARCHIVE)/libusb-compat-$(USBCMPT_VER).tar.bz2 $(D)/libusb | $(TARGETPREFIX)
	$(UNTAR)/libusb-compat-$(USBCMPT_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/libusb-compat-$(USBCMPT_VER); \
		$(CONFIGURE) --prefix= --enable-static --disable-shared ; \
		$(MAKE) ; \
		make install DESTDIR=$(TARGETPREFIX)
	rm -f $(TARGETPREFIX)/bin/libusb-config
	$(REWRITE_LIBTOOL)/libusb.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libusb.pc
	$(REMOVE)/libusb-compat-$(USBCMPT_VER)
	touch $@

$(D)/libgd2: $(D)/zlib $(D)/libpng $(D)/libjpeg $(D)/freetype $(D)/libiconv $(ARCHIVE)/gd-2.0.35.tar.gz | $(TARGETPREFIX)
	$(UNTAR)/gd-2.0.35.tar.gz
	set -e; cd $(BUILD_TMP)/gd-2.0.35; \
		chmod 0755 configure; \
		: autoreconf -fi; \
		$(CONFIGURE) --prefix= --enable-static --disable-shared --bindir=/.remove; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX)
	rm -rf $(TARGETPREFIX)/.remove
	$(REWRITE_LIBTOOL)/libgd.la
	$(REMOVE)/gd-2.0.35
	touch $@

$(D)/libdpf: $(ARCHIVE)/dpf-ax_r$(DPF-AXREV).tar.gz | $(TARGETPREFIX)
	$(REMOVE)/dpf-ax_r$(DPF-AXREV)
	$(UNTAR)/dpf-ax_r$(DPF-AXREV).tar.gz
	set -e; cd $(BUILD_TMP)/dpf-ax_r$(DPF-AXREV)/dpflib; \
		$(PATCH)/libdpf-crossbuild.diff; \
		make libdpf.a CC=$(TARGET)-gcc PREFIX=$(TARGETPREFIX); \
		mkdir -p $(TARGETPREFIX)/include/libdpf; \
		cp dpf.h $(TARGETPREFIX)/include/libdpf/libdpf.h; \
		cp ../include/spiflash.h $(TARGETPREFIX)/include/libdpf/; \
		cp ../include/usbuser.h $(TARGETPREFIX)/include/libdpf/; \
		cp libdpf.a $(TARGETPREFIX)/lib/
	$(REMOVE)/dpf-ax_r$(DPF-AXREV)
	touch $@

$(D)/lcd4linux: $(D)/libusb-compat $(D)/libgd2 $(D)/libdpf $(ARCHIVE)/lcd4linux_r$(LCD4LINUX_SVN).tar.gz | $(TARGETPREFIX)
	$(REMOVE)/lcd4linux_r$(LCD4LINUX_SVN) $(PKGPREFIX)
	$(UNTAR)/lcd4linux_r$(LCD4LINUX_SVN).tar.gz
	set -e; cd $(BUILD_TMP)/lcd4linux_r$(LCD4LINUX_SVN); \
		$(PATCH)/lcd4linux-svn1184-dpf.diff; \
		$(BUILDENV) ./bootstrap; \
		$(BUILDENV) ./configure $(CONFIGURE_OPTS) \
			--prefix= \
			--with-drivers='DPF' \
			--with-plugins='all,!dbus,!mpris_dbus,!asterisk,!isdn,!pop3,!ppp,!seti,!huawei,!imon,!kvv,!sample,!w1retap,!wireless,!xmms,!gps,!mpd,!mysql,!qnaplog' \
			--without-ncurses; \
	$(MAKE) all; \
	make install DESTDIR=$(PKGPREFIX)/opt/pkg
	install -D -m 0600 $(SCRIPTS)/lcd4linux.conf $(PKGPREFIX)/opt/pkg/etc/lcd4linux.conf
	PKG_VER=$(LCD4LINUX_SVN_VER) $(OPKG_SH) $(CONTROL_DIR)/lcd4linux
	$(REMOVE)/lcd4linux_r$(LCD4LINUX_SVN) $(PKGPREFIX)
	touch $@

$(D)/alsa-lib: $(ARCHIVE)/alsa-lib-$(ALSA_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/alsa-lib-$(ALSA_VER).tar.bz2
	rm -rf $(PKGPREFIX)
	set -e; cd $(BUILD_TMP)/alsa-lib-$(ALSA_VER); \
		$(CONFIGURE) --prefix= --mandir=/.remove --disable-aload --disable-rawmidi \
			--disable-python --disable-old-symbols \
			--disable-alisp --disable-ucm --disable-hwdep; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)/{bin,include,lib/alsa-lib,lib/pkgconfig} \
		$(PKGPREFIX)/share/alsa/{pcm,cards,smixer.conf} \
		$(PKGPREFIX)/share/aclocal
	rm $(PKGPREFIX)/lib/*.so $(PKGPREFIX)/lib/*.la
	PKG_VER=$(ALSA_VER) $(OPKG_SH) $(CONTROL_DIR)/alsa-lib
	$(REMOVE)/alsa-lib-$(ALSA_VER) $(PKGPREFIX)
	touch $@

$(D)/alsa-utils: $(ARCHIVE)/alsa-utils-$(ALSA_VER).tar.bz2 $(D)/alsa-lib | $(TARGETPREFIX)
	$(UNTAR)/alsa-utils-$(ALSA_VER).tar.bz2
	rm -rf $(PKGPREFIX)
	set -e; cd $(BUILD_TMP)/alsa-utils-$(ALSA_VER); \
		sed -ir -r "s/(alsamixer|amidi|aplay|iecset|speaker-test|seq|alsactl|alsaucm)//g" Makefile.am ;\
		autoreconf -fi -I $(TARGETPREFIX)/share/aclocal; \
		$(CONFIGURE) --prefix= --mandir=/.remove --disable-nls --disable-alsatest \
			--disable-alsaconf --disable-alsaloop --disable-alsamixer --disable-xmlto; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove $(BUILD_TMP)/pkg-tmp
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	set -e; cd $(SCRIPTS); \
		install -m 755 -D amixer.init $(PKGPREFIX)/etc/init.d/amixer; \
		ln -s amixer $(PKGPREFIX)/etc/init.d/S70amixer; \
		test -e asound.conf.$(PLATFORM) && cp asound.conf.$(PLATFORM) $(PKGPREFIX)/etc/asound.conf; \
		test -e amixer.conf.$(PLATFORM) && cp amixer.conf.$(PLATFORM) $(PKGPREFIX)/etc/amixer.conf
	rm -rf $(PKGPREFIX)/var $(PKGPREFIX)/share $(PKGPREFIX)/lib/pkgconfig
	PKG_VER=$(ALSA_VER) $(OPKG_SH) $(CONTROL_DIR)/alsa-utils
	$(REMOVE)/alsa-utils-$(ALSA_VER) $(PKGPREFIX)
	touch $@

# hg rev 116
$(ARCHIVE)/vtuner-apps-rel2.1.99.116.tar.bz2:
	$(REMOVE)/vtuner-apps-rel2.1.99.116
	set -e; cd $(BUILD_TMP); \
		wget --no-check-certificate https://apps.vtuner.googlecode.com/archive/b6fa0d2b133b5c23a0fc9e2c038c3b5dde55f3b0.zip; \
		unzip b6fa0d2b133b5c23a0fc9e2c038c3b5dde55f3b0.zip; \
		rm b6fa0d2b133b5c23a0fc9e2c038c3b5dde55f3b0.zip; \
		mv apps.vtuner-b6fa0d2b133b vtuner-apps-rel2.1.99.116; \
		tar -cvpjf $@ vtuner-apps-rel2.1.99.116

$(D)/vtuner: $(ARCHIVE)/vtuner-apps-rel2.1.tar.bz2 $(sort $(wildcard $(PATCHES)/vtuner.apps-[1-9]*)) $(PATCHES)/vtuner-2.1.99-debug.diff $(PATCHES)/vtuner-apps-compilerwarnings.diff $(PATCHES)/vtuner-ratelimit-buffer-message.diff
	$(REMOVE)/vtuner-apps-rel2.1 $(PKGPREFIX)
	$(UNTAR)/vtuner-apps-rel2.1.tar.bz2
	set -e; cd $(BUILD_TMP)/vtuner-apps-rel2.1; \
		for i in $^; do \
			test $$i = $(firstword $^) && continue; \
			echo "applying patch $$i"; patch -p1 -i $$i; done; \
		echo "CC-$(BOXARCH)=$(TARGET)-gcc" > Make.config; \
		make $(BOXARCH); \
		install -m 755 -D dist/$(BOXARCH)/vtunerd.$(BOXARCH) $(PKGPREFIX)/bin/vtunerd; \
		install -m 755 -D dist/$(BOXARCH)/vtunerc.$(BOXARCH) $(PKGPREFIX)/bin/vtunerc
	set -e; cd $(SCRIPTS); \
		install -m 755 -D vtunerd.init $(PKGPREFIX)/etc/init.d/vtunerd; \
		ln -s vtunerd $(PKGPREFIX)/etc/init.d/S70vtunerd; \
		cp vtunerd.conf $(PKGPREFIX)/etc/
	PKG_VER=2.1.99.116 $(OPKG_SH) $(CONTROL_DIR)/vtuner-apps
	$(REMOVE)/vtuner-apps-rel2.1 $(PKGPREFIX)
	touch $@

$(D)/samsremote: $(ARCHIVE)/samsremote-1.tar.gz
	$(UNTAR)/samsremote-1.tar.gz
	set -e; cd $(BUILD_TMP)/samsremote-samsremote; \
		make CC=$(TARGET)-gcc; \
		install -m 755 -D samsremote $(PKGPREFIX)/bin/samsremote
	PKG_VER=1 $(OPKG_SH) $(CONTROL_DIR)/samsremote
	$(REMOVE)/samsremote-samsremote $(PKGPREFIX)
	touch $@

$(D)/xmlto: $(ARCHIVE)/xmlto-$(XMLTO_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/xmlto-$(XMLTO_VER).tar.gz
	set -e; cd $(BUILD_TMP)/xmlto-$(XMLTO_VER); \
		$(CONFIGURE) --build=$(BUILD) --host=$(TARGET) --target=$(TARGET) \
			--prefix=; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
		rm -rf $(PKGPREFIX)/share/man
	PKG_VER=$(XMLTO_VER) $(OPKG_SH) $(CONTROL_DIR)/xmlto
	$(REMOVE)/xmlto-$(XMLTO_VER) $(PKGPREFIX)
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/xupnpd: $(D)/liblua $(ARCHIVE)/xupnpd_r$(XUPNP_SVN).tar.gz $(PLUGIN_DIR)/$(LUA_REPO) | $(TARGETPREFIX)
	$(REMOVE)/xupnpd_r$(XUPNP_SVN)
	$(UNTAR)/xupnpd_r$(XUPNP_SVN).tar.gz
	set -e; cd $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src; \
		$(PATCH)/xupnpd-crossbuild.diff; \
		$(PATCH)/xupnpd_cst.diff; \
		$(PATCH)/xupnpd-fix-memleak-on-coolstream-boxes.patch; \
		make embedded PREFIX=$(TARGET) LUAFLAGS="-I$(TARGETPREFIX)/include -L$(TARGETLIB)"
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/bin
	mkdir -p $(PKGPREFIX)/share/xupnpd/playlists
	mkdir -p $(PKGPREFIX)/share/xupnpd/plugins
	mkdir -p $(PKGPREFIX)/share/xupnpd/profiles
	mkdir -p $(PKGPREFIX)/share/xupnpd/ui
	mkdir -p $(PKGPREFIX)/share/xupnpd/www
	mkdir -p $(PKGPREFIX)/usr/share
	cp -a $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src/xupnpd $(PKGPREFIX)/bin
	cp -a $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src/*.lua  $(PKGPREFIX)/share/xupnpd
	cp -a $(PLUGIN_DIR)/$(LUA_REPO)/xupnpd/xupnpd_coolstream.lua $(PKGPREFIX)/share/xupnpd/plugins
#	cp -a $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src/plugins/xupnpd_youtube.lua    $(PKGPREFIX)/share/xupnpd/plugins
	cp -a $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src/ui/*  $(PKGPREFIX)/share/xupnpd/ui
	cp -a $(BUILD_TMP)/xupnpd_r$(XUPNP_SVN)/src/www/* $(PKGPREFIX)/share/xupnpd/www
	ln -sf ../../share/xupnpd $(PKGPREFIX)/usr/share/xupnpd
	install -m 0755 -D $(SCRIPTS)/xupnpd.init $(PKGPREFIX)/etc/init.d/xupnpd
	ln -sf xupnpd $(PKGPREFIX)/etc/init.d/S80xupnpd
	ln -sf xupnpd $(PKGPREFIX)/etc/init.d/K20xupnpd
	PKG_VER=svnr$(XUPNP_SVN) PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)/bin` $(OPKG_SH) $(CONTROL_DIR)/xupnpd
	$(REMOVE)/xupnpd_r$(XUPNP_SVN)
	rm -rf $(PKGPREFIX)
	touch $@



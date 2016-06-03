# makefiles for nfs kernelspace server
#
# you also need this:
#
# mkdir -p /var/lib/nfs
# mount -t tmpfs nfs /var/lib/nfs
#
# somewhere in your initscripts or rcS
#

ifeq ($(PLATFORM), nevis)
IPV6_LIBTIRPC = 
IPV6_NFSUTILS = --disable-ipv6
else
IPV6_LIBTIRPC = -DINET6
IPV6_NFSUTILS = --enable-ipv6
endif

$(D)/libtirpc: $(ARCHIVE)/libtirpc-$(LIBTIRPC_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/libtirpc-$(LIBTIRPC_VER)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/libtirpc-$(LIBTIRPC_VER).tar.bz2
	cd $(BUILD_TMP)/libtirpc-$(LIBTIRPC_VER) && \
	$(PATCH)/nfsd/libtirpc-01-Disable-parts-of-TIRPC-requiring-NIS-support.patch && \
	$(PATCH)/nfsd/libtirpc-02-uClibc-without-RPC-support-does-not-install-rpcent.h.patch && \
	$(PATCH)/nfsd/libtirpc-03-Make-IPv6-support-optional.patch && \
	$(PATCH)/nfsd/libtirpc-04-Add-rpcgen-program-from-nfs-utils-sources.patch && \
	$(PATCH)/nfsd/libtirpc-05-Automatically-generate-XDR-header-files-from-.x-sour.patch && \
	$(PATCH)/nfsd/libtirpc-06-Add-more-XDR-files-needed-to-build-rpcbind-on-top-of.patch && \
	$(PATCH)/nfsd/libtirpc-07-needs-pthread.patch && \
		autoreconf -fi && \
		$(CONFIGURE) \
			--prefix= \
			--target=$(TARGET) \
			--build=$(BUILD) \
			--sysconfdir=/etc \
			--disable-gssapi \
			--enable-silent-rules \
			--mandir=/.remove && \
		$(MAKE) CFLAGS="$(TARGET_CFLAGS) -DGQ $(IPV6_LIBTIRPC)" && \
		$(MAKE) install DESTDIR=$(PKGPREFIX); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	rm -fr $(TARGETPREFIX)/.remove
	rm -fr $(PKGPREFIX)/.remove
	rm -fr $(PKGPREFIX)/include
	rm -fr $(PKGPREFIX)/lib/pkgconfig
	rm -f $(PKGPREFIX)/lib/*.a
	rm -f $(PKGPREFIX)/lib/*.la
	rm -f $(PKGPREFIX)/lib/*.so
	$(REWRITE_LIBTOOL)/libtirpc.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libtirpc.pc
	PKG_VER=$(LIBTIRPC_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/nfsd-libtirpc
	$(REMOVE)/libtirpc-$(LIBTIRPC_VER)
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/rpcbind: $(D)/libtirpc $(ARCHIVE)/rpcbind-$(RPCBIND_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/rpcbind-$(RPCBIND_VER)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/rpcbind-$(RPCBIND_VER).tar.bz2
	cd $(BUILD_TMP)/rpcbind-$(RPCBIND_VER) && \
	$(PATCH)/nfsd/rpcbind-01-Remove-yellow-pages-support.patch && \
	$(PATCH)/nfsd/rpcbind-02a-Make-IPv6-configurable.patch && \
	if [ ! "$(PLATFORM)" = "nevis" ]; then \
		$(PATCH)/nfsd/rpcbind-02b-Make-IPv6-configurable.patch; \
	fi; \
		autoreconf -fi && \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=$(DEFAULT_PREFIX) \
			--enable-silent-rules \
			--with-rpcuser=root \
			--mandir=/.remove && \
		$(MAKE) && \
		$(MAKE) install DESTDIR=$(PKGPREFIX); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	rm -rf $(PKGPREFIX)/bin/rpcgen
	rm -fr $(PKGPREFIX)/.remove
	rm -rf $(TARGETPREFIX)/bin/rpcgen
	rm -fr $(TARGETPREFIX)/.remove
	PKG_VER=$(RPCBIND_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/nfsd-rpcbind
	$(REMOVE)/rpcbind-$(RPCBIND_VER)
	rm -rf $(PKGPREFIX)
	touch $@

$(D)/nfs-utils: $(D)/rpcbind $(ARCHIVE)/nfs-utils-$(NFS_UTILS_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	rm -rf $(PKGPREFIX)
	$(UNTAR)/nfs-utils-$(NFS_UTILS_VER).tar.bz2
	pushd $(BUILD_TMP)/nfs-utils-$(NFS_UTILS_VER); \
	$(PATCH)/nfsd/nfs-utils-01-build-avoid-AM_CONDITIONAL-in-conditional-execution.patch && \
	$(PATCH)/nfsd/nfs-utils-02-Patch-taken-from-Gentoo.patch && \
	$(PATCH)/nfsd/nfs-utils-03-Switch-legacy-index-in-favour-of-strchr.patch && \
	$(PATCH)/nfsd/nfs-utils-04-fix-build-with-uClibc.patch && \
	$(PATCH)/nfsd/nfs-utils-05-Allow-usage-of-getrpcbynumber-when-getrpcbynumber_r-.patch && \
	$(PATCH)/nfsd/nfs-utils-06-Let-the-configure-script-find-getrpcbynumber-in-libt.patch && \
	$(PATCH)/nfsd/nfs-utils-07-sockaddr-h-needs-stddef-h-for-NULL.patch && \
	$(PATCH)/nfsd/nfs-utils-08-tirpc-with-pkgconfig.patch && \
	export knfsd_cv_bsd_signals=no && \
	autoreconf -fi && \
		$(CONFIGURE) \
			--prefix=/ \
			--target=$(TARGET) \
			--enable-maintainer-mode \
			--docdir=/.remove \
			--mandir=/.remove \
			--enable-tirpc \
			--disable-nfsv4 \
			--disable-nfsv41 \
			--disable-gss \
			--disable-uuid \
			--without-tcp-wrappers && \
			$(IPV6_NFSUTILS); \
		$(MAKE) && \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -f $(PKGPREFIX)/sbin/mountstats
	rm -f $(PKGPREFIX)/sbin/nfsiostat
	rm -f $(PKGPREFIX)/sbin/osd_login
	rm -f $(PKGPREFIX)/sbin/start-statd
	rm -f $(PKGPREFIX)/sbin/mount.nfs4
	rm -f $(PKGPREFIX)/sbin/umount.nfs4
	rm -f $(PKGPREFIX)/sbin/showmount
	rm -f $(PKGPREFIX)/sbin/rpcdebug
	rm -rf $(PKGPREFIX)/var
	rm -rf $(PKGPREFIX)/.remove
	install -m 755 -D $(SCRIPTS)/nfsd $(PKGPREFIX)/etc/init.d/nfsd
	ln -s nfsd $(PKGPREFIX)/etc/init.d/S60nfsd
	ln -s nfsd $(PKGPREFIX)/etc/init.d/K01nfsd
	cp -fd $(PKGPREFIX)/etc/init.d/* $(TARGETPREFIX)/etc/init.d
	cp -fd $(PKGPREFIX)/sbin/* $(TARGETPREFIX)/sbin
	PKG_VER=$(NFS_UTILS_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/nfs-utils
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	rm -rf $(PKGPREFIX)
	touch $@

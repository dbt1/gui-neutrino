glibc-pkg: $(TARGETPREFIX)/sbin/ldconfig
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)
	cd $(PKGPREFIX) && \
		mkdir lib sbin etc && \
		cp -a $(CROSS_DIR)/$(TARGET)/lib/*so* lib/ && \
		cp -a $(TARGETPREFIX)/sbin/ldconfig sbin/ &&  \
		rm lib/libnss_hesiod* lib/libnss_nis* lib/libnss_compat* \
		   lib/libmudflap* lib/libnsl*
	find $(PKGPREFIX) -type f -print0 | xargs -0 $(TARGET)-strip
	touch $(PKGPREFIX)/etc/ld.so.conf
	opkg.sh $(CONTROL_DIR)/glibc $(TARGET) "$(MAINTAINER)" $(PKGPREFIX) $(BUILD_TMP)
	mv $(PKGPREFIX)/glibc-*.opk $(PACKAGE_DIR)
	rm -rf $(PKGPREFIX)

cs-drivers-pkg:
	# we have two directories packed, the newer one determines the package version
	opkg-chksvn.sh $(CONTROL_DIR)/cs-drivers $(SOURCE_DIR)/svn/COOLSTREAM/2.6.26.8-nevis || \
	opkg-chksvn.sh $(CONTROL_DIR)/cs-drivers $(SOURCE_DIR)/svn/THIRDPARTY/lib/firmware
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib/modules/2.6.26.8-nevis
	mkdir    $(PKGPREFIX)/lib/firmware
	cp -a $(SOURCE_DIR)/svn/COOLSTREAM/2.6.26.8-nevis/* $(PKGPREFIX)/lib/modules/2.6.26.8-nevis
	cp -a $(SOURCE_DIR)/svn/THIRDPARTY/lib/firmware/*   $(PKGPREFIX)/lib/firmware
	opkg.sh $(CONTROL_DIR)/cs-drivers $(TARGET) "$(MAINTAINER)" $(PKGPREFIX) $(BUILD_TMP)
	mv $(PKGPREFIX)/cs-drivers-*.opk $(PACKAGE_DIR)
	rm -rf $(PKGPREFIX)

cs-libs-pkg: $(SVN_TP_LIBS)/libnxp/libnxp.so $(SVN_TP_LIBS)/libcs/libcoolstream.so
	opkg-chksvn.sh $(CONTROL_DIR)/cs-libs $(SVN_TP_LIBS)/libnxp/libnxp.so || \
	opkg-chksvn.sh $(CONTROL_DIR)/cs-libs $(SVN_TP_LIBS)/libcs/libcoolstream.so
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/lib
	cp -a $(SVN_TP_LIBS)/libnxp/libnxp.so $(SVN_TP_LIBS)/libcs/libcoolstream.so $(PKGPREFIX)/lib
	opkg.sh $(CONTROL_DIR)/cs-libs $(TARGET) "$(MAINTAINER)" $(PKGPREFIX) $(BUILD_TMP)
	mv $(PKGPREFIX)/cs-*.opk $(PACKAGE_DIR)
	rm -rf $(PKGPREFIX)

PHONY += glibc-pkg cs-driver-pkg cs-libs-pkg

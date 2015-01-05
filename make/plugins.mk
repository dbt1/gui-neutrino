# plugins...
# experimental, don't use yet until you know what you are doing
PLUGIN_DIR   ?= $(SOURCE_DIR)/neutrino-hd-plugins
LUA_REPO     ?= cst-public-plugins-scripts-lua


$(PLUGIN_DIR)/configure.ac: | $(PLUGIN_DIR)
$(PLUGIN_DIR)/configure: $(PLUGIN_DIR)/configure.ac
	cd $(PLUGIN_DIR) && ./autogen.sh

$(BUILD_TMP)/neutrino-hd-plugins:
	mkdir $@

PLUGINS_TO_BUILD = tuxcom

plugins: $(PLUGIN_DIR)/configure $(BUILD_TMP)/neutrino-hd-plugins
	set -e; cd $(BUILD_TMP)/neutrino-hd-plugins; \
		export PKG_CONFIG=$(PKG_CONFIG); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		CC=$(TARGET)-gcc CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" LDFLAGS="$(N_LDFLAGS)" \
		$(PLUGIN_DIR)/configure --host=$(TARGET) --build=$(BUILD) --prefix= \
			--enable-maintainer-mode --with-boxtype=$(PLATFORM) --with-target=cdk; \
		$(MAKE) SUBDIRS="$(PLUGINS_TO_BUILD)"
	set -e; for i in $(PLUGINS_TO_BUILD); do \
		rm -rf $(PKGPREFIX); \
		make -j1 -C $(BUILD_TMP)/neutrino-hd-plugins install SUBDIRS="$$i" DESTDIR=$(PKGPREFIX); \
		cp -a $(PKGPREFIX)/* $(TARGETPREFIX)/; \
		$(OPKG_SH) $(CONTROL_DIR)/plugins/$$i; \
	done


$(PLUGIN_DIR)/$(LUA_REPO):
	mkdir -p $(shell dirname $@)
	cd $(shell dirname $@) && git clone git://coolstreamtech.de/cst-public-plugins-scripts-lua.git $(LUA_REPO)

PHONY += plugins

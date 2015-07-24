# basic clean rules. to be fixed up.
clean:
	make neutrino-clean

all-deps-clean:
	rm -fv $(DEPDIR)/*

pkgs-semi-clean: 
	-rm -rf $(PACKAGE_DIR)/.cache  $(PACKAGE_DIR)/.old  rm $(PACKAGE_DIR)/Packages

pkgs-clean: pkgs-semi-clean
	-rm -f $(PACKAGE_DIR)/*.opk

install-clean: pkgs-semi-clean
	-rm -rf $(BUILD_TMP)/install

# rebuild all except the toolchain
rebuild-clean: clean all-deps-clean
	-rm -rf $(TARGETPREFIX)
	-rm -rf $(HOSTPREFIX)
	-set -e;cd $(BUILD_TMP); \
		find . -mindepth 1 -maxdepth 1 ! -name 'crosstool*' -print0 | \
		xargs --no-run-if-empty -0 rm -rf

all-clean: rebuild-clean
	-rm -rf $(CROSS_BASE)


PHONY += clean all-deps-clean rebuild-clean all-clean

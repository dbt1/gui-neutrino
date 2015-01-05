# basic clean rules. to be fixed up.
clean:
	make neutrino-clean

deps-clean:
	rm -fv $(DEPDIR)/*

# rebuild all except the toolchain
rebuild-clean: clean deps-clean
	-rm -rf $(TARGETPREFIX)
	-rm -rf $(HOSTPREFIX)
	-set -e;cd $(BUILD_TMP); \
		find . -mindepth 1 -maxdepth 1 ! -name 'crosstool*' -print0 | \
		xargs --no-run-if-empty -0 rm -rf

all-clean: rebuild-clean
	-rm -rf $(CROSS_BASE)


PHONY += clean rebuild-clean all-clean

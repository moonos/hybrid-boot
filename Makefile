# Makefile

SHELL := sh -e

SCRIPTS = backend/*/* frontend/* components/* config/frontend/* config/components/*

all: build

test:
	@echo -n "Checking for syntax errors"

	@for SCRIPT in $(SCRIPTS); \
	do \
		sh -n $${SCRIPT}; \
		echo -n "."; \
	done

	@echo " done."

	@# We can't just fail yet on bashisms (FIXME)
	@if [ -x "$$(which checkbashisms 2>/dev/null)" ]; \
	then \
		echo -n "Checking for bashisms"; \
		for SCRIPT in $(SCRIPTS); \
		do \
			checkbashisms -f -x $${SCRIPT} || true; \
			echo -n "."; \
		done; \
		echo " done."; \
	else \
		echo "W: checkbashisms - command not found"; \
		echo "I: checkbashisms can be obtained from: "; \
		echo "I:   http://git.debian.org/?p=devscripts/devscripts.git"; \
		echo "I: On Debian based systems, checkbashisms can be installed with:"; \
		echo "I:   apt-get install devscripts"; \
	fi

build:
	@echo "Nothing to build."

install:
	# Install config components
	mkdir -p $(DESTDIR)/lib/systemd/system
	cp config/backend/systemd/hybrid-boot-config.systemd $(DESTDIR)/lib/systemd/system/hybrid-boot-config.service
	mkdir -p $(DESTDIR)/lib/hybrid/config
	cp config/components/* $(DESTDIR)/lib/hybrid/config
	
	mkdir -p $(DESTDIR)/var/lib/hybrid/config
	
	# Installing shared data
	mkdir -p $(DESTDIR)/usr/share/hybrid/config
	cp -r config/share/* $(DESTDIR)/usr/share/hybrid/config
	
	# Install persistence config
	mkdir -p $(DESTDIR)/lib/hybrid/etc
	cp persistence.conf $(DESTDIR)/lib/hybrid/etc
	
	# Installing components
	mkdir -p $(DESTDIR)/lib/hybrid/boot
	cp components/* $(DESTDIR)/lib/hybrid/boot
	
	# Installing executables
	mkdir -p $(DESTDIR)/usr/share/initramfs-tools/hooks
	cp backend/initramfs-tools/hybrid.hook $(DESTDIR)/usr/share/initramfs-tools/hooks/hybrid
	mkdir -p $(DESTDIR)/usr/share/initramfs-tools/scripts
	cp backend/initramfs-tools/hybrid.script $(DESTDIR)/usr/share/initramfs-tools/scripts/hybrid
	
	mkdir -p $(DESTDIR)/bin
	cp frontend/* $(DESTDIR)/bin
	cp config/frontend/* $(DESTDIR)/bin
	
	# Installing docs
	mkdir -p $(DESTDIR)/usr/share/doc/hybrid-boot
	cp -r COPYING $(DESTDIR)/usr/share/doc/hybrid-boot

uninstall:
	rm -f $(DESTDIR)/etc/init/hybrid-boot-config.conf
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/etc/init > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/etc > /dev/null 2>&1 || true
	
	rm -f $(DESTDIR)/lib/systemd/system/hybrid-boot-config.service
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib/systemd/system > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib/systemd > /dev/null 2>&1 || true
	
	# Uninstalling config components
	rm -rf $(DESTDIR)/lib/hybrid/config
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib/hybrid > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib > /dev/null 2>&1 || true

	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/hybrid/config > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/hybrid > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var > /dev/null 2>&1 || true

	# Uninstalling shared data
	rm -rf $(DESTDIR)/usr/share/hybrid/config
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/hybrid
	
	# Uninstalling executables
	rm -f $(DESTDIR)/bin/hybrid-boot
	rm -f $(DESTDIR)/bin/hybrid-swapfile
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/bin > /dev/null 2>&1 || true
	rm -f $(DESTDIR)/etc/persistence.conf
	
	rm -f $(DESTDIR)/usr/share/initramfs-tools/hooks/hybrid
	rm -f $(DESTDIR)/usr/share/initramfs-tools/scripts/hybrid
	
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/initramfs-tools/hooks > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/initramfs-tools/scripts > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/initramfs-tools > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr > /dev/null 2>&1 || true
	
	# Uninstalling docs
	rm -rf $(DESTDIR)/usr/share/doc/hybrid-boot
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/doc > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share > /dev/null 2>&1 || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr > /dev/null 2>&1 || true

clean:
	@echo "Nothing to clean."

distclean: clean
	@echo "Nothing to distclean."

reinstall: uninstall install

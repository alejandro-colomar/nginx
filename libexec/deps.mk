#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

.PHONY: all
all:
	$(MAKE) -C $(LIBEXECDIR) -f deps.mk deps-build;
	$(MAKE) -C $(LIBEXECDIR) -f deps.mk deps-run;

.PHONY: deps-build
deps-build: basic-deps
	cd $$(mktemp -d) && \
	chmod 755 . && \
	equivs-build $(ROOTDIR)/etc/debian/build-deps 2>/dev/null \
	| grep '^dpkg-deb' \
	| grep -o '\./.*\.deb' \
	| xargs sudo apt-get install --no-install-recommends -y -q=2;

.PHONY: deps-run
deps-run: submodules basic-deps
	cd $$(mktemp -d) && \
	chmod 755 . && \
	equivs-build $(ROOTDIR)/etc/debian/run-deps 2>/dev/null \
	| grep '^dpkg-deb' \
	| grep -o '\./.*\.deb' \
	| xargs sudo apt-get install --no-install-recommends -y -q=2;

.PHONY: submodules
submodules:
	sudo -Eu '$(SUDO_USER)' git submodule init;
	sudo -Eu '$(SUDO_USER)' git submodule update;
	$(MAKE) -C $(ROOTDIR)/src/alx/containers/;

.PHONY: basic-deps
basic-deps:
	apt-get install --no-install-recommends -y equivs;

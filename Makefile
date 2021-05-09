#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

# Do not print "Entering directory ..."
MAKEFLAGS += --no-print-directory

ROOTDIR		= $(CURDIR)
LIBEXECDIR	= $(ROOTDIR)/libexec
export ROOTDIR

.PHONY: all
all: image

########################################################################
# ./libexec/deps.mk

.PHONY: deps-build
deps-build:
	$(MAKE) -C $(CURDIR)/libexec -f deps.mk $@;

.PHONY: deps-run
deps-run:
	$(MAKE) -C $(CURDIR)/libexec -f deps.mk $@;

########################################################################
# ./libexec/img.mk

.PHONY: Dockerfile
Dockerfile:
	$(MAKE) -C $(CURDIR)/libexec -f img.mk $@;

.PHONY: image_
image_:
	$(MAKE) -C $(CURDIR)/libexec -f img.mk $@;

.PHONY: image
image:
	$(MAKE) -C $(CURDIR)/libexec -f img.mk $@;

.PHONY: image-manifest_
image-manifest_:
	$(MAKE) -C $(CURDIR)/libexec -f img.mk $@;

.PHONY: image-manifest
image-manifest:
	$(MAKE) -C $(CURDIR)/libexec -f img.mk $@;

########################################################################
# ./libexec/test.mk

.PHONY: test
test:
	$(MAKE) -C $(CURDIR)/libexec -f test.mk $@;

########################################################################
# ./libexec/stack.mk

.PHONY: stack-deploy
stack-deploy:
	$(MAKE) -C $(CURDIR)/libexec -f stack.mk $@;

.PHONY: stack-rm
stack-rm:
	$(MAKE) -C $(CURDIR)/libexec -f stack.mk $@;

########################################################################
# ./libexec/version.mk

.PHONY: version
version:
	$(MAKE) -C $(CURDIR)/libexec -f version.mk $@;

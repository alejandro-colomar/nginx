#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

version	= $(shell git describe --tags | sed 's/^v//')
branch	= $(shell git rev-parse --abrev-ref HEAD)
remote	= $(shell git config --get branch.$(branch).remote)

config	= $(ROOTDIR)/.config

image	= $(ROOTDIR)/etc/docker/image
reg	= $(shell <$(image) grep '^reg' | cut -f2)
user	= $(shell <$(image) grep '^user' | cut -f2)
repo	= $(shell <$(image) grep '^repo' | cut -f2)
repository = $(reg)/$(user)/$(repo)
lbl	= $(version)
img	= $(repository):$(lbl)

.PHONY: all
all: version

.PHONY: version
version:
	sed -i 's/^version.*/version	$(version)/' $(config);
	git add $(config);
	git commit -m 'v$(version)';
	git tag -a 'v$(version)' -m 'nginx $(img)';
	git push $(remote) HEAD 'v$(version)';
	git checkout -b 'version-$(version)';
	git push -u $(remote) 'version-$(version)';

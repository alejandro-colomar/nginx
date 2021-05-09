#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

version	= $(shell git describe --tags | sed 's/^v//')
branch	= $(shell git rev-parse --abbrev-ref HEAD)
remote	= $(shell git config --get branch.$(branch).remote)

arch	= $(shell uname -m)

config		= $(ROOTDIR)/.config
archs		= $(shell <$(config) grep '^archs' | cut -f2 | tr ',' ' ')
version_	= $(shell <$(config) grep '^version' | cut -f2)

nginx		= $(ROOTDIR)/etc/docker/image.d/nginx
nginx_reg	= $(shell <$(nginx) grep '^reg' | cut -f2)
nginx_user	= $(shell <$(nginx) grep '^user' | cut -f2)
nginx_repo	= $(shell <$(nginx) grep '^repo' | cut -f2)
nginx_lbl	= $(shell <$(nginx) grep '^lbl' | cut -f2)
nginx_digest	= $(shell <$(nginx) grep '^digest' | grep '$(arch)' | cut -f3)

image	= $(ROOTDIR)/etc/docker/image
reg	= $(shell <$(image) grep '^reg' | cut -f2)
user	= $(shell <$(image) grep '^user' | cut -f2)
repo	= $(shell <$(image) grep '^repo' | cut -f2)
repository = $(reg)/$(user)/$(repo)
lbl	= $(version)
lbl_a	= $(lbl)_$(arch)
img	= $(repository):$(lbl)
img_a	= $(repository):$(lbl_a)
imgs	= $(addprefix $(img)_,$(archs))

image_	= $(ROOTDIR)/run/docker/image
lbl_	= $(shell <$(image_) grep '^lbl' | cut -f2)
img_	= $(repository):$(lbl_)

.PHONY: all
all: image

.PHONY: Dockerfile
Dockerfile: $(nginx)
	@echo '	Update Dockerfile ARGs';
	sed -i \
		-e '/^ARG	NGINX_REG=/s/=.*/="$(nginx_reg)"/' \
		-e '/^ARG	NGINX_USER=/s/=.*/="$(nginx_user)"/' \
		-e '/^ARG	NGINX_REPO=/s/=.*/="$(nginx_repo)"/' \
		-e '/^ARG	NGINX_LBL=/s/=.*/="$(nginx_lbl)"/' \
		-e '/^ARG	NGINX_DIGEST=/s/=.*/="$(nginx_digest)"/' \
		$(ROOTDIR)/$@;

.PHONY: image_
image_:
	git fetch;
	git checkout -f 'version-$(version_)';
	git clean -fx;
	git pull --ff-only;
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image version=$(version_);
	$(MAKE) -C $(LIBEXECDIR) -f img.mk update-run;
	git restore $(ROOTDIR);
	git pull --rebase;
	git push;


.PHONY: image
image:
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image-build;
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image-push;

.PHONY: image-build
image-build: Dockerfile $(image)
	@echo '	DOCKER image build	$(img_a)';
	docker image build -t '$(img_a)' $(ROOTDIR);
	sed -i  's/^lbl.*/lbl	$(lbl_a)/' $(image_);
	sed -Ei 's/^(digest	$(arch)).*/\1/' $(image_);

.PHONY: image-push
image-push:
	@echo '	DOCKER image push	$(img_a)';
	docker image push '$(img_a)' \
	|grep 'digest:' \
	|sed -E 's/.*digest: ([^ ]+) .*/\1/' \
	|while read d; do \
		sed -Ei "s/^(digest	$(arch)).*/\1	$${d}/" $(image_); \
	done;

.PHONY: image-manifest_
image-manifest_:
	git fetch;
	git checkout -f 'version-$(version_)';
	git clean -fx;
	git pull --ff-only;
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image-manifest version=$(version_);
	$(MAKE) -C $(LIBEXECDIR) -f img.mk update-run;
	git restore $(ROOTDIR);
	git pull --rebase;
	git tag -a 'v$(version_)-1' -m 'Build $(img)';
	git push --follow-tags;

.PHONY: image-manifest
image-manifest:
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image-manifest-create;
	$(MAKE) -C $(LIBEXECDIR) -f img.mk image-manifest-push;

.PHONY: image-manifest-create
image-manifest-create:
	@echo '	DOCKER manifest create	$(img)';
	docker manifest create '$(img)' $(imgs);
	sed -i 's/^lbl.*/lbl	$(lbl)/' $(image_);

.PHONY: image-manifest-push
image-manifest-push:
	@echo '	DOCKER manifest push	$(img)';
	docker manifest push '$(img)';

.PHONY: update-run
update-run:
	git add $(image_);
	git commit -m 'Build $(img_)';

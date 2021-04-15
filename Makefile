#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = bash

version	= $(shell git describe --tags | sed 's/^v//')
branch	= $(shell git rev-parse --abbrev-ref HEAD)
remote	= $(shell git config --get branch.$(branch).remote)

# Do not print "Entering directory ..."
MAKEFLAGS += --no-print-directory

arch	= $(shell uname -m)
config	= $(CURDIR)/.config

nginx		= $(CURDIR)/etc/docker/image.d/nginx
nginx_reg	= $(shell <$(nginx) grep '^reg' | cut -f2)
nginx_user	= $(shell <$(nginx) grep '^user' | cut -f2)
nginx_repo	= $(shell <$(nginx) grep '^repo' | cut -f2)
nginx_lbl	= $(shell <$(nginx) grep '^lbl' | cut -f2)
nginx_digest	= $(shell <$(nginx) grep '^digest' | grep '$(arch)' | cut -f3)

image	= $(CURDIR)/etc/docker/image
reg	= $(shell <$(image) grep '^reg' | cut -f2)
user	= $(shell <$(image) grep '^user' | cut -f2)
repo	= $(shell <$(image) grep '^repo' | cut -f2)
repository = $(reg)/$(user)/$(repo)
lbl	= $(version)
lbl_a	= $(lbl)_$(arch)
img	= $(repository):$(lbl)
img_a	= $(repository):$(lbl_a)
archs	= $(shell <$(config) grep '^archs' | cut -f2 | tr ',' ' ')
imgs	= $(addprefix $(img)_,$(archs))

image_	= $(CURDIR)/run/docker/image
lbl_	= $(shell <$(image_) grep '^lbl' |cut -f2)
img_	= $(repository):$(lbl_)
digest	= $(shell <$(image_) grep '^digest' | grep '$(arch)' | cut -f3)
digest_	= $(addprefix @,$(digest))

version_	= $(shell <$(config) grep '^version' | cut -f2)
orchestrator	= $(shell <$(config) grep '^orchest' | cut -f2)
project		= $(shell <$(config) grep '^project' | cut -f2)
stability	= $(shell <$(config) grep '^stable' | cut -f2)
stack		= $(project)-$(stability)
node_role	= $(shell <$(config) grep '^node' | cut -f2)
host_port	= $(shell <$(config) grep '^port' | grep '$(stability)' | cut -f3)

# Testing
retries	= 50

.PHONY: all
.SILENT: all
all: image

.PHONY: Dockerfile
.SILENT: Dockerfile
Dockerfile: $(nginx)
	echo '	Update Dockerfile ARGs';
	sed -i \
		-e '/^ARG	NGINX_REG=/s/=.*/="$(nginx_reg)"/' \
		-e '/^ARG	NGINX_USER=/s/=.*/="$(nginx_user)"/' \
		-e '/^ARG	NGINX_REPO=/s/=.*/="$(nginx_repo)"/' \
		-e '/^ARG	NGINX_LBL=/s/=.*/="$(nginx_lbl)"/' \
		-e '/^ARG	NGINX_DIGEST=/s/=.*/="$(nginx_digest)"/' \
		$(CURDIR)/$@;

.PHONY: image
.SILENT: image
image:
	$(MAKE) image-build;
	$(MAKE) image-push;

.PHONY: image-build
.SILENT: image-build
image-build: Dockerfile $(image)
	echo '	DOCKER image build	$(img_a)';
	docker image build -t '$(img_a)' $(CURDIR) >/dev/null;
	sed -i  's/^lbl.*/lbl	$(lbl_a)/' $(image_);
	sed -Ei 's/^(digest	$(arch)).*/\1/' $(image_);

.PHONY: image-push
.SILENT: image-push
image-push:
	echo '	DOCKER image push	$(img_a)';
	docker image push '$(img_a)' \
	|grep 'digest:' \
	|sed -E 's/.*digest: ([^ ]+) .*/\1/' \
	|while read d; do \
		sed -Ei "s/^(digest	$(arch)).*/\1	$${d}/" $(image_); \
	done;

.PHONY: image-manifest
.SILENT: image-manifest
image-manifest:
	$(MAKE) image-manifest-create;
	$(MAKE) image-manifest-push;

.PHONY: image-manifest-create
.SILENT: image-manifest-create
image-manifest-create:
	echo '	DOCKER manifest create	$(img)';
	docker manifest create '$(img)' $(imgs) >/dev/null;
	sed -i 's/^lbl.*/lbl	$(lbl)/' $(image_);

.PHONY: image-manifest-push
.SILENT: image-manifest-push
image-manifest-push:
	echo '	DOCKER manifest push	$(img)';
	docker manifest push '$(img)' >/dev/null;

.PHONY: stack-deploy
.SILENT: stack-deploy
stack-deploy:
	echo '	STACK deploy	$(stack)';
	export node_role='$(node_role)'; \
	export image='$(repository)'; \
	export label='$(lbl_)'; \
	export digest='$(digest_)'; \
	export host_port='$(host_port)'; \
	alx_stack_deploy -o '$(orchestrator)' '$(stack)';

.PHONY: stack-rm
.SILENT: stack-rm
stack-rm:
	echo '	STACK rm	$(stack)';
	alx_stack_delete -o '$(orchestrator)' '$(stack)';

.PHONY: test
.SILENT: test
test:
	$(MAKE) test-docker-service;
	$(MAKE) test-curl;

.PHONY: test-docker-service
.SILENT: test-docker-service
test-docker-service:
	echo '	TEST	docker service';
	for ((i = 0; i < $(retries); i++)); do \
		sleep 1; \
		docker service ls \
		|grep -qE '([0-9])/\1' \
		&& break; \
	done;

.PHONY: test-curl
.SILENT: test-curl
test-curl:
	echo '	TEST	curl';
	for ((i = 0; i < $(retries); i++)); do \
		sleep 1; \
		curl -4s -o /dev/null -w '%{http_code}' localhost:$(host_port) \
		|grep -q 200 \
		&& break; \
	done;

.PHONY: prereq
.SILENT: prereq
prereq:
	sudo -Eu '$(SUDO_USER)' $(MAKE) prereq-config;
	$(MAKE) prereq-install;

.PHONY: prereq-config
.SILENT: prereq-config
prereq-config:
	echo '	GIT submodule init';
	git submodule init >/dev/null;
	echo '	GIT submodule update';
	git submodule update >/dev/null;

.PHONY: prereq-install
.SILENT: prereq-install
prereq-install:
	$(MAKE) -C $(CURDIR)/src/alx/containers/;

.PHONY: ci
.SILENT: ci
ci:
	echo '	DOCKER swarm init';
	sudo -Eu '$(SUDO_USER)' docker swarm init --advertise-addr lo >/dev/null 2>&1 ||:;
	echo;
	echo '	MAKE	prereq';
	$(MAKE) prereq;
	echo;
	echo '	MAKE	image-build';
	sudo -Eu '$(SUDO_USER)' $(MAKE) image-build lbl=ci;
	echo;
	echo '	MAKE	stack-deploy';
	$(MAKE) stack-deploy node_role=manager;
	echo;
	echo '	MAKE	test';
	sudo -Eu '$(SUDO_USER)' $(MAKE) test;
	echo;
	echo '	MAKE	stack-rm';
	sudo -Eu '$(SUDO_USER)' $(MAKE) stack-rm;
	echo;

.PHONY: version
.SILENT: version
version:
	echo '	CONFIG';
	sed -i 's/^version.*/version	$(version)/' $(config);
	echo '	GIT	commit & push';
	git add $(config) >/dev/null;
	git commit -m 'v$(version)' >/dev/null;
	git push >/dev/null;
	echo '	GIT	branch & push';
	git checkout -b 'version-$(version)' >/dev/null;
	git push -u $(remote) 'version-$(version)' >/dev/null;
	echo '	GIT	tag & push';
	git tag -a 'v$(version)' -m 'Build $(img)' >/dev/null;
	git push --follow-tags >/dev/null;

.PHONY: cd
.SILENT: cd
cd: cd_checkout
	echo '	MAKE	image-manifest';
	$(MAKE) image-manifest version=$(version_);
	$(MAKE) cd_update_run;
	echo '	GIT	tag & push';
	git restore . >/dev/null;
	git pull --rebase >/dev/null;
	git tag -a 'v$(version_)-1' -m 'Build $(img)' >/dev/null;
	git push --follow-tags >/dev/null;

.PHONY: cd_arch
.SILENT: cd_arch
cd_arch: cd_checkout
	echo '	MAKE	image';
	$(MAKE) image version=$(version_);
	$(MAKE) cd_update_run;
	echo '	GIT	push';
	git restore . >/dev/null;
	git pull --rebase >/dev/null;
	git push >/dev/null;

.PHONY: cd_checkout
.SILENT: cd_checkout
cd_checkout:
	echo '	GIT	checkout version-$(version_)';
	git fetch >/dev/null;
	git checkout -f 'version-$(version_)' >/dev/null;
	git pull --ff-only >/dev/null;

.PHONY: cd_update_run
.SILENT: cd_update_run
cd_update_run:
	echo '	GIT	commit';
	git add $(image_) >/dev/null;
	git commit -m 'Build $(img_)' >/dev/null;

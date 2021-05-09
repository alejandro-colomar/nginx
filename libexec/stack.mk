#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

arch	= $(shell uname -m)

image	= $(ROOTDIR)/etc/docker/image
reg	= $(shell <$(image) grep '^reg' | cut -f2)
user	= $(shell <$(image) grep '^user' | cut -f2)
repo	= $(shell <$(image) grep '^repo' | cut -f2)
repository = $(reg)/$(user)/$(repo)

image_	= $(ROOTDIR)/run/docker/image
lbl_	= $(shell <$(image_) grep '^lbl' |cut -f2)
img_	= $(repository):$(lbl_)
digest	= $(shell <$(image_) grep '^digest' | grep '$(arch)' | cut -f3)
digest_	= $(addprefix @,$(digest))

config		= $(ROOTDIR)/.config
version_	= $(shell <$(config) grep '^version' | cut -f2)
orchestrator	= $(shell <$(config) grep '^orchest' | cut -f2)
project		= $(shell <$(config) grep '^project' | cut -f2)
stability	= $(shell <$(config) grep '^stable' | cut -f2)
stack		= $(project)-$(stability)
node_role	= $(shell <$(config) grep '^node' | cut -f2)
host_port	= $(shell <$(config) grep '^port' | grep '$(stability)' | cut -f3)

.PHONY: all
all: stack-deploy

.PHONY: stack-deploy
stack-deploy:
	@echo '	STACK deploy	$(stack)';
	export node_role='$(node_role)'; \
	export image='$(repository)'; \
	export label='$(lbl_)'; \
	export digest='$(digest_)'; \
	export host_port='$(host_port)'; \
	cd $(ROOTDIR); \
	alx_stack_deploy -o '$(orchestrator)' '$(stack)';

.PHONY: stack-rm
stack-rm:
	@echo '	STACK rm	$(stack)';
	alx_stack_delete -o '$(orchestrator)' '$(stack)';

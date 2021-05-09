#!/usr/bin/make -f
########################################################################
# Copyright (C) 2021		Alejandro Colomar <alx.manpages@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################
SHELL = /bin/bash -Eeuo pipefail

LIBEXECDIR = $(ROOTDIR)/libexec

config		= $(ROOTDIR)/.config
stability	= $(shell <$(config) grep '^stable' | cut -f2)
host_port	= $(shell <$(config) grep '^port' | grep '$(stability)' | cut -f3)

retries	= 50

.PHONY: all
all: test

.PHONY: test
test:
	@echo '	DOCKER swarm init';
	sudo -Eu '$(SUDO_USER)' docker swarm init --advertise-addr lo ||:;
	@echo;
	@echo '	MAKE	deps';
	$(MAKE) -C $(LIBEXECDIR) -f deps.mk;
	@echo;
	@echo '	MAKE	image-build';
	sudo -Eu '$(SUDO_USER)' $(MAKE) -C $(LIBEXECDIR) -f img.mk image-build lbl=ci;
	@echo;
	@echo '	MAKE	stack-deploy';
	$(MAKE) -C $(LIBEXECDIR) -f stack.mk stack-deploy node_role=manager;
	@echo;
	@echo '	MAKE	run-tests';
	echo 'asd$(CURDIR)asd'
	sudo -Eu '$(SUDO_USER)' $(MAKE) -C $(LIBEXECDIR) -f test.mk run-tests;
	@echo;
	@echo '	MAKE	stack-rm';
	sudo -Eu '$(SUDO_USER)' $(MAKE) -C $(LIBEXECDIR) -f stack.mk stack-rm;
	@echo;

.PHONY: run-tests
run-tests:
	$(MAKE) -C $(LIBEXECDIR) -f test.mk run-test-docker-service;
	$(MAKE) -C $(LIBEXECDIR) -f test.mk run-test-curl;

.PHONY: run-test-docker-service
run-test-docker-service:
	@echo '	TEST	docker service';
	for ((i = 0; i < $(retries); i++)); do \
		sleep 1; \
		docker service ls \
		|grep -qE '([0-9])/\1' \
		&& break; \
	done;

.PHONY: run-test-curl
run-test-curl:
	@echo '	TEST	curl';
	for ((i = 0; i < $(retries); i++)); do \
		sleep 1; \
		curl -4s -o /dev/null -w '%{http_code}' localhost:$(host_port) \
		|grep -q 200 \
		&& break; \
	done;

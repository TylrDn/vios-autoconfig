SHELL := /usr/bin/env bash
SH_SOURCES := $(shell git ls-files '*.sh')
VERSION ?= $(shell cat VERSION 2>/dev/null || echo dev)

all: lint test

fmt:
	shfmt -d $(SH_SOURCES)

fmt-write:
	shfmt -w $(SH_SOURCES)

lint:
	shellcheck $(SH_SOURCES)
	gitleaks detect --no-git

test:
	PATH="$(PWD)/tests/mocks/bin:$$PATH" APPLY=0 bats -r tests

package: clean
	mkdir -p dist
	tar --sort=name --owner=0 --group=0 --numeric-owner -czf dist/vios-autoconfig-$(VERSION).tar.gz scripts lib maps README.md LICENSE .env.example
	sha256sum dist/vios-autoconfig-$(VERSION).tar.gz > dist/vios-autoconfig-$(VERSION).tar.gz.sha256

clean:
	rm -rf dist

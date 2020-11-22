CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)
AMEBA_BIN ?= bin/ameba

build: bin/clear-cli

bin/clear-cli:
	$(SHARDS_BIN) build

spec: build
	$(CRYSTAL_BIN) spec -Dquiet --warnings=all

ameba:
	$(AMEBA_BIN) src spec

test: build spec ameba
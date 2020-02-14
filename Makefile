CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)
AMEBA_BIN ?= bin/ameba

build: bin/clear-cli

bin/clear-cli:
	$(SHARDS_BIN) build

test: build
	$(CRYSTAL_BIN) spec -Dquiet --warnings=all
	$(AMEBA_BIN) src spec


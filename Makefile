CRYSTAL_BIN ?= $(shell which crystal)
AMEBA_BIN ?= bin/ameba
test:
	$(CRYSTAL_BIN) spec -Dquiet --warnings=all

ameba:
	$(AMEBA_BIN) src spec

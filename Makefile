CRYSTAL_BIN ?= $(shell which crystal)

test:
	$(CRYSTAL_BIN) spec -Dquiet --warnings=all


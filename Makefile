# bobodread-stores — orchestration for the Umbrel + Start9 community stores.
# See README.md for the "pact pattern".

# Each StartOS package builder lives in packages/<app>-startos and has its own Makefile.
PACKAGES := $(wildcard packages/*-startos)
REGISTRY ?= start9.bobodread.com

.PHONY: help init build publish clean

help:
	@echo "bobodread-stores targets:"
	@echo "  make init      - clone/update all package submodules"
	@echo "  make build     - build the .s9pk for every package in packages/"
	@echo "  make publish   - publish built .s9pk to the Start9 registry ($(REGISTRY))"
	@echo "  make clean     - remove built .s9pk artifacts"
	@echo ""
	@echo "Discovered packages: $(PACKAGES)"

init:
	git submodule update --init --recursive

build:
	@for pkg in $(PACKAGES); do \
		echo "==> building $$pkg"; \
		$(MAKE) -C $$pkg || exit 1; \
	done

publish:
	@./registry/publish.sh "$(REGISTRY)" $(PACKAGES)

clean:
	@for pkg in $(PACKAGES); do \
		echo "==> cleaning $$pkg"; \
		rm -f $$pkg/*.s9pk; \
	done

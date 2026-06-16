# bobodread-stores — orchestration for the Umbrel + Start9 community stores.
# See README.md for the "pact pattern".

# Each StartOS package builder lives in packages/<app>-startos and has its own Makefile.
PACKAGES := $(wildcard packages/*-startos)
REGISTRY ?= https://start9.bobodread.com

.PHONY: help init build publish publish-dry clean

help:
	@echo "atoll — Island Bitcoin community stores:"
	@echo "  make init         - clone/update all package submodules"
	@echo "  make build        - build the .s9pk for every package in packages/"
	@echo "  make publish      - build + publish every package to the registry ($(REGISTRY))"
	@echo "  make publish-dry  - preview the publish steps without executing"
	@echo "  make clean        - remove built .s9pk artifacts"
	@echo ""
	@echo "  Publishing must run on the registered-signer machine (on the registry's LAN)."
	@echo "  See registry/publish.sh for env vars (REGISTRY, REGISTRY_HOSTNAME, ...)."
	@echo ""
	@echo "Discovered packages: $(PACKAGES)"

init:
	git submodule update --init --recursive

build:
	@for pkg in $(PACKAGES); do \
		echo "==> building $$pkg"; \
		$(MAKE) -C $$pkg || exit 1; \
	done

# publish.sh builds each package itself, so this drives the whole release flow.
publish:
	@REGISTRY="$(REGISTRY)" ./registry/publish.sh $(PACKAGES)

publish-dry:
	@DRY_RUN=1 REGISTRY="$(REGISTRY)" ./registry/publish.sh $(PACKAGES)

clean:
	@for pkg in $(PACKAGES); do \
		echo "==> cleaning $$pkg"; \
		rm -f $$pkg/*.s9pk; \
	done

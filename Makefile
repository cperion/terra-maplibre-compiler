
TERRA ?= terra
NODE ?= node
NPM ?= npm

BUILD_DIR = build
DIST_DIR = dist

.PHONY: all build test clean install examples validate-abi

all: build

install:
	cd host && $(NPM) install

# Build targets
build:
	@echo "Building Terra compiler components..."
	# In a real Terra project this might involve saving a binary or just linting
	# For now we ensure directories exist
	mkdir -p $(BUILD_DIR) $(DIST_DIR)

examples:
	$(MAKE) -C examples/minimal build

# Testing targets
test: test-compiler test-host

test-compiler:
	./scripts/test-compiler.sh

test-host:
	./scripts/test-host.sh

validate-abi:
	./scripts/validate-abi.sh

# Cleanup
clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	$(MAKE) -C examples/minimal clean

demo:
	./scripts/build-demo.sh

test-integration:
	$(NODE) host/tests/integration.test.js

serve:
	npx http-server -c-1 .

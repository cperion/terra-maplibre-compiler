.PHONY: build
.PRECIOUS: intermediate
*.wasm
*.manifest.json

node_modules/
webgl2/
wasm/

# Output directories
build/
dist/
node_modules/
examples/

# Compiler binary output (compiler/bin/compiler --build
compiler/bin/terra -- *.t -- *.lua --source/*.lua
	$(LUadir) $(TERRAC) -o $(TERRAC) -c $(TERRAC_COMPILER)
	@echo "Compiler ready"
	
# Compiler intermediate files
build/*.o: *.so
build/manifest.json

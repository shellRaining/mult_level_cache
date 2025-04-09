ifndef VERBOSE
.SILENT:
endif

test: dependencies
	@echo "Running mult_level_cache tests..."
	timeout 300 nvim -e \
		--headless \
		--noplugin \
		-u test/spec.lua \
		-c "PlenaryBustedDirectory test/features {minimal_init = 'test/spec.lua'}"

time_benchmark: dependencies
	@echo "Running mult_level_cache benchmark"
	timeout 300 nvim -e \
		--headless \
		--noplugin \
		-u test/spec.lua \
		-c "luafile test/time_benchmark.lua" \
		-c "qa!"

memory-benchmark: dependencies
	@echo "Running mult_level_cache memory benchmark"
	timeout 300 nvim -e \
		--headless \
		--noplugin \
		-u test/spec.lua \
		-c "luafile test/memory_benchmark.lua" \
		-c "qa!"

stylua:
	stylua --check .

lua-language-server: dependencies
	rm -rf .ci/lua-language-server-log
	lua-language-server --configpath .luarc.$(version).json --logpath .ci/lua-language-server-log --check .
	[ -f .ci/lua-language-server-log/check.json ] && { cat .ci/lua-language-server-log/check.json 2>/dev/null; exit 1; } || true

dependencies:
	if [ ! -d .ci/vendor ]; then \
		git clone --depth 1 \
			https://github.com/nvim-lua/plenary.nvim \
			.ci/vendor/pack/vendor/start/plenary.nvim; \
		git clone --depth 1 \
			https://github.com/folke/neodev.nvim \
			.ci/vendor/pack/vendor/start/neodev.nvim; \
	fi

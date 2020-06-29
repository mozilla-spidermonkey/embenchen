.PHONY: all calls
.SUFFIXES: .wat .wasm
.wat.wasm:
	wat2wasm $< -o $@

all: calls

calls: calls.wasm calls-callee.wasm

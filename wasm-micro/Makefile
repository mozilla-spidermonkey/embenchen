JS=~/m-u/js/src/build-release/dist/bin/js --wasm-compiler=ion

.PHONY: all calls fib bench
.SUFFIXES: .wat .wasm
.wat.wasm:
	wat2wasm $< -o $@

all: calls fib
fib: fib.wasm
calls: calls.wasm calls-callee.wasm

bench: all
	$(JS) calls.js
	$(JS) fib.js

# This program is used to compute values for the policy table for wasm
# computation.  See comments in a patch on bug 1380033 for more
# information, basically it amounts to enabling some code in
# js/src/wasm/WasmCompile.cpp, recompiling, and then running this
# script.
# 
# Required first argument: path to JS engine to run.

JS=$1

# Sorted from smallest to largest by Code size (not necessarily file raw module size)
for i in primes zlib.c box2d lua_binarytrees.c bullet; do
cat <<EOF | echo $i $(JS_DISABLE_POISONING=1 $JS --no-threads --no-wasm-baseline 2>&1 | grep 'compile time' | awk '{ print $4 }')
var bin = os.file.readFile("wasm_$i.wasm", "binary");
var mod = new WebAssembly.Module(bin);
EOF
done

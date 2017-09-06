#!/usr/bin/env bash

# This program is used to compute values for the policy table for wasm
# computation.  See comments in a patch on bug 1380033 for more
# information, basically it amounts to enabling some code in
# js/src/wasm/WasmCompile.cpp, recompiling, and then running this
# script.
# 
# Required first argument: path to JS engine to run.

JS=$1
PROGS="primes zlib.c box2d lua_binarytrees.c bullet"
# Sorted from smallest to largest by Code size (not necessarily file raw module size)
k=0
for i in $PROGS; do
    cat <<EOF | (JS_DISABLE_POISONING=1 $JS --no-threads --no-wasm-baseline > tmp.txt 2>&1)
var bin = os.file.readFile("wasm_$i.wasm", "binary");
var mod = new WebAssembly.Module(bin);
EOF
    compiletime[$k]=$(grep 'compile time' tmp.txt | awk '{ print $4 }')
    ionsize[$k]=$(grep 'compiled size' tmp.txt | awk '{ print $4 }')
    k=$((k+1))
done

k=0
for i in $PROGS; do
    cat <<EOF | (JS_DISABLE_POISONING=1 $JS --no-threads --no-wasm-ion > tmp.txt 2>&1)
var bin = os.file.readFile("wasm_$i.wasm", "binary");
var mod = new WebAssembly.Module(bin);
EOF
    baselinesize[$k]=$(grep 'compiled size' tmp.txt | awk '{ print $4 }')
    k=$((k+1))
done

k=0
for i in $PROGS; do
    echo $i ${compiletime[$k]} ${ionsize[$k]} ${baselinesize[$k]}
    k=$((k+1))
done

#!/bin/bash
#
# Usage: wasm_bench.sh [ pattern ]
#
# Runs the shell without and with --wasm-always-baseline and prints:
#
#  Ion-result  Baseline-result  Ion/Baseline
#
# A lower result is always better.  Mflops and SciMark outputs are
# inverted to make this consistent.

JS_SHELL=~/moz/mozilla-inbound/js/src/build-release/dist/bin/js

function run_vanilla {
  /usr/bin/time -p $JS_SHELL $1 "$2" 2>&1 | egrep '^real' | awk '{ print $2 }'
}

function run_box2d {
  run_vanilla "$1" wasm_box2d.js
}
function run_bullet {
  run_vanilla "$1" wasm_bullet.js
}
function run_conditionals {
  run_vanilla "$1" wasm_conditionals.js
}
function run_copy {
  run_vanilla "$1" wasm_copy.js
}
function run_corrections {
  run_vanilla "$1" wasm_corrections.js
}
function run_fannkuch {
  run_vanilla "$1" wasm_fannkuch.js
}
function run_fasta {
  run_vanilla "$1" wasm_fasta.js
}
function run_ifs {
  run_vanilla "$1" wasm_ifs.js
}
function run_linpack {
  mflops=$($JS_SHELL $1 wasm_linpack_float.c.js 2>&1 | egrep 'Unrolled +Single +Precision.*Mflops' | awk '{ print $4 }')
  echo "scale=4;1000/$mflops" | bc -l
}
function run_lua_binarytrees {
  run_vanilla "$1" wasm_lua_binarytrees.c.js
}
function run_lua_scimark {
  mark=$($JS_SHELL $1 wasm_lua_scimark.c.js 2>&1 | egrep 'SciMark.*small' | awk '{ print $2 }')
  echo "scale=3;100/$mark" | bc -l
}
function run_memops {
  run_vanilla "$1" wasm_memops.js
}
function run_primes {
  run_vanilla "$1" wasm_primes.js
}
function run_skinning {
  run_vanilla "$1" wasm_skinning.js
}
function run_zlib {
  run_vanilla "$1" wasm_zlib.c.js
}

for test in box2d bullet conditionals copy corrections fannkuch fasta ifs linpack lua_binarytrees lua_scimark memops primes skinning zlib
do
  if [[ $1 == "" || $1 =~ $test ]]; then
    a=$("run_$test")
    b=$("run_$test" --wasm-always-baseline)
    echo "$test		$a	$b	$(echo "scale=3;$a/$b" | bc -l)"
  fi
done

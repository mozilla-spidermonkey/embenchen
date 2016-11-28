#!/bin/bash
#
# Usage: wasm_bench.sh [ pattern ]
#
# The pattern is a regex that can match a test case name.
#
# Runs the shell without and with --wasm-always-baseline and prints:
#
#  Ion-result  Baseline-result  Ion/Baseline
#
# A lower result is always better.  Linpack and SciMark outputs are
# inverted to make this consistent.
#
# Note, we measure the running time for the wasm code, not the
# end-to-end time including startup and compilation.  The difference
# in ratios is actually not large, but running time is probably the
# best measure.
#
# Times are in ms, linpack is 1000/mflops, scimark is 100/score.
#
# TODO: run each benchmark k times for some configurable k and report
#       median, mean, range
#
# TODO: in several cases below we'd like to check the entire output,
#       not just one line of it (and we might like for the output
#       not to contain any other lines)

if [[ $JS_SHELL == "" ]]; then
  JS_SHELL=~/moz/mozilla-inbound/js/src/build-release/dist/bin/js
fi

function fail {
  echo "Bad output for " $1
  exit 1
}

# Run without checking output
function run_nocheck {
  $JS_SHELL $1 "$2" 2>&1 | egrep '^WASM RUN TIME:' | awk '{ print $4 }'
}

# Check that the output contains a particular known pattern.
function run_match1 {
  $JS_SHELL $1 "$2" > output.tmp 2>&1
  if [ $(egrep -c "$3" output.tmp) == 0 ]; then 
    fail $2
  fi
  egrep '^WASM RUN TIME:' output.tmp | awk '{ print $4 }'
}

function run_box2d {
  run_match1 "$1" wasm_box2d.js "^frame averages:.*, range:.* to "
}
function run_bullet {
  run_match1 "$1" wasm_bullet.js "^ok.$"
}
function run_conditionals {
  run_match1 "$1" wasm_conditionals.js "^ok 144690090$"
}
function run_copy {
  run_match1 "$1" wasm_copy.js "^sum:2836$"
}
function run_corrections {
  run_match1 "$1" wasm_corrections.js "^final: 40006013:10225.$"
}
function run_fannkuch {
  # TODO: Check the entire output, this is just a spot check
  run_match1 "$1" wasm_fannkuch.js "^4312567891011$"
}
function run_fasta {
  # TODO: Check the entire output, this is just a spot check
  run_match1 "$1" wasm_fasta.js "^CCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAAGGCCGGGCGCGGT$"
}
function run_ifs {
  run_match1 "$1" wasm_ifs.js "^ok$"
}
function run_linpack {
  # We assume linpack checks itself, and that matching the output line is good enough
  mflops=$($JS_SHELL $1 wasm_linpack_float.c.js 2>&1 | egrep '^Unrolled +Single +Precision.*Mflops' | awk '{ print $4 }')
  echo "scale=4;1000/$mflops" | bc -l
}
function run_lua_binarytrees {
  # TODO: Check the entire output, this is just a spot check
  run_match1 "$1" wasm_lua_binarytrees.c.js "843	 trees of depth 10	 check: -842"
}
function run_lua_scimark {
  # We assume scimark checks itself, and that matching the output line is good enough
  mark=$($JS_SHELL $1 wasm_lua_scimark.c.js 2>&1 | egrep '^SciMark.*small' | awk '{ print $2 }')
  echo "scale=3;100/$mark" | bc -l
}
function run_memops {
  run_match1 "$1" wasm_memops.js "^final: 400.$"
}
function run_primes {
  run_match1 "$1" wasm_primes.js "^lastprime: 3043739.$"
}
function run_skinning {
  run_match1 "$1" wasm_skinning.js "^blah=0.000000$"
}
function run_zlib {
  run_match1 "$1" wasm_zlib.c.js "^sizes: 100000,25906$"
}

for test in box2d bullet conditionals copy corrections fannkuch fasta ifs linpack lua_binarytrees lua_scimark memops primes skinning zlib
do
  if [[ $1 == "" || $test =~ $1 ]]; then
    a=$("run_$test")
    if [[ $? != 0 ]]; then echo $a; exit 1; fi
    b=$("run_$test" --wasm-always-baseline)
    if [[ $? != 0 ]]; then echo $a; exit 1; fi
    echo "$test		$a	$b	$(echo "scale=3;$a/$b" | bc -l)"
  fi
done

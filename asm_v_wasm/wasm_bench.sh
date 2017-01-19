#!/bin/bash
#
# Run wasm benchmarks in two configurations and report the times.
#
# Usage: wasm_bench.sh [-n numruns] [-a argument] [-m mode] [ pattern ]
#
# `pattern` is a regex that will match against a test case name.
#
# Options:
#
#   -a   The problem size argument.  The default is 3.  With size=0
#        we effectively only compile the code and compilation time is
#        reported instead.  The max is 5.
#
#        If -a is given we do not check that the output matches the
#        expected.
#
#   -m mode
#        Compare the output of two different shells.  In this case,
#        the environment variables JS_SHELL1 and JS_SHELL2 must
#        be set.  `mode` must be "ion" or "baseline".
#
#   -n   The number of iterations to run.  We report the median time.
#        The value should be odd.
#
#
# In the default mode, runs the shell without and with --wasm-always-baseline
# and prints:
#
#  Ion-result  Baseline-result  Ion/Baseline
#
# In the other modes, runs the two shells with the same argument (depending
# on the mode) and prints:
#
#  shell1-result  shell2-result  shell1-result/shell2-result
#
# Times are in ms.  Linpack is 1000000/mflops, scimark is 10000/score,
# always as integer values (bash does not do floating point).
#
# A lower result is always better.  Linpack and SciMark outputs are
# inverted to make this consistent.
#
# Note, we measure the running time for the wasm code, not the
# end-to-end time including startup and compilation.  The difference
# in ratios is actually not large, but running time is probably the
# best measure.
#
# TODO: Also check the output for other arguments than the default.
#
# TODO: More interesting statistics when running more than once.
#
# TODO: In several cases below we'd like to check the entire output,
#       not just one line of it (and we might like for the output
#       not to contain any other lines)

LOOKFOR='^WASM RUN TIME:'
DEFAULT_SHELL=~/moz/mozilla-inbound/js/src/build-release/dist/bin/js

MODE="IonVsBaseline"
NUMRUNS=1
ARGUMENT=""
MODE=""

while true; do
  case $1 in
    -a) ARGUMENT=$2
        shift 2
        if [[ $ARGUMENT == "0" ]]; then
          LOOKFOR='^WASM COMPILE TIME:'
        fi
	;;
    -m) case $2 in
          baseline) MODE="BaselineVsBaseline" ;;
          ion)      MODE="IonVsIon" ;;
          *)        >&2 echo "Bad argument for -c" ; exit 1 ;;
        esac
        shift 2
        ;;
    -n) NUMRUNS=$2
        shift 2
        ;;
    *)  break
        ;;
  esac
done

case $MODE in
  IonVsBaseline)
    if [[ $JS_SHELL == "" ]]; then
      JS_SHELL=$DEFAULT_SHELL
    fi
    if [[ ! -x $JS_SHELL ]]; then
      >&2 echo "JS_SHELL $JS_SHELL is not executable"
      exit 1
    fi
    ;;
  *)
    if [[ $JS_SHELL1 == "" ]]; then
      >&2 echo "JS_SHELL1 not set"
      exit 1
    fi
    if [[ ! -x $JS_SHELL1 ]]; then
      >&2 echo "JS_SHELL1 $JS_SHELL1 is not executable"
      exit 1
    fi
    if [[ $JS_SHELL2 == "" ]]; then
      >&2 echo "JS_SHELL2 not set"
      exit 1
    fi
    if [[ ! -x $JS_SHELL2 ]]; then
      >&2 echo "JS_SHELL2 $JS_SHELL2 is not executable"
      exit 1
    fi
    ;;
esac

function run_match1 {
  rm -f output.tmp
  $JS_SHELL $1 "$2" $ARGUMENT > output.tmp 2>&1
  if [[ $ARGUMENT == "" ]]; then
    if [[ $(egrep -c "$3" output.tmp) == 0 ]]; then 
      >&2 echo "Bad output for " $2
      exit 1
    fi
  fi
  egrep "$LOOKFOR" output.tmp | awk '{ print $4 }'
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
  mflops=$($JS_SHELL $1 wasm_linpack_float.c.js $ARGUMENT 2>&1 | egrep '^Unrolled +Single +Precision.*Mflops' | awk '{ print $4 }')
  echo "scale=0;10000000/$mflops" | bc -l
}
function run_lua_binarytrees {
  # TODO: Check the entire output, this is just a spot check
  run_match1 "$1" wasm_lua_binarytrees.c.js "843	 trees of depth 10	 check: -842"
}
function run_lua_scimark {
  # We assume scimark checks itself, and that matching the output line is good enough
  mark=$($JS_SHELL $1 wasm_lua_scimark.c.js $ARGUMENT 2>&1 | egrep '^SciMark.*small' | awk '{ print $2 }')
  echo "scale=0;100000/$mark" | bc -l
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

declare -a as
declare -a bs

echo "# mode=$MODE, runs=$NUMRUNS, problem size=$ARGUMENT"

for test in box2d bullet conditionals copy corrections fannkuch fasta ifs linpack lua_binarytrees lua_scimark memops primes skinning zlib
do
  if [[ $1 == "" || $test =~ $1 ]]; then
    for (( i=0 ; $i <  $NUMRUNS ; ++i )); do

      ARG=""
      if [[ $MODE != "IonVsBaseline" ]]; then
        JS_SHELL=$JS_SHELL1
        if [[ $MODE == "BaselineVsBaseline" ]]; then
          ARG="--wasm-always-baseline"
        fi
      fi
      as[$i]=$("run_$test" $ARG)
      if [[ $? != 0 ]]; then echo $a; exit 1; fi

      ARG="--wasm-always-baseline"
      if [[ $MODE != "IonVsBaseline" ]]; then
        JS_SHELL=$JS_SHELL2
        if [[ $MODE == "IonVsIon" ]]; then
          ARG=""
        fi
      fi
      bs[$i]=$("run_$test" $ARG)
      if [[ $? != 0 ]]; then echo $a; exit 1; fi
    done

    for (( i=0 ; $i < $NUMRUNS-1 ; ++i )); do
      for (( j=$i+1 ; $j < $NUMRUNS ; ++j )); do
        if (( ${as[i]} > ${as[j]} )); then
          tmp=${as[i]}
          as[i]=${as[j]}
          as[j]=$tmp
        fi
        if (( ${bs[i]} > ${bs[j]} )); then
          tmp=${bs[i]}
          bs[i]=${bs[j]}
          bs[j]=$tmp
        fi
      done
    done

    mid=$(( $NUMRUNS/2 ))
    a=${as[$mid]}
    b=${bs[$mid]}

    echo "$test		$a	$b	$(echo "scale=3;$a/$b" | bc -l)"
    unset as[*]
    unset bs[*]
  fi
done

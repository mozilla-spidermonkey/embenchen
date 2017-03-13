#!/usr/bin/env python
#
# Run wasm benchmarks in various configurations and report the times.
# Run with -h for help.
#
# In the default mode, runs the shell without and with
# --wasm-always-baseline and prints three tab-separated columns:
#
#  Ion-result  Baseline-result  Ion/Baseline
#
# In the other modes, runs the two shells with the same argument (depending on
# the mode) and prints three tab-separated columns:
#
#  shell1-result  shell2-result  shell1-result/shell2-result
#
# When measuring compile times (argument = 0) results are compile
# times in ms.
#
# When measuring run times (argument > 0) results are mostly running
# times in ms, except that linpack is 1000000/mflops and scimark is
# 10000/score, always as integer values.
#
# A lower result is always better.  Linpack and SciMark outputs are
# inverted to make this consistent.
#
# We measure the running time only for the already-compiled wasm code,
# not the end-to-end time including startup and compilation.  The
# difference in ratios is actually not large, but running time is the
# best measure.
#
# TODO: catch any exception from the subprocess and print the log if
#       there was one.
#
# TODO: Also check the output for other arguments than the default.
#
# TODO: More interesting statistics when running more than once.
#
# TODO: In several cases below we'd like to check the entire output,
#       not just one line of it (and we might like for the output
#       not to contain any other lines)

import argparse, os, re, subprocess, sys

def main():
    (mode, numruns, argument, isBenchmark, isVerbose, patterns) = parse_args()
    (shell1, shell2) = get_shells(mode)
    print("# mode=" + mode + ", runs=" + str(numruns) + ", problem size=" + (str(argument) if argument != None else "default"))
    for test in tests:
        (name, _, fn, _) = test
        found = len(patterns) == 0
        for p in patterns:
            found = found or re.search(p, name)
        if not found:
            continue
        msg = name + "\t"
        if len(name) < 8:
            msg += "\t"
        if mode == "IonCheck" or mode == "BaselineCheck":
            fn(test, isVerbose, shell1, "ion" if mode == "IonCheck" else "baseline", argument)
            msg += "did not crash today"
        else:
            m1 = "baseline" if mode == "BaselineVsBaseline" else "ion"
            m2 = "ion" if mode == "IonVsIon" else "baseline"
            t1 = []
            t2 = []
            # Run back-to-back for each shell to reduce caching noise
            for i in range(numruns):
                (c, r) = fn(test, isVerbose, shell1, m1, argument)
                t1.append(c if argument == 0 else r)
            for i in range(numruns):
                (c, r) = fn(test, isVerbose, shell2, m2, argument)
                t2.append(c if argument == 0 else r)

            t1.sort()
            t2.sort()
            n1 = mid(t1)
            n2 = mid(t2)
            score = str(round(float(n1)/float(n2)*1000)/1000)

            msg += str(n1) + "\t" + str(n2) + "\t" + score
            if isVerbose:
                msg += "\t" + str(t1) + "\t" + str(t2)
        print(msg)

def mid(ss):
    return ss[len(ss)/2]

def run_std(test, isVerbose, shell, mode, argument):
    (name, program, _, correct) = test
    if program == None:
        program = "wasm_" + name + ".js"
    text = run_test(isVerbose, shell, program, mode, argument)
    return parse_output(text, argument, correct)

def run_linpack(test, isVerbose, shell, mode, argument):
    text = run_test(isVerbose, shell, "wasm_linpack_float.c.js", mode, argument)
    if argument == 0:
        return parse_ouput(text, 0, None)

    mflops = float(parse_line(text, r"Unrolled +Single +Precision.*Mflops", 4))
    score = int(10000000.0/mflops)
    return (0,score)

def run_scimark(test, isVerbose, shell, mode, argument):
    text = run_test(isVerbose, shell, "wasm_lua_scimark.c.js", mode, argument)
    if argument == 0:
        return parse_ouput(text, 0, None)

    mflops = float(parse_line(text, r"SciMark.*small", 2))
    score = int(100000.0/mflops)
    return (0,score)

tests = [ ("box2d",        None, run_std, r"frame averages:.*, range:.* to "),
          ("bullet",       None, run_std, r"ok.*"),
          ("conditionals", None, run_std, r"ok 144690090"),
          ("copy",         None, run_std, r"sum:2836"),
          ("corrections",  None, run_std, r"final: 40006013:10225."),
          ("fannkuch",     None, run_std, r"4312567891011"),
          ("fasta",        None, run_std, r"CCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAAGGCCGGGCGCGGT"),
          ("ifs",          None, run_std, r"ok"),
          ("linpack",      None, run_linpack,
                                          None),
          ("binarytrees",  "wasm_lua_binarytrees.c.js",
                                 run_std, "843\t trees of depth 10\t check: -842"),
          ("scimark",      None, run_scimark,
                                          None),
          ("memops",       None, run_std, r"final: 400."),
          ("primes",       None, run_std, r"lastprime: 3043739."),
          ("raybench",     "raybench.js",
                                 run_std, r"Render time: .*"),
          ("skinning",     None, run_std, r"blah=0.000000"),
          ("zlib",         "wasm_zlib.c.js",
                                 run_std, r"sizes: 100000,25906") ]
    
def run_test(isVerbose, shell, program, mode, argument):
    cmd = [shell]
    if mode == "baseline":
        cmd.append("--wasm-always-baseline")
    cmd.append(program)
    if argument != None:
        cmd.append(str(argument))
    if isVerbose:
        print("# " + str(cmd))
    log = open('output.tmp', 'w')
    text = subprocess.check_output(cmd, stderr=log, universal_newlines=True).split("\n")
    log.close()
    return text

def parse_output(text, argument, correct):
    compileTime = 0
    runTime = 0
    found = False
    do_check = argument == None and correct
    for t in text:
        if do_check and not found:
            found = re.match(correct, t)
        if re.match("WASM COMPILE TIME: ", t):
            compileTime = int(t[19:])
        elif re.match("WASM RUN TIME: ", t):
            runTime = int(t[15:])
    if do_check and not found:
        print(text)
        sys.exit("Error: did not match expected output " + correct)
    return (compileTime, runTime)

def parse_line(text, correct, fieldno):
    for t in text:
        if re.match(correct, t):
            return re.split(r" +", t)[fieldno-1]
    sys.exit("Error: did not match expected output " + correct)

def get_shells(mode):
    shell1 = None
    shell2 = None
    if mode == "IonVsBaseline" or mode == "IonCheck" or mode == "BaselineCheck":
        shell1 = get_shell("JS_SHELL")
        shell2 = shell1
    else:
        shell1 = get_shell("JS_SHELL1")
        shell2 = get_shell("JS_SHELL2")
    return (shell1, shell2)

def get_shell(name):
    probe = os.getenv(name)
    if not (probe and os.path.isfile(probe) and os.access(probe, os.X_OK)):
        sys.exit("Error: " + name + " does not name an executable shell")
    return probe

def parse_args():
    parser = argparse.ArgumentParser(description="Run wasm benchmarks in various configurations.")
    parser.add_argument("-a", metavar="argument", type=int, help=
                        """The problem size argument. The default is 3.  With argument=0 we
                        effectively only compile the code and compilation time is reported 
                        instead.  The max is 5.""")
    parser.add_argument("-b", action="store_true", help=
                        """Benchmark mode.  Discard the slowest time and print the 
                        mean of the remaining times.""")
    parser.add_argument("-c", metavar="mode", choices=["ion", "baseline"], help=
                        """Run only one shell (typically for sanity testing).  `mode` must 
                        be "ion" or "baseline".""")
    parser.add_argument("-m", metavar="mode", choices=["ion", "baseline"], help=
                        """Compare the output of two different shells.  In this case, 
                        the environment variables JS_SHELL1 and JS_SHELL2 must be set.
                        `mode` must be "ion" or "baseline".""")
    parser.add_argument("-n", metavar="numruns", type=int, help=
                        """The number of iterations to run.  The default is 1.  The value 
                        should be odd.  We report the median time (but see -b).""")
    parser.add_argument("-v", action="store_true", help=
                        """Verbose.  Echo commands and other information on stderr.""")
    parser.add_argument("pattern", nargs="*", help=
                        """Regular expressions to match against test names""")
    args = parser.parse_args();
    
    mode = "IonVsBaseline"
    if args.c and args.m:
        sys.exit("Error: -c and -m are incompatible")
    if args.m:
        mode = "BaselineVsBaseline" if args.m == "baseline" else "IonVsIon"
    if args.c:
        mode = "BaselineCheck" if args.c == "baseline" else "IonCheck"

    numruns = 1
    if args.n != None:
        if args.n <= 0:
            sys.exit("Error: -n requires a nonnegative integer")
        numruns = args.n
    if mode == "IonCheck" or mode == "BaselineCheck":
        numruns = 1

    argument = None
    if args.a != None:
        if args.a < 0 or args.a > 5:
            sys.exit("Error: -a requires an integer between 0 and 5")
        argument = args.a
    
    return (mode, numruns, argument, args.b, args.v, args.pattern)

main()

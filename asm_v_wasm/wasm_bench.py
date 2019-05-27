#!/usr/bin/env python
#
# Run wasm benchmarks in various configurations and report the times.
# Run with -h for help.
#
# In the default mode which is "ion+baseline", runs a single shell with
# --wasm-compiler=baseline and --wasm-compiler=ion and prints three
# tab-separated columns:
#
#  Ion-result  Baseline-result  Ion/Baseline
#
# In other benchmarking modes, runs one or two shells with the same argument
# (depending on the mode) and prints three tab-separated columns:
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
# TODO: Annotate results with - and +, derived from
#       the variance maybe.  Switch -s / --significance.
#
# TODO: catch any exception from the subprocess and print the log if
#       there was one.
#
# TODO: Also check the output for other arguments than the default.
#       Easy: use list of results for for the problems, indexed by problem size
#
# TODO: In several cases below we'd like to check the entire output,
#       not just one line of it.  Easy: lists of lines, match in order.
#
# TODO: We might like for the output not to contain any other lines than
#       the ones we are grepping for.  Not very hard - just a flag.

import argparse, os, re, subprocess, sys

def main():
    (mode, numruns, argument, isVerbose, noThreads, dumpData, dumpVariance, dumpRange, patterns) = parse_args()
    (shell1, shell2) = get_shells(mode)

    print "# mode=%s, runs=%d, problem size=%s" % (mode, numruns, (str(argument) if argument != None else "default"))
    if not is_check(mode):
        print "# Lower score is better"

    for test in tests:
        (name, _, fn, _) = test

        found = len(patterns) == 0
        for p in patterns:
            found = found or re.search(p, name)
        if not found:
            continue

        msg = name + "\t" + ("\t" if len(name) < 8 else "")

        if is_check(mode):
            fn(test, isVerbose, noThreads, shell1, get_system1(mode), argument)
            msg += "did not crash today"
        else:
            # Run back-to-back for each shell to reduce caching noise
            t1 = []
            for i in range(numruns):
                (c, r) = fn(test, isVerbose, noThreads, shell1, get_system1(mode), argument)
                t1.append(c if argument == 0 else r)
            t1.sort()

            t2 = []
            if not is_only(mode):
                for i in range(numruns):
                    (c, r) = fn(test, isVerbose, noThreads, shell2, get_system2(mode), argument)
                    t2.append(c if argument == 0 else r)
                t2.sort()

            n1 = t1[len(t1)/2]
            n2 = 1
            if not is_only(mode):
                n2 = t2[len(t2)/2]
            score = three_places(n1, n2)

            msg += str(n1) + "\t"
            if not is_only(mode):
                msg += str(n2) + "\t"
            msg += score

            if dumpVariance:
                lo1 = t1[1]
                hi1 = t1[len(t1)-2]
                msg += "\t[" + three_places(lo1, n1) + ", " + three_places(hi1, n1) + "]"
                if not is_only(mode):
                    lo2 = t2[1]
                    hi2 = t2[len(t2)-2]
                    msg += "\t[" + three_places(lo2, n2) + ", " + three_places(hi2, n2) + "]"

            if dumpRange:
                lo1 = t1[1]
                hi1 = t1[len(t1)-2]
                msg += "\t[" + str(lo1) + ", " + str(hi1) + "]"
                if not is_only(mode):
                    lo2 = t2[1]
                    hi2 = t2[len(t2)-2]
                    msg += "\t[" + str(lo2) + ", " + str(hi2) + "]"

            if dumpData:
                msg += "\t" + str(t1)
                if not is_only(mode):
                    msg += "\t" + str(t2)

        print msg

def three_places(a, b):
    if b == 0:
        return "-----"
    return str(round(float(a)/float(b)*1000)/1000)

def run_std(test, isVerbose, noThreads, shell, mode, argument):
    (name, program, _, correct) = test
    if program == None:
        program = "wasm_" + name + ".js"
    text = run_test(isVerbose, noThreads, shell, program, mode, argument)
    return parse_output(text, argument, correct)

def run_linpack(test, isVerbose, noThreads, shell, mode, argument):
    text = run_test(isVerbose, noThreads, shell, "wasm_linpack_float.c.js", mode, argument)
    if argument == 0:
        return parse_output(text, 0, None)

    mflops = float(parse_line(text, r"Unrolled +Single +Precision.*Mflops", 4))
    score = int(10000000.0/mflops)
    return (0,score)

def run_scimark(test, isVerbose, noThreads, shell, mode, argument):
    text = run_test(isVerbose, noThreads, shell, "wasm_lua_scimark.c.js", mode, argument)
    if argument == 0:
        return parse_output(text, 0, None)

    mark = float(parse_line(text, r"SciMark.*small", 2))
    score = int(100000.0/mark)
    return (0,score)

tests = [ ("box2d",        None, run_std, r"frame averages:.*, range:.* to "),
          ("bullet",       None, run_std, r"ok.*"),
          ("conditionals", None, run_std, r"ok 144690090"),
          ("copy",         None, run_std, r"sum:2836"),
          ("corrections",  None, run_std, r"final: 40006013:10225."),
          ("fannkuch",     None, run_std, r"4312567891011"),
          ("fasta",        None, run_std, r"CCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAAGGCCGGGCGCGGT"),
          ("fib",          "fib.js", run_std, r"fib.40. = 102334155"),
          ("ifs",          None, run_std, r"ok"),
          #("linpack",      None, run_linpack, None),
          ("binarytrees",  "wasm_lua_binarytrees.c.js", run_std, "843\t trees of depth 10\t check: -842"),
          #("scimark",      None, run_scimark, None),
          ("memops",       None, run_std, r"final: 400."),
          ("primes",       None, run_std, r"lastprime: 3043739."),
          ("raybench",     "raybench.js", run_std, r"Render time: .*"),
          ("rust-fannkuch", "rust-fannkuch.js", run_std, r"fannkuch\(11\) = 556355"),
          ("skinning",     None, run_std, r"blah=0.000000"),
          ("zlib",         "wasm_zlib.c.js", run_std, r"sizes: 100000,25906") ]

def run_test(isVerbose, noThreads, shell, program, mode, argument):
    cmd = [shell]
    if mode == "baseline":
        cmd.append("--wasm-compiler=baseline")
    if mode == "ion":
        cmd.append("--wasm-compiler=ion")
    if mode == "cranelift":
        cmd.append("--wasm-compiler=cranelift")
    if noThreads:
        cmd.append("--no-threads")
    cmd.append(program)
    if argument != None:
        cmd.append(str(argument))
    if isVerbose:
        print "# %s" % str(cmd)
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
        print text
        panic("Did not match expected output " + correct)
    return (compileTime, runTime)

def parse_line(text, correct, fieldno):
    for t in text:
        if re.match(correct, t):
            return re.split(r" +", t)[fieldno-1]
    panic("Did not match expected output " + correct)

def get_shells(mode):
    shell1 = None
    shell2 = None
    if uses_one_shell(mode):
        shell1 = get_shell("JS_SHELL")
        shell2 = shell1
    else:
        shell1 = get_shell("JS_SHELL1")
        shell2 = get_shell("JS_SHELL2")
    return (shell1, shell2)

def get_shell(name):
    probe = os.getenv(name)
    if not (probe and os.path.isfile(probe) and os.access(probe, os.X_OK)):
        panic(name + " does not name an executable shell")
    return probe

def is_check(mode):
    return mode == "ion_check" or mode == "baseline_check" or mode == "cranelift_check"

def uses_one_shell(mode):
    if is_check(mode) or is_only(mode):
        return True
    if get_system1(mode) != get_system2(mode):
        return True
    return False
 
def get_system1(mode):
    if re.search(r"_|\+", mode):
        return re.split(r"_|\+", mode)[0]
    return mode

def get_system2(mode):
    if re.search(r"\+", mode):
        return re.split(r"\+", mode)[1]
    panic("Mode does not have a second system: " + mode)

def is_only(mode):
    return mode == "ion_only" or mode == "baseline_only" or mode == "cranelift_only"

def panic(msg):
    sys.exit("Error: " + msg)

def parse_args():
    parser = argparse.ArgumentParser(description=
                                     """Run wasm benchmarks in various configurations.
                                     When a single JS shell is needed the default program name is 'js'; 
                                     otherwise it can be overridden with the environment variable JS_SHELL.
                                     When two shells are needed they must be named by the environment
                                     variables JS_SHELL1 and JS_SHELL2.""")
    parser.add_argument("-a", "--problem", metavar="argument", type=int, help=
                        """The problem size argument. The default is 3.  With argument=0 we
                        effectively only compile the code and compilation time is reported
                        instead.  The max is 5.""")
    parser.add_argument("-c", "--check", metavar="mode", choices=["ion", "baseline", "cranelift"], help=
                        """Run only one shell a single run, to see if it works.  `mode` must
                        be "ion" or "baseline" or "cranelift".""")
    parser.add_argument("-d", "--data", action="store_true", help=
                        """Print the measurement data as two comma-separated lists following
                        the normal results.""")
    parser.add_argument("-i", "--variance", action="store_true", help=
                        """For five or more runs, discard the high and low measurements and
                        print low/median and high/median following the standard columns.""")
    parser.add_argument("-j", "--range", action="store_true", help=
                        """For five or more runs, discard the high and low measurements and
                        print low and high following the standard columns.""")
    parser.add_argument("-m", "--mode", metavar="mode",
                        choices=["ion", "baseline", "cranelift", "ion+ion", "ion+baseline", "ion+cranelift",
                                 "baseline+ion", "baseline+baseline", "baseline+cranelift",
                                 "cranelift+ion", "cranelift+baseline", "cranelift+cranelift"],
                        help=
                        """Compare the output of two different shells.  
                        `mode` must be "ion" or "baseline" or "cranelift", or "a+b" 
                        where a and b are one of those systems.  A single system a means a+a.""")
    parser.add_argument("-n", "--numruns", metavar="numruns", type=int, help=
                        """The number of iterations to run.  The default is 1.  The value
                        should be odd.  We report the median time.""")
    parser.add_argument("-o", "--only", metavar="mode", choices=["ion", "baseline", "cranelift"], help=
                        """Run only the one shell in the normal manner, and report results
                        according to any other switches""")
    parser.add_argument("-v", "--verbose", action="store_true", help=
                        """Verbose.  Echo commands and other information on stderr.""")
    parser.add_argument("-t", "--no-threads", action="store_true", help=
                        """Disable threads in the shell, for added timing stability.
                        This will significantly impact compile times, and may impact running
                        time since eg GC runs on the remaining thread with everything else.""")
    parser.add_argument("pattern", nargs="*", help=
                        """Regular expressions to match against test names""")
    args = parser.parse_args();

    if args.check and args.mode:
        panic("--check and --mode are incompatible")
    if args.check and args.only:
        panic("--check and --only are incompatible")
    if args.mode and args.only:
        panic("--mode and --only are incompatible")

    mode = "ion+baseline"
    if args.mode:
        if re.search(r"\+", args.mode):
            mode = args.mode
        else:
            mode = args.mode + "+" + args.mode
    if args.check:
        mode = args.check + "_check"
    if args.only:
        mode = args.only + "_only"

    if args.check and args.variance:
        panic("--check and --variance are incompatible")

    if args.check and args.range:
        panic("--check and --range are incompatible")

    numruns = 1
    if args.numruns != None:
        if args.numruns <= 0:
            panic("--numruns requires a nonnegative integer")
        numruns = args.numruns

    if is_check(mode):
        numruns = 1

    if not (numruns % 2):
        panic("The number of runs must be odd")

    if args.variance and numruns < 5:
        panic("At least five runs required for --variance")

    if args.range and numruns < 5:
        panic("At least five runs required for --range")

    argument = None
    if args.problem != None:
        if args.problem < 0 or args.problem > 5:
            panic("--problem requires an integer between 0 and 5")
        argument = args.problem

    if args.verbose:
        args.data = True

    return (mode, numruns, argument, args.verbose, args.no_threads, args.data, args.variance, args.range, args.pattern)

if __name__ == '__main__':
    main()

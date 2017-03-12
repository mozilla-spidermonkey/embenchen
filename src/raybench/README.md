A simple ray tracer that is set up to trace a scene with about 200
objects as a wasm benchmark.  It can render to a browser canvas, to a
ppm file, or run headless.  See Makefile.

Pass a number to the program to scale it:
  0 -      compile only
  1 .. 5 - increasingly difficult
  
The expected output for benchmark argument '4' [sic] is in
expected-output.ppm.  (Emacs can display this, if you don't have other
software that can.)

Note, if you recompile this program the resulting .js must be manually
edited to insert code to report WASM COMPILE TIME and WASM RUN TIME
when you copy it to the benchmark directory.  See eg
../../asm_vs_wasm/wasm_primes.js for a template.

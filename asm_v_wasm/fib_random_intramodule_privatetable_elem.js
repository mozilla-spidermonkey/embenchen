/* Author: Lars T Hansen, Mozilla */

// INFO: Doubly-recursive fib(40) with indirect calls via a private table to a set of same-module functions, table initialized by elem
// There must be table bounds checks here: the index is unknown.

var ins = new WebAssembly.Instance(new WebAssembly.Module(wasmTextToBinary(`
(module

  ;; Random indices into the function table, indexed by the fib argument
  (memory 1)
  (data (i32.const 0) (i8 4 1 5 6 7 4 2 2 1 2 6 7 0 5 3 5 5 4 6 2 0 6 0 3 2 5 3 7 0 4 6 5 2 2 5 0 2 2 5 7 0))
  (data (i32.const 100) (i8 0 4 7 1 1 7 0 2 7 6 5 3 7 2 4 6 6 0 5 4 5 3 4 4 3 6 7 1 4 5 5 4 4 0 5 7 1 0 7 7 1))

  (type $ty (func (param i32) (result i32)))
  (table $t 8 funcref)
  (elem $t (i32.const 0) $fib0 $fib1 $fib2 $fib3 $fib4 $fib5 $fib6 $fib7)

  (func $fib0 (export "fib") (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib1 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib2 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib3 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib4 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib5 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib6 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

  (func $fib7 (param $n i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 1)) (i32.load8_u (local.get $n)))
                 (call_indirect (type $ty) (i32.sub (local.get $n) (i32.const 2)) (i32.load8_u offset=100 (local.get $n))))))

)
`)));

assertEq(ins.exports.fib(10), 55);

var then = new Date();
var arg = 40;
switch ((typeof scriptArgs == 'object'?scriptArgs:arguments)[0]) {
case '0':
    arg = 0;
case '1':
    arg -= 5;
    break;
case '2':
    arg -= 3;
    break;
case '4':
    arg += 3;
    break;
case '5':
    arg += 5;
    break;
}
print("fib(" + arg + ") = " + ins.exports.fib(arg));
var now = new Date();
print("WASM RUN TIME: " + (now - then));

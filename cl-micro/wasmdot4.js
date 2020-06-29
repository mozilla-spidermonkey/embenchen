var ITER = 1000;

// Compute the dot-product of vectors starting at $m and $n, both of length
// $len, ITER times, and return the final sum.
//
// Perform one dummy function call before the outer loop.

var bin = wasmTextToBinary(
    `(module
      (memory (export "mem") 100)
      (global $g (mut i32) (i32.const 0))
      (global $f (mut f64) (f64.const 0))
      (func $dummy)
      (func $dot (export "dot") (param $m i32) (param $n i32) (param $len i32) (result f64)
        (local $mm i32)
        (local $nn i32)
        (local $ll i32)
        (local $sum f64)
        (local $k1 i32)
        (local $k2 i32)
        (local $k3 i32)
        (local $k4 i32)
        (local $k5 i32)
        (local $k6 i32)
        (local $f1 f64)
        (local $f2 f64)
        (local $f3 f64)
        (local $f4 f64)
        (local $iter i32)
        (local.set $iter (i32.const ${ITER}))
        (local.set $mm (local.get $m))
        (local.set $nn (local.get $n))
        (local.set $ll (local.get $len))
        (call $dummy)
        (loop $AGAIN
          (if (local.get $len)
              (loop $L
                (local.set $sum
                  (f64.add (local.get $sum)
                           (f64.mul (f64.load (local.get $m)) (f64.load (local.get $n)))))
                (local.set $m (i32.add (local.get $m) (i32.const 8)))
                (local.set $n (i32.add (local.get $n) (i32.const 8)))
                (local.set $len (i32.sub (local.get $len) (i32.const 1)))
                (local.set $k1 (i32.add (local.get $k1) (i32.const 1)))
                (local.set $k2 (i32.add (local.get $k2) (i32.const 2)))
                (local.set $k3 (i32.add (local.get $k3) (i32.const 3)))
                (local.set $k4 (i32.add (local.get $k4) (i32.const 4)))
                (local.set $k5 (i32.add (local.get $k5) (i32.const 5)))
                (local.set $k6 (i32.add (local.get $k6) (i32.const 6)))
                (local.set $f1 (f64.add (local.get $f1) (f64.const 1)))
                (local.set $f2 (f64.add (local.get $f2) (f64.const 2)))
                (local.set $f3 (f64.add (local.get $f3) (f64.const 3)))
                (local.set $f4 (f64.add (local.get $f4) (f64.const 4)))
                (br_if $L (local.get $len))))
          (global.set $g (i32.add (i32.add (i32.add (i32.add (i32.add (local.get $k1) (local.get $k2)) (local.get $k3)) (local.get $k4)) (local.get $k5)) (local.get $k6)))
          (global.set $f (f64.add (f64.add (f64.add (local.get $f1) (local.get $f2)) (local.get $f3)) (local.get $f4)))
          (local.set $iter (i32.sub (local.get $iter) (i32.const 1)))
          (local.set $m (local.get $mm))
          (local.set $n (local.get $nn))
          (local.set $len (local.get $ll))
          (br_if $AGAIN (local.get $iter)))
        (local.get $sum)))`);

var mod = new WebAssembly.Module(bin);
var ins = new WebAssembly.Instance(mod);
var mem = new Float64Array(ins.exports.mem.buffer);

// Sanity check
var a = 33;
var b = 330000;
var sum = 0;
for ( var i=0; i < 10; i++ ) {
    mem[a+i] = i;
    mem[b+i] = i+1;
    sum += mem[a+i] * mem[b+i];
}
assertEq(ins.exports.dot(a*8, b*8, 10), ITER*sum);

for ( var i=0; i < 100000; i++ ) {
    mem[a+i] = i;
    mem[b+i] = i+1;
}
for ( var i=0 ; i < 10 ; i++ ) {
    var then = new Date();
    ins.exports.dot(a*8, b*8, 100000);
    var now = new Date();
    print(now - then);
}

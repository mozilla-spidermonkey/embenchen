var ITER = 1000;

// Compute the dot-product of vectors starting at $m and $n, both of length
// $len, ITER times, and return the final sum.  Split this into one function per
// loop.
//
// Reduces register pressure relative to wasmdot.js since temps holding original
// values are local to the outer function.

var bin = wasmTextToBinary(
    `(module
      (memory (export "mem") 100)
      (func $dodot (param $m i32) (param $n i32) (param $len i32) (result f64)
        (local $sum f64)
        (if (local.get $len)
            (loop $L
              (local.set $sum
                (f64.add (local.get $sum)
                         (f64.mul (f64.load (local.get $m)) (f64.load (local.get $n)))))
              (local.set $m (i32.add (local.get $m) (i32.const 8)))
              (local.set $n (i32.add (local.get $n) (i32.const 8)))
              (local.set $len (i32.sub (local.get $len) (i32.const 1)))
              (br_if $L (local.get $len))))
        (local.get $sum))

      (func $dot (export "dot") (param $m i32) (param $n i32) (param $len i32) (result f64)
        (local $sum f64)
        (local $iter i32)
        (local.set $iter (i32.const ${ITER}))
        (loop $AGAIN
          (local.set $sum
            (f64.add (local.get $sum)
                     (call $dodot (local.get $m) (local.get $n) (local.get $len))))
          (local.set $iter (i32.sub (local.get $iter) (i32.const 1)))
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

var bin = wasmTextToBinary(
    `(module
      (func $fib (export "fib") (param $n i32) (result i32)
        (if i32 (i32.lt_s (local.get $n) (i32.const 2))
            (local.get $n)
            (i32.add (call $fib (i32.sub (local.get $n) (i32.const 1)))
                     (call $fib (i32.sub (local.get $n) (i32.const 2)))))))`);

var mod = new WebAssembly.Module(bin);
var ins = new WebAssembly.Instance(mod);

assertEq(ins.exports.fib(10), 55);

for ( var i=0 ; i < 10 ; i++ ) {
    var then = new Date();
    ins.exports.fib(37);
    var now = new Date();
    print(now - then);
}

var bin = wasmTextToBinary(
    `(module
      (func $fib (export "fib") (param $n i32) (result i32)
        (if (result i32 ) (i32.lt_s (local.get $n) (i32.const 2))
            (local.get $n)
            (i32.add (call $fib (i32.sub (local.get $n) (i32.const 1)))
                     (call $fib (i32.sub (local.get $n) (i32.const 2)))))))`);

var before_compile = new Date();
var mod = new WebAssembly.Module(bin);
var after_compile = new Date();
print("WASM COMPILE TIME: " + (after_compile - before_compile));

var ins = new WebAssembly.Instance(mod);


assertEq(ins.exports.fib(10), 55);

var then = new Date();
var arg = 40;
switch (scriptArgs[0]) {
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
print("fib(40) = " + ins.exports.fib(arg));
var now = new Date();
print("WASM RUN TIME: " + (now - then));

// var bin = wasmTextToBinary(
//     `(module
//       (func $fib (export "fib") (param $n i32) (result i32)
//         (if (result i32 ) (i32.lt_s (local.get $n) (i32.const 2))
//             (local.get $n)
//             (i32.add (call $fib (i32.sub (local.get $n) (i32.const 1)))
//                      (call $fib (i32.sub (local.get $n) (i32.const 2)))))))`);
var bin = new Uint8Array([0,97,115,109,1,0,0,0,1,6,1,96,1,127,1,127,3,2,1,0,7,7,1,3,102,105,98,0,0,10,30,1,28,0,32,0,65,2,72,4,127,32,0,5,32,0,65,1,107,16,0,32,0,65,2,107,16,0,106,11,11,0,21,4,110,97,109,101,1,6,1,0,3,102,105,98,2,6,1,0,1,0,1,110]);

var before_compile = new Date();
var mod = new WebAssembly.Module(bin);
var after_compile = new Date();
print("WASM COMPILE TIME: " + (after_compile - before_compile));

var ins = new WebAssembly.Instance(mod);

if (ins.exports.fib(10) != 55) throw "assert fib(10) = 55";

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
print("fib(40) = " + ins.exports.fib(arg));
var now = new Date();
print("WASM RUN TIME: " + (now - then));

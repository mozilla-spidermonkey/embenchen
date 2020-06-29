var M = new WebAssembly.Instance(
    new WebAssembly.Module(
        os.file.readFile('calls-callee.wasm','binary')));

var ins = new WebAssembly.Instance(
    new WebAssembly.Module(
        os.file.readFile('calls.wasm', 'binary')),
    { M: M.exports });

// Sanity test
assertEq(ins.exports.run_external(3), 3*(8+42));
assertEq(ins.exports.run_internal(3), 3*(7+37));
assertEq(ins.exports.run_direct(3), 3*(7+37));

var iter = 100000000;

var then = performance.now();
ins.exports.run_external(iter);
print("external: " + (performance.now() - then));

var then = performance.now();
ins.exports.run_internal(iter);
print("internal: " + (performance.now() - then));

var then = performance.now();
ins.exports.run_direct(iter);
print("direct: " + (performance.now() - then));

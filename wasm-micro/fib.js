var ins = new WebAssembly.Instance(
    new WebAssembly.Module(
        os.file.readFile('fib.wasm','binary')));

// Sanity check
assertEq(ins.exports.fib(10), 55);

var iterations = 10;
var argument = 37;
var times = [];

for ( let i=0 ; i < iterations ; i++ ) {
    let then = new Date();
    ins.exports.fib(argument);
    let now = new Date();
    times.push(now - then);
}
print(`fib ${argument}: ${times.reduce((x,y) => x+y)/times.length}`);

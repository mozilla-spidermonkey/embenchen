var bin = os.file.readFile('rust-fannkuch.wasm','binary');

var then = new Date();
var mod = new WebAssembly.Module(bin);
var now = new Date();
print("WASM COMPILE TIME: " + (now - then));

var ins = new WebAssembly.Instance(mod);

var arg = 11;
switch (scriptArgs[0]) {
case '0': arg = 8; break;
case '1': arg = 9; break;
case '2': arg = 10; break;
case '4': arg = 12; break;
case '5': arg = 13; break;
}
var then = new Date();
var result = ins.exports.run_fannkuch(arg);
var now = new Date();
print("WASM RUN TIME: " + (now - then));
print(`fannkuch(${arg}) = ${result}`);
if (arg == 11) {
    assertEq(result, 556355);
}

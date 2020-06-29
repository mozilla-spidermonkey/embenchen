// Could do compileStreaming?
// Also want some kind of error handling

var modules = {};
var instances = {};
var ready = false;

Promise.allSettled(['fib','calls-callee','calls']
                   .map((m) => WebAssembly.compileStreaming(fetch(m + '.wasm')).then(fetchDone(m))))
    .then(instantiateAll);

function fetchDone(name) {
    return function(module) {
        modules[name] = module
    }
}

function instantiateAll() {
    instances['fib'] = new WebAssembly.Instance(modules['fib']);
    {
        let M = new WebAssembly.Instance(modules['calls-callee']);
        instances['calls'] = new WebAssembly.Instance(modules['calls'], {M: M.exports});
    }
    ready = true;
}

function runBench() {
    if (!ready) {
        console.log("Not ready");
        return;
    }

    runCallExternal();
    runCallInternal();
    runCallDirect();
    runFib();
}

function log(msg) {
    document.getElementById('results').appendChild(document.createTextNode(msg + "\n"));
}

const call_iter = 100000000;

function runCallExternal() {
    var ins = instances['calls'];
    var then = performance.now();
    ins.exports.run_external(call_iter);
    log("call external: " + (performance.now() - then));
}

function runCallInternal() {
    var ins = instances['calls'];
    var then = performance.now();
    ins.exports.run_internal(call_iter);
    log("call internal: " + (performance.now() - then));
}

function runCallDirect() {
    var ins = instances['calls'];
    var then = performance.now();
    ins.exports.run_direct(call_iter);
    log("call direct: " + (performance.now() - then));
}

function runFib() {
    var ins = instances['fib'];
    var iterations = 10;
    var argument = 37;
    var times = [];

    for ( let i=0 ; i < iterations ; i++ ) {
        let then = new Date();
        ins.exports.fib(argument);
        let now = new Date();
        times.push(now - then);
    }
    log(`fib ${argument}: ${times.reduce((x,y) => x+y)/times.length}`);
}

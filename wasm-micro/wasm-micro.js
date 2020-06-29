// Benchmark driver for browser.  See wasm-micro.html.

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

var benchmarks;

function runBench() {
    if (!ready) {
        console.log("Not ready");
        return;
    }
    benchmarks = [runCallExternal, runCallInternal, runCallDirect, runFib];
    runNext();
}

function runNext() {
    if (benchmarks.length > 0) {
        (benchmarks.shift())();
        setTimeout(runNext, 0);
    }
}

function log(msg) {
    document.getElementById('results').appendChild(document.createTextNode(msg + "\n"));
}

function logBenchmark(tag, thunk, iterations = 1) {
    let times = [];
    for ( let i=0 ; i < iterations; i++ ) {
        let then = performance.now();
        thunk();
        times.push(performance.now() - then);
    }
    let time = times.reduce((x,y) => x+y)/times.length;
    log(tag + ": " + time);
}

const call_iter = 100000000;

function runCallExternal() {
    logBenchmark("call external", () => instances.calls.exports.run_external(call_iter));
}

function runCallInternal() {
    logBenchmark("call internal", () => instances.calls.exports.run_internal(call_iter));
}

function runCallDirect() {
    logBenchmark("call direct", () => instances.calls.exports.run_direct(call_iter));
}

function runFib() {
    let argument = 37;
    logBenchmark(`fib ${argument}`, () => instances.fib.exports.fib(argument), 10);
}

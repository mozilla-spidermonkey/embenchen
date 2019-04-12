var bin = wasmTextToBinary(
    `(module
      (memory (export "mem") 100)
      (func $loop (export "dot") (param $m1 i32) (param $m2 i32) (param $m3 i32) (result i32)
        (local $k1 i32)
        (local $k3 i32)
        (local $k5 i32)
        (local.set $k1 (i32.const 1))
        (local.set $k3 (i32.const 3))
        (local.set $k5 (i32.const 5))
        (i32.add (i32.add (i32.div_u (local.get $k1) (local.get $m1))
                          (i32.div_u (local.get $k3) (local.get $m2)))
                 (i32.div_u (local.get $k5) (local.get $m3)))))`);

var mod = new WebAssembly.Module(bin);

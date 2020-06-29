var bin = wasmTextToBinary(
    `(module
      (memory (export "mem") 100)
      (func $dummy)
      (func $loop (export "dot") (param $len i32) (result i32)
        (local $k1 i32)
        (local $k2 i32)
        (local $k3 i32)
        (local $k4 i32)
        (local $k5 i32)
        (local $k6 i32)
;; This call can be commented out to contrast how things work
        (call $dummy)
        (loop $AGAIN
          (if (local.get $len)
              (block
                (local.set $len (i32.sub (local.get $len) (i32.const 1)))
                (local.set $k1 (i32.add (local.get $k1) (i32.const 1)))
                (local.set $k2 (i32.add (local.get $k2) (i32.const 2)))
                (local.set $k3 (i32.add (local.get $k3) (i32.const 3)))
                (local.set $k4 (i32.add (local.get $k4) (i32.const 4)))
                (local.set $k5 (i32.add (local.get $k5) (i32.const 5)))
                (local.set $k6 (i32.add (local.get $k6) (i32.const 6)))
                (br_if $AGAIN (local.get $len)))))
          (i32.add (i32.add (i32.add (i32.add (i32.add (local.get $k1) (local.get $k2)) (local.get $k3)) (local.get $k4)) (local.get $k5)) (local.get $k6))))`);

var mod = new WebAssembly.Module(bin);

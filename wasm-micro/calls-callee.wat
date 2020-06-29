;; The imported callee used in the calls microbenchmark
(module
  (func (export "f") (param i32) (result i32)
    (i32.add (local.get 0) (i32.const 42))))

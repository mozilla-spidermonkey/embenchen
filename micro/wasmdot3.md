# Cranelift behavior on double-loop dot product with dummy call

## Source:

```
(module
  (memory (export "mem") 100)
  (func $dummy)
  (func $dot (export "dot") (param $m i32) (param $n i32) (param $len i32) (result f64)
    (local $mm i32) (local $nn i32) (local $ll i32) (local $sum f64) (local $iter i32)
    (local.set $iter (i32.const ${ITER}))
    (local.set $mm (local.get $m))
    (local.set $nn (local.get $n))
    (local.set $ll (local.get $len))
    (call $dummy)
    (loop $AGAIN
      (if (local.get $len)
          (loop $L
            (local.set $sum
              (f64.add (local.get $sum)
                       (f64.mul (f64.load (local.get $m)) (f64.load (local.get $n)))))
            (local.set $m (i32.add (local.get $m) (i32.const 8)))
            (local.set $n (i32.add (local.get $n) (i32.const 8)))
            (local.set $len (i32.sub (local.get $len) (i32.const 1)))
            (br_if $L (local.get $len))))
      (local.set $iter (i32.sub (local.get $iter) (i32.const 1)))
      (local.set $m (local.get $mm))
      (local.set $n (local.get $nn))
      (local.set $len (local.get $ll))
      (br_if $AGAIN (local.get $iter)))
    (local.get $sum)))
```

## Analysis 2010-04-08

(This assumes pending changes for LICM, https://github.com/CraneStation/cranelift/pull/727)

This is the same as wasmdot.js, see wasmdot.md for general analysis of
the loop code.  The only difference here is the call to the dummy
function before the outer loop.  This makes the program take 3x longer
in both Ion and Cranelift.  As such, we're on par with Ion here, but
this is really not good.

Basically the problem is that a lot of variables are spilled for the
duration of their lifetimes.

It's easier to see in this code:

```
(module
  (func $dummy)
  (func $dot (export "dot") (result f64)
    (local $sum f64)
    (local $iter i32)
    (call $dummy)
    (local.set $iter (i32.const 1000))
    (loop $AGAIN
      (if (local.get $iter)
          (then
            (local.set $sum (f64.add (local.get $sum) (f64.const 1)))
            (local.set $iter (i32.sub (local.get $iter) (i32.const 1)))
            (br $AGAIN))))
    (local.get $sum)))
```

The IR after register allocation is this:

```
function u0:1(i64 vmctx [%rdi], i64 fp [%rbp]) -> f64 [%xmm0], i64 fp [%rbp] system_v {
    ss0 = spill_slot 8, offset -24
    ss1 = incoming_arg 16, offset -16
    sig0 = (i64 vmctx [%rdi]) system_v
    fn0 = u0:0 sig0

                                ebb0(v0: i64 [%rdi], v17: i64 [%rbp]):
[RexOp1pushq#50]                    x86_push v17
[RexOp1copysp#8089]                 copy_special %rsp -> %rbp
[RexOp1adjustsp_ib#d083]            adjust_sp_down_imm 16
@0028 [RexMp2f64imm_z#557,%xmm0]    v13 = f64const 0.0
@0028 [RexMp2fspillSib32#711,ss0]   v2 = spill v13
@002c [RexOp1fnaddr8#80b8,%rax]     v11 = func_addr.i64 fn0
@002c [RexOp1call_r#20ff]           call_indirect sig0, v11(v0)
@002e [RexOp1pu_id#b8,%rax]         v4 = iconst.i32 1000
@0033 [-]                           fallthrough ebb2(v4, v2)

                                ebb2(v5: i32 [%rax], v6: f64 [ss0]):
@0037 [RexOp1tjccb#74]              brz v5, ebb4
@003b [RexOp1pu_iq#80b8,%rcx]       v12 = iconst.i64 0x3ff0_0000_0000_0000
@003b [RexMp2frurm#856e,%xmm0]      v7 = bitcast.f64 v12
@0044 [RexMp2ffillSib32#710,%xmm1]  v14 = fill v6
@0044 [RexMp2fa#758,%xmm1]          v15 = fadd v14, v7
@0044 [RexMp2fspillSib32#711,ss0]   v8 = spill v15
@004b [RexOp1r_ib#83,%rax]          v10 = iadd_imm v5, -1
@004e [RexOp1jmpb#eb]               jump ebb2(v10, v8)

                                ebb4:
@0051 [-]                           fallthrough ebb3

                                ebb3:
@0054 [-]                           fallthrough ebb1(v6)

                                ebb1(v1: f64 [ss0]):
@0054 [RexMp2ffillSib32#710,%xmm0]  v16 = fill v1
[RexOp1adjustsp_ib#8083]            adjust_sp_up_imm 16
[RexOp1popq#58,%rbp]                v18 = x86_pop.i64 
@0054 [Op1ret#c3]                   return v16, v18
}
```

Here we return $sum == v16 == fill v1 == v6 == v2 == spill v13 ==
spill f64const.0.0.  The sensible thing would have been to split the
live range of $sum across the call so that it could have been in a
register after the call.  (And then to rematerialize the 0.0 after the
call instead of storing and reloading it.)

Observe that $iter _is_ handled properly in this case even though it
too is technically initialized to zero before the call.

Of course in the original example there are no easy constants to deal
with, but the live ranges could still be split at the call.  As it is,
everything is live across the call, and so everything is spilled and
reloaded, and there's a lot of memory traffic.  (The reloader also
fails to reload values already in registers, exacerbating the
problem.)

Consider the machine code of the inner loop of the original program:
```
  69:	40 89 ce             	mov	esi, ecx                    // ???
  6c:	48 8b bc 24 10 00 00 00	mov	rdi, qword ptr [rsp + 0x10] // load spilled vmctx
  74:	48 8b 3f             	mov	rdi, qword ptr [rdi]        // load heap pointer
  77:	f2 40 0f 10 04 37    	movsd	xmm0, qword ptr [rdi + rsi] // load value
  7d:	40 89 d6             	mov	esi, edx                    // ???
  80:	48 8b bc 24 10 00 00 00	mov	rdi, qword ptr [rsp + 0x10] // load spilled vmctx
  88:	48 8b 3f             	mov	rdi, qword ptr [rdi]        // load heap pointer
  8b:	f2 40 0f 10 0c 37    	movsd	xmm1, qword ptr [rdi + rsi] // load value
  91:	f2 40 0f 59 c1       	mulsd	xmm0, xmm1                  // multiply values
  96:	f2 40 0f 10 8c 24 08 00 00 00	
				movsd	xmm1, qword ptr [rsp + 8]   // load sum
  a0:	f2 40 0f 58 c8       	addsd	xmm1, xmm0                  // add to sum
  a5:	f2 40 0f 11 8c 24 08 00 00 00	
				movsd	qword ptr [rsp + 8], xmm1   // store sum
  af:	40 83 c1 08          	add	ecx, 8
  b3:	40 83 c2 08          	add	edx, 8
  b7:	40 83 c3 ff          	add	ebx, -1
  bb:	40 85 db             	test	ebx, ebx
  be:	75 a9                	jne	0x69
```

Here we have:

* Redundant loads of the vmctx, which is a parameter that was spilled for its lifetime
* Failure to hoist heap pointer loads, since they now depend on the vmctx load even though this value is constant
* Unnecessary filling and spilling of the sum
* Unnecessary moving of index values into rsi for dereferencing (unless this is a sign-extend?)
* Unnecessary testing of ebx, since the necessary flags should already be set

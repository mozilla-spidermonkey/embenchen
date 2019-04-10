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

#### Spidermonkey code

This is from a debug build.  Cranelift is actually good about keeping
integer values in registers in the inner loop, but not floating-point
values - not sure why that is.  It could be because $sum is also used
in the last block, the same problem we're seeing in wasmfib.js.

It LICMs the heap pointer but not the vmctx, which is kind of
fascinating.

```
00000000  41 83 fa 6f               cmp $0x6F, %r10d          // api check
00000004  0f 84 06 00 00 00         jz 0x0000000000000010     //  of
0000000A  0f 0b                     ud2                       //    some
0000000C  0f 1f 40 00               nopl %eax, (%rax)         //      sort
00000010  41 56                     push %r14                 // set
00000012  55                        push %rbp                 //   up
00000013  48 8b ec                  mov %rsp, %rbp            //     frame
00000016  48 83 ec 28               sub $0x28, %rsp           //       and
0000001A  49 39 66 28               cmpq %rsp, 0x28(%r14)     //         check
0000001E  0f 82 02 00 00 00         jb 0x0000000000000026     //           for
00000024  0f 0b                     ud2                       //             overflow
00000026  89 bc 24 24 00 00 00      movl %edi, 0x24(%rsp)     // save $m and $mm
0000002D  89 b4 24 20 00 00 00      movl %esi, 0x20(%rsp)     // save $n and $nn
00000034  89 94 24 1c 00 00 00      movl %edx, 0x1C(%rsp)     // save $len and $ll
0000003B  4c 89 b4 24 10 00 00 00   movq %r14, 0x10(%rsp)     // save vmctx
00000043  66 0f 57 c0               xorpd %xmm0, %xmm0        // clear $sum
00000047  f2 0f 11 84 24 08 00 00 00 
                                    movsdq %xmm0, 0x08(%rsp)  // spill $sum
00000050  b8 e8 03 00 00            mov $0x3E8, %eax          // set up $iter
00000055  89 84 24 18 00 00 00      movl %eax, 0x18(%rsp)     // spill $iter
0000005C  48 8b 84 24 10 00 00 00   movq 0x10(%rsp), %rax     // load vmctx
00000064  49 89 c6                  mov %rax, %r14            //   and move it
00000067  e8 00 00 00 00            call 0x000000000000006C   // call $dummy
0000006C  48 8b 84 24 10 00 00 00   movq 0x10(%rsp), %rax     // load vmctx
00000074  48 8b 00                  movq (%rax), %rax         // load heap pointer
00000077  8b 8c 24 1c 00 00 00      movl 0x1C(%rsp), %ecx     // load $len
0000007E  8b 94 24 20 00 00 00      movl 0x20(%rsp), %edx     // load $n
00000085  8b 9c 24 24 00 00 00      movl 0x24(%rsp), %ebx     // load $m

// Outer loop starts here
0000008C  8b b4 24 1c 00 00 00      movl 0x1C(%rsp), %esi     // redundant copy
00000093  89 b4 24 1c 00 00 00      movl %esi, 0x1C(%rsp)     //   of $ll
0000009A  8b b4 24 20 00 00 00      movl 0x20(%rsp), %esi     // redundant copy
000000A1  89 b4 24 20 00 00 00      movl %esi, 0x20(%rsp)     //   of $nn
000000A8  8b b4 24 24 00 00 00      movl 0x24(%rsp), %esi     // redundant copy
000000AF  89 b4 24 24 00 00 00      movl %esi, 0x24(%rsp)     //   of $mm
000000B6  48 8b b4 24 10 00 00 00   movq 0x10(%rsp), %rsi     // load vmctx
000000BE  48 8b 76 30               movq 0x30(%rsi), %rsi     // load interrupt flag
000000C2  48 83 fe 00               cmp $0x00, %rsi           // check
000000C6  74 02                     jz 0x00000000000000CA     //   for
000000C8  0f 0b                     ud2                       //     interrupts
000000CA  85 c9                     test %ecx, %ecx           // check len
000000CC  74 49                     jz 0x0000000000000117

// Inner loop starts here
000000CE  48 8b b4 24 10 00 00 00   movq 0x10(%rsp), %rsi     // load vmctx
000000D6  48 8b 76 30               movq 0x30(%rsi), %rsi     // load interrupt flag
000000DA  48 83 fe 00               cmp $0x00, %rsi           // check
000000DE  74 02                     jz 0x00000000000000E2     //   for
000000E0  0f 0b                     ud2                       //     interrupts
000000E2  89 de                     mov %ebx, %esi            // sign extension 
000000E4  f2 0f 10 04 30            movsdq (%rax,%rsi,1), %xmm0 // load lhs
000000E9  89 d6                     mov %edx, %esi            // sign extension
000000EB  f2 0f 10 0c 30            movsdq (%rax,%rsi,1), %xmm1 // load rhs
000000F0  f2 0f 59 c1               mulsd %xmm1, %xmm0        // lhs*rhs
000000F4  f2 0f 10 8c 24 08 00 00 00 
                                    movsdq 0x08(%rsp), %xmm1  // load $sum
000000FD  f2 0f 58 c8               addsd %xmm0, %xmm1        // add product
00000101  f2 0f 11 8c 24 08 00 00 00 
                                    movsdq %xmm1, 0x08(%rsp)  // store $sum
0000010A  83 c3 08                  add $0x08, %ebx
0000010D  83 c2 08                  add $0x08, %edx
00000110  83 c1 ff                  add $-0x01, %ecx
00000113  85 c9                     test %ecx, %ecx
00000115  75 b7                     jnz 0x00000000000000CE    // back edge to inner loop

00000117  8b 8c 24 18 00 00 00      movl 0x18(%rsp), %ecx     // load $iter
0000011E  83 c1 ff                  add $-0x01, %ecx          // dec
00000121  89 8c 24 18 00 00 00      movl %ecx, 0x18(%rsp)     // store $iter
00000128  8b 8c 24 1c 00 00 00      movl 0x1C(%rsp), %ecx     // load $mm and assign to $m
0000012F  8b 94 24 20 00 00 00      movl 0x20(%rsp), %edx     // load $nn and assign to $n
00000136  8b 9c 24 24 00 00 00      movl 0x24(%rsp), %ebx     // load $ll and assign to $len
0000013D  8b b4 24 18 00 00 00      movl 0x18(%rsp), %esi     // load $iter again
00000144  85 f6                     test %esi, %esi
00000146  0f 85 40 ff ff ff         jnz 0x000000000000008C    // back edge to outer loop
0000014C  f2 0f 10 84 24 08 00 00 00 

                                    movsdq 0x08(%rsp), %xmm0  // load $sum
00000155  4c 8b 74 24 30            movq 0x30(%rsp), %r14     // load vmctx
0000015A  4d 8b 3e                  movq (%r14), %r15         // restore heap ptr
0000015D  48 83 c4 28               add $0x28, %rsp           // tear down
00000161  5d                        pop %rbp                  //   frame
00000162  41 5e                     pop %r14                  //     and
00000164  c3                        ret                       //       return
```

So, mysteries to solve:

* Why those redundant copies at the head of the outer loop?
* Why are we not seeing any registers above the lower eight, apart
  from r14, and that only when it can't be avoided at a call boundary?
  We should have space for other values to be in registers.
* Why is the xmm register so different from the integer registers?  Is
  it because it is not flagged as rematerializable?  Is it because it
  is used in the tail block so "must" be spilled anyway? Is there some
  other bug?
* Why is the vmctx load not hoisted out of the inner loop?  The heap
  pointer is a known-redundant load.  But the vmctx is a spill, so that
  could be the reason.

#### Redundant copies

The redundant copies appear to be fill-spill pairs.  Here's the whole
thing after the "reload" pass, ebb2 is the outer loop.  Observe that
eg v45 is used again later.  But something must have gone wrong here,
because if we have val=spill(x)=fill(y) we should just equate val with
y, I should think.  Before the reload pass, the fill-spill pairs are
"copy" nodes.


```
function u0:1(i32 [%rdi], i32 [%rsi], i32 [%rdx], i64 vmctx [%r14]) -> f64 [%xmm0] baldrdash {
    ss0 = spill_slot 4
    ss1 = spill_slot 4
    ss2 = spill_slot 4
    ss3 = spill_slot 8
    ss4 = spill_slot 8
    ss5 = spill_slot 4
    gv0 = vmctx
    gv1 = iadd_imm.i64 gv0, 48
    gv2 = load.i64 notrap aligned readonly gv0
    heap0 = static gv2, min 0x0064_0000, bound 0x0001_0000_0000, offset_guard 0x8000_0000, index_type i32
    sig0 = (i64 vmctx [%r14]) baldrdash
    fn0 = colocated u0:0 sig0

                                ebb0(v63: i32, v64: i32, v65: i32, v66: i64):
[RexOp1spillSib32#89,ss0]           v0 = spill v63
[RexOp1spillSib32#89,ss1]           v1 = spill v64
[RexOp1spillSib32#89,ss2]           v2 = spill v65
[RexOp1spillSib32#8089,ss3]         v3 = spill v66
@0054 [RexMp2f64imm_z#557,-]        v67 = f64const 0.0
@0054 [RexMp2fspillSib32#711,ss4]   v6 = spill v67
@0058 [RexOp1pu_id#b8,-]            v68 = iconst.i32 1000
@0058 [RexOp1spillSib32#89,ss5]     v8 = spill v68
@0069 [RexOp1fillSib32#808b,-]      v69 = fill v3
@0069 [Op1call_id#e8]               call fn0(v69)
@0077 [RexOp1fillSib32#808b,-]      v70 = fill v3
@0077 [RexOp1ld#808b,-]             v51 = load.i64 notrap aligned readonly v70
                                    v53 -> v51
@006b [RexOp1fillSib32#8b,-]        v58 = fill v2
@006b [RexOp1fillSib32#8b,-]        v60 = fill v1
@006b [RexOp1fillSib32#8b,-]        v62 = fill v0
@006b [RexOp1jmpb#eb]               jump ebb2(v58, v6, v62, v60, v8, v0, v1, v2)

                                ebb2(v11: i32, v30: f64 [ss4], v31: i32, v32: i32, v34: i32 [ss5], v54: i32 [ss0], v55: i32 [ss1], v56: i32 [ss2]):
                                    v33 -> v34
                                    v35 -> v34
@006b [RexOp1fillSib32#8b,-]        v71 = fill v56
@006b [RexOp1spillSib32#89,ss2]     v45 = spill v71
                                    v44 -> v45
                                    v46 -> v45
@006b [RexOp1fillSib32#8b,-]        v72 = fill v55
@006b [RexOp1spillSib32#89,ss1]     v42 = spill v72
                                    v41 -> v42
                                    v43 -> v42
@006b [RexOp1fillSib32#8b,-]        v73 = fill v54
@006b [RexOp1spillSib32#89,ss0]     v39 = spill v73
                                    v38 -> v39
                                    v40 -> v39
@006b [RexOp1fillSib32#808b,-]      v74 = fill.i64 v3
@006b [RexOp1ldDisp8#808b,-]        v10 = load.i64 v74+48
@006b [RexOp1rcmp_ib#f083,-]        v48 = ifcmp_imm v10, 0
@006b [trapif#00]                   trapif ne v48, interrupt
@006f [RexOp1tjccb#74]              brz v11, ebb4(v30)
@0071 [RexOp1jmpb#eb]               jump ebb5(v30, v31, v32, v11)

                                ebb5(v14: f64 [ss4], v15: i32, v18: i32, v27: i32):
@0071 [RexOp1fillSib32#808b,-]      v75 = fill.i64 v3
@0071 [RexOp1ldDisp8#808b,-]        v13 = load.i64 v75+48
@0071 [RexOp1rcmp_ib#f083,-]        v49 = ifcmp_imm v13, 0
@0071 [trapif#00]                   trapif ne v49, interrupt
@0077 [RexOp1umr#89,-]              v50 = uextend.i64 v15
@0077 [RexMp2fldWithIndex#710,-]    v17 = load_complex.f64 v51+v50
@007c [RexOp1umr#89,-]              v52 = uextend.i64 v18
@007c [RexMp2fldWithIndex#710,-]    v20 = load_complex.f64 v51+v52
@007f [RexMp2fa#759,-]              v21 = fmul v17, v20
@0080 [RexMp2ffillSib32#710,-]      v76 = fill v14
@0080 [RexMp2fa#758,-]              v77 = fadd v76, v21
@0080 [RexMp2fspillSib32#711,ss4]   v22 = spill v77
@0087 [RexOp1r_ib#83,-]             v24 = iadd_imm v15, 8
@008e [RexOp1r_ib#83,-]             v26 = iadd_imm v18, 8
@0095 [RexOp1r_ib#83,-]             v29 = iadd_imm v27, -1
@009a [RexOp1tjccb#75]              brnz v29, ebb5(v22, v24, v26, v29)
@009c [RexOp1jmpb#eb]               jump ebb6

                                ebb6:
@009d [RexOp1jmpb#eb]               jump ebb4(v22)

                                ebb4(v47: f64 [ss4]):
@00a2 [RexOp1fillSib32#8b,-]        v78 = fill.i32 v34
@00a2 [RexOp1r_ib#83,-]             v79 = iadd_imm v78, -1
@00a2 [RexOp1spillSib32#89,ss5]     v37 = spill v79
@00b3 [RexOp1fillSib32#8b,-]        v57 = fill.i32 v45
@00b3 [RexOp1fillSib32#8b,-]        v59 = fill.i32 v42
@00b3 [RexOp1fillSib32#8b,-]        v61 = fill.i32 v39
@00b3 [RexOp1fillSib32#8b,-]        v80 = fill v37
@00b3 [RexOp1tjccb#75]              brnz v80, ebb2(v57, v47, v61, v59, v37, v39, v42, v45)
@00b5 [RexOp1jmpb#eb]               jump ebb3

                                ebb3:
@00b8 [RexOp1jmpb#eb]               jump ebb1(v47)

                                ebb1(v4: f64 [ss4]):
@00b8 [RexMp2ffillSib32#710,-]      v81 = fill v4
@00b8 [-]                           fallthrough_return v81
}
```

#### Higher register numbers

It turns out that higher register numbers are being used, if we create
enough register pressure.  Suppose we create variables $k1 thru $k6
that are incremented in the loop and whose sum is later stored in a
global.  (This is wasmdot4.js.)  These get allocated to registers
*except for the last one*, and that is true whether it's four of them
or six of them - the last one is stack-allocated, the others are in
registers.

Here's an excerpt, we add 1 to $k1, 2 to $k2 etc:

```
[Codegen] 0000014F  41 83 c2 01               add $0x01, %r10d
[Codegen] 00000153  41 83 c1 02               add $0x02, %r9d
[Codegen] 00000157  41 83 c0 03               add $0x03, %r8d
[Codegen] 0000015B  83 c7 04                  add $0x04, %edi
[Codegen] 0000015E  83 c6 05                  add $0x05, %esi
[Codegen] 00000161  44 8b 9c 24 18 00 00 00   movl 0x18(%rsp), %r11d
[Codegen] 00000169  41 83 c3 06               add $0x06, %r11d
[Codegen] 0000016D  44 89 9c 24 18 00 00 00   movl %r11d, 0x18(%rsp)
```

Without the dummy function call present this is not an issue, so it's
some spill/reload thing that goes awry.

What happens is that there is one canonical integer zero created at
the start of the program.  This is then spilled(!).  The first five
variables get copies of this spill, which turn into fills after the
dummy call.  But the sixth variable gets the zero itself, which is
still spilled.

I wonder what happens if also the sixth one is made a copy.

The copies are introduced by the coalsecing pass, in the register
allocator.  There's a generic algorithm there to insert copies
carefully.

It's weird that values are live across calls.  It is manifestly not
true if there are no callee-saves registers.  So at some point in the
pipeline, at least for Firefox, we should lower to a form that
expresses this fact, and the SSA should follow.



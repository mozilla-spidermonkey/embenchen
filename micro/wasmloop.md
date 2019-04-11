# Non-hot function calls pessimize register assignments globally

Updated 2019-04-11.

## Summary

Function calls that are well outside any hot loops, just somewhere in the
function, can mess up register allocation in various ways they shouldn't.
Specifically:

* Constant values are spilled to memory and reloaded instead of being
  rematerialized.

* Some locals whose live range starts after the function call and which could
  be allocated to registers are not, while others are.

* Some locals whose live range starts before the function call are spilled and
  henceforth always kept in memory after the function call, while splitting the
  live range at the call would have been more reasonable.

This analysis is for integer registers but float registers behave the same.

The underlying reason seems to be that the spill+reload pass can't distinguish
normal capacity spills from enforced function call spills (which are really
enforced live range splits), and end up forcing values live across a call into
memory.

## Source code

The call to $dummy can be commented out.  Code shown below results from having
the call absent or present.

```
(module
  (memory (export "mem") 100)
  (func $dummy)
  (func $loop (export "dot") (param $len i32) (result i32)
    (local $k1 i32)
    (local $k2 i32)
    (local $k3 i32)
    (local $k4 i32)
    (local $k5 i32)
    (local $k6 i32)
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
      (i32.add (i32.add (i32.add (i32.add (i32.add (local.get $k1) (local.get $k2))
                                          (local.get $k3))
                                 (local.get $k4))
                        (local.get $k5))
               (local.get $k6))))
```

## Analysis of the generated code in SpiderMonkey

(The logs here were obtained with IONFLAGS=codegen; requires a disassembler
patch that is not landed at this time.)

### Without the dummy call

This code is basically very good, all objections are minor.  We could discuss
whether the initial zeroing is the best possible; in the inner loop the
decrement of `$len` could be moved to just before the test, and then merged
with the test; and the interrupt check could use a compare-with-memory.

```
00000016  48 83 ec 08               sub $0x08, %rsp       // Align stack
0000001A  b8 00 00 00 00            mov $0x00, %eax       // Zero $k6
0000001F  89 c1                     mov %eax, %ecx        //  and $k5
00000021  89 c2                     mov %eax, %edx        //   and $k4
00000023  89 c3                     mov %eax, %ebx        //    and $k3
00000025  89 c6                     mov %eax, %esi        //     and $k2
00000027  41 89 c0                  mov %eax, %r8d        //      and $k1

// Loop head
0000002A  4d 8b 4e 30               movq 0x30(%r14), %r9  // Check
0000002E  49 83 f9 00               cmp $0x00, %r9        //  for
00000032  74 02                     jz 0x0000000000000036 //   interrupt
00000034  0f 0b                     ud2                   //    or trap
00000036  85 ff                     test %edi, %edi       // initial
00000038  74 1a                     jz 0x0000000000000054 //  guard

0000003A  83 c7 ff                  add $-0x01, %edi      // $len--
0000003D  41 83 c0 01               add $0x01, %r8d       // $k1 += 1
00000041  83 c6 02                  add $0x02, %esi       //  etc
00000044  83 c3 03                  add $0x03, %ebx
00000047  83 c2 04                  add $0x04, %edx
0000004A  83 c1 05                  add $0x05, %ecx
0000004D  83 c0 06                  add $0x06, %eax
00000050  85 ff                     test %edi, %edi       // backedge
00000052  75 d6                     jnz 0x000000000000002A//  guard

// Final return
00000054  41 01 f0                  add %esi, %r8d        // sum values
00000057  41 01 d8                  add %ebx, %r8d
0000005A  41 01 d0                  add %edx, %r8d
0000005D  41 01 c8                  add %ecx, %r8d
00000060  41 01 c0                  add %eax, %r8d        //  ... into temp reg
00000063  44 89 c0                  mov %r8d, %eax        //   and move/signextend into return reg
0000006E  48 83 c4 08               add $0x08, %rsp       // pop stack
```

### With the dummy call

This code has many problems:

* At 0x35 we create and spill a zero value, in a slot that will be used for
  `$k6`, but the useful live range of `$k6` is really from after the call,
  along with the other variables, and at 0x51 et seq we can see that the
  compiler has figure this out for the other variables.

* The variables `$k1` through `$k5` are being initialized by loading the zero
  from memory rather than by just setting them to zero.

* `$len` is kept in memory throughout the loop even though it need not be: it
  only needs to be saved across the call.

* The tls is kept in memory throughout the loop ditto.

```
00000016  48 83 ec 18               sub $0x18, %rsp       // allocate
0000001A  49 39 66 28               cmpq %rsp, 0x28(%r14) //  and test
0000001E  0f 82 02 00 00 00         jb 0x0000000000000026 //   overflow
00000024  0f 0b                     ud2                   //    or trap
00000026  89 bc 24 14 00 00 00      movl %edi, 0x14(%rsp) // spill $len
0000002D  4c 89 b4 24 08 00 00 00   movq %r14, 0x08(%rsp) // spill tls
00000035  b8 00 00 00 00            mov $0x00, %eax       // make a zero value
0000003A  89 84 24 10 00 00 00      movl %eax, 0x10(%rsp) //  and store in $k6
00000041  48 8b 84 24 08 00 00 00   movq 0x08(%rsp), %rax // reload tls
00000049  49 89 c6                  mov %rax, %r14        //  and move it into place
0000004C  e8 00 00 00 00            call 0x0000000000000051
00000051  8b 84 24 10 00 00 00      movl 0x10(%rsp), %eax // load
00000058  8b 8c 24 10 00 00 00      movl 0x10(%rsp), %ecx //  five
0000005F  8b 94 24 10 00 00 00      movl 0x10(%rsp), %edx //   zeroes
00000066  8b 9c 24 10 00 00 00      movl 0x10(%rsp), %ebx //    from
0000006D  8b b4 24 10 00 00 00      movl 0x10(%rsp), %esi //     memory

// Loop head
00000074  48 8b bc 24 08 00 00 00   movq 0x08(%rsp), %rdi // load tls
0000007C  48 8b 7f 30               movq 0x30(%rdi), %rdi // check
00000080  48 83 ff 00               cmp $0x00, %rdi       //  for
00000084  74 02                     jz 0x0000000000000088 //   interrupt
00000086  0f 0b                     ud2                   //    or trap
00000088  8b bc 24 14 00 00 00      movl 0x14(%rsp), %edi // initial
0000008F  85 ff                     test %edi, %edi       //  loop
00000091  74 3c                     jz 0x00000000000000CF //   guard

00000093  8b bc 24 14 00 00 00      movl 0x14(%rsp), %edi // load $len
0000009A  83 c7 ff                  add $-0x01, %edi      //  and decrement
0000009D  89 bc 24 14 00 00 00      movl %edi, 0x14(%rsp) //   and store
000000A4  83 c6 01                  add $0x01, %esi       // inc $k1
000000A7  83 c3 02                  add $0x02, %ebx       //  and $k2
000000AA  83 c2 03                  add $0x03, %edx       //   and $k3
000000AD  83 c1 04                  add $0x04, %ecx       //    and $k4
000000B0  83 c0 05                  add $0x05, %eax       //     and $k5
000000B3  8b bc 24 10 00 00 00      movl 0x10(%rsp), %edi // load $k6
000000BA  83 c7 06                  add $0x06, %edi       //  and increment
000000BD  89 bc 24 10 00 00 00      movl %edi, 0x10(%rsp) //   and store
000000C4  8b bc 24 14 00 00 00      movl 0x14(%rsp), %edi // backedge
000000CB  85 ff                     test %edi, %edi       //  loop
000000CD  75 a5                     jnz 0x0000000000000074//   guard

000000CF  01 de                     add %ebx, %esi        // sum values
000000D1  01 d6                     add %edx, %esi
000000D3  01 ce                     add %ecx, %esi
000000D5  01 c6                     add %eax, %esi
000000D7  8b 84 24 10 00 00 00      movl 0x10(%rsp), %eax
000000DE  01 c6                     add %eax, %esi        //  ... into temp reg
000000E0  89 f0                     mov %esi, %eax        //   and move/signextend into return reg
000000EA  48 83 c4 18               add $0x18, %rsp       // pop stack
```

## What happens in the register allocator?

(The dumps here were obtained with RUST_LOG=debug.)

### Coalescing / CSSA generation

It turns out that coalescing / the generation of "Conventional SSA" does not
"break" `$k6`, instead it just (mostly accidentally I think) sets up things for
`$k1` through `$k5` so that spill/reload do not do anything bad with them.

Here is the input to the CSSA pass.  v0 is `$len`, v1 is the tls.  This all
looks fine.  Note v0, v1, and v3 are live across the call.

```
  ebb0(v0: i32, v1: i64):
      v3 = iconst.i32 0
      call fn0(v1)
      jump ebb2(v0, v3, v3, v3, v3, v3, v3)

  ebb2(v6: i32, v9: i32, v12: i32, v15: i32, v18: i32, v21: i32, v24: i32):
      v5 = load.i64 v1+48
      v38 = ifcmp_imm v5, 0
      trapif ne v38, interrupt
      brz v6, ebb4(v9, v12, v15, v18, v21, v24)
      v8 = iadd_imm v6, -1
      v11 = iadd_imm v9, 1
      v14 = iadd_imm v12, 2
      v17 = iadd_imm v15, 3
      v20 = iadd_imm v18, 4
      v23 = iadd_imm v21, 5
      v26 = iadd_imm v24, 6
      brnz v8, ebb2(v8, v11, v14, v17, v20, v23, v26)
      jump ebb4(v11, v14, v17, v20, v23, v26)

  ebb4(v27: i32, v28: i32, v30: i32, v32: i32, v34: i32, v36: i32):
      v29 = iadd.i32 v27, v28
      v31 = iadd v29, v30
      v33 = iadd v31, v32
      v35 = iadd v33, v34
      v37 = iadd v35, v36
      v39 = uextend.i64 v2
      fallthrough_return v39
```

And here is the output of the CSSA pass, this happens to be identical except
for ebb0 so let's look only at that:

```
  ebb0(v0: i32, v1: i64):
      v3 = iconst.i32 0
      call fn0(v1)
      v40 = copy v3
      v41 = copy v3
      v42 = copy v3
      v43 = copy v3
      v44 = copy v3
      jump ebb2(v0, v44, v43, v42, v41, v40, v3)
```

That is, the reason `$k6` is treated differently and is stack-allocated is
sheer accident: it is a variable that was created before the call and remained
live across the call, while the others were copies inserted by coalescing that
were made live after the call.

The copies are inserted because in ebb2, the incoming parameters represent
different values, in turn because at the backedge to ebb2, the last six
parameters all represent different values.  The copies are required by the CSSA
form.

(It still seems silly, however, that when v40 through v44 are initialized they
are initialized by loading that zero from memory.  A copy of a constant
probably ought to be that constant, at least if the constant is cheap to
rematerialize.  However, we don't yet know that it will be loaded from memory
so it's too soon to make that determination.)

Thus the problem does not seem to be with copy insertion per se.

### Spilling and reloading

The spill/fill pass however generates code that is not great.  Here v40, for
example, would be more meaningfully represented as a constant 0.  More
importantly, v1, being spilled before the call, is still live across the call
(it is used in the first line of ebb2), as is v0 (it is used in the jump to
ebb2 at the end of ebb0) and v3 (it is used extensively in the tail of ebb0).

In the presence of callee-save registers and a good allocator for those, this
code may be sensible: v0, v1, and v3 might all be represented as moves to
callee-saves registers, and then we're golden; fills from those could be
represented as copies or even as direct uses.

In the absence of callee-save registers, however, the spills v0, v1, and v3
must be actual spills, and then any fill from those turns into an actual fill.

```
  ebb0(v45: i32, v46: i64):
      v0 = spill v45
      v1 = spill v46
      v47 = iconst.i32 0
      v3 = spill v47
      v48 = fill v1
      call fn0(v48)
      v40 = fill v3
      v41 = fill v3
      v42 = fill v3
      v43 = fill v3
      v44 = fill v3
      jump ebb2(v0, v44, v43, v42, v41, v40, v3)

  ebb2(v6: i32 [ss0], v9: i32, v12: i32, v15: i32, v18: i32, v21: i32, v24: i32 [ss2]):
      v49 = fill.i64 v1
      v5 = load.i64 v49+48
      v38 = ifcmp_imm v5, 0
      trapif ne v38, interrupt
      v50 = fill v6
      brz v50, ebb4(v9, v12, v15, v18, v21, v24)
      v51 = fill v6
      v52 = iadd_imm v51, -1
      v8 = spill v52
      v11 = iadd_imm v9, 1
      v14 = iadd_imm v12, 2
      v17 = iadd_imm v15, 3
      v20 = iadd_imm v18, 4
      v23 = iadd_imm v21, 5
      v53 = fill v24
      v54 = iadd_imm v53, 6
      v26 = spill v54
      v55 = fill v8
      brnz v55, ebb2(v8, v11, v14, v17, v20, v23, v26)
      jump ebb4(v11, v14, v17, v20, v23, v26)

  ebb4(v27: i32, v28: i32, v30: i32, v32: i32, v34: i32, v36: i32 [ss2]):
      v29 = iadd.i32 v27, v28
      v31 = iadd v29, v30
      v33 = iadd v31, v32
      v35 = iadd v33, v34
      v56 = fill.i32 v36
      v37 = iadd v35, v56
      v39 = uextend.i64 v2
      fallthrough_return v39
```

So what's the strategy for spilling and filling around function calls?  The
regalloc runs a "spilling" pass and then a "reload" pass.

The spilling pass does not insert any instructions apart from copy
instructions, but it does annotate values with their affinities (register or
stack, and in the case of register, the register class).  Values that need to
be spilled have their affinity set to "Stack".

All live values at a call are spilled at the call, just like that; calls are
not handled specially as save/restore pairs or anything like that.

Callee-saves registers are not considered at this stage and indeed there's a
TODO comment stating this.

The reload pass works per-ebb and inserts spill and fill instructions
sufficient for instructions that operate on a register always to get the
operand in that register.  (It can keep track of register contents within the
EBB but currently does not do so, but this would at best reduce the number of
extranous fills.  In our example it would remove the "fill v6" after the brz in
ebb2 - that's all.)

## Why are calls different?

Spills for calls are not "capacity" spills, they are necessary -- the value is
live after the call but can't be in a register during the call.  From the point
of view of the caller, but ignoring the call, the value should be in a register
unless capacity requires it to be on the stack.  And even then it need not be on
the stack always.

By spilling a live range just because there is a function call, we force the
value onto the stack completely.  The coalescing phase has some mention of
"splitting" but it seems like a technical matter having to do with inserting
copies for the CSSA, not live range splitting.

## What then must we do?

### Insert copies

It turns out that the register allocator already behaves well if a value that's
live across a call is introduced as a copy of the live value directly after the
call.  This effectively *splits the live range* of the value.  We see an
example of this above, where CSSA construction introduces copies of v3 in ebb0;
these turn into fill instructions (from the value spilled across the call) that
are then properly allocated to registers for the rest of the function.  But the
CSSA construction does this by accident in this case, and as we've seen it does
not do it for the remaining use of v3 nor for v0 and v1.

So what we should do is probably introduce systematic copies of values across
calls so that the register allocator can concern itself only with capacity
spills; then these copied values will be spilled before the call and filled
after.  In the case above, we would get a definition below the call along the
lines of `vNN = copy v3`, with later uses of v3 replaces by vNN, and the CSSA
pass would introduce further copies of vNN for the arguments for ebb2.  That
is, for ebb0 I'd expect to see this:

```
  ebb0(v0: i32, v1: i64):
      v3 = iconst.i32 0
      call fn0(v1)
      v99 = copy v0
      v98 = copy v3
      v97 = copy v1
      v40 = copy v98
      v41 = copy v98
      v42 = copy v98
      v43 = copy v98
      v44 = copy v98
      jump ebb2(v99, v44, v43, v42, v41, v40, v98)
```

Other blocks would be like they already are except references to v1 are
replaced by references to v97, the in-register copy of the tls; this is
globally live and not modified and thus not passed around as a parameter.

In general, though, it is possible that this transformation will introduce new
ebb parameters, as values restored (by copy) after calls along two paths meet
at a node.  For example, if we have:

```
  ebb1():
    bnz v9, ebb2()
    jump ebb3()
  ebb2():
    call f()
    jump ebb3()
  ebb3():
    call g(v0)
```

we will need to rewrite this as:

```
  ebb1():
    bnz v9, ebb2()
    jump ebb3(v0)
  ebb2():
    call f()
    v2 = copy v0
    jump ebb3(v2)
  ebb3(v3):
    call g(v3)
```

since v0 at ebb3 is either the original v0 or the new value v2, restored after
the call to f.  Clearly v0 and v2 have the same value, but they are not the
same SSA value since they are two different definitions.

### When and how to insert copies

Logically this is part of register allocation, so it's most reasonable to
insert the copies first in the register allocation phase.  (Both the live range
information and the CSSA form will be affected by the copies and the new
names.)

Inserting copies around calls will require liveness and flow information
however - we only copy those values that are live across the call, and we only
want to insert ebb parameters where a copy (a new value) can meet another copy
or the original value.

If we can, it would be beneficial to make use of the existing liveness
computation, so we may end up computing liveness twice, once to insert copies
and parameters and rename and then again to do the rest of register
allocation.

(More work coming)

### What does this do for callee-saves registers?

It doesn't do anyting one way or the other.  It is likely that the register
allocator can do better (in the long run) if we're able to hint that the
introduced copies should be placed in callee-saves registers.

### What to do about extraneous copies and extra spills and fills?

There's a real risk with back-to-back calls that we'll get a fill/spill pair of
the value between the two calls.  So it's possible we need to have an
optimization to deal with that.  From other test cases I've seen evidence that
we don't have it.

Consider:

```
   v0 = ...
   call f()
   call g()
   ...
   ... v0
```

which turns into

```
   v0 = ...
   call f()
   v1 = copy v0
   call g()
   v2 = copy v1
   ...
   ... v2
```

which naively turns into

```
   v0 = ...
   v3 = spill v0
   call f()
   v1 = fill v3
   v4 = spill v1
   call g()
   v2 = fill v4
   ...
   ... v2
```

where the fill/spill pair between the two calls is redundant; v2 could be filled from v3.

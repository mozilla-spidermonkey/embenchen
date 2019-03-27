# Cranelift behavior on doubly-recursive fib()

## Source:

```
(module
  (func $fib (export "fib") (param $n i32) (result i32)
    (if i32 (i32.lt_s (local.get $n) (i32.const 2))
        (local.get $n)
        (i32.add (call $fib (i32.sub (local.get $n) (i32.const 1)))
                 (call $fib (i32.sub (local.get $n) (i32.const 2)))))))
```

## Analysis 2019-03-26

### Machine code in SpiderMonkey (obtained from gdb):

```
   0x24c03c9b020:    push     %r14             // save tls
   0x24c03c9b022:    push     %rbp             // save fp
   0x24c03c9b023:    mov      %rsp,%rbp        // setup frame
   0x24c03c9b026:    sub      $0x18,%rsp       // stack
   0x24c03c9b02a:    cmp      %rsp,0x28(%r14)  //   overflow
   0x24c03c9b02e:    jb       0x24c03c9b036    //     check
   0x24c03c9b034:    ud2                       //       and trap
   0x24c03c9b036:    mov      %edi,0x14(%rsp)  // spill arg - TOO SOON [1]
   0x24c03c9b03d:    mov      %r14,0x8(%rsp)   // spill tls - BAD [2]
   0x24c03c9b045:    mov      0x14(%rsp),%eax  // reload arg - BAD [3]
   0x24c03c9b04c:    cmp      $0x2,%eax        // relation to "2"?
   0x24c03c9b04f:    jge      0x24c03c9b053    // jump-across-jump -
   0x24c03c9b051:    jmp  L1  0x24c03c9b0a4    //   BAD [4]
   0x24c03c9b053:    mov      0x14(%rsp),%eax  // reload arg - BAD [5]
   0x24c03c9b05a:    add      $0xffffffff,%eax // sub 1
   0x24c03c9b05d:    mov      0x8(%rsp),%rcx   // load tls - BAD [6]
   0x24c03c9b065:    rex mov  %eax,%edi        // superfluous mov - BAD [7]
   0x24c03c9b068:    mov      %rcx,%r14        // superfluous mov - BAD [8]
   0x24c03c9b06b:    callq    0x24c03c9b020    // recursive call to fib
   0x24c03c9b070:    mov      %eax,0x10(%rsp)  // spill result
   0x24c03c9b077:    mov      0x14(%rsp),%eax  // load arg
   0x24c03c9b07e:    add      $0xfffffffe,%eax // sub 2
   0x24c03c9b081:    mov      0x8(%rsp),%rcx   // load tls - IFFY [9]
   0x24c03c9b089:    rex mov  %eax,%edi        // superflous mov - BAD [10]
   0x24c03c9b08c:    mov      %rcx,%r14        // superflous mov - BAD [11]
   0x24c03c9b08f:    callq    0x24c03c9b020    // recursive call to fib
   0x24c03c9b094:    mov      0x10(%rsp),%ecx  // load prev result
   0x24c03c9b09b:    add      %eax,%ecx        // +
   0x24c03c9b09d:    mov      %ecx,0x14(%rsp)  // spill result - NOT GOOD [12]
L1:
   0x24c03c9b0a4:    mov      0x14(%rsp),%eax  // load result - NOT GOOD [13]
   0x24c03c9b0ab:    mov      %eax,%eax        // superflous mov? - IFFY [14]
   0x24c03c9b0ad:    mov      0x20(%rsp),%r14  // load tls - BAD [15]
                                               //   because popped below
   0x24c03c9b0b2:    mov      (%r14),%r15      // load memory base - BAD [16]
   0x24c03c9b0b5:    add      $0x18,%rsp       // teardown frame
   0x24c03c9b0b9:    pop      %rbp             // pop fp
   0x24c03c9b0ba:    pop      %r14             // pop tls
   0x24c03c9b0bc:    retq   
```

### Notes

1. Really it only needs to be saved in the non-base case.  It could be spilled here either because the spilling algorithm does not do shrinkwrapping or because there is something fishy that requires the phi at L1 to take the value on the stack.
2. Tls is alredy on the stack, we don't need to save it again [102]
3. The argument is still in edi [101]
4. The target L1 is well within reach of the jge, so that should have been "jl L1" and the unconditional jmp should have been avoided [104]
5. The argument is still in edi [101]
6. Tls is still in r14 still [101]
7. The load at ...53 could have targeted edi, or even better, just not been there at all since the value we want is in edi [101]
8. The load at ...5d could have targeted r14, or even better, just not been there at all since the value we want is already in r14 [101]
9. What is the save discipline for tls?  The code of this function seems to assume that it is callee-saves, in which case this load is clearly redundant.  If this code is not redundant, then the final popping of the tls at ...ba is redundant. [101][102]
10. As [7] for the load at ...77, though at least this time the load is necessary [101]
11. The load at ...81 could have loaded directly into r14 [101]
12. Also see [1].  It's going to flow into the phi at L1 and there's no good reason why it can't be in a register.
13. See [12] and [1], the value should have been in a register (edi would have been good).
14. It's possible this is a move that truncates the top part of the value, to correspond to some calling convention, but the value here is the result of strictly typed code, so I'm not convinced this is really necessary (and in that case the mov is redundant).
15. Why?  The heapreg should be callee-saves + it's untouched.  Is it because the function is exported?  That might make sense for tls, but not for heapreg...  [100][102]
16. Ditto [103]

### Notes to the notes

#### [100] About loading the heapreg at the end of the function:

I now see the comment in GenerateCraneliftCode() in WasmCraneliftCompile.cpp.  And I now see that Cranelift doesn't use the heapreg at all.  Not sure how wise that is.  We tried to make heapreg spillable in Ion, and we got slowdowns, https://bugzilla.mozilla.org/show_bug.cgi?id=1342121.

The general bug for Cranelift for this heapReg interaction thing is https://bugzilla.mozilla.org/show_bug.cgi?id=1507820.  The right fix here might be to pin the register by removing it from Cranelift's register set, and just use it, certainly on all 64-bit platforms we are likely to have a heapreg, and even though there's some lip service in the Wasm CG toward multiple memories nobody seems to believe that will happen for several years, sort of like 64-bit memories.  We should optimize for the single-memory case.

And even if we don't do that, would it not be sufficient to remove r15 from Cranelift's register mask so that we don't have to have these two chained loads at the end of every function?  Or will that interact poorly with eg callouts to C++?

Is it possible to run an experiment here by removing the lines that reload the heapreg and running with --wasm-compiler=cranelift, since we won't have any use for the register and we won't have any interaction with baseline code?  Curious about how much this matters, if at all.  (For the case with tiering, this won't work, since baseline code that may be returned to will expect the heapreg to be sane.)

Benjamin was working on this: https://github.com/CraneStation/cranelift/pull/624 but is not currently doing so.

#### [101] About reloading spilled values already in registers

This is https://github.com/CraneStation/cranelift/issues/246.

#### [102] The tls is currently callee-saves.

It should not be reloaded after a call, it should be assumed to be in a register (but see [101] for what may be confusing the issue).

#### [103] We should not be reloading the heapreg like this

But if we are, it would be better to do it after the "pop r14" than here...

#### [104] Some work ongoing to improve branch optimizations

Here: https://github.com/CraneStation/cranelift/pull/629.

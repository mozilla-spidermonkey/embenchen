# Cranelift behavior on double-loop dot product

## Source:

```
(module
  (memory (export "mem") 100)
  (func $dot (export "dot") (param $m i32) (param $n i32) (param $len i32) (result f64)
    (local $mm i32) (local $nn i32) (local $ll i32) (local $sum f64) (local $iter i32)
    (local.set $iter (i32.const ${ITER}))
    (local.set $mm (local.get $m))
    (local.set $nn (local.get $n))
    (local.set $ll (local.get $len))
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

With pending changes for LICM
(https://github.com/CraneStation/cranelift/pull/727) performance is on
par with Ion.  The cranelift code still has too many spurious MOVs in
it and slightly higher register pressure and that will hurt it
eventually, but on this benchmark it doesn't matter.


## Analysis 2019-04-05

The Ion code (see below) is very good, the only thing one could do
here is to tile the loop so that interrupt checks are not executed on
every iteration, and then unroll the inner loop.

The Cranelift code is not bad, but it has several weaknesses:

* interrupt checks are load-compare instruction pairs instead of compare-with-memory
* there are three obviously redundant MOVs at the inner loop head
* it loads the heap pointer from the tls on every iteration instead of hoisting the loaded value, even though there should be plenty of registers available for this
* before making a heap reference it MOVs the index value into a temp register instead of using the register the index value is already in
* it manipulates the stack pointer for unknown reasons and then does not use the frame, this looks like frame alignment that ion does not think it necessary to do

With regards to reloading the heap pointer, Cranelift's LICM considers
loads trivially unsafe.  The load of the heap pointer is flagged as
readonly + nontrapping when it's created yet licm does not look at
that.


### Cranelift code

```
00000000  41 83 fa 6f               cmp $0x6F, %r10d
00000004  0f 84 06 00 00 00         jz 0x0000000000000010
0000000A  0f 0b                     ud2
0000000C  0f 1f 40 00               nopl %eax, (%rax)

00000010  41 56                     push %r14
00000012  55                        push %rbp
00000013  48 8b ec                  mov %rsp, %rbp
00000016  48 83 ec 08               sub $0x08, %rsp // Extra push
0000001A  66 0f 57 c0               xorpd %xmm0, %xmm0
0000001E  b8 e8 03 00 00            mov $0x3E8, %eax
00000023  89 d1                     mov %edx, %ecx
00000025  89 f3                     mov %esi, %ebx
00000027  41 89 f8                  mov %edi, %r8d

;; Outer loop
0000002A  89 d2                     mov %edx, %edx  // Redundant
0000002C  89 f6                     mov %esi, %esi  //  reg-reg
0000002E  89 ff                     mov %edi, %edi  //    moves
00000030  4d 8b 4e 30               movq 0x30(%r14), %r9  // Load+cmp instead of cmpmem
00000034  49 83 f9 00               cmp $0x00, %r9
00000038  74 02                     jz 0x000000000000003C
0000003A  0f 0b                     ud2

0000003C  85 c9                     test %ecx, %ecx
0000003E  74 37                     jz 0x0000000000000077

;; Inner loop
00000040  4d 8b 4e 30               movq 0x30(%r14), %r9  // Load+cmp instead of cmpmem
00000044  49 83 f9 00               cmp $0x00, %r9
00000048  74 02                     jz 0x000000000000004C
0000004A  0f 0b                     ud2

;; Inner loop body
0000004C  45 89 c1                  mov %r8d, %r9d        // redundant move
0000004F  4d 8b 16                  movq (%r14), %r10     // load heap ptr - not hoisted
00000052  f2 43 0f 10 0c 0a         movsdq (%r10,%r9,1), %xmm1 // load from mem
00000058  41 89 d9                  mov %ebx, %r9d        // redundant move
0000005B  f2 43 0f 10 14 0a         movsdq (%r10,%r9,1), %xmm2 // load from mem
00000061  f2 0f 59 ca               mulsd %xmm2, %xmm1
00000065  f2 0f 58 c1               addsd %xmm1, %xmm0
00000069  41 83 c0 08               add $0x08, %r8d
0000006D  83 c3 08                  add $0x08, %ebx
00000070  83 c1 ff                  add $-0x01, %ecx
00000073  85 c9                     test %ecx, %ecx
00000075  75 c9                     jnz 0x0000000000000040 ;; inner loop

00000077  83 c0 ff                  add $-0x01, %eax
0000007A  89 d1                     mov %edx, %ecx
0000007C  89 f3                     mov %esi, %ebx
0000007E  41 89 f8                  mov %edi, %r8d
00000081  85 c0                     test %eax, %eax
00000083  75 a5                     jnz 0x000000000000002A ;; outer loop

;; Epilogue
00000085  4c 8b 74 24 10            movq 0x10(%rsp), %r14  // redundant 
0000008A  4d 8b 3e                  movq (%r14), %r15      //   restore heap reg
0000008D  48 83 c4 08               add $0x08, %rsp
00000091  5d                        pop %rbp
00000092  41 5e                     pop %r14
00000094  c3                        ret
```

### Ion code

```
cmpl       $0x6f, %r10d
je         .Lfrom10
ud2

.set .Lfrom10
push       %r14
push       %rbp
movq       %rsp, %rbp
xorpd      %xmm0, %xmm0
movl       $0x3e8, %eax

;; Outer loop
.set .Llabel31
cmpl       $0x0, 0x30(%r14)
je         .Lfrom42
ud2

.set .Lfrom42
testl      %edx, %edx
je         .Lfrom52

movl       %edx, %ebx
movl       %esi, %ecx
movl       %edi, %r8d

;; Inner loop
.set .Llabel59
cmpl       $0x0, 0x30(%r14)
je         .Lfrom70
ud2

;; Inner loop body
.set .Lfrom70
movsd      0x0(%r15,%r8,1), %xmm1
movsd      0x0(%r15,%rcx,1), %xmm2
mulsd      %xmm2, %xmm1
addsd      %xmm1, %xmm0
addl       $8, %r8d
addl       $8, %ecx
subl       $1, %ebx
testl      %ebx, %ebx
jne        .Llabel59

.set .Lfrom52
subl       $1, %eax
testl      %eax, %eax
jne        .Llabel31

;; Epilogue
pop        %rbp
pop        %r14
ret
```

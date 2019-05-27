# The idiv test

## Source

```
      (func $loop (export "dot") (param $m1 i32) (param $m2 i32) (param $m3 i32) (result i32)
        (local $k1 i32)
        (local $k3 i32)
        (local $k5 i32)
        (local.set $k1 (i32.const 1))
        (local.set $k3 (i32.const 3))
        (local.set $k5 (i32.const 5))
        (i32.add (i32.add (i32.div_u (local.get $k1) (local.get $m1))
                          (i32.div_u (local.get $k3) (local.get $m2)))
                 (i32.div_u (local.get $k5) (local.get $m3)))))
```

## Cranelift machine code in Spidermonkey

We see that fairly trivial rematerialization would do a lot to clean this code
up, but even ignoring that there's a fair amount of pointless shuffling here.
Some could be redundant sign extension instructions.

I'm also surprised to see explicit division-by-zero tests.  We should be able
to capture SIGFP and inspect the faulting instruction on most interesting
platforms.  It may be that division is so rare or so expensive that it doesn't
matter.  And the traps won't affect the SSA form.

```
;; Initially edi = m1, esi = m2, edx = m3
0000001A  b8 00 00 00 00            mov $0x00, %eax        ; eax = 0
0000001F  b9 01 00 00 00            mov $0x01, %ecx        ; ecx = 1
00000024  bb 03 00 00 00            mov $0x03, %ebx        ; ebx = 3
00000029  41 b8 05 00 00 00         mov $0x05, %r8d        ; r8 = 5
0000002F  83 ff 00                  cmp $0x00, %edi        ; check m1 != 0
00000032  75 02                     jnz 0x0000000000000036
00000034  0f 0b                     ud2
00000036  41 89 c1                  mov %eax, %r9d         ; r9 = 0
00000039  41 89 d2                  mov %edx, %r10d        ; save m3
0000003C  44 89 ca                  mov %r9d, %edx         ; edx = 0
0000003F  41 89 c1                  mov %eax, %r9d         ; r9 = 0 just to be sure
00000042  40 89 c8                  mov %ecx, %eax         ; setup k1
00000045  44 89 d1                  mov %r10d, %ecx        ; m3 now in ecx
00000048  f7 f7                     div %edi               ; (edx, eax) <- edx:eax divrem edi
0000004A  83 fe 00                  cmp $0x00, %esi        ; check m2 != 0
0000004D  75 02                     jnz 0x0000000000000051
0000004F  0f 0b                     ud2
00000051  44 89 ca                  mov %r9d, %edx         ; edx = 0
00000054  40 89 c7                  mov %eax, %edi         ; save sum
00000057  40 89 d8                  mov %ebx, %eax         ; setup k2
0000005A  40 89 fb                  mov %edi, %ebx         ; move sum around a bit
0000005D  f7 f6                     div %esi               ; (edx, eax) <- edx:eax divrem esi
0000005F  01 c3                     add %eax, %ebx         ; incorporate in sum
00000061  83 f9 00                  cmp $0x00, %ecx        ; check m3 != 0
00000064  75 02                     jnz 0x0000000000000068
00000066  0f 0b                     ud2
00000068  44 89 c0                  mov %r8d, %eax         ; setup k3
0000006B  44 89 ca                  mov %r9d, %edx         ; edx = 0
0000006E  f7 f1                     div %ecx               ; (edx, eax) <- edx:eax divrem ecx
00000070  01 c3                     add %eax, %ebx         ; incorporate in sum
00000072  89 d8                     mov %ebx, %eax         ;  and move/signextend
```


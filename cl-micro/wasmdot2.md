# Cranelift behavior on double-loop double-function dot product

This behaves roughly the same in Ion and Cranelift as wasmdot.js, so
no separate analysis here.  Without the LICM changes brought on by
wasmdot.js, wasmdot2.js is slightly slower than wasmdot.js in
Cranelift, but it's not clear why that should be.

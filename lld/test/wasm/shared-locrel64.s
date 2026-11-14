## Location-relative data relocations (R_WASM_MEMORY_ADDR_LOCREL_I32/I64, used
## for example by Swift's relative pointers) between two locations in the same
## module are position-independent: the value written at link time holds
## wherever the module is loaded, so no runtime relocation is generated for
## them, whether the target is hidden or exported.  An absolute address
## (R_WASM_MEMORY_ADDR_I64) still gets one.

# RUN: llvm-mc -filetype=obj -triple=wasm64-unknown-unknown -o %t.o %s
# RUN: wasm-ld -mwasm64 --experimental-pic -shared -o %t.wasm %t.o
# RUN: obj2yaml %t.wasm | FileCheck %s
# RUN: llvm-objdump --disassemble-symbols=__wasm_apply_data_relocs --no-show-raw-insn --no-leading-addr %t.wasm | FileCheck %s --check-prefixes DIS

.section .data.hidden_target,"",@
.globl hidden_target
.hidden hidden_target
.p2align 2
hidden_target:
  .int32 1
  .size hidden_target, 4

.section .data.exported_target,"",@
.globl exported_target
.p2align 2
exported_target:
  .int32 2
  .size exported_target, 4

.section .data.pointers,"",@
.globl pointers
.p2align 3
pointers:
  .int32 hidden_target - pointers
  .int32 exported_target - (pointers + 4)
  .int64 hidden_target - (pointers + 8)
  .int64 exported_target - (pointers + 16)
  .int64 hidden_target
  .size pointers, 32

## hidden_target is at 0, exported_target at 4 and pointers at 8, so the
## relative pointers are 0 - 8, 4 - 12, 0 - 16 and 4 - 24.  The absolute
## pointer is 0 until __wasm_apply_data_relocs adds __memory_base to it.
# CHECK:      - Type:            DATA
# CHECK:          Content:         0100000002000000F8FFFFFFF8FFFFFFF0FFFFFFFFFFFFFFECFFFFFFFFFFFFFF0000000000000000

## Only the absolute pointer, at 32, is relocated at load time.
# DIS:      <__wasm_apply_data_relocs>:
# DIS-EMPTY:
# DIS-NEXT:   i64.const 32
# DIS-NEXT:   global.get 0
# DIS-NEXT:   i64.add
# DIS-NEXT:   global.get 0
# DIS-NEXT:   i64.const 0
# DIS-NEXT:   i64.add
# DIS-NEXT:   i64.store 0
# DIS-NEXT:   end

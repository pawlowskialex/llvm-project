# Location-relative data relocations (R_WASM_MEMORY_ADDR_LOCREL_I32, which
# Swift emits for its relative pointers) are position-independent: in a shared
# library their link-time value holds wherever the library is loaded, so no
# runtime relocation may be generated for them, whether the target is hidden
# or exported. An absolute address (R_WASM_MEMORY_ADDR_I32) still gets one.

# RUN: llvm-mc -filetype=obj -triple=wasm32-unknown-unknown -o %t.o %s
# RUN: wasm-ld --experimental-pic -shared -o %t.wasm %t.o
# RUN: obj2yaml %t.wasm | FileCheck %s
# RUN: llvm-objdump --disassemble-symbols=__wasm_apply_data_relocs --no-show-raw-insn --no-leading-addr %t.wasm | FileCheck %s --check-prefixes DIS

.globaltype __memory_base, i32, immutable

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
.p2align 2
pointers:
  .int32 hidden_target - pointers
  .int32 exported_target - (pointers + 4)
  .int32 hidden_target
  .size pointers, 12

# hidden_target at 0, exported_target at 4, pointers at 8: the relative
# pointers are 0 - 8 and 4 - 12, written at link time; the absolute one is 0
# until __wasm_apply_data_relocs adds __memory_base.
# CHECK:        - Type:            DATA
# CHECK:            Content:         0100000002000000F8FFFFFFF8FFFFFF00000000

# Only the absolute pointer, at 16, is relocated at load.
# DIS:      <__wasm_apply_data_relocs>:
# DIS-EMPTY:
# DIS-NEXT:   i32.const 16
# DIS-NEXT:   global.get 0
# DIS-NEXT:   i32.add
# DIS-NEXT:   global.get 0
# DIS-NEXT:   i32.const 0
# DIS-NEXT:   i32.add
# DIS-NEXT:   i32.store 0
# DIS-NEXT:   end

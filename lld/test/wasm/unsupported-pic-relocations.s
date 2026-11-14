# RUN: llvm-mc -filetype=obj -triple=wasm32-unknown-unknown -o %t.o %s

# RUN: not wasm-ld -shared %t.o -o /dev/null 2>&1 | \
# RUN:   FileCheck %s

# RUN: not wasm-ld -shared %t.o -o /dev/null  --unresolved-symbols=report-all 2>&1 | \
# RUN:   FileCheck %s

# RUN: not wasm-ld -shared %t.o -o /dev/null  --warn-unresolved-symbols 2>&1 | \
# RUN:   FileCheck %s

# RUN: not wasm-ld -shared %t.o -o /dev/null  --unresolved-symbols=ignore-all 2>&1 | \
# RUN:   FileCheck %s

# RUN: not wasm-ld -shared %t.o -o /dev/null  --unresolved-symbols=import-dynamic 2>&1 | \
# RUN:   FileCheck %s

## These errors should not be reported under -r/--relocation (i.e. when
## generating an object file)
# RUN: wasm-ld -r %t.o -o /dev/null

.functype external_func () -> ()

use_undefined_function:
    .functype use_undefined_function () -> ()
    i32.const external_func@TBREL
    # CHECK: error: {{.*}}.o: relocation R_WASM_TABLE_INDEX_REL_SLEB is not supported against an undefined symbol `external_func`
    drop
    end_function

use_undefined_data:
    .functype use_undefined_data () -> ()
    i32.const external_data@MBREL
    # CHECK: error: {{.*}}.o: relocation R_WASM_MEMORY_ADDR_REL_SLEB is not supported against an undefined symbol `external_data`
    drop
    end_function

.globl _start
_start:
    .functype _start () -> ()
    call use_undefined_function
    call use_undefined_data
    end_function

## Location-relative relocations are resolved at link time, which requires
## their target to be defined in the module.
.section .data.locrel,"",@
.globl locrel
locrel:
  .int32 external_data - locrel
  # CHECK: error: {{.*}}.o: relocation R_WASM_MEMORY_ADDR_LOCREL_I32 cannot be used against symbol `external_data` which is not defined in this module
  .int64 external_data - (locrel + 4)
  # CHECK: error: {{.*}}.o: relocation R_WASM_MEMORY_ADDR_LOCREL_I64 cannot be used against symbol `external_data` which is not defined in this module
  .size locrel, 12

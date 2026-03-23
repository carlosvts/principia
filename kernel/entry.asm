; entry.asm — kernel entry point
;
; Limine hands control here already in 64-bit long mode, with interrupts
; disabled. Our only job: set up a valid stack, then jump into C.

bits 64
section .text

global _start
extern kernel_main

_start:
    ; Point rsp to the top of our reserved stack region.
    ; x86 stacks grow downward, so we start at the top.
    mov rsp, stack_top

    ; Align rsp to 16 bytes. The System V AMD64 ABI requires this
    ; before any call, so gcc-generated code doesn't break.
    and rsp, -16

    ; Hand off to C. Everything from here lives in kernel.c.
    call kernel_main

    ; kernel_main should never return (it has while(1)).
    ; If it does, halt the CPU. hlt waits for the next interrupt;
    ; the loop re-halts in case one fires.
.hang:
    cli ; disable interrupts defensively before halting (hlt)
    hlt
    jmp .hang


section .bss

; 16 KiB stack. .bss is zero-initialized and takes no space on disk.
align 16
stack_bottom:
    resb 16384
stack_top:







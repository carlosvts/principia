/* principia/linker.ld */

ENTRY(_start)

SECTIONS
{
    . = 0xFFFFFFFF80000000;

    .requests_start_marker : { *(.requests_start_marker) }
    .requests : { *(.requests) }
    .requests_end_marker : { *(.requests_end_marker) }

    .text BLOCK(4K) : ALIGN(4K) { *(.text*) }
    .rodata BLOCK(4K) : ALIGN(4K) { *(.rodata*) }
    .data BLOCK(4K) : ALIGN(4K) { *(.data*) }
    .bss BLOCK(4K) : ALIGN(4K)
    {
        *(COMMON)
        *(.bss*)
    }
}

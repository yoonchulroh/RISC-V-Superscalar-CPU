OUTPUT_ARCH(riscv)
ENTRY(_start)

INCLUDE "constants.ld"

SECTIONS
{
    . = 0x0;

    .text : {
        start.o(.text)
        . = TRAP_START;
        trap.o(.text)
        *(EXCLUDE_FILE(*terminate.o *trap.o *start.o *main.o) .text)
        . = PROGRAM_START;
        main.o(.text)
        terminate.o(.text)
    }
}
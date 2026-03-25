.include "constants.S"

.globl terminate_program

.text
terminate_program:
    .insn r 0x0B, 0, 0, x0, x0, x0
    
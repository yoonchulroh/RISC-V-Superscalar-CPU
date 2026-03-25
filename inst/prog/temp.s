.text
    .globl _start

_start:
    li t0, MTIMECMP_ADDRESS
    li t1, 1000
    sw t1, 0(t0)

loop:
    nop
    nop
    nop
    nop
    nop
    nop
    li a0, 10
    ecall
    jal x0, loop

fail:

done:

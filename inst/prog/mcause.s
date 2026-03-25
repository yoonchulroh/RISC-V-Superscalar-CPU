# RV32I_zicsr program to test mcause register
# 1. First ecall (triggers exception, mcause gets set)
# 2. Save mcause value to a0
# 3. Second ecall (prints mcause value)

.section .text
.globl _start

_start:
    # First ecall - this will set mcause to environment call exception code
    ecall

    # Read mcause into a0
    csrr    a0, mcause

    # Second ecall - prints the value of a0 (mcause)
    ecall

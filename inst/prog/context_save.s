# RV32IMA_zicsr context save test program
# Tests if all register values (x1-x31) are preserved before and after ecall
# Strategy: set xi = i, ecall, then verify each xi == i
# If xi != i, set a0 = i and ecall to report the failing register
# If all preserved, set a0 = 0 and ecall

.section .text
.globl _start

_start:
    # Load value i into register xi for all x1-x31
    li x1,  1
    li x2,  2
    li x3,  3
    li x4,  4
    li x5,  5
    li x6,  6
    li x7,  7
    li x8,  8
    li x9,  9
    li x10, 10
    li x11, 11
    li x12, 12
    li x13, 13
    li x14, 14
    li x15, 15
    li x16, 16
    li x17, 17
    li x18, 18
    li x19, 19
    li x20, 20
    li x21, 21
    li x22, 22
    li x23, 23
    li x24, 24
    li x25, 25
    li x26, 26
    li x27, 27
    li x28, 28
    li x29, 29
    li x30, 30
    li x31, 31

    li t0, MTIMECMP_ADDRESS
    sw t1, 0(t0)
    li t0, 5

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    # After ecall, verify each register xi still holds value i
    # Use addi xi, xi, -i to check: if xi == i, result is 0
    # Compare against x0 (always 0). This destroys the register value,
    # but we check each register only once.

    # Check x1 (ra)
    addi x1, x1, -1
    bne x1, x0, fail_1

    # Check x2 (sp)
    addi x2, x2, -2
    bne x2, x0, fail_2

    # Check x3 (gp)
    addi x3, x3, -3
    bne x3, x0, fail_3

    # Check x4 (tp)
    addi x4, x4, -4
    bne x4, x0, fail_4

    # Check x5 (t0)
    addi x5, x5, -5
    bne x5, x0, fail_5

    # Check x6 (t1)
    addi x6, x6, -6
    bne x6, x0, fail_6

    # Check x7 (t2)
    addi x7, x7, -7
    bne x7, x0, fail_7

    # Check x8 (s0)
    addi x8, x8, -8
    bne x8, x0, fail_8

    # Check x9 (s1)
    addi x9, x9, -9
    bne x9, x0, fail_9

    # Check x10 (a0)
    addi x10, x10, -10
    bne x10, x0, fail_10

    # Check x11 (a1)
    addi x11, x11, -11
    bne x11, x0, fail_11

    # Check x12 (a2)
    addi x12, x12, -12
    bne x12, x0, fail_12

    # Check x13 (a3)
    addi x13, x13, -13
    bne x13, x0, fail_13

    # Check x14 (a4)
    addi x14, x14, -14
    bne x14, x0, fail_14

    # Check x15 (a5)
    addi x15, x15, -15
    bne x15, x0, fail_15

    # Check x16 (a6)
    addi x16, x16, -16
    bne x16, x0, fail_16

    # Check x17 (a7)
    addi x17, x17, -17
    bne x17, x0, fail_17

    # Check x18 (s2)
    addi x18, x18, -18
    bne x18, x0, fail_18

    # Check x19 (s3)
    addi x19, x19, -19
    bne x19, x0, fail_19

    # Check x20 (s4)
    addi x20, x20, -20
    bne x20, x0, fail_20

    # Check x21 (s5)
    addi x21, x21, -21
    bne x21, x0, fail_21

    # Check x22 (s6)
    addi x22, x22, -22
    bne x22, x0, fail_22

    # Check x23 (s7)
    addi x23, x23, -23
    bne x23, x0, fail_23

    # Check x24 (s8)
    addi x24, x24, -24
    bne x24, x0, fail_24

    # Check x25 (s9)
    addi x25, x25, -25
    bne x25, x0, fail_25

    # Check x26 (s10)
    addi x26, x26, -26
    bne x26, x0, fail_26

    # Check x27 (s11)
    addi x27, x27, -27
    bne x27, x0, fail_27

    # Check x28 (t3)
    addi x28, x28, -28
    bne x28, x0, fail_28

    # Check x29 (t4)
    addi x29, x29, -29
    bne x29, x0, fail_29

    # Check x30 (t5)
    addi x30, x30, -30
    bne x30, x0, fail_30

    # Check x31 (t6)
    addi x31, x31, -31
    bne x31, x0, fail_31

    # All registers preserved! Report success
    li a0, 0
    ecall
    jal success

fail_1:
    li a0, 1
    ecall

fail_2:
    li a0, 2
    ecall

fail_3:
    li a0, 3
    ecall

fail_4:
    li a0, 4
    ecall

fail_5:
    li a0, 5
    ecall

fail_6:
    li a0, 6
    ecall

fail_7:
    li a0, 7
    ecall

fail_8:
    li a0, 8
    ecall

fail_9:
    li a0, 9
    ecall

fail_10:
    li a0, 10
    ecall

fail_11:
    li a0, 11
    ecall

fail_12:
    li a0, 12
    ecall

fail_13:
    li a0, 13
    ecall

fail_14:
    li a0, 14
    ecall

fail_15:
    li a0, 15
    ecall

fail_16:
    li a0, 16
    ecall

fail_17:
    li a0, 17
    ecall

fail_18:
    li a0, 18
    ecall

fail_19:
    li a0, 19
    ecall

fail_20:
    li a0, 20
    ecall

fail_21:
    li a0, 21
    ecall

fail_22:
    li a0, 22
    ecall

fail_23:
    li a0, 23
    ecall

fail_24:
    li a0, 24
    ecall

fail_25:
    li a0, 25
    ecall

fail_26:
    li a0, 26
    ecall

fail_27:
    li a0, 27
    ecall

fail_28:
    li a0, 28
    ecall

fail_29:
    li a0, 29
    ecall

fail_30:
    li a0, 30
    ecall

fail_31:
    li a0, 31
    ecall

success:

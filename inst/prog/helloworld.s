# RV32IMA_zicsr Hello World program
# Writes the ASCII values of "Hello World!\n" to the stack
# without overwriting the current stack contents.

.include "ASCII.S"

.section .text
.globl _start

_start:
    # Allocate 16 bytes on the stack (13 chars needed, aligned to 4)
    addi sp, sp, -16

    # Store each character of "Hello World!\n" using ASCII.S constants

    # 'H'
    li t0, H
    sb t0, 0(sp)

    # 'e'
    li t0, e
    sb t0, 1(sp)

    # 'l'
    li t0, l
    sb t0, 2(sp)

    # 'l'
    li t0, l
    sb t0, 3(sp)

    # 'o'
    li t0, o
    sb t0, 4(sp)

    # ' ' (space)
    li t0, SPACE
    sb t0, 5(sp)

    # 'W'
    li t0, W
    sb t0, 6(sp)

    # 'o'
    li t0, o
    sb t0, 7(sp)

    # 'r'
    li t0, r
    sb t0, 8(sp)

    # 'l'
    li t0, l
    sb t0, 9(sp)

    # 'd'
    li t0, d
    sb t0, 10(sp)

    # '!'
    li t0, EXCLAMATION
    sb t0, 11(sp)

    # '\n' (newline)
    li t0, LF
    sb t0, 12(sp)

    add a0, sp, zero
    li a1, 13
    jal print_string
    
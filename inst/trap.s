.include "constants.S"

.text
.section .text

context_save:
    csrrw sp, mscratch, sp # swap kernel_sp and sp
    addi sp, sp, -128
    sw x1,  1*4(sp)  # ra
    # x2 in mscratch
    sw x3,  3*4(sp)  # gp
    sw x4,  4*4(sp)  # tp
    sw x5,  5*4(sp)  # t0
    sw x6,  6*4(sp)  # t1
    sw x7,  7*4(sp)  # t2
    sw x8,  8*4(sp)  # s0/fp
    sw x9,  9*4(sp)  # s1
    sw x10, 10*4(sp) # a0
    sw x11, 11*4(sp) # a1
    sw x12, 12*4(sp) # a2
    sw x13, 13*4(sp) # a3
    sw x14, 14*4(sp) # a4
    sw x15, 15*4(sp) # a5
    sw x16, 16*4(sp) # a6
    sw x17, 17*4(sp) # a7
    sw x18, 18*4(sp) # s2
    sw x19, 19*4(sp) # s3
    sw x20, 20*4(sp) # s4
    sw x21, 21*4(sp) # s5
    sw x22, 22*4(sp) # s6
    sw x23, 23*4(sp) # s7
    sw x24, 24*4(sp) # s8
    sw x25, 25*4(sp) # s9
    sw x26, 26*4(sp) # s10
    sw x27, 27*4(sp) # s11
    sw x28, 28*4(sp) # t3
    sw x29, 29*4(sp) # t4
    sw x30, 30*4(sp) # t5
    sw x31, 31*4(sp) # t6

    csrr t0, mcause
    li t1, 1
    srli t2, t0, 31
    beq t1, t2, interrupt
    li t1, 11
    beq t0, t1, print
    li t1, 3
    beq t0, t1, debug
    jal error

interrupt:
    li a0, 7838
    .insn r 0x2B, 0, 0, x0, a0, x0
    li t0, MTIME_ADDRESS
    lw t1, 0(t0)
    li t2, 10000
    add t1, t1, t2
    li t0, MTIMECMP_ADDRESS
    sw t1, 0(t0)
    jal context_restore

print:
    .insn r 0x2B, 0, 0, x0, a0, x0 # print a0
    csrrw t0, mepc, x0    # Read mepc into t0
    addi t0, t0, 4        # Add 4 to t0
    csrrw x0, mepc, t0    # Write t0 back to mepc
    jal context_restore

debug:
    .insn r 0x2B, 0, 0, x0, a0, x0 # print a0
    tail terminate_program

error:
    .insn r 0x2B, 0, 0, x0, t0, x0 # print mcause
    csrr t0, mepc
    .insn r 0x2B, 0, 0, x0, t0, x0 # print mepc
    csrr t0, mtval
    .insn r 0x2B, 0, 0, x0, t0, x0 # print mtval
    tail terminate_program

context_restore:
    lw x1,  1*4(sp)
    # x2 in mscratch
    lw x3,  3*4(sp)
    lw x4,  4*4(sp)
    lw x5,  5*4(sp)
    lw x6,  6*4(sp)
    lw x7,  7*4(sp)
    lw x8,  8*4(sp)
    lw x9,  9*4(sp)
    lw x10, 10*4(sp)
    lw x11, 11*4(sp)
    lw x12, 12*4(sp)
    lw x13, 13*4(sp)
    lw x14, 14*4(sp)
    lw x15, 15*4(sp)
    lw x16, 16*4(sp)
    lw x17, 17*4(sp)
    lw x18, 18*4(sp)
    lw x19, 19*4(sp)
    lw x20, 20*4(sp)
    lw x21, 21*4(sp)
    lw x22, 22*4(sp)
    lw x23, 23*4(sp)
    lw x24, 24*4(sp)
    lw x25, 25*4(sp)
    lw x26, 26*4(sp)
    lw x27, 27*4(sp)
    lw x28, 28*4(sp)
    lw x29, 29*4(sp)
    lw x30, 30*4(sp)
    lw x31, 31*4(sp)
    addi sp, sp, 128
    csrrw sp, mscratch, sp # swap kernel_sp and sp
    mret
    
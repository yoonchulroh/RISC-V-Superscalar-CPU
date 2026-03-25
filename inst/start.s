.include "constants.S"

.text
    li t0, INITIAL_MSTATUS # MPIE = 1, MIE = 0
    csrrw x0, mstatus, t0 # set mstatus

    li t0, 128 # MTIE = 1
    csrrw x0, mie, t0 # set mie

    li t0, TRAP_START # start of interrupt
    csrrw x0, mtvec, t0 # set mtvec to the start of interrupt

    li t0, MTIME_ADDRESS
    sw zero, 0(t0) # set mtime to 0

    li t0, PROGRAM_START
    csrrw x0, mepc, t0 # set mepc to the start of main program

    li sp, INITIAL_SP # set sp to INITIAL_SP
    li t0, INITIAL_KSP
    csrrw x0, mscratch, t0 # set mscratch to INITIAL_KSP
    
    mret # jump to main program, and set MIE to 1

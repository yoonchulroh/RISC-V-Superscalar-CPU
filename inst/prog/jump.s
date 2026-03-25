# File: inst/prog/jump.s
# Description: Test Next PC prediction accuracy for Unconditional Jumps (JAL).
#              Executes a JAL loop multiple times to allow predictor training.

    .section .text
    .globl _start

_start:
    # ---------------------------------------------------------
    # Setup
    # ---------------------------------------------------------
    addi    a0, x0, 0       # a0 = 0 (Accumulator/Result)
    addi    t0, x0, 2000    # t0 = 2000 (Loop counter)
    addi    t1, x0, 1       # t1 = 1 (Decrement value)

    # ---------------------------------------------------------
    # Jump Prediction Test Loop
    # We use JAL (Jump And Link) to jump back to 'loop_start'.
    # This tests if the CPU correctly predicts the target of
    # a repeated unconditional jump.
    # ---------------------------------------------------------
loop_start:
    add     a0, a0, t1      # Increment result a0 by 1
    sub     t0, t0, t1      # Decrement loop counter t0
    
    # Check if loop is finished. 
    # If t0 == 0, skip the JAL and go to padding/exit.
    # We use a branch here to exit, but the main test is the JAL below.
    beq     t0, x0, test_done 

    # The Jump to be predicted:
    # Jumps to 'loop_start'. x0 is used as link register (discard return addr).
    jal     x0, loop_start  

test_done:
    # ---------------------------------------------------------
    # Completion
    # ---------------------------------------------------------
    # The result in a0 should be 2000 (0x7D0) if executed correctly.

    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0
    
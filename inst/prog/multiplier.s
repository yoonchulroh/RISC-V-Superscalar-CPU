  .text
  .align 2       # Make sure we're aligned to 4 bytes
  .globl _start

_start:
    # 1. Initialize Registers
    li t0, 156           # Load immediate 11 into t0 (Multiplicand)
    li t1, 4325           # Load immediate 14 into t1 (Multiplier / Counter)
    li a0, 0            # Initialize result register a0 to 0

loop:
    # 2. Check Loop Condition
    beq t1, zero, done  # If t1 == 0, break the loop and go to 'done'

    # 3. Perform Addition (The "Continuous Addition" step)
    add a0, a0, t0      # a0 = a0 + t0

    # 4. Decrement Counter
    addi t1, t1, -1     # t1 = t1 - 1

    # 5. Jump back to start of loop
    j loop              # Unconditional jump to 'loop'

done:
.insn r 0x2B, 0, 0, x0, a0, x0 # Print a0

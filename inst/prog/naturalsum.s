# -------------------------------------------------------------------
# RV32I Core Test
# Goal: Calculate Sum(1..5) = 15 (0xF)
# Result: Stored in x10
# -------------------------------------------------------------------

.global _start

_start:
    # 1. INITIALIZATION
    # We cannot assume registers are zero. We must clear/init them using x0.
    addi x2, x0, 80      # Initialize Stack Pointer (sp) to address 80
    addi x10, x0, 1000      # Set argument n = 5 in argument register (a0)

    # 2. FUNCTION CALL
    jal x1, sum_func     # Jump and Link: Call sum_func, save return addr in x1 (ra)
    beq x0, x0, stop


# -------------------------------------------------------------------
# Function: sum_func
# Input: x10 (n)
# Output: x10 (sum)
# -------------------------------------------------------------------
sum_func:
    # Prologue: Save Return Address to Stack
    # Address 80 is used here (which is < 100)
    sw x1, 0(x2)         # Store contents of x1 (ra) to memory at address in x2
    addi x2, x2, -4      # Move stack pointer down to 76

    # Initialize Loop Variables
    addi x5, x0, 0       # x5 (t0) will be our accumulator (sum = 0)
    addi x6, x0, 16      # x6 (t1) holds a memory address for testing (address 16)

loop:
    # Memory Access Test
    # We store the partial sum to memory address 16, then load it back.
    # This verifies load/store logic works at low addresses.
    sw x5, 0(x6)         # Store current sum to [address 16]
    lw x7, 0(x6)         # Load it back into x7 (t2) to verify data path

    # Arithmetic Logic
    add x5, x5, x10      # sum (x5) = sum (x5) + n (x10)
    addi x10, x10, -1    # n (x10) = n (x10) - 1

    # Loop Control
    bne x10, x0, loop    # If n != 0, jump back to 'loop'

    # Epilogue: Restore Return Address
    addi x2, x2, 4       # Move stack pointer back to 80
    lw x1, 0(x2)         # Load original return address from memory

    # Prepare Result
    addi x10, x5, 0      # Move final sum from x5 to result register x10
    jalr x0, 0(x1)       # Return to caller

stop:
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0

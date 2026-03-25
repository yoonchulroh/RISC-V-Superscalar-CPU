  .text
  .align 2       # Make sure we're aligned to 4 bytes
  .globl _start
_start:
    # 1. Initialize values
    li t0, 145990       # Load immediate 144 into register t0 (Dividend)
    li t1, 12        # Load immediate 12 into register t1  (Divisor)
    li a0, 0         # Initialize a0 (Quotient) to 0
    
    # Safety check: Avoid infinite loop if dividing by zero
    beq t1, zero, end_program

division_loop:
    # 2. Check condition: Is dividend < divisor?
    # If t0 is less than t1, we cannot subtract anymore.
    # The current value in t0 would be the 'remainder'.
    blt t0, t1, end_program

    # 3. Perform subtraction
    sub t0, t0, t1   # t0 = t0 - t1 (Remaining Dividend)
    
    # 4. Increment quotient
    addi a0, a0, 1   # a0 = a0 + 1
    
    # 5. Repeat
    j division_loop

end_program:
    # Result floor(144/12) = 12 is now stored in register a0.
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0
    
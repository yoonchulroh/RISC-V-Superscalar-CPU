.text
.align 2       # Make sure we're aligned to 4 bytes

.globl _start

# -------------------------------------------------------------------
# Function: fibonacci
# Input:    a0 (n - the index of the Fibonacci number to compute)
# Output:   a0 (The nth Fibonacci number)
# -------------------------------------------------------------------

_start:
    addi a0, zero, 40
    # Base Case Check: If n <= 1, the result is just n (Fib(0)=0, Fib(1)=1)
    li      t0, 1           # Load immediate 1 into t0 for comparison
    ble     a0, t0, finish  # If a0 <= 1, jump to 'finish' (result is already in a0)

    # Initialization
    mv      t0, a0          # Move n to t0 to use as a loop counter
    addi    t0, t0, -1      # We loop (n-1) times
    li      t1, 0           # t1 = Fib(i-1) (Initially Fib(0) = 0)
    li      a0, 1           # a0 = Fib(i)   (Initially Fib(1) = 1) - this will hold result

loop:
    beqz    t0, finish      # If counter is 0, we are done
    
    # Calculate next Fibonacci number
    add     t2, t1, a0      # t2 = t1 + a0 (next = prev + curr)
    
    # Shift values for next iteration
    mv      t1, a0          # prev = curr
    mv      a0, t2          # curr = next (Update result register)
    
    # Decrement loop counter
    addi    t0, t0, -1      
    j       loop            # Jump back to start of loop

finish:
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0

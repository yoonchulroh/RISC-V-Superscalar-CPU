# gshare.s - Test cases demonstrating gshare branch predictor advantages
# These patterns show correlated branches where global history helps prediction
# a0 = 0 if all tests pass, 1 otherwise
# Strictly RV32I only (no M extension)

.text
.globl _start

_start:
    # Initialize registers
    li a0, 0            # Result register (0 = pass)
    li t0, 0            # Counter
    li t1, 0            # Temp
    li t2, 0            # Temp
    li t3, 0            # Expected value
    li t4, 0            # Actual value
    li t5, 0            # Loop counter
    li t6, 0            # Temp

    # =========================================================================
    # TEST 1: Correlated Branch Pattern
    # Pattern: if (cond1) then branch2 is always taken
    # Gshare learns: after branch1 taken, branch2 is taken
    # Without history: branch2 appears random (50% taken)
    # =========================================================================
test1:
    li t0, 0            # Counter for correct predictions
    li t5, 16           # Number of iterations
    li t1, 0            # i = 0

test1_loop:
    andi t2, t1, 1      # t2 = i % 2
    beqz t2, test1_skip1 # Branch 1: skip if i is even
    
    # i is odd - this path taken when branch1 NOT taken
    addi t0, t0, 1      # Increment counter
    j test1_branch2
    
test1_skip1:
    # i is even - this path taken when branch1 taken
    nop                 # Do nothing

test1_branch2:
    andi t2, t1, 1      # t2 = i % 2 (same condition)
    beqz t2, test1_skip2 # Branch 2: CORRELATED with branch 1!
    
    # Gshare knows: if branch1 was not taken, branch2 won't be taken
    addi t0, t0, 1
    j test1_next
    
test1_skip2:
    nop

test1_next:
    addi t1, t1, 1      # i++
    blt t1, t5, test1_loop
    
    # t0 should be 16 (8 iterations * 2 increments when odd)
    li t3, 16
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 2: Alternating Nested Loop Pattern
    # Outer loop controls inner loop direction
    # Gshare learns: outer loop state predicts inner loop behavior
    # =========================================================================
test2:
    li t0, 0            # Result accumulator
    li t5, 8            # Outer loop count
    li t1, 0            # Outer counter

test2_outer:
    andi t2, t1, 1      # t2 = outer_i % 2
    li t6, 4            # Inner loop count
    li t3, 0            # Inner counter
    
    beqz t2, test2_inner_type_a  # Branch based on outer loop parity
    j test2_inner_type_b

test2_inner_type_a:
    # Type A: count up pattern
test2_inner_a_loop:
    addi t0, t0, 1
    addi t3, t3, 1
    blt t3, t6, test2_inner_a_loop  # Gshare: knows this follows type A path
    j test2_outer_next

test2_inner_type_b:
    # Type B: count down pattern
test2_inner_b_loop:
    addi t0, t0, 2
    addi t3, t3, 1
    blt t3, t6, test2_inner_b_loop  # Gshare: knows this follows type B path
    j test2_outer_next

test2_outer_next:
    addi t1, t1, 1
    blt t1, t5, test2_outer
    
    # 4 even outer (type A): 4 * 4 * 1 = 16
    # 4 odd outer (type B): 4 * 4 * 2 = 32
    # Total = 48
    li t3, 48
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 3: Diamond Pattern with History Correlation
    # Two consecutive branches that are always opposite
    # Gshare learns: B1 taken => B2 not taken, B1 not taken => B2 taken
    # Using i % 3 via subtraction
    # =========================================================================
test3:
    li t0, 0            # Counter
    li t5, 21           # Iterations (divisible by 3 for easy check)
    li t1, 0            # Loop counter

test3_loop:
    # Compute i % 3 using subtraction (result in t3)
    mv t3, t1
test3_mod3:
    li t4, 3
    blt t3, t4, test3_mod3_done
    sub t3, t3, t4
    j test3_mod3
test3_mod3_done:
    
    bnez t3, test3_b1_not_taken  # Branch 1
    
test3_b1_taken:
    # B1 was taken (i % 3 == 0)
    addi t0, t0, 1
    beqz t3, test3_after  # Branch 2: CORRELATED - if B1 taken, this is taken too
    j test3_after
    
test3_b1_not_taken:
    # B1 was not taken (i % 3 != 0)
    addi t0, t0, 2
    bnez t3, test3_after  # Branch 2: CORRELATED - if B1 not taken, this is taken
    j test3_after

test3_after:
    addi t1, t1, 1
    blt t1, t5, test3_loop
    
    # When i % 3 == 0: +1 (happens for i=0,3,6,9,12,15,18 -> 7 times)
    # When i % 3 != 0: +2 (happens 14 times)
    # Total = 7*1 + 14*2 = 7 + 28 = 35
    li t3, 35
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 4: Triple Correlated Branches
    # Three branches in sequence, all with same condition
    # Strong history correlation
    # =========================================================================
test4:
    li t0, 0
    li t5, 24           # Iterations (divisible by 4)
    li t1, 0

test4_loop:
    andi t2, t1, 3      # t2 = i % 4
    
    # Branch A
    li t3, 1
    beq t2, t3, test4_a_taken
    j test4_a_skip
test4_a_taken:
    addi t0, t0, 1
test4_a_skip:

    # Branch B - same condition, correlated!
    beq t2, t3, test4_b_taken
    j test4_b_skip
test4_b_taken:
    addi t0, t0, 1
test4_b_skip:

    # Branch C - same condition, correlated!
    beq t2, t3, test4_c_taken
    j test4_c_skip
test4_c_taken:
    addi t0, t0, 1
test4_c_skip:

    addi t1, t1, 1
    blt t1, t5, test4_loop
    
    # i % 4 == 1 happens 6 times (i=1,5,9,13,17,21)
    # Each time adds 3
    # Total = 6 * 3 = 18
    li t3, 18
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 5: Loop with Conditional Exit Pattern
    # Inner loop exit depends on outer loop state
    # =========================================================================
test5:
    li t0, 0
    li t5, 6            # Outer iterations
    li t1, 0            # Outer counter

test5_outer:
    li t3, 0            # Inner counter
    andi t4, t1, 1      # Condition based on outer

test5_inner:
    addi t0, t0, 1
    addi t3, t3, 1
    
    # Different exit condition based on outer loop
    beqz t4, test5_check_even
    
    # Odd outer: exit at 3
    li t6, 3
    blt t3, t6, test5_inner
    j test5_outer_inc
    
test5_check_even:
    # Even outer: exit at 5
    li t6, 5
    blt t3, t6, test5_inner

test5_outer_inc:
    addi t1, t1, 1
    blt t1, t5, test5_outer
    
    # Even outer (i=0,2,4): 3 * 5 = 15
    # Odd outer (i=1,3,5): 3 * 3 = 9
    # Total = 24
    li t3, 24
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 6: Zigzag Pattern - alternating branch directions
    # Pattern: T, NT, T, NT... where each depends on previous
    # =========================================================================
test6:
    li t0, 0
    li t5, 32           # Iterations
    li t1, 0            # Counter
    li t2, 0            # State (alternates)

test6_loop:
    beqz t2, test6_state0
    
test6_state1:
    addi t0, t0, 2
    li t2, 0            # Next state = 0
    j test6_next
    
test6_state0:
    addi t0, t0, 1
    li t2, 1            # Next state = 1
    
test6_next:
    addi t1, t1, 1
    blt t1, t5, test6_loop
    
    # 16 state0 (+1) + 16 state1 (+2) = 16 + 32 = 48
    li t3, 48
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 7: Multi-level Correlation
    # Branch C depends on both Branch A and Branch B outcomes
    # =========================================================================
test7:
    li t0, 0
    li t5, 16
    li t1, 0

test7_loop:
    li t2, 0            # Flags
    
    # Branch A: taken if i % 2 == 0
    andi t3, t1, 1
    bnez t3, test7_a_nt
    ori t2, t2, 1       # Set bit 0
test7_a_nt:
    
    # Branch B: taken if i % 4 < 2
    andi t3, t1, 3
    li t4, 2
    bge t3, t4, test7_b_nt
    ori t2, t2, 2       # Set bit 1
test7_b_nt:
    
    # Branch C: behavior depends on A and B (t2 value)
    # Gshare can learn: after A taken + B taken, C behaves one way
    li t4, 3            # Both A and B taken
    beq t2, t4, test7_c_both
    beqz t2, test7_c_none
    j test7_c_one
    
test7_c_both:
    addi t0, t0, 4
    j test7_next
test7_c_none:
    addi t0, t0, 1
    j test7_next
test7_c_one:
    addi t0, t0, 2
    
test7_next:
    addi t1, t1, 1
    blt t1, t5, test7_loop
    
    # i=0: A=T, B=T -> both (4)
    # i=1: A=NT, B=T -> one (2)
    # i=2: A=T, B=NT -> one (2)
    # i=3: A=NT, B=NT -> none (1)
    # Pattern repeats 4 times
    # Total = 4 * (4 + 2 + 2 + 1) = 4 * 9 = 36
    li t3, 36
    bne t0, t3, test_fail

    # =========================================================================
    # TEST 8: Sequential Dependent Branches (3-cycle pattern)
    # Using i % 3 via subtraction
    # =========================================================================
test8:
    li t0, 0
    li t5, 21           # Iterations (divisible by 3)
    li t1, 0

test8_loop:
    # Compute i % 3 using subtraction (result in t2)
    mv t2, t1
test8_mod3:
    li t3, 3
    blt t2, t3, test8_mod3_done
    sub t2, t2, t3
    j test8_mod3
test8_mod3_done:
    
    # B1: taken if pattern == 0
    bnez t2, test8_b1_nt
    addi t0, t0, 1
    j test8_b2
test8_b1_nt:
    nop
    
test8_b2:
    # B2: taken if pattern == 1 (after B1)
    li t3, 1
    bne t2, t3, test8_b2_nt
    addi t0, t0, 2
    j test8_b3
test8_b2_nt:
    nop
    
test8_b3:
    # B3: taken if pattern == 2 (after B1, B2)
    li t3, 2
    bne t2, t3, test8_b3_nt
    addi t0, t0, 3
    j test8_next
test8_b3_nt:
    nop
    
test8_next:
    addi t1, t1, 1
    blt t1, t5, test8_loop
    
    # pattern=0: 7 times, +1 each = 7
    # pattern=1: 7 times, +2 each = 14
    # pattern=2: 7 times, +3 each = 21
    # Total = 7 + 14 + 21 = 42
    li t3, 42
    bne t0, t3, test_fail

    # =========================================================================
    # All tests passed
    # =========================================================================
    li a0, 0
    j done

test_fail:
    li a0, 1

done:
    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0

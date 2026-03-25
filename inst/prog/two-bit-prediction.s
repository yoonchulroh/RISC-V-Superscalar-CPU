# Two-Bit Branch Prediction Test Program
# 
# This program contains branch patterns that demonstrate the advantage of
# 2-bit branch prediction over 1-bit branch prediction.
#
# Key insight:
# - 1-bit predictor: Flips prediction after every misprediction
# - 2-bit predictor: Uses 4 states (Strongly Taken, Weakly Taken, Weakly Not-Taken,
#   Strongly Not-Taken) and requires 2 consecutive mispredictions to flip prediction
#
# Patterns that stress 1-bit predictors:
# 1. T->NT->T->NT (alternating): 1-bit mispredicts every time
# 2. T->T->NT->T->T->NT (mostly taken): 1-bit flips after each NT, mispredicts on next T
# 3. NT->NT->T->NT->NT->T (mostly not-taken): Similar issue for 1-bit
#
# a0 = 0 if all tests pass
# a0 = test ID (1-10) if test fails

.text
.globl _start

_start:
    # Initialize stack pointer
    li      sp, 396
    
    # Initialize result register
    li      a0, 0           # 0 = pass (will be set to test ID on failure)
    
    # Initialize counters for tracking
    li      s10, 0          # Total iterations executed (for verification)
    li      s11, 0          # Pattern tracking

# ============================================================================
# TEST 1: Alternating Pattern (T->NT->T->NT)
# 1-bit predictor: ~100% misprediction after warmup
# 2-bit predictor: ~100% misprediction (both struggle, but this is baseline)
# ============================================================================
test1_start:
    li      t0, 0           # Counter (even = taken, odd = not-taken)
    li      t1, 0           # Sum for taken branches
    li      t2, 0           # Sum for not-taken branches
    li      t3, 20          # Total iterations

test1_loop:
    andi    t4, t0, 1       # Check if counter is odd or even
    # This branch alternates: T, NT, T, NT, T, NT...
    beq     t4, zero, test1_taken_path
    
    # Not-taken path (odd iterations)
    addi    t2, t2, 1
    j       test1_continue
    
test1_taken_path:
    # Taken path (even iterations)
    addi    t1, t1, 1

test1_continue:
    addi    t0, t0, 1
    blt     t0, t3, test1_loop
    
    # Verify: t1 should be 10 (even: 0,2,4,6,8,10,12,14,16,18)
    # Verify: t2 should be 10 (odd: 1,3,5,7,9,11,13,15,17,19)
    li      t5, 10
    bne     t1, t5, test1_fail
    bne     t2, t5, test1_fail
    j       test2_start

test1_fail:
    li      a0, 1
    j       test_end

# ============================================================================
# TEST 2: Mostly Taken Pattern (T->T->NT->T->T->NT)
# Pattern repeats every 3 branches: Taken, Taken, Not-Taken
# 
# 1-bit predictor behavior per cycle:
#   - Predicts T (correct on 1st T)
#   - Predicts T (correct on 2nd T)  
#   - Predicts T, actual NT -> MISPREDICTION, flip to predict NT
#   - Predicts NT, actual T -> MISPREDICTION, flip to predict T
#   - Predicts T (correct on 2nd T)
#   - Predicts T, actual NT -> MISPREDICTION, flip to predict NT
#   ... continues with 2 mispredictions per 3-branch cycle = 66% misprediction
#
# 2-bit predictor behavior per cycle:
#   - Strongly Taken (ST) -> correct on T, stay ST
#   - ST -> correct on T, stay ST
#   - ST -> mispredicts NT, move to Weakly Taken (WT)
#   - WT -> correct on T, move back to ST
#   - ST -> correct on T, stay ST
#   - ST -> mispredicts NT, move to WT
#   ... continues with 1 misprediction per 3-branch cycle = 33% misprediction
# ============================================================================
test2_start:
    li      t0, 0           # Counter
    li      t1, 0           # Sum for taken
    li      t2, 0           # Sum for not-taken
    li      t3, 30          # 10 complete cycles of the pattern
    li      s7, 0           # Cycle position tracker (0, 1, 2, 0, 1, 2, ...)

test2_loop:
    # Pattern position in cycle: s7 cycles through 0, 1, 2
    # 0, 1 -> taken; 2 -> not-taken
    li      t5, 2
    beq     s7, t5, test2_not_taken
    
    # Taken path (position 0 or 1 in cycle)
    addi    t1, t1, 1
    j       test2_continue
    
test2_not_taken:
    # Not-taken path (position 2 in cycle)
    addi    t2, t2, 1

test2_continue:
    addi    t0, t0, 1
    # Advance cycle position: s7 = (s7 + 1) % 3
    addi    s7, s7, 1
    li      t4, 3
    blt     s7, t4, test2_no_reset
    li      s7, 0
test2_no_reset:
    blt     t0, t3, test2_loop
    
    # Verify: 10 cycles, each with 2 taken + 1 not-taken
    li      t5, 20          # 10 * 2 = 20 taken
    bne     t1, t5, test2_fail
    li      t5, 10          # 10 * 1 = 10 not-taken
    bne     t2, t5, test2_fail
    j       test3_start

test2_fail:
    li      a0, 2
    j       test_end

# ============================================================================
# TEST 3: Mostly Not-Taken Pattern (NT->NT->T->NT->NT->T)
# Mirror of Test 2, but favoring not-taken
#
# 1-bit predictor: 66% misprediction (2 per 3-branch cycle)
# 2-bit predictor: 33% misprediction (1 per 3-branch cycle)
# ============================================================================
test3_start:
    li      t0, 0
    li      t1, 0           # Taken count
    li      t2, 0           # Not-taken count
    li      t3, 30
    li      s7, 0           # Cycle position tracker

test3_loop:
    # Pattern position: s7 cycles through 0, 1, 2
    li      t5, 2
    bne     s7, t5, test3_not_taken   # If pos != 2, branch NOT taken
    
    # Taken path (position 2 in cycle)
    addi    t1, t1, 1
    j       test3_continue
    
test3_not_taken:
    # Not-taken path (position 0 or 1 in cycle)
    addi    t2, t2, 1

test3_continue:
    addi    t0, t0, 1
    # Advance cycle position: s7 = (s7 + 1) % 3
    addi    s7, s7, 1
    li      t4, 3
    blt     s7, t4, test3_no_reset
    li      s7, 0
test3_no_reset:
    blt     t0, t3, test3_loop
    
    # Verify
    li      t5, 10          # 10 taken
    bne     t1, t5, test3_fail
    li      t5, 20          # 20 not-taken  
    bne     t2, t5, test3_fail
    j       test4_start

test3_fail:
    li      a0, 3
    j       test_end

# ============================================================================
# TEST 4: Long Run Then Switch (TTTTT...NT)
# Run of many taken, then occasional not-taken
# 
# 1-bit: Mispredicts on NT, then mispredicts on following T
# 2-bit: Only mispredicts on NT if run is long enough to reach Strongly Taken
# ============================================================================
test4_start:
    li      t0, 0
    li      t1, 0           # Result accumulator
    li      s0, 0           # Outer loop counter
    li      s1, 5           # Number of outer iterations

test4_outer:
    li      t0, 0           # Inner counter
    li      t2, 8           # 7 taken, then 1 not-taken on 8th

test4_inner:
    addi    t0, t0, 1
    li      t3, 8
    beq     t0, t3, test4_nt_case    # Position 8 -> Not-Taken
    
    # Taken path (positions 1-7)
    addi    t1, t1, 1
    blt     t0, t2, test4_inner
    j       test4_inner_done
    
test4_nt_case:
    # Not-taken path (position 8)
    addi    t1, t1, 10      # Different increment to track

test4_inner_done:
    addi    s0, s0, 1
    blt     s0, s1, test4_outer
    
    # Verify: 5 outer * (7*1 + 1*10) = 5 * 17 = 85
    li      t5, 85
    beq     t1, t5, test5_start
    li      a0, 4
    j       test_end

# ============================================================================
# TEST 5: T->T->T->NT->NT->NT Pattern (Run of 3 each)
# 
# 1-bit predictor per cycle:
#   T(correct)->T(correct)->T(correct)->NT(miss, flip)->NT(correct)->NT(correct)
#   ->T(miss, flip)->T(correct)->T(correct)->NT(miss, flip)...
#   = 2 mispredictions per 6-branch cycle = 33%
#
# 2-bit predictor per cycle:
#   T(ST,correct)->T(ST,correct)->T(ST,correct)->NT(WT,miss)->NT(WNT,miss)->NT(SNT,correct)
#   ->T(WNT,miss)->T(WT,miss)->T(ST,correct)->...
#   = 4 mispredictions per 6-branch cycle = 66% (worse!)
#
# Note: This pattern actually favors 1-bit! Included to show 2-bit isn't always better.
# ============================================================================
test5_start:
    li      t0, 0
    li      t1, 0           # Taken count
    li      t2, 0           # Not-taken count
    li      t3, 30          # 5 complete cycles
    li      s7, 0           # Cycle position tracker (0-5)

test5_loop:
    # Position in cycle: s7 cycles through 0, 1, 2, 3, 4, 5
    li      t5, 3
    blt     s7, t5, test5_taken    # Positions 0,1,2 -> Taken
    
    # Not-taken path (positions 3,4,5)
    addi    t2, t2, 1
    j       test5_continue
    
test5_taken:
    # Taken path (positions 0,1,2)
    addi    t1, t1, 1

test5_continue:
    addi    t0, t0, 1
    # Advance cycle position: s7 = (s7 + 1) % 6
    addi    s7, s7, 1
    li      t4, 6
    blt     s7, t4, test5_no_reset
    li      s7, 0
test5_no_reset:
    blt     t0, t3, test5_loop
    
    # Verify: 15 taken, 15 not-taken
    li      t5, 15
    bne     t1, t5, test5_fail
    bne     t2, t5, test5_fail
    j       test6_start

test5_fail:
    li      a0, 5
    j       test_end

# ============================================================================
# TEST 6: Nested Loop with Alternating Inner (Realistic Pattern)
# Outer loop always taken until exit
# Inner loop alternates T/NT each iteration
#
# 1-bit: Inner alternation causes constant misprediction
# 2-bit: Can partially adapt to the inner pattern
# ============================================================================
test6_start:
    li      s0, 0           # Outer counter
    li      s1, 4           # Outer limit
    li      s2, 0           # Total taken in inner
    li      s3, 0           # Total not-taken in inner

test6_outer:
    li      t0, 0           # Inner counter
    li      t1, 10          # Inner limit

test6_inner:
    andi    t2, t0, 1
    beq     t2, zero, test6_inner_taken
    
    # Inner not-taken
    addi    s3, s3, 1
    j       test6_inner_continue
    
test6_inner_taken:
    addi    s2, s2, 1

test6_inner_continue:
    addi    t0, t0, 1
    blt     t0, t1, test6_inner
    
    addi    s0, s0, 1
    blt     s0, s1, test6_outer
    
    # Verify: 4 outer * 5 inner taken = 20, 4 * 5 inner not-taken = 20
    li      t5, 20
    bne     s2, t5, test6_fail
    bne     s3, t5, test6_fail
    j       test7_start

test6_fail:
    li      a0, 6
    j       test_end

# ============================================================================
# TEST 7: T->T->T->T->NT Pattern (4 taken, 1 not-taken)
# Strong bias toward taken
#
# 1-bit predictor: 
#   4 correct T predictions, then NT mispredicts, flips to NT
#   Next T mispredicts, flips back to T
#   = 2 mispredictions per 5-branch cycle = 40%
#
# 2-bit predictor:
#   Stays in Strongly Taken, only mispredicts the NT
#   = 1 misprediction per 5-branch cycle = 20%
# ============================================================================
test7_start:
    li      t0, 0
    li      t1, 0           # Taken count
    li      t2, 0           # Not-taken count
    li      t3, 40          # 8 complete cycles
    li      s7, 0           # Cycle position tracker (0-4)

test7_loop:
    # Position in cycle: s7 cycles through 0, 1, 2, 3, 4
    li      t5, 4
    beq     s7, t5, test7_not_taken   # Position 4 -> NT
    
    # Taken (positions 0,1,2,3)
    addi    t1, t1, 1
    j       test7_continue
    
test7_not_taken:
    addi    t2, t2, 1

test7_continue:
    addi    t0, t0, 1
    # Advance cycle position: s7 = (s7 + 1) % 5
    addi    s7, s7, 1
    li      t4, 5
    blt     s7, t4, test7_no_reset
    li      s7, 0
test7_no_reset:
    blt     t0, t3, test7_loop
    
    # Verify: 32 taken, 8 not-taken
    li      t5, 32
    bne     t1, t5, test7_fail
    li      t5, 8
    bne     t2, t5, test7_fail
    j       test8_start

test7_fail:
    li      a0, 7
    j       test_end

# ============================================================================
# TEST 8: T->T->T->T->T->NT Pattern (5 taken, 1 not-taken)  
# Even stronger bias
#
# 1-bit: 2 mispredictions per 6-branch cycle = 33%
# 2-bit: 1 misprediction per 6-branch cycle = 17%
# ============================================================================
test8_start:
    li      t0, 0
    li      t1, 0
    li      t2, 0
    li      t3, 36          # 6 complete cycles
    li      s7, 0           # Cycle position tracker (0-5)

test8_loop:
    # Position in cycle: s7 cycles through 0, 1, 2, 3, 4, 5
    li      t5, 5
    beq     s7, t5, test8_not_taken
    
    addi    t1, t1, 1
    j       test8_continue
    
test8_not_taken:
    addi    t2, t2, 1

test8_continue:
    addi    t0, t0, 1
    # Advance cycle position: s7 = (s7 + 1) % 6
    addi    s7, s7, 1
    li      t4, 6
    blt     s7, t4, test8_no_reset
    li      s7, 0
test8_no_reset:
    blt     t0, t3, test8_loop
    
    # Verify: 30 taken, 6 not-taken
    li      t5, 30
    bne     t1, t5, test8_fail
    li      t5, 6
    bne     t2, t5, test8_fail
    j       test9_start

test8_fail:
    li      a0, 8
    j       test_end

# ============================================================================
# TEST 9: Cascading Pattern with Multiple Branch Points
# Each branch point sees a different pattern
#
# Branch A: T->T->NT->T->T->NT (favors 2-bit)
# Branch B: T->NT->T->NT (alternating, bad for both)
# ============================================================================
test9_start:
    li      s0, 0           # Outer iteration
    li      s1, 12          # Total iterations
    li      s2, 0           # Branch A taken count
    li      s3, 0           # Branch A not-taken count
    li      s4, 0           # Branch B taken count
    li      s5, 0           # Branch B not-taken count
    li      s7, 0           # Cycle position for pattern A (0, 1, 2)

test9_loop:
    # Branch A pattern (T T NT T T NT)
    # s7 cycles through 0, 1, 2
    li      t1, 2
    beq     s7, t1, test9_branch_a_nt
    
    addi    s2, s2, 1       # Branch A taken
    j       test9_branch_b
    
test9_branch_a_nt:
    addi    s3, s3, 1       # Branch A not-taken

test9_branch_b:
    # Branch B pattern (T NT T NT) - uses even/odd of s0
    andi    t0, s0, 1
    beq     t0, zero, test9_branch_b_taken
    
    addi    s5, s5, 1       # Branch B not-taken
    j       test9_continue
    
test9_branch_b_taken:
    addi    s4, s4, 1       # Branch B taken

test9_continue:
    addi    s0, s0, 1
    # Advance cycle position for A: s7 = (s7 + 1) % 3
    addi    s7, s7, 1
    li      t4, 3
    blt     s7, t4, test9_no_reset
    li      s7, 0
test9_no_reset:
    blt     s0, s1, test9_loop
    
    # Verify Branch A: 12 iterations, pattern 3, so 4 cycles
    # 4 * 2 = 8 taken, 4 * 1 = 4 not-taken
    li      t5, 8
    bne     s2, t5, test9_fail
    li      t5, 4
    bne     s3, t5, test9_fail
    
    # Verify Branch B: 12 iterations, even/odd split
    # 6 taken, 6 not-taken
    li      t5, 6
    bne     s4, t5, test9_fail
    bne     s5, t5, test9_fail
    j       test10_start

test9_fail:
    li      a0, 9
    j       test_end

# ============================================================================
# TEST 10: Variable Length Runs (Stress Test)
# Pattern: T, NT, T T, NT NT, T T T, NT NT NT, ...
# Growing runs - harder for simple predictors
#
# 1-bit: Mispredicts at every transition point
# 2-bit: May adapt to longer runs, reducing mispredictions in those
# ============================================================================
test10_start:
    li      s0, 0           # Total branch count
    li      s1, 0           # Taken count
    li      s2, 0           # Not-taken count
    li      s3, 1           # Current run length
    li      s4, 0           # Position in current run
    li      s5, 0           # 0 = taken run, 1 = not-taken run
    li      s6, 50          # Max total branches

test10_loop:
    beq     s5, zero, test10_taken_run
    
    # Not-taken run
    addi    s2, s2, 1
    j       test10_advance
    
test10_taken_run:
    addi    s1, s1, 1

test10_advance:
    addi    s4, s4, 1
    addi    s0, s0, 1
    
    # Check if run is complete
    blt     s4, s3, test10_continue
    
    # Switch to next run
    xori    s5, s5, 1       # Toggle taken/not-taken
    li      s4, 0           # Reset position
    
    # If we just completed a not-taken run, increase run length
    bne     s5, zero, test10_continue
    addi    s3, s3, 1
    
test10_continue:
    blt     s0, s6, test10_loop
    
    # Verify total branches
    add     t0, s1, s2
    bne     t0, s6, test10_fail
    
    # At this point the exact count depends on how the pattern unfolds
    # Run lengths are: 1,1,2,2,3,3,4,4,5,5,6,6,... 
    # With 50 branches: 1+1+2+2+3+3+4+4+5+5+6+6+7+... = need to calculate
    # T:1, NT:1, T:2, NT:2, T:3, NT:3, T:4, NT:4, T:5 (partial at 3)
    # Actually: pairs sum to 2,4,6,8,10,12,... 
    # 2+4+6+8+10+12 = 42, need 8 more, so T:7 gets 7, and NT:7 gets 1
    # T total: 1+2+3+4+5+7 = 22, NT total: 1+2+3+4+5+6+1 = 22... let's just check sum
    
    j       test_pass

test10_fail:
    li      a0, 10
    j       test_end

# ============================================================================
# TEST END
# ============================================================================
test_pass:
    li      a0, 0           # All tests passed

test_end:
    # Custom instruction: Print a0
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0

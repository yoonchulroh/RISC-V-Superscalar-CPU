# Branch Target Buffer (BTB), Speculation, and Flush Test Program
# Tests various branch patterns to verify correct BTB behavior,
# speculative execution, and pipeline flush on misprediction.
# 
# a0 = 0 if all tests pass
# a0 = test ID (1-30) if test fails

.text
.globl _start

_start:
    # Initialize stack pointer (must be done first, memory < 400)
    li      sp, 396         # Stack pointer at top of usable memory
    
    # Initialize registers
    li      a0, 0           # a0 = 0 (will be set to 1 on failure)
    li      t0, 0           # Counter/test value
    li      t1, 0
    li      t2, 0
    li      t3, 0
    li      t4, 0
    li      t5, 0
    li      t6, 0
    li      s0, 0
    li      s1, 0
    li      s2, 0
    li      s3, 0
    li      s4, 0
    li      s5, 0
    li      s6, 0
    li      s7, 0
    li      s8, 0
    li      s9, 0
    li      s10, 0
    li      s11, 0

# ============================================================================
# TEST 1: Simple taken branch (BTB should learn and predict taken)
# ============================================================================
test1_start:
    li      t0, 10          # Loop counter
    li      t1, 0           # Sum accumulator
test1_loop:
    addi    t1, t1, 1       # Increment sum
    addi    t0, t0, -1      # Decrement counter
    bne     t0, zero, test1_loop  # Branch back if not zero (should be predicted taken after first iteration)
    
    # Verify result: t1 should be 10
    li      t2, 10
    beq     t1, t2, test1_pass
    li      a0, 1           # Test 1 failed
    j       test_end
test1_pass:

# ============================================================================
# TEST 2: Simple not-taken branch (BTB may initially predict taken incorrectly)
# ============================================================================
test2_start:
    li      t0, 0
    li      t1, 5
    beq     t0, t1, test2_fail  # Should NOT be taken (0 != 5)
    j       test2_pass
test2_fail:
    li      a0, 2           # Test 2 failed
    j       test_end
test2_pass:

# ============================================================================
# TEST 3: Alternating taken/not-taken pattern (stresses BTB prediction)
# ============================================================================
test3_start:
    li      t0, 0           # Counter
    li      t1, 0           # Sum for taken branches
    li      t2, 0           # Sum for not-taken branches
test3_loop:
    andi    t3, t0, 1       # t3 = t0 & 1 (check if odd/even)
    beq     t3, zero, test3_even  # Branch if even
    # Odd case (not taken)
    addi    t2, t2, 1       # Increment not-taken sum
    j       test3_next
test3_even:
    # Even case (taken)
    addi    t1, t1, 1       # Increment taken sum
test3_next:
    addi    t0, t0, 1
    li      t4, 20
    bne     t0, t4, test3_loop
    
    # Verify: t1 should be 10 (even: 0,2,4,6,8,10,12,14,16,18)
    # t2 should be 10 (odd: 1,3,5,7,9,11,13,15,17,19)
    li      t5, 10
    bne     t1, t5, test3_fail
    bne     t2, t5, test3_fail
    j       test3_pass
test3_fail:
    li      a0, 3           # Test 3 failed
    j       test_end
test3_pass:

# ============================================================================
# TEST 4: Nested loops (multiple BTB entries)
# ============================================================================
test4_start:
    li      t0, 0           # Outer counter
    li      t1, 0           # Inner counter
    li      t2, 0           # Total iterations
test4_outer:
    li      t1, 0
test4_inner:
    addi    t2, t2, 1       # Count iteration
    addi    t1, t1, 1
    li      t3, 5
    bne     t1, t3, test4_inner  # Inner loop: 5 iterations
    addi    t0, t0, 1
    li      t3, 4
    bne     t0, t3, test4_outer  # Outer loop: 4 iterations
    
    # Verify: t2 should be 20 (4 * 5)
    li      t3, 20
    beq     t2, t3, test4_pass
    li      a0, 4           # Test 4 failed
    j       test_end
test4_pass:

# ============================================================================
# TEST 5: JAL instruction (direct jump, BTB should cache target)
# ============================================================================
test5_start:
    li      t0, 0
    jal     ra, test5_func  # Call function
    li      t1, 42
    bne     t0, t1, test5_fail
    j       test5_pass
    
test5_func:
    li      t0, 42
    jalr    zero, ra, 0     # Return (jalr to ra)
    
test5_fail:
    li      a0, 5           # Test 5 failed
    j       test_end
test5_pass:

# ============================================================================
# TEST 6: Multiple JAL calls (BTB should handle multiple targets)
# ============================================================================
test6_start:
    li      t0, 0
    jal     ra, test6_func_a
    jal     ra, test6_func_b
    jal     ra, test6_func_c
    li      t1, 111         # 10 + 21 + 80
    beq     t0, t1, test6_pass
    li      a0, 6           # Test 6 failed
    j       test_end

test6_func_a:
    addi    t0, t0, 10
    jalr    zero, ra, 0

test6_func_b:
    addi    t0, t0, 21
    jalr    zero, ra, 0

test6_func_c:
    addi    t0, t0, 80
    jalr    zero, ra, 0

test6_pass:

# ============================================================================
# TEST 7: JALR with computed target (indirect jump - hard to predict)
# ============================================================================
test7_start:
    li      t0, 0
    la      t1, test7_target1
    jalr    ra, t1, 0       # Jump to computed address
    la      t1, test7_target2
    jalr    ra, t1, 0
    la      t1, test7_target3
    jalr    ra, t1, 0
    li      t2, 63          # 1 + 2 + 60
    beq     t0, t2, test7_pass
    li      a0, 7           # Test 7 failed
    j       test_end

test7_target1:
    addi    t0, t0, 1
    jalr    zero, ra, 0

test7_target2:
    addi    t0, t0, 2
    jalr    zero, ra, 0

test7_target3:
    addi    t0, t0, 60
    jalr    zero, ra, 0

test7_pass:

# ============================================================================
# TEST 8: Branch with back-to-back dependencies (stall + speculation)
# ============================================================================
test8_start:
    li      t0, 5
    li      t1, 0
test8_loop:
    addi    t1, t1, 1
    addi    t0, t0, -1      # RAW dependency with next branch
    bne     t0, zero, test8_loop  # Uses t0 immediately after modification
    
    li      t2, 5
    beq     t1, t2, test8_pass
    li      a0, 8           # Test 8 failed
    j       test_end
test8_pass:

# ============================================================================
# TEST 9: Long forward branch (test branch offset handling)
# ============================================================================
test9_start:
    li      t0, 1
    beq     t0, t0, test9_far_target  # Taken forward branch
    # These should be skipped
    li      a0, 9           # Test 9 failed
    j       test_end
    li      a0, 9           # Test 9 failed
    j       test_end
    li      a0, 9           # Test 9 failed
    j       test_end
    li      a0, 9           # Test 9 failed
    j       test_end
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
test9_far_target:
    li      t1, 1
    beq     t0, t1, test9_pass
    li      a0, 9           # Test 9 failed
    j       test_end
test9_pass:

# ============================================================================
# TEST 10: Multiple consecutive branches (BTB pressure)
# ============================================================================
test10_start:
    li      t0, 0
    li      t1, 1
    li      t2, 2
    li      t3, 3
    li      s0, 0           # Result accumulator
    
    beq     t0, zero, test10_b1_taken
    j       test10_fail
test10_b1_taken:
    addi    s0, s0, 1
    
    bne     t1, zero, test10_b2_taken
    j       test10_fail
test10_b2_taken:
    addi    s0, s0, 1
    
    blt     t0, t1, test10_b3_taken
    j       test10_fail
test10_b3_taken:
    addi    s0, s0, 1
    
    bge     t2, t1, test10_b4_taken
    j       test10_fail
test10_b4_taken:
    addi    s0, s0, 1
    
    bltu    t1, t2, test10_b5_taken
    j       test10_fail
test10_b5_taken:
    addi    s0, s0, 1
    
    bgeu    t3, t2, test10_b6_taken
    j       test10_fail
test10_b6_taken:
    addi    s0, s0, 1
    
    # Verify s0 = 6
    li      t4, 6
    beq     s0, t4, test10_pass
test10_fail:
    li      a0, 10          # Test 10 failed
    j       test_end
test10_pass:

# ============================================================================
# TEST 11: Branch not-taken after many taken (misprediction expected)
# ============================================================================
test11_start:
    li      t0, 8
    li      t1, 0
test11_loop:
    addi    t1, t1, 1
    addi    t0, t0, -1
    bne     t0, zero, test11_loop  # Taken 7 times, then not taken
    
    # Now the same branch address but opposite condition
    li      t0, 0
    bne     t0, zero, test11_fail  # Should NOT be taken (BTB might predict taken)
    j       test11_pass
test11_fail:
    li      a0, 11          # Test 11 failed
    j       test_end
test11_pass:
    li      t2, 8
    bne     t1, t2, test11_fail2
    j       test11_done
test11_fail2:
    li      a0, 11          # Test 11 failed
    j       test_end
test11_done:

# ============================================================================
# TEST 12: Recursive function call simulation (return address stack test)
# ============================================================================
test12_start:
    li      s0, 0           # Depth counter
    li      s1, 0           # Result
    jal     ra, test12_recurse
    li      t0, 5
    bne     s1, t0, test12_fail
    j       test12_pass

test12_recurse:
    addi    sp, sp, -8      # Allocate stack (simulated)
    sw      ra, 0(sp)       # Save return address
    sw      s0, 4(sp)       # Save depth
    
    addi    s0, s0, 1       # Increment depth
    addi    s1, s1, 1       # Increment result
    
    li      t0, 5
    bge     s0, t0, test12_base_case  # Base case: depth >= 5
    jal     ra, test12_recurse        # Recursive call
    
test12_base_case:
    lw      ra, 0(sp)       # Restore return address
    lw      s0, 4(sp)       # Restore depth
    addi    sp, sp, 8       # Deallocate stack
    jalr    zero, ra, 0     # Return

test12_fail:
    li      a0, 12          # Test 12 failed
    j       test_end
test12_pass:

# ============================================================================
# TEST 13: Conditional chain (many dependent branches)
# ============================================================================
test13_start:
    li      t0, 50
    li      t1, 0
    
    li      t2, 10
    blt     t0, t2, test13_fail     # 50 < 10? No
    addi    t1, t1, 1
    
    li      t2, 100
    bge     t0, t2, test13_fail     # 50 >= 100? No
    addi    t1, t1, 1
    
    li      t2, 50
    bne     t0, t2, test13_fail     # 50 != 50? No
    addi    t1, t1, 1
    
    beq     t0, t2, test13_c4       # 50 == 50? Yes
    j       test13_fail
test13_c4:
    addi    t1, t1, 1
    
    li      t2, 4
    bne     t1, t2, test13_fail
    j       test13_pass
    
test13_fail:
    li      a0, 13          # Test 13 failed
    j       test_end
test13_pass:

# ============================================================================
# TEST 14: Switch-case simulation with JALR (indirect jumps)
# ============================================================================
test14_start:
    li      s0, 0           # Result accumulator
    
    # Test case 0
    li      t0, 0
    jal     ra, test14_switch
    li      t1, 100
    bne     s0, t1, test14_fail
    
    # Test case 1
    li      t0, 1
    jal     ra, test14_switch
    li      t1, 120
    bne     s0, t1, test14_fail
    
    # Test case 2
    li      t0, 2
    jal     ra, test14_switch
    li      t1, 150
    bne     s0, t1, test14_fail
    
    j       test14_pass

test14_switch:
    beq     t0, zero, test14_case0
    li      t2, 1
    beq     t0, t2, test14_case1
    li      t2, 2
    beq     t0, t2, test14_case2
    j       test14_default
    
test14_case0:
    li      s0, 100
    jalr    zero, ra, 0
test14_case1:
    addi    s0, s0, 20
    jalr    zero, ra, 0
test14_case2:
    addi    s0, s0, 30
    jalr    zero, ra, 0
test14_default:
    li      s0, -1
    jalr    zero, ra, 0
    
test14_fail:
    li      a0, 14          # Test 14 failed
    j       test_end
test14_pass:

# ============================================================================
# TEST 15: Bubble sort pattern (realistic branch behavior)
# ============================================================================
test15_start:
    # Initialize array in memory (addresses 0-16)
    li      t0, 5
    li      t1, 0
    sw      t0, 0(t1)       # arr[0] = 5
    li      t0, 3
    sw      t0, 4(t1)       # arr[1] = 3
    li      t0, 8
    sw      t0, 8(t1)       # arr[2] = 8
    li      t0, 1
    sw      t0, 12(t1)      # arr[3] = 1
    li      t0, 9
    sw      t0, 16(t1)      # arr[4] = 9
    
    # Simple bubble sort (n=5)
    li      s0, 0           # i = 0
test15_outer:
    li      s1, 0           # j = 0
    li      t2, 4           # n-1 = 4
test15_inner:
    # Load arr[j] and arr[j+1]
    slli    t3, s1, 2       # j * 4
    lw      t4, 0(t3)       # arr[j]
    addi    t5, t3, 4
    lw      t6, 0(t5)       # arr[j+1]
    
    # Compare and swap if needed
    ble     t4, t6, test15_no_swap
    sw      t6, 0(t3)       # arr[j] = arr[j+1]
    sw      t4, 0(t5)       # arr[j+1] = arr[j]
test15_no_swap:
    addi    s1, s1, 1
    blt     s1, t2, test15_inner
    
    addi    s0, s0, 1
    li      t2, 4
    blt     s0, t2, test15_outer
    
    # Verify sorted: should be 1, 3, 5, 8, 9
    li      t0, 0
    lw      t1, 0(t0)
    li      t2, 1
    bne     t1, t2, test15_fail
    lw      t1, 4(t0)
    li      t2, 3
    bne     t1, t2, test15_fail
    lw      t1, 8(t0)
    li      t2, 5
    bne     t1, t2, test15_fail
    lw      t1, 12(t0)
    li      t2, 8
    bne     t1, t2, test15_fail
    lw      t1, 16(t0)
    li      t2, 9
    bne     t1, t2, test15_fail
    j       test15_pass
    
test15_fail:
    li      a0, 15          # Test 15 failed
    j       test_end
test15_pass:

# ============================================================================
# TEST 16: Triangular number calculation (sum 1+2+...+n)
# ============================================================================
test16_start:
    li      t0, 10          # n = 10
    li      t1, 0           # sum = 0
    li      t2, 1           # i = 1
test16_loop:
    add     t1, t1, t2      # sum += i
    addi    t2, t2, 1       # i++
    ble     t2, t0, test16_loop  # while i <= n
    
    # Verify: sum should be 55
    li      t3, 55
    beq     t1, t3, test16_pass
    li      a0, 16          # Test 16 failed
    j       test_end
test16_pass:

# ============================================================================
# TEST 17: Fibonacci sequence (multiple register dependencies)
# ============================================================================
test17_start:
    li      t0, 0           # fib(0)
    li      t1, 1           # fib(1)
    li      t2, 10          # Calculate fib(10)
    li      t3, 2           # Current index
test17_loop:
    add     t4, t0, t1      # fib(n) = fib(n-1) + fib(n-2)
    mv      t0, t1          # fib(n-2) = fib(n-1)
    mv      t1, t4          # fib(n-1) = fib(n)
    addi    t3, t3, 1
    ble     t3, t2, test17_loop
    
    # Verify: fib(10) should be 55
    li      t5, 55
    beq     t1, t5, test17_pass
    li      a0, 17          # Test 17 failed
    j       test_end
test17_pass:

# ============================================================================
# TEST 18: GCD calculation (Euclidean algorithm)
# ============================================================================
test18_start:
    li      t0, 48          # a = 48
    li      t1, 18          # b = 18
test18_loop:
    beq     t1, zero, test18_done
    mv      t2, t1          # temp = b
    # Calculate a % b
    mv      t3, t0          # temp_a = a
test18_mod:
    blt     t3, t1, test18_mod_done
    sub     t3, t3, t1
    j       test18_mod
test18_mod_done:
    mv      t0, t2          # a = b
    mv      t1, t3          # b = a % b
    j       test18_loop
test18_done:
    # Verify: gcd(48, 18) should be 6
    li      t2, 6
    beq     t0, t2, test18_pass
    li      a0, 18          # Test 18 failed
    j       test_end
test18_pass:

# ============================================================================
# TEST 19: Power of 2 check (bit manipulation with branches)
# ============================================================================
test19_start:
    # Test 8 (is power of 2: yes)
    li      t0, 8
    jal     ra, test19_is_power2
    beq     t0, zero, test19_fail  # Should return 1
    
    # Test 7 (is power of 2: no)
    li      t0, 7
    jal     ra, test19_is_power2
    bne     t0, zero, test19_fail  # Should return 0
    
    # Test 16 (is power of 2: yes)
    li      t0, 16
    jal     ra, test19_is_power2
    beq     t0, zero, test19_fail  # Should return 1
    
    # Test 15 (is power of 2: no)
    li      t0, 15
    jal     ra, test19_is_power2
    bne     t0, zero, test19_fail  # Should return 0
    
    j       test19_pass

test19_is_power2:
    # Check if t0 is power of 2: (n & (n-1)) == 0 and n > 0
    beq     t0, zero, test19_not_power2
    addi    t1, t0, -1
    and     t2, t0, t1
    bne     t2, zero, test19_not_power2
    li      t0, 1
    jalr    zero, ra, 0
test19_not_power2:
    li      t0, 0
    jalr    zero, ra, 0
    
test19_fail:
    li      a0, 19          # Test 19 failed
    j       test_end
test19_pass:

# ============================================================================
# TEST 20: Count bits set (popcount)
# ============================================================================
test20_start:
    li      t0, 0xFF        # 255 = 8 bits set
    jal     ra, test20_popcount
    li      t1, 8
    bne     t0, t1, test20_fail
    
    li      t0, 0x55        # 0101_0101 = 4 bits set
    jal     ra, test20_popcount
    li      t1, 4
    bne     t0, t1, test20_fail
    
    li      t0, 0x00        # 0 bits set
    jal     ra, test20_popcount
    bne     t0, zero, test20_fail
    
    j       test20_pass

test20_popcount:
    li      t1, 0           # count = 0
test20_pop_loop:
    beq     t0, zero, test20_pop_done
    andi    t2, t0, 1       # Check lowest bit
    add     t1, t1, t2      # count += (n & 1)
    srli    t0, t0, 1       # n >>= 1
    j       test20_pop_loop
test20_pop_done:
    mv      t0, t1
    jalr    zero, ra, 0

test20_fail:
    li      a0, 20          # Test 20 failed
    j       test_end
test20_pass:

# ============================================================================
# TEST 21: Interleaved function calls (stress return address stack)
# ============================================================================
test21_start:
    li      s0, 0
    jal     ra, test21_func_outer
    li      t0, 50          # 10 + 15 + 10 + 15 = 50
    bne     s0, t0, test21_fail
    j       test21_pass

test21_func_outer:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    
    jal     ra, test21_func_a
    jal     ra, test21_func_b
    jal     ra, test21_func_a
    jal     ra, test21_func_b
    
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jalr    zero, ra, 0

test21_func_a:
    addi    s0, s0, 10
    jalr    zero, ra, 0

test21_func_b:
    addi    s0, s0, 15
    jalr    zero, ra, 0

test21_fail:
    li      a0, 21          # Test 21 failed
    j       test_end
test21_pass:

# ============================================================================
# TEST 22: Branch prediction thrashing (same address, different outcomes)
# ============================================================================
test22_start:
    li      s0, 0           # Result
    li      s1, 0           # Iteration
test22_outer:
    li      t0, 0
    
test22_branch_point:
    # Same branch address, but condition alternates based on s1
    andi    t1, s1, 1
    beq     t1, zero, test22_taken_path
    # Not taken path
    addi    s0, s0, 1
    j       test22_continue
test22_taken_path:
    addi    s0, s0, 2
test22_continue:
    addi    t0, t0, 1
    li      t2, 5
    blt     t0, t2, test22_branch_point
    
    addi    s1, s1, 1
    li      t2, 6
    blt     s1, t2, test22_outer
    
    # Expected: 3 even iterations (s1=0,2,4) * 5 * 2 = 30
    #         + 3 odd iterations (s1=1,3,5) * 5 * 1 = 15
    #         = 45
    li      t0, 45
    beq     s0, t0, test22_pass
    li      a0, 22          # Test 22 failed
    j       test_end
test22_pass:

# ============================================================================
# TEST 23: Deeply nested loops (BTB capacity test)
# ============================================================================
test23_start:
    li      s0, 0           # Counter
    li      t0, 0           # i
test23_loop_i:
    li      t1, 0           # j
test23_loop_j:
    li      t2, 0           # k
test23_loop_k:
    addi    s0, s0, 1
    addi    t2, t2, 1
    li      t4, 3
    blt     t2, t4, test23_loop_k
    addi    t1, t1, 1
    li      t4, 4
    blt     t1, t4, test23_loop_j
    addi    t0, t0, 1
    li      t4, 2
    blt     t0, t4, test23_loop_i
    
    # Expected: 2 * 4 * 3 = 24
    li      t5, 24
    beq     s0, t5, test23_pass
    li      a0, 23          # Test 23 failed
    j       test_end
test23_pass:

# ============================================================================
# TEST 24: Signed vs unsigned branch comparison
# ============================================================================
test24_start:
    li      t0, -1          # 0xFFFFFFFF
    li      t1, 1
    
    # Signed: -1 < 1 should be true
    blt     t0, t1, test24_signed_ok
    li      a0, 24          # Test 24 failed
    j       test_end
test24_signed_ok:
    
    # Unsigned: 0xFFFFFFFF > 1 should be true
    bltu    t1, t0, test24_unsigned_ok
    li      a0, 24          # Test 24 failed
    j       test_end
test24_unsigned_ok:

    # Signed: -1 >= 1 should be false (not taken)
    bge     t0, t1, test24_fail
    j       test24_unsigned_check2
test24_fail:
    li      a0, 24          # Test 24 failed
    j       test_end
    
test24_unsigned_check2:
    # Unsigned: 1 >= 0xFFFFFFFF should be false (not taken)
    bgeu    t1, t0, test24_fail2
    j       test24_pass
test24_fail2:
    li      a0, 24          # Test 24 failed
    j       test_end
test24_pass:

# ============================================================================
# TEST 25: Early exit pattern (break from loop)
# ============================================================================
test25_start:
    li      t0, 0           # i = 0
    li      t1, 0           # Found index
    li      t2, 100         # Array base (simulated)
    
    # Store values
    li      t3, 5
    sw      t3, 100(zero)
    li      t3, 10
    sw      t3, 104(zero)
    li      t3, 15
    sw      t3, 108(zero)
    li      t3, 42          # Target value
    sw      t3, 112(zero)
    li      t3, 25
    sw      t3, 116(zero)
    
test25_search:
    slli    t3, t0, 2
    add     t3, t3, t2
    lw      t4, 0(t3)
    li      t5, 42
    beq     t4, t5, test25_found  # Early exit when found
    addi    t0, t0, 1
    li      t5, 5
    blt     t0, t5, test25_search
    # Not found
    li      t1, -1
    j       test25_verify

test25_found:
    mv      t1, t0          # Found at index t0

test25_verify:
    # Should be found at index 3
    li      t5, 3
    beq     t1, t5, test25_pass
    li      a0, 25          # Test 25 failed
    j       test_end
test25_pass:

# ============================================================================
# TEST 26: Multiple return points in function
# ============================================================================
test26_start:
    li      t0, 5
    jal     ra, test26_classify
    li      t1, 1           # Expected: small
    bne     t0, t1, test26_fail
    
    li      t0, 50
    jal     ra, test26_classify
    li      t1, 2           # Expected: medium
    bne     t0, t1, test26_fail
    
    li      t0, 150
    jal     ra, test26_classify
    li      t1, 3           # Expected: large
    bne     t0, t1, test26_fail
    
    j       test26_pass

test26_classify:
    li      t1, 10
    blt     t0, t1, test26_small
    li      t1, 100
    blt     t0, t1, test26_medium
    li      t0, 3           # Large
    jalr    zero, ra, 0
test26_small:
    li      t0, 1
    jalr    zero, ra, 0
test26_medium:
    li      t0, 2
    jalr    zero, ra, 0

test26_fail:
    li      a0, 26          # Test 26 failed
    j       test_end
test26_pass:

# ============================================================================
# TEST 27: Branch after load (load-use hazard with branch)
# ============================================================================
test27_start:
    # Store value
    li      t0, 42
    sw      t0, 200(zero)
    
    # Load and immediately branch
    lw      t1, 200(zero)
    li      t2, 42
    beq     t1, t2, test27_check2  # Branch depends on loaded value
    li      a0, 27          # Test 27 failed
    j       test_end

test27_check2:
    # Another load-branch sequence
    sw      zero, 204(zero)
    lw      t1, 204(zero)
    bne     t1, zero, test27_fail
    j       test27_pass

test27_fail:
    li      a0, 27          # Test 27 failed
    j       test_end
test27_pass:

# ============================================================================
# TEST 28: Long chain of unconditional jumps
# ============================================================================
test28_start:
    li      t0, 0
    j       test28_j1
test28_j8:
    addi    t0, t0, 1
    j       test28_done
test28_j1:
    addi    t0, t0, 1
    j       test28_j2
test28_j2:
    addi    t0, t0, 1
    j       test28_j3
test28_j3:
    addi    t0, t0, 1
    j       test28_j4
test28_j4:
    addi    t0, t0, 1
    j       test28_j5
test28_j5:
    addi    t0, t0, 1
    j       test28_j6
test28_j6:
    addi    t0, t0, 1
    j       test28_j7
test28_j7:
    addi    t0, t0, 1
    j       test28_j8
test28_done:
    li      t1, 8
    beq     t0, t1, test28_pass
    li      a0, 28          # Test 28 failed
    j       test_end
test28_pass:

# ============================================================================
# TEST 29: Mutual recursion simulation
# ============================================================================
test29_start:
    li      s0, 0           # Call count
    li      t0, 5           # Limit
    sw      t0, 220(zero)
    li      t0, 0
    sw      t0, 224(zero)   # Current depth
    jal     ra, test29_func_a
    li      t0, 5           # Should have 5 total calls (depth goes 0→1→2→3→4, then 5 >= limit)
    bne     s0, t0, test29_fail
    j       test29_pass

test29_func_a:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    addi    s0, s0, 1       # Count call
    lw      t0, 224(zero)
    addi    t0, t0, 1
    sw      t0, 224(zero)
    lw      t1, 220(zero)
    bge     t0, t1, test29_a_done
    jal     ra, test29_func_b
test29_a_done:
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jalr    zero, ra, 0

test29_func_b:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    addi    s0, s0, 1       # Count call
    lw      t0, 224(zero)
    addi    t0, t0, 1
    sw      t0, 224(zero)
    lw      t1, 220(zero)
    bge     t0, t1, test29_b_done
    jal     ra, test29_func_a
test29_b_done:
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jalr    zero, ra, 0

test29_fail:
    li      a0, 29          # Test 29 failed
    j       test_end
test29_pass:

# ============================================================================
# TEST 30: Final comprehensive check
# ============================================================================
test30_start:
    # If we reached here, all previous tests passed
    # Do a final verification sequence
    li      t0, 0
    li      t1, 100
test30_loop:
    addi    t0, t0, 1
    bne     t0, t1, test30_loop
    
    # Verify t0 = 100
    li      t1, 100
    beq     t0, t1, test30_pass
    li      a0, 30          # Test 30 failed
    j       test_end
test30_pass:
    # All tests passed!
    li      a0, 0

# ============================================================================
# End of all tests
# ============================================================================
test_end:
    # Custom instructions for printing result
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0

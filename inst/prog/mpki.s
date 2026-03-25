# Branch Prediction Accuracy Test (MPKI - Misses Per Kilo Instructions)
# This program contains many branches executed repeatedly to stress-test branch predictors.
# All registers and memory locations are assumed to start at 0.
# Memory addresses are kept below 4000. Strictly RV32I only (no M extension).
# Register a0 should be 0 at the end.

.text
.globl _start

_start:
    # Initialize loop counters and constants
    li t0, 100          # Outer loop count
    li t1, 0            # Outer loop counter
    li t2, 50           # Inner loop count
    li t3, 0            # Inner loop counter
    li t4, 10           # Pattern loop count
    li a0, 0            # Result register (should be 0 at end)

# ==============================================================================
# TEST 1: Simple forward branch (always taken)
# The predictor should learn this pattern quickly
# ==============================================================================
test1_outer:
    li t3, 0            # Reset inner counter
test1_inner:
    addi t3, t3, 1      # Increment inner counter
    blt t3, t2, test1_inner  # Branch back (taken ~50 times per outer iteration)
    addi t1, t1, 1      # Increment outer counter
    blt t1, t0, test1_outer  # Branch back (taken ~100 times)

# ==============================================================================
# TEST 2: Simple backward branch (loop pattern)
# Classic loop pattern - predictor should adapt well
# ==============================================================================
    li t0, 100
    li t1, 0
test2_outer:
    li t3, 0
test2_inner:
    addi t3, t3, 1
    blt t3, t2, test2_inner
    addi t1, t1, 1
    blt t1, t0, test2_outer

# ==============================================================================
# TEST 3: Alternating branch pattern (T-NT-T-NT...)
# This pattern is harder for simple predictors
# ==============================================================================
    li t0, 200          # Number of iterations
    li t1, 0            # Counter
test3_loop:
    andi t5, t1, 1      # Get LSB (0 or 1)
    beq t5, zero, test3_even  # Branch if even
    j test3_continue
test3_even:
    nop
test3_continue:
    addi t1, t1, 1
    blt t1, t0, test3_loop

# ==============================================================================
# TEST 4: Nested loops with different branch patterns
# ==============================================================================
    li t0, 50           # Outer loop
    li t1, 0
test4_outer:
    li t3, 0
    li t2, 30           # Inner loop 1
test4_inner1:
    addi t3, t3, 1
    blt t3, t2, test4_inner1

    li t3, 0
    li t2, 20           # Inner loop 2
test4_inner2:
    addi t3, t3, 1
    blt t3, t2, test4_inner2

    addi t1, t1, 1
    blt t1, t0, test4_outer

# ==============================================================================
# TEST 5: Pattern of 2 taken, 1 not taken (TTN-TTN-TTN...)
# Using modulo 3 via subtraction
# ==============================================================================
    li t0, 300
    li t1, 0
test5_loop:
    # Compute t1 % 3 using repeated subtraction
    mv t6, t1
test5_mod3:
    li t5, 3
    blt t6, t5, test5_mod3_done
    sub t6, t6, t5
    j test5_mod3
test5_mod3_done:
    # t6 now contains t1 % 3
    li t5, 2
    blt t6, t5, test5_taken  # Branch if t6 < 2 (taken 2/3 of the time)
    j test5_continue
test5_taken:
    nop
test5_continue:
    addi t1, t1, 1
    blt t1, t0, test5_loop

# ==============================================================================
# TEST 6: Long sequence of always-taken branches
# ==============================================================================
    li t0, 80
    li t1, 0
test6_outer:
    li t3, 0
    li t2, 60
test6_inner:
    addi t3, t3, 1
    blt t3, t2, test6_inner
    addi t1, t1, 1
    blt t1, t0, test6_outer

# ==============================================================================
# TEST 7: Multiple conditional branches in sequence
# ==============================================================================
    li t0, 100
    li t1, 0
test7_loop:
    li t5, 10
    blt t1, t5, test7_path1
    li t5, 20
    blt t1, t5, test7_path2
    li t5, 30
    blt t1, t5, test7_path3
    li t5, 40
    blt t1, t5, test7_path4
    j test7_default
test7_path1:
    nop
    j test7_end
test7_path2:
    nop
    j test7_end
test7_path3:
    nop
    j test7_end
test7_path4:
    nop
    j test7_end
test7_default:
    nop
test7_end:
    addi t1, t1, 1
    blt t1, t0, test7_loop

# ==============================================================================
# TEST 8: Deep nested loops
# ==============================================================================
    li s0, 20           # Level 1
    li s1, 0
test8_l1:
    li s2, 0
    li s3, 15           # Level 2
test8_l2:
    li s4, 0
    li s5, 10           # Level 3
test8_l3:
    addi s4, s4, 1
    blt s4, s5, test8_l3
    addi s2, s2, 1
    blt s2, s3, test8_l2
    addi s1, s1, 1
    blt s1, s0, test8_l1

# ==============================================================================
# TEST 9: Mixed forward and backward branches
# ==============================================================================
    li t0, 150
    li t1, 0
test9_loop:
    andi t5, t1, 3      # t5 = t1 & 3
    beq t5, zero, test9_case0
    li t6, 1
    beq t5, t6, test9_case1
    li t6, 2
    beq t5, t6, test9_case2
    j test9_case3
test9_case0:
    nop
    j test9_next
test9_case1:
    nop
    j test9_next
test9_case2:
    nop
    j test9_next
test9_case3:
    nop
test9_next:
    addi t1, t1, 1
    blt t1, t0, test9_loop

# ==============================================================================
# TEST 10: BEQ patterns
# ==============================================================================
    li t0, 100
    li t1, 0
test10_outer:
    li t3, 0
    li t2, 40
test10_inner:
    li t5, 20
    beq t3, t5, test10_match
    j test10_nomatch
test10_match:
    nop
test10_nomatch:
    addi t3, t3, 1
    blt t3, t2, test10_inner
    addi t1, t1, 1
    blt t1, t0, test10_outer

# ==============================================================================
# TEST 11: BNE patterns
# ==============================================================================
    li t0, 100
    li t1, 0
test11_outer:
    li t3, 0
    li t2, 40
test11_inner:
    li t5, 25
    bne t3, t5, test11_nomatch
    j test11_match
test11_nomatch:
    nop
test11_match:
    addi t3, t3, 1
    blt t3, t2, test11_inner
    addi t1, t1, 1
    blt t1, t0, test11_outer

# ==============================================================================
# TEST 12: BGE patterns
# ==============================================================================
    li t0, 80
    li t1, 0
test12_outer:
    li t3, 0
    li t2, 50
test12_inner:
    li t5, 25
    bge t3, t5, test12_ge
    j test12_lt
test12_ge:
    nop
test12_lt:
    addi t3, t3, 1
    blt t3, t2, test12_inner
    addi t1, t1, 1
    blt t1, t0, test12_outer

# ==============================================================================
# TEST 13: BGEU patterns (unsigned comparison)
# ==============================================================================
    li t0, 80
    li t1, 0
test13_outer:
    li t3, 0
    li t2, 50
test13_inner:
    li t5, 30
    bgeu t3, t5, test13_geu
    j test13_ltu
test13_geu:
    nop
test13_ltu:
    addi t3, t3, 1
    blt t3, t2, test13_inner
    addi t1, t1, 1
    blt t1, t0, test13_outer

# ==============================================================================
# TEST 14: BLTU patterns (unsigned comparison)
# ==============================================================================
    li t0, 80
    li t1, 0
test14_outer:
    li t3, 0
    li t2, 50
test14_inner:
    li t5, 35
    bltu t3, t5, test14_ltu
    j test14_geu
test14_ltu:
    nop
test14_geu:
    addi t3, t3, 1
    blt t3, t2, test14_inner
    addi t1, t1, 1
    blt t1, t0, test14_outer

# ==============================================================================
# TEST 15: Pattern with memory operations between branches
# Memory addresses: 0-100
# ==============================================================================
    li t0, 60
    li t1, 0
    li s0, 0            # Base address
test15_outer:
    li t3, 0
    li t2, 25
test15_inner:
    slli t5, t3, 2      # t5 = t3 * 4
    add t5, t5, s0      # Address
    sw t3, 0(t5)        # Store
    lw t6, 0(t5)        # Load
    addi t3, t3, 1
    blt t3, t2, test15_inner
    addi t1, t1, 1
    blt t1, t0, test15_outer

# ==============================================================================
# TEST 16: Interleaved branches with arithmetic
# ==============================================================================
    li t0, 120
    li t1, 0
    li s1, 0            # Accumulator
test16_loop:
    add s1, s1, t1
    andi t5, t1, 7      # t5 = t1 & 7
    beq t5, zero, test16_zero
    li t6, 4
    blt t5, t6, test16_small
    j test16_large
test16_zero:
    sub s1, s1, t1
    j test16_cont
test16_small:
    addi s1, s1, 1
    j test16_cont
test16_large:
    addi s1, s1, -1
test16_cont:
    addi t1, t1, 1
    blt t1, t0, test16_loop

# ==============================================================================
# TEST 17: Countdown loops
# ==============================================================================
    li t0, 100
test17_outer:
    li t2, 40
test17_inner:
    addi t2, t2, -1
    bgt t2, zero, test17_inner
    addi t0, t0, -1
    bgt t0, zero, test17_outer

# ==============================================================================
# TEST 18: Multiple exit conditions
# ==============================================================================
    li t0, 80
    li t1, 0
test18_outer:
    li t3, 0
    li t2, 60
test18_inner:
    li t5, 15
    beq t3, t5, test18_exit1
    li t5, 30
    beq t3, t5, test18_exit2
    li t5, 45
    beq t3, t5, test18_exit3
    addi t3, t3, 1
    blt t3, t2, test18_inner
    j test18_next
test18_exit1:
    nop
    j test18_next
test18_exit2:
    nop
    j test18_next
test18_exit3:
    nop
test18_next:
    addi t1, t1, 1
    blt t1, t0, test18_outer

# ==============================================================================
# TEST 19: Biased branches (mostly taken) - using AND for mod 8
# ==============================================================================
    li t0, 200
    li t1, 0
test19_loop:
    andi t6, t1, 7      # t6 = t1 & 7 (equivalent to mod 8)
    bne t6, zero, test19_taken  # Taken 7/8 times
    j test19_notaken
test19_taken:
    nop
test19_notaken:
    addi t1, t1, 1
    blt t1, t0, test19_loop

# ==============================================================================
# TEST 20: Biased branches (mostly not taken) - using AND for mod 8
# ==============================================================================
    li t0, 200
    li t1, 0
test20_loop:
    andi t6, t1, 7      # t6 = t1 & 7
    beq t6, zero, test20_taken  # Taken 1/8 times
    j test20_notaken
test20_taken:
    nop
test20_notaken:
    addi t1, t1, 1
    blt t1, t0, test20_loop

# ==============================================================================
# TEST 21: Long running simple loop
# ==============================================================================
    li t0, 500
    li t1, 0
test21_loop:
    addi t1, t1, 1
    blt t1, t0, test21_loop

# ==============================================================================
# TEST 22: Memory-intensive branch patterns
# Memory addresses: 200-400
# ==============================================================================
    li t0, 40
    li t1, 0
    li s0, 200          # Base address
test22_outer:
    li t3, 0
    li t2, 50
test22_inner:
    slli t5, t3, 2
    add t5, t5, s0
    sw t1, 0(t5)
    lw t6, 0(t5)
    beq t6, t1, test22_match
    j test22_nomatch
test22_match:
    nop
test22_nomatch:
    addi t3, t3, 1
    blt t3, t2, test22_inner
    addi t1, t1, 1
    blt t1, t0, test22_outer

# ==============================================================================
# TEST 23: Complex conditional chain using AND for mod 4
# ==============================================================================
    li t0, 100
    li t1, 0
test23_loop:
    andi t6, t1, 3      # t6 = t1 & 3 (mod 4)
    beq t6, zero, test23_mod0
    li t5, 1
    beq t6, t5, test23_mod1
    li t5, 2
    beq t6, t5, test23_mod2
    j test23_mod3
test23_mod0:
    nop
    j test23_end
test23_mod1:
    nop
    j test23_end
test23_mod2:
    nop
    j test23_end
test23_mod3:
    nop
test23_end:
    addi t1, t1, 1
    blt t1, t0, test23_loop

# ==============================================================================
# TEST 24: Back-to-back branches
# ==============================================================================
    li t0, 80
    li t1, 0
test24_outer:
    li t3, 0
    li t2, 30
test24_inner:
    li t5, 10
    blt t3, t5, test24_b1
    nop
test24_b1:
    li t5, 20
    blt t3, t5, test24_b2
    nop
test24_b2:
    li t5, 25
    bge t3, t5, test24_b3
    nop
test24_b3:
    addi t3, t3, 1
    blt t3, t2, test24_inner
    addi t1, t1, 1
    blt t1, t0, test24_outer

# ==============================================================================
# TEST 25: Triangular loop pattern
# ==============================================================================
    li t0, 30
    li t1, 0
test25_outer:
    li t3, 0
    mv t2, t1           # Inner loop runs t1 times
test25_inner:
    addi t3, t3, 1
    blt t3, t2, test25_inner
    addi t1, t1, 1
    blt t1, t0, test25_outer

# ==============================================================================
# TEST 26: Fibonacci-like branch pattern
# ==============================================================================
    li t0, 100
    li t1, 0
    li s1, 0            # fib(n-2)
    li s2, 1            # fib(n-1)
test26_loop:
    add s3, s1, s2      # fib(n) = fib(n-1) + fib(n-2)
    mv s1, s2
    mv s2, s3
    li t5, 1000
    blt s3, t5, test26_cont
    li s1, 0            # Reset if too large
    li s2, 1
test26_cont:
    addi t1, t1, 1
    blt t1, t0, test26_loop

# ==============================================================================
# TEST 27: Double nested with conditional
# ==============================================================================
    li t0, 25
    li t1, 0
test27_l1:
    li t3, 0
    li t2, 20
test27_l2:
    add t5, t1, t3
    andi t5, t5, 3
    beq t5, zero, test27_skip
    nop
test27_skip:
    addi t3, t3, 1
    blt t3, t2, test27_l2
    addi t1, t1, 1
    blt t1, t0, test27_l1

# ==============================================================================
# TEST 28: Stride pattern branches (mod 4 using AND)
# ==============================================================================
    li t0, 150
    li t1, 0
test28_loop:
    andi t6, t1, 3      # t6 = t1 & 3
    beq t6, zero, test28_stride
    j test28_nostride
test28_stride:
    nop
test28_nostride:
    addi t1, t1, 1
    blt t1, t0, test28_loop

# ==============================================================================
# TEST 29: Pattern using mod 8 (AND)
# ==============================================================================
    li t0, 140
    li t1, 0
test29_loop:
    andi t6, t1, 7      # t6 = t1 & 7
    beq t6, zero, test29_div8
    li t5, 1
    beq t6, t5, test29_mod1
    li t5, 2
    beq t6, t5, test29_mod2
    j test29_other
test29_div8:
    nop
    j test29_end
test29_mod1:
    nop
    j test29_end
test29_mod2:
    nop
    j test29_end
test29_other:
    nop
test29_end:
    addi t1, t1, 1
    blt t1, t0, test29_loop

# ==============================================================================
# TEST 30: Power of 2 detection pattern
# ==============================================================================
    li t0, 256
    li t1, 1
test30_loop:
    addi t5, t1, -1
    and t5, t5, t1
    beq t5, zero, test30_pow2
    j test30_notpow2
test30_pow2:
    nop
test30_notpow2:
    addi t1, t1, 1
    blt t1, t0, test30_loop

# ==============================================================================
# TEST 31: Signed comparison branches
# ==============================================================================
    li t0, 100
    li t1, -50
test31_loop:
    blt t1, zero, test31_neg
    j test31_pos
test31_neg:
    nop
test31_pos:
    addi t1, t1, 1
    blt t1, t0, test31_loop

# ==============================================================================
# TEST 32: Mixed loop with arithmetic dependencies
# ==============================================================================
    li t0, 80
    li t1, 0
    li s1, 1
test32_loop:
    slli s1, s1, 1      # s1 = s1 << 1
    li t5, 256
    bge s1, t5, test32_reset
    j test32_cont
test32_reset:
    li s1, 1
test32_cont:
    addi t1, t1, 1
    blt t1, t0, test32_loop

# ==============================================================================
# TEST 33: Triple nested loops
# ==============================================================================
    li s0, 10
    li s1, 0
test33_l1:
    li s2, 0
    li s3, 12
test33_l2:
    li s4, 0
    li s5, 15
test33_l3:
    addi s4, s4, 1
    blt s4, s5, test33_l3
    addi s2, s2, 1
    blt s2, s3, test33_l2
    addi s1, s1, 1
    blt s1, s0, test33_l1

# ==============================================================================
# TEST 34: Burst of short loops
# ==============================================================================
    li t0, 50
    li t1, 0
test34_outer:
    # Short loop 1
    li t3, 0
    li t2, 5
test34_s1:
    addi t3, t3, 1
    blt t3, t2, test34_s1
    # Short loop 2
    li t3, 0
test34_s2:
    addi t3, t3, 1
    blt t3, t2, test34_s2
    # Short loop 3
    li t3, 0
test34_s3:
    addi t3, t3, 1
    blt t3, t2, test34_s3
    # Short loop 4
    li t3, 0
test34_s4:
    addi t3, t3, 1
    blt t3, t2, test34_s4
    addi t1, t1, 1
    blt t1, t0, test34_outer

# ==============================================================================
# TEST 35: Load-dependent branches
# Memory addresses: 400-600
# ==============================================================================
    li t0, 50
    li t1, 0
    li s0, 400
    # Initialize memory
test35_init:
    slli t5, t1, 2
    add t5, t5, s0
    sw t1, 0(t5)
    addi t1, t1, 1
    blt t1, t0, test35_init
    # Now test
    li t1, 0
test35_outer:
    li t3, 0
    li t2, 50
test35_inner:
    slli t5, t3, 2
    add t5, t5, s0
    lw t6, 0(t5)
    li t4, 25
    blt t6, t4, test35_small
    j test35_big
test35_small:
    nop
test35_big:
    addi t3, t3, 1
    blt t3, t2, test35_inner
    addi t1, t1, 1
    li t0, 30
    blt t1, t0, test35_outer

# ==============================================================================
# TEST 36: XOR-based pattern
# ==============================================================================
    li t0, 160
    li t1, 0
    li s1, 0xAA
test36_loop:
    xor t5, t1, s1
    andi t5, t5, 0x0F
    li t6, 8
    blt t5, t6, test36_low
    j test36_high
test36_low:
    nop
test36_high:
    addi t1, t1, 1
    blt t1, t0, test36_loop

# ==============================================================================
# TEST 37: Alternating loop lengths
# ==============================================================================
    li t0, 40
    li t1, 0
test37_outer:
    andi t5, t1, 1
    beq t5, zero, test37_long
    # Short iteration
    li t3, 0
    li t2, 10
test37_short:
    addi t3, t3, 1
    blt t3, t2, test37_short
    j test37_cont
test37_long:
    li t3, 0
    li t2, 30
test37_longloop:
    addi t3, t3, 1
    blt t3, t2, test37_longloop
test37_cont:
    addi t1, t1, 1
    blt t1, t0, test37_outer

# ==============================================================================
# TEST 38: Comparison chain
# ==============================================================================
    li t0, 100
    li t1, 0
test38_loop:
    li t5, 20
    blt t1, t5, test38_r1
    li t5, 40
    blt t1, t5, test38_r2
    li t5, 60
    blt t1, t5, test38_r3
    li t5, 80
    blt t1, t5, test38_r4
    j test38_r5
test38_r1:
    nop
    j test38_end
test38_r2:
    nop
    j test38_end
test38_r3:
    nop
    j test38_end
test38_r4:
    nop
    j test38_end
test38_r5:
    nop
test38_end:
    addi t1, t1, 1
    blt t1, t0, test38_loop

# ==============================================================================
# TEST 39: Sum accumulation with threshold checks
# ==============================================================================
    li t0, 150
    li t1, 0
    li s1, 0
test39_loop:
    add s1, s1, t1
    li t5, 500
    bge s1, t5, test39_reset
    j test39_cont
test39_reset:
    li s1, 0
test39_cont:
    addi t1, t1, 1
    blt t1, t0, test39_loop

# ==============================================================================
# TEST 40: Bit manipulation branches
# ==============================================================================
    li t0, 128
    li t1, 0
test40_loop:
    andi t5, t1, 0x1F
    li t6, 16
    bge t5, t6, test40_high
    j test40_low
test40_high:
    nop
test40_low:
    addi t1, t1, 1
    blt t1, t0, test40_loop

# ==============================================================================
# TEST 41: Quad nested loops
# ==============================================================================
    li s0, 5
    li s1, 0
test41_l1:
    li s2, 0
    li s3, 6
test41_l2:
    li s4, 0
    li s5, 7
test41_l3:
    li s6, 0
    li s7, 8
test41_l4:
    addi s6, s6, 1
    blt s6, s7, test41_l4
    addi s4, s4, 1
    blt s4, s5, test41_l3
    addi s2, s2, 1
    blt s2, s3, test41_l2
    addi s1, s1, 1
    blt s1, s0, test41_l1

# ==============================================================================
# TEST 42: Sequential memory access with branches
# Memory addresses: 600-800
# ==============================================================================
    li t0, 30
    li t1, 0
    li s0, 600
test42_outer:
    li t3, 0
    li t2, 50
test42_inner:
    slli t5, t3, 2
    add t5, t5, s0
    sw t3, 0(t5)
    andi t6, t3, 3
    beq t6, zero, test42_skip
    lw t4, 0(t5)
test42_skip:
    addi t3, t3, 1
    blt t3, t2, test42_inner
    addi t1, t1, 1
    blt t1, t0, test42_outer

# ==============================================================================
# TEST 43: Decrementing with conditional
# ==============================================================================
    li t0, 50
test43_outer:
    mv t1, t0
test43_inner:
    li t5, 25
    bge t1, t5, test43_ge
    j test43_lt
test43_ge:
    nop
test43_lt:
    addi t1, t1, -1
    bgt t1, zero, test43_inner
    addi t0, t0, -1
    bgt t0, zero, test43_outer

# ==============================================================================
# TEST 44: Modulo 8 pattern (using AND)
# ==============================================================================
    li t0, 200
    li t1, 0
test44_loop:
    andi t5, t1, 7
    beq t5, zero, test44_m0
    li t6, 1
    beq t5, t6, test44_m1
    li t6, 2
    beq t5, t6, test44_m2
    li t6, 3
    beq t5, t6, test44_m3
    j test44_other
test44_m0:
    nop
    j test44_end
test44_m1:
    nop
    j test44_end
test44_m2:
    nop
    j test44_end
test44_m3:
    nop
    j test44_end
test44_other:
    nop
test44_end:
    addi t1, t1, 1
    blt t1, t0, test44_loop

# ==============================================================================
# TEST 45: LFSR-like pattern using shifts and XOR (no multiply)
# ==============================================================================
    li t0, 100
    li t1, 1
test45_loop:
    # Simple LFSR: feedback = bit0 XOR bit2
    andi t5, t1, 1      # bit 0
    srli t6, t1, 2
    andi t6, t6, 1      # bit 2
    xor t5, t5, t6      # feedback
    srli t1, t1, 1      # shift right
    slli t5, t5, 7      # move feedback to bit 7
    or t1, t1, t5       # insert feedback
    andi t1, t1, 0xFF   # keep 8 bits
    li t6, 128
    blt t1, t6, test45_low
    j test45_high
test45_low:
    nop
test45_high:
    addi t0, t0, -1
    bgt t0, zero, test45_loop

# ==============================================================================
# TEST 46: Early exit pattern
# ==============================================================================
    li t0, 60
    li t1, 0
test46_outer:
    li t3, 0
    li t2, 100
test46_inner:
    li t5, 50
    beq t3, t5, test46_early
    addi t3, t3, 1
    blt t3, t2, test46_inner
test46_early:
    addi t1, t1, 1
    blt t1, t0, test46_outer

# ==============================================================================
# TEST 47: Binary search pattern simulation
# ==============================================================================
    li t0, 80
    li t1, 0
test47_outer:
    li s1, 0            # Low
    li s2, 64           # High
test47_search:
    add s3, s1, s2      # Mid = (low + high) / 2
    srli s3, s3, 1
    li t5, 42           # Target
    beq s3, t5, test47_found
    blt s3, t5, test47_goleft
    mv s2, s3
    j test47_check
test47_goleft:
    mv s1, s3
test47_check:
    sub t5, s2, s1
    li t6, 1
    bgt t5, t6, test47_search
test47_found:
    addi t1, t1, 1
    blt t1, t0, test47_outer

# ==============================================================================
# TEST 48: Ripple pattern using AND
# ==============================================================================
    li t0, 60
    li t1, 0
test48_outer:
    li t3, 0
    li t2, 40
test48_inner:
    add t5, t1, t3
    andi t5, t5, 7      # mod 8 using AND
    li t6, 3
    blt t5, t6, test48_action
    j test48_skip
test48_action:
    nop
test48_skip:
    addi t3, t3, 1
    blt t3, t2, test48_inner
    addi t1, t1, 1
    blt t1, t0, test48_outer

# ==============================================================================
# TEST 49: Final stress test - long running loops
# ==============================================================================
    li t0, 200
    li t1, 0
test49_loop:
    addi t1, t1, 1
    blt t1, t0, test49_loop

    li t0, 200
    li t1, 0
test49b_loop:
    addi t1, t1, 1
    blt t1, t0, test49b_loop

    li t0, 200
    li t1, 0
test49c_loop:
    addi t1, t1, 1
    blt t1, t0, test49c_loop

# ==============================================================================
# TEST 50: Mixed final test
# ==============================================================================
    li t0, 50
    li t1, 0
test50_outer:
    li t3, 0
    li t2, 30
test50_inner:
    andi t5, t3, 3
    beq t5, zero, test50_a
    li t6, 1
    beq t5, t6, test50_b
    li t6, 2
    beq t5, t6, test50_c
    j test50_d
test50_a:
    nop
    j test50_cont
test50_b:
    nop
    j test50_cont
test50_c:
    nop
    j test50_cont
test50_d:
    nop
test50_cont:
    addi t3, t3, 1
    blt t3, t2, test50_inner
    addi t1, t1, 1
    blt t1, t0, test50_outer

# ==============================================================================
# FINALIZATION
# ==============================================================================
    # Set a0 to 0 (success)
    li a0, 0

    # Custom instruction to print a0
    .insn r 0x2B, 0, 0, x0, a0, x0

    # Custom instruction to stop execution

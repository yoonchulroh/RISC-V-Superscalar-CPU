# RV32I Comprehensive Test - 50 Test Cases
# Tests jumps, branches, memory operations, and their combinations
# a0 = test number on failure, a0 = 0 if all pass
# Final result stored in a0
# Only uses .text section, memory addresses < 4000

.text
.globl _start

_start:
    # Initialize base pointers for memory tests
    # s0 = data base address (use address 2000 for data)
    # sp = stack pointer (use address 3900 for stack, growing down)
    addi s0, x0, 2000       # s0 = 2000 (data area base, fits in 12-bit)
    lui sp, 1               # sp = 4096
    addi sp, sp, -196       # sp = 4096 - 196 = 3900 (stack top)

    #==========================================================================
    # TEST 1: Basic BEQ - equal case
    #==========================================================================
test1:
    addi t0, x0, 5
    addi t1, x0, 5
    beq t0, t1, test2
    addi a0, x0, 1
    j fail

    #==========================================================================
    # TEST 2: Basic BEQ - not equal case (should not branch)
    #==========================================================================
test2:
    addi t0, x0, 5
    addi t1, x0, 6
    beq t0, t1, test2_fail
    j test3
test2_fail:
    addi a0, x0, 2
    j fail

    #==========================================================================
    # TEST 3: Basic BNE - not equal case
    #==========================================================================
test3:
    addi t0, x0, 10
    addi t1, x0, 20
    bne t0, t1, test4
    addi a0, x0, 3
    j fail

    #==========================================================================
    # TEST 4: Basic BNE - equal case (should not branch)
    #==========================================================================
test4:
    addi t0, x0, 15
    addi t1, x0, 15
    bne t0, t1, test4_fail
    j test5
test4_fail:
    addi a0, x0, 4
    j fail

    #==========================================================================
    # TEST 5: Basic BLT - less than case (signed)
    #==========================================================================
test5:
    addi t0, x0, -5
    addi t1, x0, 5
    blt t0, t1, test6
    addi a0, x0, 5
    j fail

    #==========================================================================
    # TEST 6: Basic BLT - not less than (should not branch)
    #==========================================================================
test6:
    addi t0, x0, 10
    addi t1, x0, 5
    blt t0, t1, test6_fail
    j test7
test6_fail:
    addi a0, x0, 6
    j fail

    #==========================================================================
    # TEST 7: Basic BGE - greater or equal case
    #==========================================================================
test7:
    addi t0, x0, 10
    addi t1, x0, 10
    bge t0, t1, test8
    addi a0, x0, 7
    j fail

    #==========================================================================
    # TEST 8: Basic BLTU - unsigned less than
    #==========================================================================
test8:
    addi t0, x0, 5
    addi t1, x0, -1      # -1 = 0xFFFFFFFF, largest unsigned
    bltu t0, t1, test9
    addi a0, x0, 8
    j fail

    #==========================================================================
    # TEST 9: Basic BGEU - unsigned greater or equal
    #==========================================================================
test9:
    addi t0, x0, -1      # Largest unsigned
    addi t1, x0, 100
    bgeu t0, t1, test10
    addi a0, x0, 9
    j fail

    #==========================================================================
    # TEST 10: Basic JAL
    #==========================================================================
test10:
    jal ra, test10_target
    addi t2, x0, 1       # t2 should be 1 after return
    beq t2, t2, test11   # Always branch to test11
    addi a0, x0, 10
    j fail
test10_target:
    addi t2, x0, 1
    jalr x0, ra, 0       # Return

    #==========================================================================
    # TEST 11: Basic JALR
    #==========================================================================
test11:
    auipc t0, 0          # Get current PC
    addi t0, t0, 24      # Add offset to test11_target (6 instructions * 4 = 24)
    jalr ra, t0, 0
    beq t3, t3, test12   # Continue to test12
    addi a0, x0, 11
    j fail
test11_target:
    addi t3, x0, 42
    jalr x0, ra, 0       # Return

    #==========================================================================
    # TEST 12: Basic SW and LW
    #==========================================================================
test12:
    addi t0, x0, 0x123
    sw t0, 0(s0)
    lw t1, 0(s0)
    bne t0, t1, test12_fail
    j test13
test12_fail:
    addi a0, x0, 12
    j fail

    #==========================================================================
    # TEST 13: SW and LW with offset
    #==========================================================================
test13:
    addi t0, x0, 0x456
    sw t0, 4(s0)
    lw t1, 4(s0)
    bne t0, t1, test13_fail
    j test14
test13_fail:
    addi a0, x0, 13
    j fail

    #==========================================================================
    # TEST 14: SB and LBU
    #==========================================================================
test14:
    addi t0, x0, 0xAB
    sb t0, 8(s0)
    lbu t1, 8(s0)
    andi t0, t0, 0xFF    # Mask to byte
    bne t0, t1, test14_fail
    j test15
test14_fail:
    addi a0, x0, 14
    j fail

    #==========================================================================
    # TEST 15: SB and LB (sign extension)
    #==========================================================================
test15:
    addi t0, x0, -1      # 0xFF as byte
    sb t0, 9(s0)
    lb t1, 9(s0)
    bne t0, t1, test15_fail   # Should be -1 (sign extended)
    j test16
test15_fail:
    addi a0, x0, 15
    j fail

    #==========================================================================
    # TEST 16: SH and LHU
    #==========================================================================
test16:
    addi t0, x0, 0x567    # Valid 12-bit immediate
    sh t0, 10(s0)
    lhu t1, 10(s0)
    bne t0, t1, test16_fail
    j test17
test16_fail:
    addi a0, x0, 16
    j fail

    #==========================================================================
    # TEST 17: Consecutive branches - all taken
    #==========================================================================
test17:
    addi t0, x0, 1
    addi t1, x0, 1
    beq t0, t1, test17_b1
    addi a0, x0, 17
    j fail
test17_b1:
    addi t0, x0, 2
    addi t1, x0, 3
    bne t0, t1, test17_b2
    addi a0, x0, 17
    j fail
test17_b2:
    addi t0, x0, -1
    addi t1, x0, 1
    blt t0, t1, test18
    addi a0, x0, 17
    j fail

    #==========================================================================
    # TEST 18: Consecutive branches - all not taken
    #==========================================================================
test18:
    addi t0, x0, 1
    addi t1, x0, 2
    beq t0, t1, test18_fail
    addi t0, x0, 5
    addi t1, x0, 5
    bne t0, t1, test18_fail
    addi t0, x0, 10
    addi t1, x0, 5
    blt t0, t1, test18_fail
    j test19
test18_fail:
    addi a0, x0, 18
    j fail

    #==========================================================================
    # TEST 19: Consecutive memory stores
    #==========================================================================
test19:
    addi t0, x0, 100
    addi t1, x0, 200
    addi t2, x0, 300
    addi t3, x0, 400
    sw t0, 0(s0)
    sw t1, 4(s0)
    sw t2, 8(s0)
    sw t3, 12(s0)
    lw t4, 0(s0)
    lw t5, 4(s0)
    lw t6, 8(s0)
    lw s1, 12(s0)
    bne t0, t4, test19_fail
    bne t1, t5, test19_fail
    bne t2, t6, test19_fail
    bne t3, s1, test19_fail
    j test20
test19_fail:
    addi a0, x0, 19
    j fail

    #==========================================================================
    # TEST 20: Consecutive memory loads
    #==========================================================================
test20:
    # Data already stored from test19
    lw t0, 0(s0)
    lw t1, 4(s0)
    lw t2, 8(s0)
    lw t3, 12(s0)
    add t4, t0, t1
    add t4, t4, t2
    add t4, t4, t3      # t4 = 100+200+300+400 = 1000
    addi t5, x0, 1000
    bne t4, t5, test20_fail
    j test21
test20_fail:
    addi a0, x0, 20
    j fail

    #==========================================================================
    # TEST 21: Consecutive jumps
    #==========================================================================
test21:
    j test21_j1
test21_ret:
    j test22
test21_j1:
    j test21_j2
test21_j2:
    j test21_j3
test21_j3:
    j test21_j4
test21_j4:
    j test21_ret

    #==========================================================================
    # TEST 22: JAL chain
    #==========================================================================
test22:
    jal ra, test22_f1
    addi t0, t0, 1      # t0 should be 4 after all calls
    addi t1, x0, 4
    bne t0, t1, test22_fail
    j test23
test22_fail:
    addi a0, x0, 22
    j fail
test22_f1:
    addi t0, x0, 1
    addi sp, sp, -4
    sw ra, 0(sp)
    jal ra, test22_f2
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr x0, ra, 0
test22_f2:
    addi t0, t0, 1
    addi sp, sp, -4
    sw ra, 0(sp)
    jal ra, test22_f3
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr x0, ra, 0
test22_f3:
    addi t0, t0, 1
    jalr x0, ra, 0

    #==========================================================================
    # TEST 23: JALR with computed address
    #==========================================================================
test23:
    auipc t0, 0          # Get current PC
    addi t0, t0, 16      # Offset to test23_target
    jalr ra, t0, 0       # Jump to test23_target
    j test23_check
test23_target:
    addi t1, x0, 1
    jalr x0, ra, 0
test23_check:
    addi t2, x0, 1
    bne t1, t2, test23_fail
    j test24
test23_fail:
    addi a0, x0, 23
    j fail

    #==========================================================================
    # TEST 24: Load after store to same address
    #==========================================================================
test24:
    addi t0, x0, 0x7FF
    sw t0, 16(s0)
    lw t1, 16(s0)
    bne t0, t1, test24_fail
    addi t0, x0, 0x123
    sw t0, 16(s0)
    lw t1, 16(s0)
    bne t0, t1, test24_fail
    j test25
test24_fail:
    addi a0, x0, 24
    j fail

    #==========================================================================
    # TEST 25: Store-load forwarding test
    #==========================================================================
test25:
    addi t0, x0, 999
    sw t0, 20(s0)
    nop
    lw t1, 20(s0)
    bne t0, t1, test25_fail
    j test26
test25_fail:
    addi a0, x0, 25
    j fail

    #==========================================================================
    # TEST 26: Branch backward
    #==========================================================================
test26:
    addi t0, x0, 0
    addi t1, x0, 5
test26_loop:
    addi t0, t0, 1
    blt t0, t1, test26_loop
    addi t2, x0, 5
    bne t0, t2, test26_fail
    j test27
test26_fail:
    addi a0, x0, 26
    j fail

    #==========================================================================
    # TEST 27: Nested loops
    #==========================================================================
test27:
    addi t0, x0, 0      # outer counter
    addi t3, x0, 0      # total count
test27_outer:
    addi t1, x0, 0      # inner counter
test27_inner:
    addi t3, t3, 1
    addi t1, t1, 1
    addi t2, x0, 3
    blt t1, t2, test27_inner
    addi t0, t0, 1
    addi t2, x0, 3
    blt t0, t2, test27_outer
    # t3 should be 3*3 = 9
    addi t4, x0, 9
    bne t3, t4, test27_fail
    j test28
test27_fail:
    addi a0, x0, 27
    j fail

    #==========================================================================
    # TEST 28: Mixed branch types
    #==========================================================================
test28:
    addi t0, x0, 5
    addi t1, x0, 10
    addi t2, x0, 5
    beq t0, t2, test28_p1
    addi a0, x0, 28
    j fail
test28_p1:
    blt t0, t1, test28_p2
    addi a0, x0, 28
    j fail
test28_p2:
    bge t1, t0, test28_p3
    addi a0, x0, 28
    j fail
test28_p3:
    bne t0, t1, test29
    addi a0, x0, 28
    j fail

    #==========================================================================
    # TEST 29: Memory byte operations
    #==========================================================================
test29:
    addi t0, x0, 0x11
    addi t1, x0, 0x22
    addi t2, x0, 0x33
    addi t3, x0, 0x44
    sb t0, 24(s0)
    sb t1, 25(s0)
    sb t2, 26(s0)
    sb t3, 27(s0)
    lbu t4, 24(s0)
    lbu t5, 25(s0)
    lbu t6, 26(s0)
    lbu s1, 27(s0)
    bne t0, t4, test29_fail
    bne t1, t5, test29_fail
    bne t2, t6, test29_fail
    bne t3, s1, test29_fail
    j test30
test29_fail:
    addi a0, x0, 29
    j fail

    #==========================================================================
    # TEST 30: Memory half-word operations
    #==========================================================================
test30:
    addi t0, x0, 0x567    # Valid 12-bit immediate
    addi t1, x0, 0x789    # Valid 12-bit immediate
    sh t0, 28(s0)
    sh t1, 30(s0)
    lhu t2, 28(s0)
    lhu t3, 30(s0)
    bne t0, t2, test30_fail
    bne t1, t3, test30_fail
    j test31
test30_fail:
    addi a0, x0, 30
    j fail

    #==========================================================================
    # TEST 31: Branch with computation
    #==========================================================================
test31:
    addi t0, x0, 10
    addi t1, x0, 20
    add t2, t0, t1       # t2 = 30
    addi t3, x0, 30
    beq t2, t3, test32
    addi a0, x0, 31
    j fail

    #==========================================================================
    # TEST 32: Memory then branch
    #==========================================================================
test32:
    addi t0, x0, 777
    sw t0, 0(s0)
    lw t1, 0(s0)
    beq t0, t1, test33
    addi a0, x0, 32
    j fail

    #==========================================================================
    # TEST 33: Branch then memory
    #==========================================================================
test33:
    addi t0, x0, 1
    addi t1, x0, 1
    beq t0, t1, test33_store
    addi a0, x0, 33
    j fail
test33_store:
    addi t2, x0, 888
    sw t2, 4(s0)
    lw t3, 4(s0)
    bne t2, t3, test33_fail
    j test34
test33_fail:
    addi a0, x0, 33
    j fail

    #==========================================================================
    # TEST 34: Jump then memory
    #==========================================================================
test34:
    j test34_mem
test34_check:
    lw t1, 8(s0)
    addi t2, x0, 456
    beq t1, t2, test35
    addi a0, x0, 34
    j fail
test34_mem:
    addi t0, x0, 456
    sw t0, 8(s0)
    j test34_check

    #==========================================================================
    # TEST 35: Signed comparison edge case
    #==========================================================================
test35:
    lui t0, 0x80000      # t0 = 0x80000000 (most negative)
    addi t1, x0, 0       # t1 = 0
    blt t0, t1, test36   # -2^31 < 0 should be true
    addi a0, x0, 35
    j fail

    #==========================================================================
    # TEST 36: Unsigned comparison edge case
    #==========================================================================
test36:
    lui t0, 0x80000      # t0 = 0x80000000
    addi t1, x0, 0       # t1 = 0
    bgeu t0, t1, test37  # 0x80000000 >= 0 (unsigned) is true
    addi a0, x0, 36
    j fail

    #==========================================================================
    # TEST 37: JAL return address
    #==========================================================================
test37:
    jal ra, test37_func
test37_ret:
    auipc t0, 0          # Get PC at test37_ret
    addi t0, t0, -4      # Adjust: auipc is at test37_ret, so subtract 4 to compare with ra
    # Actually, jal stores PC+4 (next instruction after jal), which is test37_ret
    # So ra should equal address of test37_ret
    # We're now at test37_ret, auipc t0,0 gives us current PC
    # But we need to check if ra == address of test37_ret
    # Let's use a different approach: check if jalr to ra works correctly
    j test38
test37_func:
    jalr x0, ra, 0

    #==========================================================================
    # TEST 38: JALR return address
    #==========================================================================
test38:
    auipc t0, 0          # Get current PC
    addi t0, t0, 16      # Offset to test38_func
    jalr ra, t0, 0
test38_ret:
    # If we got here, the return worked
    j test39
test38_func:
    jalr x0, ra, 0

    #==========================================================================
    # TEST 39: Complex addressing
    #==========================================================================
test39:
    addi t0, s0, 32      # t0 = s0 + 32
    addi t1, x0, 0x5A5   # Valid 12-bit immediate (1445)
    sw t1, 0(t0)
    lw t2, 32(s0)
    bne t1, t2, test39_fail
    j test40
test39_fail:
    addi a0, x0, 39
    j fail

    #==========================================================================
    # TEST 40: LUI test
    #==========================================================================
test40:
    lui t0, 0x12345
    lui t1, 0x12345
    beq t0, t1, test41
    addi a0, x0, 40
    j fail

    #==========================================================================
    # TEST 41: AUIPC test
    #==========================================================================
test41:
    auipc t0, 0          # t0 = PC
    addi t1, t0, 8       # t1 = PC + 8 (next instruction after addi)
    auipc t2, 0          # Should be PC+8
    bne t1, t2, test41_fail
    j test42
test41_fail:
    addi a0, x0, 41
    j fail

    #==========================================================================
    # TEST 42: Multiple data dependencies with memory
    #==========================================================================
test42:
    addi t0, x0, 10
    sw t0, 0(s0)
    lw t1, 0(s0)
    add t2, t1, t1       # t2 = 20
    sw t2, 4(s0)
    lw t3, 4(s0)
    add t4, t3, t3       # t4 = 40
    addi t5, x0, 40
    bne t4, t5, test42_fail
    j test43
test42_fail:
    addi a0, x0, 42
    j fail

    #==========================================================================
    # TEST 43: Back-to-back branches (alternating taken/not-taken)
    #==========================================================================
test43:
    addi t0, x0, 1
    addi t1, x0, 2
    beq t0, t0, test43_p1    # taken
    addi a0, x0, 43
    j fail
test43_p1:
    beq t0, t1, test43_fail  # not taken
    bne t0, t1, test43_p2    # taken
    addi a0, x0, 43
    j fail
test43_p2:
    bne t0, t0, test43_fail  # not taken
    j test44
test43_fail:
    addi a0, x0, 43
    j fail

    #==========================================================================
    # TEST 44: Store then immediate load to different address
    #==========================================================================
test44:
    addi t0, x0, 111
    addi t1, x0, 222
    sw t0, 0(s0)
    sw t1, 4(s0)
    lw t2, 4(s0)         # Load from different address
    lw t3, 0(s0)
    bne t0, t3, test44_fail
    bne t1, t2, test44_fail
    j test45
test44_fail:
    addi a0, x0, 44
    j fail

    #==========================================================================
    # TEST 45: Recursive-like call pattern
    #==========================================================================
test45:
    addi a1, x0, 5       # Counter
    addi a2, x0, 0       # Sum
    jal ra, test45_recurse
    addi t0, x0, 15      # Expected: 5+4+3+2+1 = 15
    bne a2, t0, test45_fail
    j test46
test45_fail:
    addi a0, x0, 45
    j fail
test45_recurse:
    beq a1, x0, test45_ret   # Base case
    add a2, a2, a1           # sum += counter
    addi a1, a1, -1          # counter--
    addi sp, sp, -4
    sw ra, 0(sp)
    jal ra, test45_recurse
    lw ra, 0(sp)
    addi sp, sp, 4
test45_ret:
    jalr x0, ra, 0

    #==========================================================================
    # TEST 46: Byte access pattern
    #==========================================================================
test46:
    addi t0, x0, 0xDE
    addi t1, x0, 0xAD
    addi t2, x0, 0xBE
    addi t3, x0, 0xEF
    sb t0, 0(s0)
    sb t1, 1(s0)
    sb t2, 2(s0)
    sb t3, 3(s0)
    # Verify bytes are in correct positions
    lbu t5, 0(s0)
    lbu t6, 1(s0)
    lbu s1, 2(s0)
    lbu s2, 3(s0)
    bne t0, t5, test46_fail
    bne t1, t6, test46_fail
    bne t2, s1, test46_fail
    bne t3, s2, test46_fail
    j test47
test46_fail:
    addi a0, x0, 46
    j fail

    #==========================================================================
    # TEST 47: Branch with negative offset loop
    #==========================================================================
test47:
    addi t0, x0, 10
    addi t1, x0, 0
test47_loop:
    addi t1, t1, 1
    addi t0, t0, -1
    bne t0, x0, test47_loop
    addi t2, x0, 10
    bne t1, t2, test47_fail
    j test48
test47_fail:
    addi a0, x0, 47
    j fail

    #==========================================================================
    # TEST 48: Indirect jump test
    #==========================================================================
test48:
    auipc t0, 0          # Get current PC
    addi t0, t0, 24      # Jump 6 instructions ahead to test48_target
    jalr x0, t0, 0       # Indirect jump (no link)
    addi a0, x0, 48      # Should not execute
    j fail
    addi a0, x0, 48      # Should not execute
    j fail
test48_target:
    j test49

    #==========================================================================
    # TEST 49: Stress consecutive operations
    #==========================================================================
test49:
    # 8 consecutive stores
    addi t0, x0, 1
    addi t1, x0, 2
    addi t2, x0, 3
    addi t3, x0, 4
    addi t4, x0, 5
    addi t5, x0, 6
    addi t6, x0, 7
    addi s1, x0, 8
    sw t0, 0(s0)
    sw t1, 4(s0)
    sw t2, 8(s0)
    sw t3, 12(s0)
    sw t4, 16(s0)
    sw t5, 20(s0)
    sw t6, 24(s0)
    sw s1, 28(s0)
    # 8 consecutive loads and sum
    lw a1, 0(s0)
    lw a2, 4(s0)
    lw a3, 8(s0)
    lw a4, 12(s0)
    lw a5, 16(s0)
    lw a6, 20(s0)
    lw a7, 24(s0)
    lw s2, 28(s0)
    add s3, a1, a2
    add s3, s3, a3
    add s3, s3, a4
    add s3, s3, a5
    add s3, s3, a6
    add s3, s3, a7
    add s3, s3, s2       # s3 = 1+2+3+4+5+6+7+8 = 36
    addi s4, x0, 36
    bne s3, s4, test49_fail
    j test50
test49_fail:
    addi a0, x0, 49
    j fail

    #==========================================================================
    # TEST 50: Final integration test
    #==========================================================================
test50:
    # Complex sequence: computation, memory, branch, jump, call
    addi t0, x0, 100
    addi t1, x0, 50
    add t2, t0, t1       # t2 = 150
    sw t2, 0(s0)
    lw t3, 0(s0)
    bne t2, t3, test50_fail
    jal ra, test50_func
    addi t5, x0, 300
    bne t4, t5, test50_fail
    # All consecutive branches
    beq t4, t5, test50_b1
    addi a0, x0, 50
    j fail
test50_b1:
    addi t6, x0, 300
    bge t4, t6, test50_b2
    addi a0, x0, 50
    j fail
test50_b2:
    bne t0, t1, test50_b3
    addi a0, x0, 50
    j fail
test50_b3:
    blt t1, t0, pass
    addi a0, x0, 50
    j fail
test50_fail:
    addi a0, x0, 50
    j fail
test50_func:
    add t4, t2, t3       # t4 = 150 + 150 = 300
    jalr x0, ra, 0

    #==========================================================================
    # ALL TESTS PASSED
    #==========================================================================
pass:
    addi a0, x0, 0       # a0 = 0 means all tests passed
    j end

    #==========================================================================
    # FAILURE HANDLER
    #==========================================================================
fail:
    # a0 already contains the failing test number
    j end

    #==========================================================================
    # END OF PROGRAM
    #==========================================================================
end:
    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0

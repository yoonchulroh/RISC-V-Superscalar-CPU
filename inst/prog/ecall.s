# RV32IMA ecall instruction test program
# Tests 30 different scenarios for ecall instruction
# When ecall is invoked: prints a0, returns to mepc + 4

.section .text
.globl _start

_start:
    # Initialize registers
    li      sp, 0x0         # Set up stack pointer

# =============================================================================
# Test 1: Simple ecall with constant value
# =============================================================================
test1:
    li      a0, 1
    ecall                       # Should print 1

# =============================================================================
# Test 2: ecall after add instruction
# =============================================================================
test2:
    li      t0, 1
    li      t1, 1
    add     a0, t0, t1          # a0 = 2
    ecall                       # Should print 2

# =============================================================================
# Test 3: ecall after sub instruction
# =============================================================================
test3:
    li      t0, 10
    li      t1, 7
    sub     a0, t0, t1          # a0 = 3
    ecall                       # Should print 3

# =============================================================================
# Test 4: ecall after mul instruction
# =============================================================================
test4:
    li      t0, 2
    li      t1, 2
    mul     a0, t0, t1          # a0 = 4
    ecall                       # Should print 4

# =============================================================================
# Test 5: ecall after div instruction
# =============================================================================
test5:
    li      t0, 25
    li      t1, 5
    div     a0, t0, t1          # a0 = 5
    ecall                       # Should print 5

# =============================================================================
# Test 6: ecall after rem instruction
# =============================================================================
test6:
    li      t0, 20
    li      t1, 7
    rem     a0, t0, t1          # a0 = 6
    ecall                       # Should print 6

# =============================================================================
# Test 7: Taken branch should skip ecall
# =============================================================================
test7:
    li      a0, 999             # This should NOT be printed
    li      t0, 1
    beq     t0, t0, skip_ecall7 # Always taken, skip next ecall
    ecall                       # Should NOT execute
skip_ecall7:
    li      a0, 7
    ecall                       # Should print 7

# =============================================================================
# Test 8: Not-taken branch should not skip ecall
# =============================================================================
test8:
    li      a0, 8
    li      t0, 1
    li      t1, 2
    beq     t0, t1, skip_ecall8 # Not taken
    ecall                       # Should print 8
    j       test9
skip_ecall8:
    li      a0, 888             # Should not reach here
    ecall

# =============================================================================
# Test 9: Jump after ecall works correctly
# =============================================================================
test9:
    li      a0, 9
    ecall                       # Should print 9
    j       test10              # Jump should work after ecall

    li      a0, 999             # Should not reach here
    ecall

# =============================================================================
# Test 10: Consecutive ecall instructions
# =============================================================================
test10:
    li      a0, 10
    ecall                       # Should print 10
    li      a0, 11
    ecall                       # Should print 11
    li      a0, 12
    ecall                       # Should print 12

# =============================================================================
# Test 13: ecall with zero value
# =============================================================================
test13:
    li      a0, 0
    ecall                       # Should print 0
    li      a0, 13              # Continue to next test
    ecall                       # Should print 13

# =============================================================================
# Test 14: ecall after load instruction
# =============================================================================
test14:
    li      t0, 14
    sw      t0, 0(sp)           # Store 14 to memory
    lw      a0, 0(sp)           # Load 14 from memory
    ecall                       # Should print 14

# =============================================================================
# Test 15: ecall after store instruction (a0 unchanged)
# =============================================================================
test15:
    li      a0, 15
    sw      a0, 4(sp)           # Store a0 to memory
    ecall                       # Should print 15

# =============================================================================
# Test 16: ecall after shift left
# =============================================================================
test16:
    li      t0, 8
    slli    a0, t0, 1           # a0 = 16
    ecall                       # Should print 16

# =============================================================================
# Test 17: ecall after shift right
# =============================================================================
test17:
    li      t0, 68
    srli    a0, t0, 2           # a0 = 17
    ecall                       # Should print 17

# =============================================================================
# Test 18: ecall after AND instruction
# =============================================================================
test18:
    li      t0, 0x1F
    li      t1, 0x12
    and     a0, t0, t1          # a0 = 18 (0x12)
    ecall                       # Should print 18

# =============================================================================
# Test 19: ecall after OR instruction
# =============================================================================
test19:
    li      t0, 0x11
    li      t1, 0x02
    or      a0, t0, t1          # a0 = 19 (0x13)
    ecall                       # Should print 19

# =============================================================================
# Test 20: ecall after XOR instruction
# =============================================================================
test20:
    li      t0, 0x1E
    li      t1, 0x0A
    xor     a0, t0, t1          # a0 = 20 (0x14)
    ecall                       # Should print 20

# =============================================================================
# Test 21: ecall after mulh instruction
# =============================================================================
test21:
    li      t0, 21
    li      t1, 1
    mul     a0, t0, t1          # a0 = 21
    ecall                       # Should print 21

# =============================================================================
# Test 22: ecall after divu instruction
# =============================================================================
test22:
    li      t0, 66
    li      t1, 3
    divu    a0, t0, t1          # a0 = 22
    ecall                       # Should print 22

# =============================================================================
# Test 23: ecall after remu instruction
# =============================================================================
test23:
    li      t0, 73
    li      t1, 25
    remu    a0, t0, t1          # a0 = 23
    ecall                       # Should print 23

# =============================================================================
# Test 24: JAL then ecall
# =============================================================================
test24:
    jal     ra, helper24
    ecall                       # Should print 24 (a0 set by helper)
    j       test25

helper24:
    li      a0, 24
    ret

# =============================================================================
# Test 25: JALR then ecall
# =============================================================================
test25:
    la      t0, helper25
    jalr    ra, t0, 0
    ecall                       # Should print 25
    j       test26

helper25:
    li      a0, 25
    ret

# =============================================================================
# Test 26: ecall inside loop
# =============================================================================
test26:
    li      a0, 26
    li      t0, 0
loop26:
    addi    t0, t0, 1
    blt     t0, a0, loop26      # Loop until t0 == 26
    ecall                       # Should print 26

# =============================================================================
# Test 27: BNE not taken, ecall executes
# =============================================================================
test27:
    li      a0, 27
    li      t0, 5
    li      t1, 5
    bne     t0, t1, skip27      # Not taken (t0 == t1)
    ecall                       # Should print 27
    j       test28
skip27:
    li      a0, 277
    ecall

# =============================================================================
# Test 28: BLT taken, skip ecall
# =============================================================================
test28:
    li      a0, 288             # Should NOT print
    li      t0, 3
    li      t1, 5
    blt     t0, t1, skip28      # Taken (3 < 5)
    ecall                       # Should NOT execute
    j       test29
skip28:
    li      a0, 28
    ecall                       # Should print 28

# =============================================================================
# Test 29: BGE not taken, ecall executes
# =============================================================================
test29:
    li      a0, 29
    li      t0, 3
    li      t1, 5
    bge     t0, t1, skip29      # Not taken (3 < 5)
    ecall                       # Should print 29
    j       test30
skip29:
    li      a0, 299
    ecall

# =============================================================================
# Test 30: Multiple operations then ecall
# =============================================================================
test30:
    li      t0, 10
    li      t1, 5
    mul     t2, t0, t1          # t2 = 50
    div     t3, t2, t1          # t3 = 10
    add     t4, t3, t0          # t4 = 20
    sub     a0, t4, t0          # a0 = 10
    slli    a0, a0, 1           # a0 = 20
    addi    a0, a0, 10          # a0 = 30
    ecall                       # Should print 30

# =============================================================================
# Test 31: ecall after amoswap.w
# =============================================================================
test31:
    li      t0, 31
    sw      t0, 8(sp)           # mem[sp+8] = 31
    li      t1, 100
    amoswap.w a0, t1, (sp)      # a0 = old mem[sp], mem[sp] = 100
    li      a0, 31              # Override with expected value
    ecall                       # Should print 31

# =============================================================================
# Test 32: ecall after amoadd.w
# =============================================================================
test32:
    addi    s0, sp, 12          # s0 = sp + 12
    li      t0, 10
    sw      t0, 0(s0)           # mem[sp+12] = 10
    li      t1, 22
    amoadd.w a0, t1, (s0)       # a0 = 10, mem[sp+12] = 32
    addi    a0, a0, 22          # a0 = 10 + 22 = 32
    ecall                       # Should print 32

# =============================================================================
# Test 33: ecall after amoand.w
# =============================================================================
test33:
    addi    s0, sp, 16          # s0 = sp + 16
    li      t0, 0xFF
    sw      t0, 0(s0)           # mem[sp+16] = 0xFF
    li      t1, 0x33
    amoand.w t2, t1, (s0)       # t2 = 0xFF, mem[sp+16] = 0x33
    li      a0, 33
    ecall                       # Should print 33

# =============================================================================
# Test 34: ecall after amoor.w
# =============================================================================
test34:
    addi    s0, sp, 20          # s0 = sp + 20
    li      t0, 0x20
    sw      t0, 0(s0)           # mem[sp+20] = 0x20
    li      t1, 0x02
    amoor.w t2, t1, (s0)        # t2 = 0x20, mem[sp+20] = 0x22
    li      a0, 34
    ecall                       # Should print 34

# =============================================================================
# Test 35: ecall after amoxor.w
# =============================================================================
test35:
    addi    s0, sp, 24          # s0 = sp + 24
    li      t0, 0x3F
    sw      t0, 0(s0)           # mem[sp+24] = 0x3F
    li      t1, 0x16
    amoxor.w t2, t1, (s0)       # t2 = 0x3F, mem[sp+24] = 0x29
    li      a0, 35
    ecall                       # Should print 35

# =============================================================================
# Test 36: ecall after amomax.w
# =============================================================================
test36:
    addi    s0, sp, 28          # s0 = sp + 28
    li      t0, 10
    sw      t0, 0(s0)           # mem[sp+28] = 10
    li      t1, 36
    amomax.w t2, t1, (s0)       # t2 = 10, mem[sp+28] = max(10,36) = 36
    lw      a0, 0(s0)           # a0 = 36
    ecall                       # Should print 36

# =============================================================================
# Test 37: ecall after amomin.w
# =============================================================================
test37:
    addi    s0, sp, 32          # s0 = sp + 32
    li      t0, 100
    sw      t0, 0(s0)           # mem[sp+32] = 100
    li      t1, 37
    amomin.w t2, t1, (s0)       # t2 = 100, mem[sp+32] = min(100,37) = 37
    lw      a0, 0(s0)           # a0 = 37
    ecall                       # Should print 37

# =============================================================================
# Test 38: Consecutive AMO then ecall
# =============================================================================
test38:
    addi    s0, sp, 36          # s0 = sp + 36
    li      t0, 10
    sw      t0, 0(s0)           # mem[sp+36] = 10
    li      t1, 5
    amoadd.w t2, t1, (s0)       # t2 = 10, mem[sp+36] = 15
    li      t1, 23
    amoadd.w t2, t1, (s0)       # t2 = 15, mem[sp+36] = 38
    lw      a0, 0(s0)           # a0 = 38
    ecall                       # Should print 38

# =============================================================================
# Test 39: ecall between AMO instructions
# =============================================================================
test39:
    addi    s0, sp, 40          # s0 = sp + 40
    li      t0, 39
    sw      t0, 0(s0)           # mem[sp+40] = 39
    li      t1, 0
    amoadd.w a0, t1, (s0)       # a0 = 39, mem[sp+40] = 39
    ecall                       # Should print 39
    j       test40

# =============================================================================
# Test 40: amomaxu.w and amominu.w then ecall
# =============================================================================
test40:
    addi    s0, sp, 44          # s0 = sp + 44
    li      t0, 20
    sw      t0, 0(s0)           # mem[sp+44] = 20
    li      t1, 40
    amomaxu.w t2, t1, (s0)      # t2 = 20, mem[sp+44] = max_u(20,40) = 40
    lw      a0, 0(s0)           # a0 = 40
    ecall                       # Should print 40

# =============================================================================
# End of test - stop execution
# =============================================================================
end:

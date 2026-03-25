# RV32IM Division and Remainder Instruction Test
# Tests div, divu, rem, remu with 40 test cases (10 each)
# If test i fails, a0 = i. If all pass, a0 = 0.

.text
.globl _start

_start:
    # ============================================
    # DIV Tests (Signed Division) - Tests 1-10
    # ============================================

    # Test 1: Basic positive / positive: 20 / 4 = 5
    li t0, 20
    li t1, 4
    div t2, t0, t1
    li t3, 5
    li a0, 1
    bne t2, t3, fail

    # Test 2: Negative / positive: -20 / 4 = -5
    li t0, -20
    li t1, 4
    div t2, t0, t1
    li t3, -5
    li a0, 2
    bne t2, t3, fail

    # Test 3: Positive / negative: 20 / -4 = -5
    li t0, 20
    li t1, -4
    div t2, t0, t1
    li t3, -5
    li a0, 3
    bne t2, t3, fail

    # Test 4: Negative / negative: -20 / -4 = 5
    li t0, -20
    li t1, -4
    div t2, t0, t1
    li t3, 5
    li a0, 4
    bne t2, t3, fail

    # Test 5: Division by zero: 10 / 0 = -1 (all bits set)
    li t0, 10
    li t1, 0
    div t2, t0, t1
    li t3, -1
    li a0, 5
    bne t2, t3, fail

    # Test 6: Overflow case: MIN_INT / -1 = MIN_INT (0x80000000)
    li t0, 0x80000000      # -2147483648
    li t1, -1
    div t2, t0, t1
    li t3, 0x80000000
    li a0, 6
    bne t2, t3, fail

    # Test 7: Large positive / small positive: 1000000 / 7 = 142857
    li t0, 1000000
    li t1, 7
    div t2, t0, t1
    li t3, 142857
    li a0, 7
    bne t2, t3, fail

    # Test 8: Small / large: 5 / 100 = 0
    li t0, 5
    li t1, 100
    div t2, t0, t1
    li t3, 0
    li a0, 8
    bne t2, t3, fail

    # Test 9: Zero dividend: 0 / 5 = 0
    li t0, 0
    li t1, 5
    div t2, t0, t1
    li t3, 0
    li a0, 9
    bne t2, t3, fail

    # Test 10: Equal values: 123 / 123 = 1
    li t0, 123
    li t1, 123
    div t2, t0, t1
    li t3, 1
    li a0, 10
    bne t2, t3, fail

    # ============================================
    # DIVU Tests (Unsigned Division) - Tests 11-20
    # ============================================

    # Test 11: Basic unsigned: 20 / 4 = 5
    li t0, 20
    li t1, 4
    divu t2, t0, t1
    li t3, 5
    li a0, 11
    bne t2, t3, fail

    # Test 12: Large unsigned / small: 0xFFFFFFFF / 2 = 0x7FFFFFFF
    li t0, 0xFFFFFFFF
    li t1, 2
    divu t2, t0, t1
    li t3, 0x7FFFFFFF
    li a0, 12
    bne t2, t3, fail

    # Test 13: Division by zero: 10 / 0 = 0xFFFFFFFF
    li t0, 10
    li t1, 0
    divu t2, t0, t1
    li t3, 0xFFFFFFFF
    li a0, 13
    bne t2, t3, fail

    # Test 14: 0x80000000 / 2 = 0x40000000
    li t0, 0x80000000
    li t1, 2
    divu t2, t0, t1
    li t3, 0x40000000
    li a0, 14
    bne t2, t3, fail

    # Test 15: Large values: 0xF0000000 / 0x10 = 0x0F000000
    li t0, 0xF0000000
    li t1, 0x10
    divu t2, t0, t1
    li t3, 0x0F000000
    li a0, 15
    bne t2, t3, fail

    # Test 16: Small / large unsigned: 5 / 0x80000000 = 0
    li t0, 5
    li t1, 0x80000000
    divu t2, t0, t1
    li t3, 0
    li a0, 16
    bne t2, t3, fail

    # Test 17: Zero dividend: 0 / 5 = 0
    li t0, 0
    li t1, 5
    divu t2, t0, t1
    li t3, 0
    li a0, 17
    bne t2, t3, fail

    # Test 18: Equal values: 0xABCDEF00 / 0xABCDEF00 = 1
    li t0, 0xABCDEF00
    li t1, 0xABCDEF00
    divu t2, t0, t1
    li t3, 1
    li a0, 18
    bne t2, t3, fail

    # Test 19: 100 / 7 = 14
    li t0, 100
    li t1, 7
    divu t2, t0, t1
    li t3, 14
    li a0, 19
    bne t2, t3, fail

    # Test 20: Power of 2: 256 / 16 = 16
    li t0, 256
    li t1, 16
    divu t2, t0, t1
    li t3, 16
    li a0, 20
    bne t2, t3, fail

    # ============================================
    # REM Tests (Signed Remainder) - Tests 21-30
    # ============================================

    # Test 21: Basic positive % positive: 20 % 7 = 6
    li t0, 20
    li t1, 7
    rem t2, t0, t1
    li t3, 6
    li a0, 21
    bne t2, t3, fail

    # Test 22: Negative % positive: -20 % 7 = -6
    li t0, -20
    li t1, 7
    rem t2, t0, t1
    li t3, -6
    li a0, 22
    bne t2, t3, fail

    # Test 23: Positive % negative: 20 % -7 = 6
    li t0, 20
    li t1, -7
    rem t2, t0, t1
    li t3, 6
    li a0, 23
    bne t2, t3, fail

    # Test 24: Negative % negative: -20 % -7 = -6
    li t0, -20
    li t1, -7
    rem t2, t0, t1
    li t3, -6
    li a0, 24
    bne t2, t3, fail

    # Test 25: Remainder by zero: 10 % 0 = 10 (dividend)
    li t0, 10
    li t1, 0
    rem t2, t0, t1
    li t3, 10
    li a0, 25
    bne t2, t3, fail

    # Test 26: Overflow case: MIN_INT % -1 = 0
    li t0, 0x80000000
    li t1, -1
    rem t2, t0, t1
    li t3, 0
    li a0, 26
    bne t2, t3, fail

    # Test 27: Exact division: 21 % 7 = 0
    li t0, 21
    li t1, 7
    rem t2, t0, t1
    li t3, 0
    li a0, 27
    bne t2, t3, fail

    # Test 28: Small % large: 5 % 100 = 5
    li t0, 5
    li t1, 100
    rem t2, t0, t1
    li t3, 5
    li a0, 28
    bne t2, t3, fail

    # Test 29: Zero % positive: 0 % 5 = 0
    li t0, 0
    li t1, 5
    rem t2, t0, t1
    li t3, 0
    li a0, 29
    bne t2, t3, fail

    # Test 30: Large positive % small: 1000003 % 1000 = 3
    li t0, 1000003
    li t1, 1000
    rem t2, t0, t1
    li t3, 3
    li a0, 30
    bne t2, t3, fail

    # ============================================
    # REMU Tests (Unsigned Remainder) - Tests 31-40
    # ============================================

    # Test 31: Basic unsigned: 20 % 7 = 6
    li t0, 20
    li t1, 7
    remu t2, t0, t1
    li t3, 6
    li a0, 31
    bne t2, t3, fail

    # Test 32: Large unsigned: 0xFFFFFFFF % 0x10 = 0xF
    li t0, 0xFFFFFFFF
    li t1, 0x10
    remu t2, t0, t1
    li t3, 0xF
    li a0, 32
    bne t2, t3, fail

    # Test 33: Remainder by zero: 10 % 0 = 10 (dividend)
    li t0, 10
    li t1, 0
    remu t2, t0, t1
    li t3, 10
    li a0, 33
    bne t2, t3, fail

    # Test 34: 0x80000000 % 3 = 2
    li t0, 0x80000000
    li t1, 3
    remu t2, t0, t1
    li t3, 2
    li a0, 34
    bne t2, t3, fail

    # Test 35: Exact division: 100 % 25 = 0
    li t0, 100
    li t1, 25
    remu t2, t0, t1
    li t3, 0
    li a0, 35
    bne t2, t3, fail

    # Test 36: Small % large: 5 % 0x80000000 = 5
    li t0, 5
    li t1, 0x80000000
    remu t2, t0, t1
    li t3, 5
    li a0, 36
    bne t2, t3, fail

    # Test 37: Zero % positive: 0 % 5 = 0
    li t0, 0
    li t1, 5
    remu t2, t0, t1
    li t3, 0
    li a0, 37
    bne t2, t3, fail

    # Test 38: Equal values: 0xDEADBEEF % 0xDEADBEEF = 0
    li t0, 0xDEADBEEF
    li t1, 0xDEADBEEF
    remu t2, t0, t1
    li t3, 0
    li a0, 38
    bne t2, t3, fail

    # Test 39: Power of 2: 0xABCD1234 % 0x100 = 0x34
    li t0, 0xABCD1234
    li t1, 0x100
    remu t2, t0, t1
    li t3, 0x34
    li a0, 39
    bne t2, t3, fail

    # Test 40: Large % small: 0xFFFFFFF0 % 7 = 2
    li t0, 0xFFFFFFF0
    li t1, 7
    remu t2, t0, t1
    li t3, 2
    li a0, 40
    bne t2, t3, fail

    # ============================================
    # All tests passed
    # ============================================
    li a0, 0

fail:
    ecall
    

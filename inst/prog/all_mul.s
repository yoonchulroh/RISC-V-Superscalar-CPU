# inst/prog/all_mul.s
# RV32IM Multiply High Test Suite
# Tests mulh, mulhu, mulhsu

.section .text
.globl _start

# -----------------------------------------------------------------------------
# Macro: TEST_CASE
# Arguments:
#   id:       Immediate value for the test case ID (1-30)
#   opcode:   The instruction to test (mulh, mulhu, mulhsu)
#   op1:      Operand 1 (immediate value)
#   op2:      Operand 2 (immediate value)
#   exp:      Expected result in the destination register (upper 32 bits)
# -----------------------------------------------------------------------------
.macro TEST_CASE id, opcode, op1, op2, exp
    li      a0, \id           # Load Test ID into a0 (in case of failure)
    li      t0, \op1          # Load operand 1
    li      t1, \op2          # Load operand 2
    li      t2, \exp          # Load expected result
    
    \opcode t3, t0, t1        # Execute: t3 = (t0 * t1) >> 32
    
    bne     t3, t2, fail      # If t3 != expected, jump to fail
.endm

_start:
    # -------------------------------------------------------------------------
    # BATCH 1: MULH (Signed * Signed)
    # -------------------------------------------------------------------------

    # Test 1: 0 * 0 = 0
    TEST_CASE 1, mulh, 0, 0, 0

    # Test 2: Small positive * Small positive (No overflow to high)
    # 10 * 10 = 100. High = 0
    TEST_CASE 2, mulh, 10, 10, 0

    # Test 3: Small neg * Small neg (No overflow to high)
    # -1 * -1 = 1. High = 0
    TEST_CASE 3, mulh, -1, -1, 0

    # Test 4: Small pos * Small neg (Sign extension check)
    # 10 * -1 = -10 (0xFF...F6). High = -1 (0xFFFFFFFF)
    TEST_CASE 4, mulh, 10, -1, -1

    # Test 5: 2^30 * 4 (Crosses 32-bit boundary)
    # 0x40000000 * 4 = 0x100000000. High = 1
    TEST_CASE 5, mulh, 0x40000000, 4, 1

    # Test 6: INT_MAX * 2
    # 0x7FFFFFFF * 2 = 0xFFFFFFFE (Fits in 32-bit uns, but signed 64-bit result is pos)
    # Signed calc: 2147483647 * 2 = 4294967294. 
    # In Hex 64: 0x00000000FFFFFFFE. High = 0
    TEST_CASE 6, mulh, 0x7FFFFFFF, 2, 0

    # Test 7: INT_MIN * INT_MIN (Max overflow)
    # -2^31 * -2^31 = 2^62. 
    # Hex: 0x4000000000000000. High = 0x40000000
    TEST_CASE 7, mulh, 0x80000000, 0x80000000, 0x40000000

    # Test 8: INT_MIN * INT_MAX
    # -2^31 * (2^31 - 1) = -2^62 + 2^31
    # Hex: 0xC000000080000000. High = 0xC0000000
    TEST_CASE 8, mulh, 0x80000000, 0x7FFFFFFF, 0xC0000000

    # Test 9: -1 * 1
    # Result -1 (0xFF...FF). High = -1
    TEST_CASE 9, mulh, -1, 1, -1

    # Test 10: 2^30 * 5
    # 0x40000000 * 5 = 5 * 2^30 = (4+1)*2^30 = 2^32 + 2^30
    # Hex: 0x140000000. High = 1
    TEST_CASE 10, mulh, 0x40000000, 5, 1

    # -------------------------------------------------------------------------
    # BATCH 2: MULHU (Unsigned * Unsigned)
    # -------------------------------------------------------------------------

    # Test 11: 0 * 0xFFFFFFFF
    TEST_CASE 11, mulhu, 0, 0xFFFFFFFF, 0

    # Test 12: UINT_MAX * 1
    TEST_CASE 12, mulhu, 0xFFFFFFFF, 1, 0

    # Test 13: UINT_MAX * 2
    # (2^32 - 1) * 2 = 2^33 - 2. 
    # Hex: 0x1FFFFFFFE. High = 1
    TEST_CASE 13, mulhu, 0xFFFFFFFF, 2, 1

    # Test 14: UINT_MAX * UINT_MAX
    # (2^32 - 1)^2 = 2^64 - 2^33 + 1
    # Hex: 0xFFFFFFFE00000001. High = 0xFFFFFFFE
    TEST_CASE 14, mulhu, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFE

    # Test 15: 0x80000000 * 2
    # 2^31 * 2 = 2^32. High = 1
    TEST_CASE 15, mulhu, 0x80000000, 2, 1

    # Test 16: 0x80000000 * 0x80000000
    # 2^31 * 2^31 = 2^62. High = 0x40000000
    TEST_CASE 16, mulhu, 0x80000000, 0x80000000, 0x40000000

    # Test 17: Large alternating bits pattern
    # 0xAAAAAAAA * 2
    # 1010... * 10 = 1010...0
    # Hex 64: 0x155555554. High = 1
    TEST_CASE 17, mulhu, 0xAAAAAAAA, 2, 1

    # Test 18: 0x40000000 * 4
    # 2^30 * 2^2 = 2^32. High = 1
    TEST_CASE 18, mulhu, 0x40000000, 4, 1

    # Test 19: 0x10000000 * 0x10000000
    # 2^28 * 2^28 = 2^56.
    # 56 - 32 = 24. High = 2^24 = 0x01000000
    TEST_CASE 19, mulhu, 0x10000000, 0x10000000, 0x01000000

    # Test 20: Just below overflow
    # 0xFFFFFFFF * 0 = 0
    TEST_CASE 20, mulhu, 0xFFFFFFFF, 0, 0

    # -------------------------------------------------------------------------
    # BATCH 3: MULHSU (Signed * Unsigned)
    # RS1 is Signed, RS2 is Unsigned
    # -------------------------------------------------------------------------

    # Test 21: -1 (Signed) * 1 (Unsigned)
    # -1 * 1 = -1. 64-bit Hex: 0xFFFFFFFFFFFFFFFF. High = 0xFFFFFFFF
    TEST_CASE 21, mulhsu, -1, 1, 0xFFFFFFFF

    # Test 22: 1 (Signed) * 0xFFFFFFFF (Unsigned, large positive)
    # 1 * (2^32 - 1) = 2^32 - 1. 
    # 64-bit Hex: 0x00000000FFFFFFFF. High = 0
    TEST_CASE 22, mulhsu, 1, 0xFFFFFFFF, 0

    # Test 23: -1 (Signed) * 0xFFFFFFFF (Unsigned)
    # -1 * (2^32 - 1) = -2^32 + 1
    # 64-bit Hex: 0xFFFFFFFF00000001. High = 0xFFFFFFFF
    TEST_CASE 23, mulhsu, -1, 0xFFFFFFFF, 0xFFFFFFFF

    # Test 24: INT_MIN (Signed) * 2 (Unsigned)
    # -2^31 * 2 = -2^32.
    # 64-bit Hex: 0xFFFFFFFF00000000. High = 0xFFFFFFFF
    TEST_CASE 24, mulhsu, 0x80000000, 2, 0xFFFFFFFF

    # Test 25: INT_MIN (Signed) * 0 (Unsigned)
    TEST_CASE 25, mulhsu, 0x80000000, 0, 0

    # Test 26: INT_MIN (Signed) * INT_MIN (interpreted as Unsigned)
    # Signed: -2^31. Unsigned: 2^31.
    # -2^31 * 2^31 = -2^62.
    # 64-bit Hex: 0xC000000000000000. High = 0xC0000000
    TEST_CASE 26, mulhsu, 0x80000000, 0x80000000, 0xC0000000

    # Test 27: -2 (Signed) * 2 (Unsigned)
    # -2 * 2 = -4. High = 0xFFFFFFFF
    TEST_CASE 27, mulhsu, -2, 2, 0xFFFFFFFF

    # Test 28: 0 (Signed) * 0xFFFFFFFF (Unsigned)
    TEST_CASE 28, mulhsu, 0, 0xFFFFFFFF, 0

    # Test 29: 0x40000000 (Pos Signed) * 0x80000000 (Pos Unsigned)
    # 2^30 * 2^31 = 2^61.
    # 64-bit Hex: 0x2000000000000000. High = 0x20000000
    TEST_CASE 29, mulhsu, 0x40000000, 0x80000000, 0x20000000

    # Test 30: -2^31 (Signed) * 1 (Unsigned)
    # Result: -2^31. High: 0xFFFFFFFF (Sign extension of negative number)
    TEST_CASE 30, mulhsu, 0x80000000, 1, 0xFFFFFFFF

pass:
    li      a0, 0             # Set return code to 0 (Success)
    j       end               # Jump to cleanup

fail:
    # a0 is already set to the Test ID by the macro
    j       end

end:
    # Custom instructions as requested
    ecall
    
# inst/prog/atomic.s
# RV32IMA Atomic Instruction Test Suite
# Tests: amoswap.w, amoadd.w, amoand.w, amoor.w, amoxor.w, amomax.w, amomin.w
# 10 Test Cases per instruction.

.global _start

.data
# No data needed, using immediate addresses.

.text

# -----------------------------------------------------------------------------
# Macro: START_TEST
# Arguments:
#   id:       Test Case ID (stored in t6 for error reporting)
#   init_mem: Initial value to store in memory at 0(s1)
#   val_rs2:  Initial value for rs2 (t1)
# -----------------------------------------------------------------------------
.macro START_TEST id, init_mem, val_rs2
    li      t6, \id             # Load Test ID
    
    # Initialize Memory
    li      t0, \init_mem
    sw      t0, 0(s1)           # Store initial value to [s1]

    # Initialize rs2
    li      t1, \val_rs2        # Set rs2 (t1)
.endm

# -----------------------------------------------------------------------------
# Macro: CHECK_TEST
# Arguments:
#   exp_rd:   Expected value in destination register (t2)
#   exp_mem:  Expected value in memory at 0(s1)
# -----------------------------------------------------------------------------
.macro CHECK_TEST exp_rd, exp_mem
    # Check Destination Register (t2)
    li      t3, \exp_rd
    bne     t2, t3, test_fail

    # Check Memory Result
    lw      t4, 0(s1)
    li      t5, \exp_mem
    bne     t4, t5, test_fail
.endm

_start:
    # Initialize Base Address for Atomic Operations
    # Address 0x100 is < 4000.
    li      s1, 0x100   
    li      x0, 0       # Ensure x0 is 0

    # =========================================================================
    # 1. AMOSWAP.W (Swap)
    #    rd = mem; mem = rs2
    # =========================================================================

    # Case 1: Basic Swap
    START_TEST 1, 10, 20
    amoswap.w t2, t1, (s1)
    CHECK_TEST 10, 20

    # Case 2: Swap with Zero
    START_TEST 2, 55, 0
    amoswap.w t2, t1, (s1)
    CHECK_TEST 55, 0

    # Case 3: Swap Negative Values
    START_TEST 3, -5, -10
    amoswap.w t2, t1, (s1)
    CHECK_TEST -5, -10

    # Case 4: Swap Max Int
    START_TEST 4, 0, 0x7FFFFFFF
    amoswap.w t2, t1, (s1)
    CHECK_TEST 0, 0x7FFFFFFF

    # Case 5: Swap Min Int
    START_TEST 5, 1, 0x80000000
    amoswap.w t2, t1, (s1)
    CHECK_TEST 1, 0x80000000

    # Case 6: Mul right before AMO
    START_TEST 6, 100, 200
    li      t5, 10
    li      t3, 20
    mul     t5, t5, t3
    amoswap.w t2, t1, (s1)
    CHECK_TEST 100, 200

    # Case 7: Consecutive AMO
    START_TEST 7, 10, 30
    li      t5, 20
    amoswap.w t0, t5, (s1)      # First: Mem becomes 20
    amoswap.w t2, t1, (s1)      # Second (Tested): Swap 30. Exp rd=20
    CHECK_TEST 20, 30

    # Case 8: Memory Store right before AMO
    START_TEST 8, 999, 40
    li      t5, 50
    sw      t5, 0(s1)           # Overwrite 999 with 50
    amoswap.w t2, t1, (s1)
    CHECK_TEST 50, 40

    # Case 9: Memory Load right after AMO
    START_TEST 9, 11, 22
    amoswap.w t2, t1, (s1)
    lw      t0, 0(s1)           # Load immediately after
    CHECK_TEST 11, 22

    # Case 10: Register update right before AMO
    START_TEST 10, 5, 10
    addi    t1, t1, 5           # Update rs2: 10 -> 15
    amoswap.w t2, t1, (s1)
    CHECK_TEST 5, 15

    # =========================================================================
    # 2. AMOADD.W (Add)
    #    rd = mem; mem = mem + rs2
    # =========================================================================

    # Case 11: Basic Add
    START_TEST 11, 10, 20
    amoadd.w t2, t1, (s1)
    CHECK_TEST 10, 30

    # Case 12: Add Zero
    START_TEST 12, 50, 0
    amoadd.w t2, t1, (s1)
    CHECK_TEST 50, 50

    # Case 13: Add Negative
    START_TEST 13, 10, -5
    amoadd.w t2, t1, (s1)
    CHECK_TEST 10, 5

    # Case 14: Add Overflow (Positive)
    START_TEST 14, 0x7FFFFFFF, 1
    amoadd.w t2, t1, (s1)
    CHECK_TEST 0x7FFFFFFF, 0x80000000

    # Case 15: Add Overflow (Negative)
    START_TEST 15, -1, -1
    amoadd.w t2, t1, (s1)
    CHECK_TEST -1, -2

    # Case 16: Div right before AMO
    START_TEST 16, 100, 50
    li      t5, 200
    li      t3, 2
    div     t5, t5, t3
    amoadd.w t2, t1, (s1)
    CHECK_TEST 100, 150

    # Case 17: Consecutive AMO
    START_TEST 17, 10, 5
    li      t5, 5
    amoadd.w t0, t5, (s1)       # Mem 10+5 = 15
    amoadd.w t2, t1, (s1)       # Mem 15+5 = 20
    CHECK_TEST 15, 20

    # Case 18: Store right before
    START_TEST 18, 0, 10
    li      t5, 5
    sw      t5, 0(s1)           # Mem = 5
    amoadd.w t2, t1, (s1)
    CHECK_TEST 5, 15

    # Case 19: Load right after
    START_TEST 19, 10, 10
    amoadd.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 10, 20

    # Case 20: Register update (rs2)
    START_TEST 20, 10, 10
    addi    t1, t1, 10          # rs2 = 20
    amoadd.w t2, t1, (s1)
    CHECK_TEST 10, 30

    # =========================================================================
    # 3. AMOAND.W (Logical AND)
    #    rd = mem; mem = mem & rs2
    # =========================================================================

    # Case 21: Basic And
    START_TEST 21, 0xF, 0x3
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xF, 0x3

    # Case 22: And Zero
    START_TEST 22, 0xFF, 0x0
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xFF, 0x0

    # Case 23: And Identity
    START_TEST 23, 0x55, 0xFFFFFFFF
    amoand.w t2, t1, (s1)
    CHECK_TEST 0x55, 0x55

    # Case 24: Bit clearing
    START_TEST 24, 0xF0, 0x0F
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xF0, 0x0

    # Case 25: Complex Mask
    START_TEST 25, 0xABC, 0x0F0
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xABC, 0x0B0

    # Case 26: Mul before
    START_TEST 26, 0xF, 0x1
    mul     t5, t1, t1
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xF, 0x1

    # Case 27: Consecutive
    START_TEST 27, 0xF, 0x3
    li      t5, 0x7
    amoand.w t0, t5, (s1)       # Mem: F & 7 = 7
    amoand.w t2, t1, (s1)       # Mem: 7 & 3 = 3
    CHECK_TEST 0x7, 0x3

    # Case 28: Store before
    START_TEST 28, 0, 0xF
    li      t5, 0xFF
    sw      t5, 0(s1)           # Mem = FF
    amoand.w t2, t1, (s1)       # FF & F = F
    CHECK_TEST 0xFF, 0xF

    # Case 29: Load after
    START_TEST 29, 0xFF, 0xF0
    amoand.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 0xFF, 0xF0

    # Case 30: Reg update
    START_TEST 30, 0xF, 0x0
    addi    t1, t1, 1           # rs2 = 1
    amoand.w t2, t1, (s1)
    CHECK_TEST 0xF, 0x1

    # =========================================================================
    # 4. AMOOR.W (Logical OR)
    #    rd = mem; mem = mem | rs2
    # =========================================================================

    # Case 31: Basic Or
    START_TEST 31, 0x1, 0x2
    amoor.w t2, t1, (s1)
    CHECK_TEST 0x1, 0x3

    # Case 32: Or Zero
    START_TEST 32, 0x55, 0x0
    amoor.w t2, t1, (s1)
    CHECK_TEST 0x55, 0x55

    # Case 33: Or All Ones
    START_TEST 33, 0x0, 0xFFFFFFFF
    amoor.w t2, t1, (s1)
    CHECK_TEST 0x0, -1

    # Case 34: Overlapping bits
    START_TEST 34, 0xF0, 0xFF
    amoor.w t2, t1, (s1)
    CHECK_TEST 0xF0, 0xFF

    # Case 35: High bits
    START_TEST 35, 0x1, 0x80000000
    amoor.w t2, t1, (s1)
    CHECK_TEST 0x1, 0x80000001

    # Case 36: Div before
    START_TEST 36, 0x1, 0x2
    div     t5, t1, t1
    amoor.w t2, t1, (s1)
    CHECK_TEST 0x1, 0x3

    # Case 37: Consecutive
    START_TEST 37, 0, 2
    li      t5, 1
    amoor.w t0, t5, (s1)        # Mem: 0 | 1 = 1
    amoor.w t2, t1, (s1)        # Mem: 1 | 2 = 3
    CHECK_TEST 1, 3

    # Case 38: Store before
    START_TEST 38, 0, 1
    sw      x0, 0(s1)           # Store 0
    amoor.w t2, t1, (s1)
    CHECK_TEST 0, 1

    # Case 39: Load after
    START_TEST 39, 0xF, 0x0
    amoor.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 0xF, 0xF

    # Case 40: Reg update
    START_TEST 40, 0x0, 0x1
    addi    t1, t1, 2           # rs2: 1 -> 3
    amoor.w t2, t1, (s1)        # 0 | 3 = 3
    CHECK_TEST 0x0, 0x3

    # =========================================================================
    # 5. AMOXOR.W (Logical XOR)
    #    rd = mem; mem = mem ^ rs2
    # =========================================================================

    # Case 41: Basic Xor
    START_TEST 41, 0xF, 0xF
    amoxor.w t2, t1, (s1)
    CHECK_TEST 0xF, 0

    # Case 42: Xor Zero
    START_TEST 42, 0x55, 0x0
    amoxor.w t2, t1, (s1)
    CHECK_TEST 0x55, 0x55

    # Case 43: Toggle bits
    START_TEST 43, 0xFF, 0x0F
    amoxor.w t2, t1, (s1)
    CHECK_TEST 0xFF, 0xF0

    # Case 44: Xor Negatives
    START_TEST 44, -1, -1
    amoxor.w t2, t1, (s1)
    CHECK_TEST -1, 0

    # Case 45: Alternating bits
    START_TEST 45, 0xAAAAAAAA, 0x55555555
    amoxor.w t2, t1, (s1)
    CHECK_TEST 0xAAAAAAAA, -1

    # Case 46: Mul before
    START_TEST 46, 1, 1
    mul     t5, t1, t1
    amoxor.w t2, t1, (s1)
    CHECK_TEST 1, 0

    # Case 47: Consecutive
    START_TEST 47, 0, 5
    li      t5, 5
    amoxor.w t0, t5, (s1)       # 0 ^ 5 = 5
    amoxor.w t2, t1, (s1)       # 5 ^ 5 = 0
    CHECK_TEST 5, 0

    # Case 48: Store before
    START_TEST 48, 0, 0xF
    li      t5, 0xA
    sw      t5, 0(s1)           # Mem = 0xA
    amoxor.w t2, t1, (s1)       # A ^ F = 5
    CHECK_TEST 0xA, 0x5

    # Case 49: Load after
    START_TEST 49, 0xFF, 0xFF
    amoxor.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 0xFF, 0

    # Case 50: Reg update
    START_TEST 50, 0xF, 0x0
    addi    t1, t1, 1           # rs2 = 1
    amoxor.w t2, t1, (s1)       # F ^ 1 = E
    CHECK_TEST 0xF, 0xE

    # =========================================================================
    # 6. AMOMAX.W (Signed Max)
    #    rd = mem; mem = max(mem, rs2)
    # =========================================================================

    # Case 51: Max(Small, Large) -> Update
    START_TEST 51, 10, 20
    amomax.w t2, t1, (s1)
    CHECK_TEST 10, 20

    # Case 52: Max(Large, Small) -> No Update
    START_TEST 52, 20, 10
    amomax.w t2, t1, (s1)
    CHECK_TEST 20, 20

    # Case 53: Max(Neg, Pos)
    START_TEST 53, -5, 5
    amomax.w t2, t1, (s1)
    CHECK_TEST -5, 5

    # Case 54: Max(Neg Small, Neg Large)
    # -1 > -10
    START_TEST 54, -1, -10
    amomax.w t2, t1, (s1)
    CHECK_TEST -1, -1

    # Case 55: Max(Neg Large, Neg Small)
    START_TEST 55, -10, -1
    amomax.w t2, t1, (s1)
    CHECK_TEST -10, -1

    # Case 56: Mul before
    START_TEST 56, 10, 20
    mul     t5, t1, t1
    amomax.w t2, t1, (s1)
    CHECK_TEST 10, 20

    # Case 57: Consecutive
    START_TEST 57, 10, 20
    li      t5, 5
    amomax.w t0, t5, (s1)       # Max(10, 5) = 10
    amomax.w t2, t1, (s1)       # Max(10, 20) = 20
    CHECK_TEST 10, 20

    # Case 58: Store before
    START_TEST 58, 0, 100
    li      t5, 50
    sw      t5, 0(s1)           # Mem = 50
    amomax.w t2, t1, (s1)       # Max(50, 100) = 100
    CHECK_TEST 50, 100

    # Case 59: Load after
    START_TEST 59, 10, 10
    amomax.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 10, 10

    # Case 60: Reg update
    START_TEST 60, 10, 5
    addi    t1, t1, 15          # rs2 = 20
    amomax.w t2, t1, (s1)       # Max(10, 20) = 20
    CHECK_TEST 10, 20

    # =========================================================================
    # 7. AMOMIN.W (Signed Min)
    #    rd = mem; mem = min(mem, rs2)
    # =========================================================================

    # Case 61: Min(Small, Large) -> No Update
    START_TEST 61, 10, 20
    amomin.w t2, t1, (s1)
    CHECK_TEST 10, 10

    # Case 62: Min(Large, Small) -> Update
    START_TEST 62, 20, 10
    amomin.w t2, t1, (s1)
    CHECK_TEST 20, 10

    # Case 63: Min(Neg, Pos)
    START_TEST 63, -5, 5
    amomin.w t2, t1, (s1)
    CHECK_TEST -5, -5

    # Case 64: Min(Pos, Neg)
    START_TEST 64, 5, -5
    amomin.w t2, t1, (s1)
    CHECK_TEST 5, -5

    # Case 65: Min of negatives
    # -10 < -1
    START_TEST 65, -1, -10
    amomin.w t2, t1, (s1)
    CHECK_TEST -1, -10

    # Case 66: Div before
    START_TEST 66, 10, 5
    div     t5, t1, t1
    amomin.w t2, t1, (s1)
    CHECK_TEST 10, 5

    # Case 67: Consecutive
    START_TEST 67, 10, 5
    li      t5, 20
    amomin.w t0, t5, (s1)       # Min(10, 20) = 10
    amomin.w t2, t1, (s1)       # Min(10, 5) = 5
    CHECK_TEST 10, 5

    # Case 68: Store before
    START_TEST 68, 0, 10
    li      t5, 20
    sw      t5, 0(s1)           # Mem = 20
    amomin.w t2, t1, (s1)       # Min(20, 10) = 10
    CHECK_TEST 20, 10

    # Case 69: Load after
    START_TEST 69, 5, 10
    amomin.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 5, 5

    # Case 70: Reg update
    START_TEST 70, 20, 30
    addi    t1, t1, -20         # rs2 = 10
    amomin.w t2, t1, (s1)       # Min(20, 10) = 10
    CHECK_TEST 20, 10

    # =========================================================================
    # 8. AMOMAXU.W (Unsigned Max)
    #    rd = mem; mem = maxu(mem, rs2)
    # =========================================================================

    # Case 71: Basic Maxu (Small < Large) -> Update
    START_TEST 71, 10, 20
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 10, 20

    # Case 72: Basic Maxu (Large > Small) -> No Update
    START_TEST 72, 20, 10
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 20, 20

    # Case 73: Unsigned vs Signed Distinction
    # Signed: 1 > -1. Unsigned: 1 < 0xFFFFFFFF.
    # We expect update to 0xFFFFFFFF (-1).
    START_TEST 73, 1, -1
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 1, -1

    # Case 74: Maxu with Zero
    START_TEST 74, 0, 5
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 0, 5

    # Case 75: Maxu High Values
    # 0xFFFFFF00 < 0xFFFFFF01
    START_TEST 75, 0xFFFFFF00, 0xFFFFFF01
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 0xFFFFFF00, 0xFFFFFF01

    # Case 76: Mul before
    START_TEST 76, 10, 20
    mul     t5, t1, t1
    amomaxu.w t2, t1, (s1)
    CHECK_TEST 10, 20

    # Case 77: Consecutive
    START_TEST 77, 10, 100
    li      t5, 50
    amomaxu.w t0, t5, (s1)      # Maxu(10, 50) = 50
    amomaxu.w t2, t1, (s1)      # Maxu(50, 100) = 100
    CHECK_TEST 50, 100

    # Case 78: Store before
    START_TEST 78, 0, 0xFFFFFFFF
    li      t5, 1
    sw      t5, 0(s1)           # Mem = 1
    amomaxu.w t2, t1, (s1)      # Maxu(1, -1) = -1 (unsigned max)
    CHECK_TEST 1, -1

    # Case 79: Load after
    START_TEST 79, 100, 200
    amomaxu.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 100, 200

    # Case 80: Reg update
    START_TEST 80, 100, 50
    addi    t1, t1, 100         # rs2 = 150
    amomaxu.w t2, t1, (s1)      # Maxu(100, 150) = 150
    CHECK_TEST 100, 150

    # =========================================================================
    # 9. AMOMINU.W (Unsigned Min)
    #    rd = mem; mem = minu(mem, rs2)
    # =========================================================================

    # Case 81: Basic Minu (Small < Large) -> No Update
    START_TEST 81, 10, 20
    amominu.w t2, t1, (s1)
    CHECK_TEST 10, 10

    # Case 82: Basic Minu (Large > Small) -> Update
    START_TEST 82, 20, 10
    amominu.w t2, t1, (s1)
    CHECK_TEST 20, 10

    # Case 83: Unsigned vs Signed Distinction
    # Signed: -1 < 1. Unsigned: 0xFFFFFFFF > 1.
    # We expect NO update (Mem 1 is smaller unsigned).
    START_TEST 83, 1, -1
    amominu.w t2, t1, (s1)
    CHECK_TEST 1, 1

    # Case 84: Unsigned vs Signed (Inverse)
    # Mem = -1 (0xFF..), rs2 = 1.
    # Unsigned: 0xFF.. > 1. Update to 1.
    START_TEST 84, -1, 1
    amominu.w t2, t1, (s1)
    CHECK_TEST -1, 1

    # Case 85: Minu with Zero
    START_TEST 85, 100, 0
    amominu.w t2, t1, (s1)
    CHECK_TEST 100, 0

    # Case 86: Div before
    START_TEST 86, 20, 10
    div     t5, t1, t1
    amominu.w t2, t1, (s1)
    CHECK_TEST 20, 10

    # Case 87: Consecutive
    START_TEST 87, 50, 10
    li      t5, 20
    amominu.w t0, t5, (s1)      # Minu(50, 20) = 20
    amominu.w t2, t1, (s1)      # Minu(20, 10) = 10
    CHECK_TEST 20, 10

    # Case 88: Store before
    START_TEST 88, 0, 10
    li      t5, 50
    sw      t5, 0(s1)           # Mem = 50
    amominu.w t2, t1, (s1)      # Minu(50, 10) = 10
    CHECK_TEST 50, 10

    # Case 89: Load after
    START_TEST 89, 5, 10
    amominu.w t2, t1, (s1)
    lw      t0, 0(s1)
    CHECK_TEST 5, 5

    # Case 90: Reg update
    START_TEST 90, 100, 200
    addi    t1, t1, -150        # rs2 = 50
    amominu.w t2, t1, (s1)      # Minu(100, 50) = 50
    CHECK_TEST 100, 50


pass:
    li      a0, 0
    j       exit

test_fail:
    # t6 contains the current test ID
    mv      a0, t6
    j       exit

exit:
    # Print a0
    ecall
    # Stop execution
    
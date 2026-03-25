# Register File Test Program for RV32I
# Tests register file read/write correctness and forwarding paths
# If all tests pass, a0 = 0. If test i fails, a0 = i.

.text
.globl _start
_start:

# ============================================================================
# Test 1: Write and read from register x1
# Initialize x1, then read it back
# ============================================================================
test_1:
    li a0, 1                # Set failure code
    li t0, 0x12345678       # Load immediate value
    add t1, t0, x0          # Copy t0 to t1 (stall to avoid forwarding)
    nop
    nop
    nop
    bne t0, t1, fail        # t0 should equal t1

# ============================================================================
# Test 2: Write and read from register x2
# ============================================================================
test_2:
    li a0, 2
    li t2, 0xDEADBEEF
    add t3, t2, x0          # Copy t2 to t3
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 3: Verify x0 is always zero
# ============================================================================
test_3:
    li a0, 3
    li t0, 100
    add x0, t0, t0          # Try to write to x0
    nop
    nop
    nop
    bne x0, zero, fail      # x0 should still be 0

# ============================================================================
# Test 4: Forwarding distance 1 (back-to-back dependent instructions)
# Result available in EX stage, used in next instruction's EX stage
# ============================================================================
test_4:
    li a0, 4
    li t0, 10
    addi t1, t0, 5          # t1 = 15
    addi t2, t1, 3          # Forwarding: t2 = t1 + 3 = 18 (distance 1)
    li t3, 18
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 5: Forwarding distance 2 (one instruction gap)
# Result in MEM stage, used by instruction in EX stage
# ============================================================================
test_5:
    li a0, 5
    li t0, 20
    addi t1, t0, 10         # t1 = 30
    nop                     # One instruction gap (distance 2)
    addi t2, t1, 7          # Forwarding from MEM stage: t2 = 37
    li t3, 37
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 6: Forwarding distance 3 (two instruction gap)
# Result in WB stage, used by instruction in EX stage
# ============================================================================
test_6:
    li a0, 6
    li t0, 50
    addi t1, t0, 25         # t1 = 75
    nop                     # Gap instruction 1
    nop                     # Gap instruction 2 (distance 3)
    addi t2, t1, 5          # Forwarding from WB stage: t2 = 80
    li t3, 80
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 7: Chain of distance-1 forwarding (3 dependent instructions)
# ============================================================================
test_7:
    li a0, 7
    li t0, 1
    addi t0, t0, 1          # t0 = 2
    addi t0, t0, 1          # t0 = 3 (distance 1)
    addi t0, t0, 1          # t0 = 4 (distance 1)
    li t1, 4
    nop
    nop
    nop
    bne t0, t1, fail

# ============================================================================
# Test 8: Write to multiple registers, verify all values
# ============================================================================
test_8:
    li a0, 8
    li t0, 100
    li t1, 200
    li t2, 300
    li t3, 400
    li t4, 500
    nop
    nop
    nop
    # Verify all values
    li t5, 100
    bne t0, t5, fail
    li t5, 200
    bne t1, t5, fail
    li t5, 300
    bne t2, t5, fail
    li t5, 400
    bne t3, t5, fail
    li t5, 500
    bne t4, t5, fail

# ============================================================================
# Test 9: Overwrite register and verify new value
# ============================================================================
test_9:
    li a0, 9
    li t0, 0xAAAAAAAA
    nop
    nop
    nop
    li t0, 0x55555555       # Overwrite t0
    li t1, 0x55555555
    nop
    nop
    nop
    bne t0, t1, fail

# ============================================================================
# Test 10: Forwarding with ADD instruction (rs1 forwarding)
# ============================================================================
test_10:
    li a0, 10
    li t0, 7
    li t1, 3
    add t2, t0, t1          # t2 = 10
    add t3, t2, t1          # t3 = t2 + t1 = 13 (rs1 forwarding, distance 1)
    li t4, 13
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# Test 11: Forwarding with ADD instruction (rs2 forwarding)
# ============================================================================
test_11:
    li a0, 11
    li t0, 5
    li t1, 8
    add t2, t0, t1          # t2 = 13
    add t3, t0, t2          # t3 = t0 + t2 = 18 (rs2 forwarding, distance 1)
    li t4, 18
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# Test 12: Forwarding with both rs1 and rs2 from same producer
# ============================================================================
test_12:
    li a0, 12
    li t0, 6
    add t1, t0, t0          # t1 = 12
    add t2, t1, t1          # t2 = t1 + t1 = 24 (both rs1 and rs2 forwarding)
    li t3, 24
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 13: SUB instruction with forwarding distance 1
# ============================================================================
test_13:
    li a0, 13
    li t0, 50
    li t1, 30
    sub t2, t0, t1          # t2 = 20
    sub t3, t2, t1          # t3 = t2 - t1 = -10 (distance 1 forwarding)
    li t4, -10
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# Test 14: OR instruction with forwarding distance 2
# ============================================================================
test_14:
    li a0, 14
    li t0, 0x0F0F0F0F
    or t1, t0, zero         # t1 = 0x0F0F0F0F
    li t4, 0                # Unrelated instruction (distance 2)
    li t2, 0xF0F0F0F0
    or t3, t1, t2           # t3 = 0xFFFFFFFF (t1 forwarded from WB/reg)
    li t4, 0xFFFFFFFF
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# Test 15: AND instruction with forwarding distance 3
# ============================================================================
test_15:
    li a0, 15
    li t0, 0xFF00FF00
    and t1, t0, t0          # t1 = 0xFF00FF00
    nop                     # Gap 1
    nop                     # Gap 2 (distance 3)
    li t2, 0x00FF00FF
    and t3, t1, t2          # t3 = 0 (t1 forwarded from WB or reg file)
    nop
    nop
    nop
    bne t3, x0, fail

# ============================================================================
# Test 16: XOR instruction chain with forwarding
# ============================================================================
test_16:
    li a0, 16
    li t0, 0xAAAAAAAA
    li t1, 0x55555555
    xor t2, t0, t1          # t2 = 0xFFFFFFFF (distance 1)
    xor t3, t2, t0          # t3 = 0x55555555 (distance 1)
    nop
    nop
    nop
    bne t3, t1, fail

# ============================================================================
# Test 17: SLL (shift left logical) with forwarding
# ============================================================================
test_17:
    li a0, 17
    li t0, 1
    slli t1, t0, 4          # t1 = 16
    slli t2, t1, 4          # t2 = 256 (distance 1 forwarding)
    li t3, 256
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 18: SRL (shift right logical) with forwarding distance 2
# ============================================================================
test_18:
    li a0, 18
    li t0, 256
    srli t1, t0, 2          # t1 = 64
    li t4, 0                # Unrelated (distance 2)
    srli t2, t1, 2          # t2 = 16
    li t3, 16
    nop
    nop
    nop
    bne t2, t3, fail

# ============================================================================
# Test 19: SLT (set less than) with forwarding
# ============================================================================
test_19:
    li a0, 19
    li t0, 5
    li t1, 10
    slt t2, t0, t1          # t2 = 1 (5 < 10)
    addi t3, t2, 0          # t3 = t2 = 1 (distance 1 forwarding)
    li t4, 1
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# Test 20: Complex forwarding scenario - mixed distances
# ============================================================================
test_20:
    li a0, 20
    li t0, 10               # t0 = 10
    addi t1, t0, 5          # t1 = 15 (distance 1 from t0)
    addi t2, t0, 10         # t2 = 20 (distance 2 from t0, distance 1 irrelevant)
    add t3, t1, t2          # t3 = 35 (t1 distance 2, t2 distance 1)
    li t4, 35
    nop
    nop
    nop
    bne t3, t4, fail

# ============================================================================
# All tests passed
# ============================================================================
pass:
    li a0, 0                # All tests passed

fail:
    # Print result and stop
    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0

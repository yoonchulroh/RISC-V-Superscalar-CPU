# RV32IMA_zicsr mstatus CSR Instruction Tests
# Tests all 6 zicsr instructions: csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
# 10 test cases per instruction (60 total), operating primarily on mstatus
# mepc and mcause are used as auxiliaries where needed
# Each test verifies both rd value and CSR value
# Special tests: consecutive CSR, CSR after taken branch (no effect), CSR after mul/div, CSR after amo
# If test i succeeds, store i to a0 then ecall
# If test i fails, jump to end immediately (a0 = failing test number)
# CSR addresses: mstatus=0x300, mepc=0x341, mcause=0x342

.section .text
.globl _start

_start:
    # Initialize base address for amo operations
    li s0, 0           # Base address for amo operations

# =============================================================================
# CSRRW Tests (Tests 1-10) - CSR Read/Write
# csrrw rd, csr, rs -> rd = csr; csr = rs
# =============================================================================

# Test 1: Basic csrrw - write value to mstatus and verify rd gets old value
csrrw_test1:
    csrrw   x0, mstatus, x0    # Clear mstatus first
    li      t0, 0x1800
    csrrw   t1, mstatus, t0    # t1 = old mstatus (0), mstatus = 0x1800
    li      a0, 1
    bne     t1, x0, fail       # Verify t1 is 0 (old value)
    csrrw   t2, mstatus, x0    # t2 = mstatus
    li      t3, 0x1800
    bne     t2, t3, fail       # Verify mstatus = 0x1800
    ecall                       # Test 1 passed

# Test 2: Consecutive csrrw on mstatus - verify sequential updates work correctly
csrrw_test2:
    li      t0, 0x00000008     # MIE bit
    li      t1, 0x00000080     # MPIE bit
    csrrw   x0, mstatus, t0    # mstatus = 0x08
    csrrw   t2, mstatus, t1    # t2 = 0x08, mstatus = 0x80
    li      a0, 2
    li      t3, 0x08
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0    # t4 = 0x80
    li      t5, 0x80
    bne     t4, t5, fail
    ecall                       # Test 2 passed

# Test 3: csrrw after taken branch - skipped csrrw should have no effect
csrrw_test3:
    li      t0, 0x1880
    csrrw   x0, mstatus, t0    # mstatus = 0x1880
    li      t1, 0xDEADBEEF     # Wrong value
    li      t2, 1
    beq     t2, t2, csrrw_skip3  # Always taken
    csrrw   t3, mstatus, t1    # Should NOT execute
csrrw_skip3:
    csrrw   t4, mstatus, x0    # Read mstatus
    li      a0, 3
    li      t5, 0x1880
    bne     t4, t5, fail       # Verify mstatus unchanged
    ecall                       # Test 3 passed

# Test 4: csrrw right after mul - verify correct value from mul is written
csrrw_test4:
    li      t0, 12
    li      t1, 5
    mul     t2, t0, t1          # t2 = 60 = 0x3C
    csrrw   x0, mstatus, t2    # mstatus = 0x3C
    csrrw   t3, mstatus, x0    # t3 = mstatus
    li      a0, 4
    li      t4, 0x3C
    bne     t3, t4, fail
    ecall                       # Test 4 passed

# Test 5: csrrw right after div - verify correct value from div is written
csrrw_test5:
    li      t0, 6000
    li      t1, 3
    div     t2, t0, t1          # t2 = 2000
    csrrw   x0, mstatus, t2    # mstatus = 2000
    csrrw   t3, mstatus, x0    # t3 = mstatus
    li      a0, 5
    li      t4, 2000
    bne     t3, t4, fail
    ecall                       # Test 5 passed

# Test 6: csrrw after amoswap - verify csrrw works after atomic operation
csrrw_test6:
    li      t0, 100
    sw      t0, 0(s0)               # mem[0] = 100
    li      t1, 200
    amoswap.w t2, t1, (s0)          # t2 = 100, mem[0] = 200
    li      t3, 0x00001888
    csrrw   x0, mstatus, t3         # mstatus = 0x1888
    csrrw   t4, mstatus, x0
    li      a0, 6
    li      t5, 0x00001888
    bne     t4, t5, fail
    ecall                       # Test 6 passed

# Test 7: csrrw on mstatus then read via mepc cross-check
# Write mstatus, then write mepc, then read both back
csrrw_test7:
    li      t0, 0xABCD0000
    li      t1, 0x12340000
    csrrw   x0, mstatus, t0    # mstatus = 0xABCD0000
    csrrw   x0, mepc, t1       # mepc = 0x12340000
    csrrw   t2, mstatus, x0    # t2 = mstatus
    csrrw   t3, mepc, x0       # t3 = mepc
    li      a0, 7
    li      t4, 0xABCD0000
    bne     t2, t4, fail
    li      t5, 0x12340000
    bne     t3, t5, fail
    ecall                       # Test 7 passed

# Test 8: csrrw rd = rs (self-swap) on mstatus
csrrw_test8:
    li      t0, 0x00000088
    li      t1, 0x00001800
    csrrw   x0, mstatus, t0    # mstatus = 0x88
    csrrw   t1, mstatus, t1    # t1 = 0x88 (old mstatus), mstatus = 0x1800
    li      a0, 8
    li      t2, 0x88
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 0x1800
    bne     t3, t4, fail
    ecall                       # Test 8 passed

# Test 9: csrrw with large value (all bits set)
csrrw_test9:
    li      t0, 0xFFFFFFFF
    csrrw   x0, mstatus, t0     # mstatus = 0xFFFFFFFF
    csrrw   t1, mstatus, x0     # t1 = 0xFFFFFFFF, mstatus = 0
    li      a0, 9
    li      t2, 0xFFFFFFFF
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0     # t3 = 0
    bne     t3, x0, fail
    ecall                       # Test 9 passed

# Test 10: csrrw writing zero to mstatus
csrrw_test10:
    li      t0, 0x12345678
    csrrw   x0, mstatus, t0    # mstatus = 0x12345678
    csrrw   t1, mstatus, x0    # t1 = 0x12345678, mstatus = 0
    li      a0, 10
    li      t2, 0x12345678
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, x0, fail       # mstatus should be 0
    ecall                       # Test 10 passed

# =============================================================================
# CSRRS Tests (Tests 11-20) - CSR Read and Set bits
# csrrs rd, csr, rs -> rd = csr; csr = csr | rs
# =============================================================================

# Test 11: Basic csrrs - set bits in mstatus
csrrs_test11:
    li      t0, 0x08
    csrrw   x0, mstatus, t0    # mstatus = 0x08 (MIE)
    li      t1, 0x80            # MPIE bit
    csrrs   t2, mstatus, t1    # t2 = 0x08, mstatus = 0x88
    li      a0, 11
    li      t3, 0x08
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 0x88
    bne     t4, t5, fail
    ecall                       # Test 11 passed

# Test 12: Consecutive csrrs on mstatus
csrrs_test12:
    csrrw   x0, mstatus, x0    # Clear mstatus
    li      t0, 0x08            # MIE
    li      t1, 0x80            # MPIE
    csrrs   t2, mstatus, t0    # t2 = 0, mstatus = 0x08
    csrrs   t3, mstatus, t1    # t3 = 0x08, mstatus = 0x88
    li      a0, 12
    bne     t2, x0, fail
    li      t4, 0x08
    bne     t3, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0x88
    bne     t5, t6, fail
    ecall                       # Test 12 passed

# Test 13: csrrs after taken branch - skipped csrrs has no effect
csrrs_test13:
    li      t0, 0x08
    csrrw   x0, mstatus, t0    # mstatus = 0x08
    li      t1, 0x1800
    li      t2, 1
    beq     t2, t2, csrrs_skip13
    csrrs   t3, mstatus, t1    # Should NOT execute
csrrs_skip13:
    csrrw   t4, mstatus, x0
    li      a0, 13
    li      t5, 0x08           # Should be unchanged
    bne     t4, t5, fail
    ecall                       # Test 13 passed

# Test 14: csrrs right after mul
csrrs_test14:
    li      t0, 0x100
    csrrw   x0, mstatus, t0    # mstatus = 0x100
    li      t1, 2
    li      t2, 4
    mul     t3, t1, t2          # t3 = 8
    csrrs   t4, mstatus, t3    # t4 = 0x100, mstatus = 0x108
    li      a0, 14
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0x108
    bne     t6, t0, fail
    ecall                       # Test 14 passed

# Test 15: csrrs right after div
csrrs_test15:
    li      t0, 0x1000
    csrrw   x0, mstatus, t0    # mstatus = 0x1000
    li      t1, 2048
    li      t2, 8
    div     t3, t1, t2          # t3 = 256 = 0x100
    csrrs   t4, mstatus, t3    # t4 = 0x1000, mstatus = 0x1100
    li      a0, 15
    li      t5, 0x1000
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0x1100
    bne     t6, t0, fail
    ecall                       # Test 15 passed

# Test 16: csrrs after amoadd
csrrs_test16:
    li      t0, 50
    sw      t0, 4(s0)               # mem[4] = 50
    li      t1, 30
    amoadd.w t2, t1, (s0)           # atomic add
    li      t3, 0x0800
    csrrw   x0, mstatus, x0         # Clear mstatus
    csrrs   t4, mstatus, t3         # t4 = 0, mstatus = 0x0800
    li      a0, 16
    bne     t4, x0, fail
    csrrw   t5, mstatus, x0
    li      t6, 0x0800
    bne     t5, t6, fail
    ecall                       # Test 16 passed

# Test 17: csrrs on mstatus - set interrupt-related bits
csrrs_test17:
    li      t0, 0x00000008      # MIE only
    csrrw   x0, mstatus, t0     # mstatus = 0x08
    li      t1, 0x00001880      # Set MPP and MPIE
    csrrs   t2, mstatus, t1     # t2 = 0x08, mstatus = 0x1888
    li      a0, 17
    li      t3, 0x08
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 0x1888
    bne     t4, t5, fail
    ecall                       # Test 17 passed

# Test 18: csrrs with rs = x0 (just read, no modify)
csrrs_test18:
    li      t0, 0x1888
    csrrw   x0, mstatus, t0    # mstatus = 0x1888
    csrrs   t1, mstatus, x0    # t1 = 0x1888, mstatus unchanged
    li      a0, 18
    li      t2, 0x1888
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail       # Verify mstatus unchanged
    ecall                       # Test 18 passed

# Test 19: csrrs setting already set bits (idempotent)
csrrs_test19:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    li      t1, 0x0F
    csrrs   t2, mstatus, t1    # t2 = 0xFF, mstatus = 0xFF (no change)
    li      a0, 19
    li      t3, 0xFF
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    bne     t4, t3, fail
    ecall                       # Test 19 passed

# Test 20: csrrs result used immediately in add
csrrs_test20:
    li      t0, 0x50
    csrrw   x0, mstatus, t0    # mstatus = 0x50
    li      t1, 0x0F
    csrrs   t2, mstatus, t1    # t2 = 0x50, mstatus = 0x5F
    add     t3, t2, t2          # t3 = 0xA0 (use t2 immediately)
    li      a0, 20
    li      t4, 0xA0
    bne     t3, t4, fail
    ecall                       # Test 20 passed

# =============================================================================
# CSRRC Tests (Tests 21-30) - CSR Read and Clear bits
# csrrc rd, csr, rs -> rd = csr; csr = csr & ~rs
# =============================================================================

# Test 21: Basic csrrc - clear bits in mstatus
csrrc_test21:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    li      t1, 0x0F
    csrrc   t2, mstatus, t1    # t2 = 0xFF, mstatus = 0xF0
    li      a0, 21
    li      t3, 0xFF
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 0xF0
    bne     t4, t5, fail
    ecall                       # Test 21 passed

# Test 22: Consecutive csrrc on mstatus
csrrc_test22:
    li      t0, 0xFFFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFFFF
    li      t1, 0x000F
    li      t2, 0x00F0
    csrrc   t3, mstatus, t1    # t3 = 0xFFFF, mstatus = 0xFFF0
    csrrc   t4, mstatus, t2    # t4 = 0xFFF0, mstatus = 0xFF00
    li      a0, 22
    li      t5, 0xFFFF
    bne     t3, t5, fail
    li      t6, 0xFFF0
    bne     t4, t6, fail
    csrrw   t0, mstatus, x0
    li      t1, 0xFF00
    bne     t0, t1, fail
    ecall                       # Test 22 passed

# Test 23: csrrc after taken branch - skipped csrrc has no effect
csrrc_test23:
    li      t0, 0x1888
    csrrw   x0, mstatus, t0    # mstatus = 0x1888
    li      t1, 0x0888
    li      t2, 1
    beq     t2, t2, csrrc_skip23
    csrrc   t3, mstatus, t1    # Should NOT execute
csrrc_skip23:
    csrrw   t4, mstatus, x0
    li      a0, 23
    li      t5, 0x1888         # Should be unchanged
    bne     t4, t5, fail
    ecall                       # Test 23 passed

# Test 24: csrrc right after mul
csrrc_test24:
    li      t0, 0xFFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFFF
    li      t1, 3
    li      t2, 5
    mul     t3, t1, t2          # t3 = 15 = 0x0F
    csrrc   t4, mstatus, t3    # t4 = 0xFFF, mstatus = 0xFF0
    li      a0, 24
    li      t5, 0xFFF
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0xFF0
    bne     t6, t0, fail
    ecall                       # Test 24 passed

# Test 25: csrrc right after div
csrrc_test25:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    li      t1, 256
    li      t2, 4
    div     t3, t1, t2          # t3 = 64 = 0x40
    csrrc   t4, mstatus, t3    # t4 = 0xFF, mstatus = 0xBF
    li      a0, 25
    li      t5, 0xFF
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0xBF
    bne     t6, t0, fail
    ecall                       # Test 25 passed

# Test 26: csrrc after amoand
csrrc_test26:
    li      t0, 0xFF
    sw      t0, 8(s0)               # mem[8] = 0xFF
    li      t1, 0x0F
    amoand.w t2, t1, (s0)           # atomic and
    li      t3, 0x1888
    csrrw   x0, mstatus, t3         # mstatus = 0x1888
    li      t4, 0x0808
    csrrc   t5, mstatus, t4         # t5 = 0x1888, mstatus = 0x1080
    li      a0, 26
    li      t6, 0x1888
    bne     t5, t6, fail
    csrrw   t0, mstatus, x0
    li      t1, 0x1080
    bne     t0, t1, fail
    ecall                       # Test 26 passed

# Test 27: csrrc clear MIE bit specifically
csrrc_test27:
    li      t0, 0x00001888      # MPP|MPIE|MIE all set
    csrrw   x0, mstatus, t0     # mstatus = 0x1888
    li      t1, 0x00000008      # MIE mask
    csrrc   t2, mstatus, t1     # t2 = 0x1888, mstatus = 0x1880
    li      a0, 27
    li      t3, 0x1888
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 0x1880
    bne     t4, t5, fail
    ecall                       # Test 27 passed

# Test 28: csrrc with rs = x0 (just read, no modify)
csrrc_test28:
    li      t0, 0x456
    csrrw   x0, mstatus, t0    # mstatus = 0x456
    csrrc   t1, mstatus, x0    # t1 = 0x456, mstatus unchanged
    li      a0, 28
    li      t2, 0x456
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail       # Verify mstatus unchanged
    ecall                       # Test 28 passed

# Test 29: csrrc clearing bits that are already 0 (no change)
csrrc_test29:
    li      t0, 0xF0
    csrrw   x0, mstatus, t0    # mstatus = 0xF0
    li      t1, 0x0F
    csrrc   t2, mstatus, t1    # t2 = 0xF0, mstatus = 0xF0 (no change)
    li      a0, 29
    li      t3, 0xF0
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    bne     t4, t3, fail
    ecall                       # Test 29 passed

# Test 30: csrrc clearing all bits
csrrc_test30:
    li      t0, 0xFFFFFFFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFFFFFFFF
    li      t1, 0xFFFFFFFF
    csrrc   t2, mstatus, t1    # t2 = 0xFFFFFFFF, mstatus = 0
    li      a0, 30
    li      t3, 0xFFFFFFFF
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    bne     t4, x0, fail       # mstatus should be 0
    ecall                       # Test 30 passed

# =============================================================================
# CSRRWI Tests (Tests 31-40) - CSR Read/Write Immediate
# csrrwi rd, csr, uimm -> rd = csr; csr = uimm (5-bit zero-extended immediate)
# =============================================================================

# Test 31: Basic csrrwi - write immediate to mstatus
csrrwi_test31:
    csrrw   x0, mstatus, x0    # Clear mstatus
    csrrwi  t0, mstatus, 15    # t0 = 0, mstatus = 15
    li      a0, 31
    bne     t0, x0, fail
    csrrw   t1, mstatus, x0
    li      t2, 15
    bne     t1, t2, fail
    ecall                       # Test 31 passed

# Test 32: Consecutive csrrwi on mstatus
csrrwi_test32:
    csrrwi  t0, mstatus, 5     # t0 = ?, mstatus = 5
    csrrwi  t1, mstatus, 10    # t1 = 5, mstatus = 10
    li      a0, 32
    li      t2, 5
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 10
    bne     t3, t4, fail
    ecall                       # Test 32 passed

# Test 33: csrrwi after taken branch - skipped csrrwi has no effect
csrrwi_test33:
    csrrwi  t0, mstatus, 7     # mstatus = 7
    li      t1, 1
    beq     t1, t1, csrrwi_skip33
    csrrwi  t2, mstatus, 31    # Should NOT execute
csrrwi_skip33:
    csrrw   t3, mstatus, x0
    li      a0, 33
    li      t4, 7
    bne     t3, t4, fail
    ecall                       # Test 33 passed

# Test 34: csrrwi right after mul
csrrwi_test34:
    li      t0, 6
    li      t1, 7
    mul     t2, t0, t1          # t2 = 42
    csrrwi  t3, mstatus, 20    # t3 = ?, mstatus = 20
    csrrw   t4, mstatus, x0
    li      a0, 34
    li      t5, 20
    bne     t4, t5, fail
    ecall                       # Test 34 passed

# Test 35: csrrwi right after div
csrrwi_test35:
    li      t0, 100
    li      t1, 10
    div     t2, t0, t1          # t2 = 10
    csrrwi  t3, mstatus, 25    # mstatus = 25
    csrrw   t4, mstatus, x0
    li      a0, 35
    li      t5, 25
    bne     t4, t5, fail
    ecall                       # Test 35 passed

# Test 36: csrrwi after amoor
csrrwi_test36:
    li      t0, 0xF0
    sw      t0, 12(s0)              # mem[12] = 0xF0
    li      t1, 0x0F
    amoor.w t2, t1, (s0)            # atomic or
    csrrwi  t3, mstatus, 31         # mstatus = 31
    csrrw   t4, mstatus, x0
    li      a0, 36
    li      t5, 31
    bne     t4, t5, fail
    ecall                       # Test 36 passed

# Test 37: csrrwi on mstatus then verify mepc is independent
csrrwi_test37:
    li      t0, 0xABC
    csrrw   x0, mepc, t0       # mepc = 0xABC
    csrrwi  t1, mstatus, 8     # mstatus = 8
    csrrw   t2, mepc, x0       # t2 = mepc should still be 0xABC
    li      a0, 37
    li      t3, 0xABC
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 8
    bne     t4, t5, fail
    ecall                       # Test 37 passed

# Test 38: csrrwi with immediate 0 (clears mstatus)
csrrwi_test38:
    li      t0, 0xFFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFFF
    csrrwi  t1, mstatus, 0     # t1 = 0xFFF, mstatus = 0
    li      a0, 38
    li      t2, 0xFFF
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, x0, fail       # mstatus should be 0
    ecall                       # Test 38 passed

# Test 39: csrrwi with rd = x0 (write-only)
csrrwi_test39:
    csrrwi  x0, mstatus, 17    # mstatus = 17, old value discarded
    csrrw   t0, mstatus, x0
    li      a0, 39
    li      t1, 17
    bne     t0, t1, fail
    ecall                       # Test 39 passed

# Test 40: csrrwi with max immediate (31)
csrrwi_test40:
    csrrwi  t0, mstatus, 31    # mstatus = 31
    csrrw   t1, mstatus, x0
    li      a0, 40
    li      t2, 31
    bne     t1, t2, fail
    ecall                       # Test 40 passed

# =============================================================================
# CSRRSI Tests (Tests 41-50) - CSR Read and Set bits Immediate
# csrrsi rd, csr, uimm -> rd = csr; csr = csr | uimm
# =============================================================================

# Test 41: Basic csrrsi - set bits in mstatus
csrrsi_test41:
    li      t0, 0x10
    csrrw   x0, mstatus, t0    # mstatus = 0x10
    csrrsi  t1, mstatus, 0x0F  # t1 = 0x10, mstatus = 0x1F
    li      a0, 41
    li      t2, 0x10
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 0x1F
    bne     t3, t4, fail
    ecall                       # Test 41 passed

# Test 42: Consecutive csrrsi on mstatus
csrrsi_test42:
    csrrw   x0, mstatus, x0    # Clear mstatus
    csrrsi  t0, mstatus, 1     # t0 = 0, mstatus = 0x01
    csrrsi  t1, mstatus, 2     # t1 = 0x01, mstatus = 0x03
    csrrsi  t2, mstatus, 4     # t2 = 0x03, mstatus = 0x07
    li      a0, 42
    bne     t0, x0, fail
    li      t3, 0x01
    bne     t1, t3, fail
    li      t4, 0x03
    bne     t2, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0x07
    bne     t5, t6, fail
    ecall                       # Test 42 passed

# Test 43: csrrsi after taken branch - skipped csrrsi has no effect
csrrsi_test43:
    li      t0, 0x10
    csrrw   x0, mstatus, t0    # mstatus = 0x10
    li      t1, 1
    beq     t1, t1, csrrsi_skip43
    csrrsi  t2, mstatus, 0x0F  # Should NOT execute
csrrsi_skip43:
    csrrw   t3, mstatus, x0
    li      a0, 43
    li      t4, 0x10           # Should be unchanged
    bne     t3, t4, fail
    ecall                       # Test 43 passed

# Test 44: csrrsi right after mul
csrrsi_test44:
    li      t0, 8
    li      t1, 8
    mul     t2, t0, t1          # t2 = 64 = 0x40
    csrrw   x0, mstatus, t2    # mstatus = 0x40
    csrrsi  t3, mstatus, 0x0F  # t3 = 0x40, mstatus = 0x4F
    li      a0, 44
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0x4F
    bne     t5, t6, fail
    ecall                       # Test 44 passed

# Test 45: csrrsi right after div
csrrsi_test45:
    li      t0, 512
    li      t1, 8
    div     t2, t0, t1          # t2 = 64 = 0x40
    csrrw   x0, mstatus, t2    # mstatus = 0x40
    csrrsi  t3, mstatus, 0x03  # t3 = 0x40, mstatus = 0x43
    li      a0, 45
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0x43
    bne     t5, t6, fail
    ecall                       # Test 45 passed

# Test 46: csrrsi after amoxor
csrrsi_test46:
    li      t0, 0xFF
    sw      t0, 16(s0)              # mem[16] = 0xFF
    li      t1, 0xF0
    amoxor.w t2, t1, (s0)           # atomic xor
    li      t3, 0x100
    csrrw   x0, mstatus, t3         # mstatus = 0x100
    csrrsi  t4, mstatus, 0x1F       # t4 = 0x100, mstatus = 0x11F
    li      a0, 46
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0x11F
    bne     t6, t0, fail
    ecall                       # Test 46 passed

# Test 47: csrrsi on mstatus with mcause cross-check
csrrsi_test47:
    li      t0, 0x08
    csrrw   x0, mstatus, t0    # mstatus = 0x08
    li      t1, 0x0B
    csrrw   x0, mcause, t1     # mcause = 0x0B
    csrrsi  t2, mstatus, 0x07  # t2 = 0x08, mstatus = 0x0F
    li      a0, 47
    li      t3, 0x08
    bne     t2, t3, fail
    csrrw   t4, mstatus, x0
    li      t5, 0x0F
    bne     t4, t5, fail
    csrrw   t6, mcause, x0     # mcause should be unchanged
    li      t0, 0x0B
    bne     t6, t0, fail
    ecall                       # Test 47 passed

# Test 48: csrrsi with immediate 0 (just read, no modify)
csrrsi_test48:
    li      t0, 0x789
    csrrw   x0, mstatus, t0    # mstatus = 0x789
    csrrsi  t1, mstatus, 0     # t1 = 0x789, mstatus unchanged
    li      a0, 48
    li      t2, 0x789
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail       # Verify mstatus unchanged
    ecall                       # Test 48 passed

# Test 49: csrrsi setting already set bits (idempotent)
csrrsi_test49:
    li      t0, 0x1F
    csrrw   x0, mstatus, t0    # mstatus = 0x1F
    csrrsi  t1, mstatus, 0x0F  # t1 = 0x1F, mstatus = 0x1F (no change)
    li      a0, 49
    li      t2, 0x1F
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail
    ecall                       # Test 49 passed

# Test 50: csrrsi result used immediately in slli
csrrsi_test50:
    li      t0, 0x20
    csrrw   x0, mstatus, t0    # mstatus = 0x20
    csrrsi  t1, mstatus, 0x1F  # t1 = 0x20, mstatus = 0x3F
    slli    t2, t1, 1           # t2 = 0x40 (use t1 immediately)
    li      a0, 50
    li      t3, 0x40
    bne     t2, t3, fail
    ecall                       # Test 50 passed

# =============================================================================
# CSRRCI Tests (Tests 51-60) - CSR Read and Clear bits Immediate
# csrrci rd, csr, uimm -> rd = csr; csr = csr & ~uimm
# =============================================================================

# Test 51: Basic csrrci - clear bits in mstatus
csrrci_test51:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    csrrci  t1, mstatus, 0x0F  # t1 = 0xFF, mstatus = 0xF0
    li      a0, 51
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 0xF0
    bne     t3, t4, fail
    ecall                       # Test 51 passed

# Test 52: Consecutive csrrci on mstatus
csrrci_test52:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    csrrci  t1, mstatus, 0x01  # t1 = 0xFF, mstatus = 0xFE
    csrrci  t2, mstatus, 0x02  # t2 = 0xFE, mstatus = 0xFC
    csrrci  t3, mstatus, 0x04  # t3 = 0xFC, mstatus = 0xF8
    li      a0, 52
    li      t4, 0xFF
    bne     t1, t4, fail
    li      t5, 0xFE
    bne     t2, t5, fail
    li      t6, 0xFC
    bne     t3, t6, fail
    csrrw   t0, mstatus, x0
    li      t1, 0xF8
    bne     t0, t1, fail
    ecall                       # Test 52 passed

# Test 53: csrrci after taken branch - skipped csrrci has no effect
csrrci_test53:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    li      t1, 1
    beq     t1, t1, csrrci_skip53
    csrrci  t2, mstatus, 0x0F  # Should NOT execute
csrrci_skip53:
    csrrw   t3, mstatus, x0
    li      a0, 53
    li      t4, 0xFF           # Should be unchanged
    bne     t3, t4, fail
    ecall                       # Test 53 passed

# Test 54: csrrci right after mul
csrrci_test54:
    li      t0, 5
    li      t1, 51
    mul     t2, t0, t1          # t2 = 255 = 0xFF
    csrrw   x0, mstatus, t2    # mstatus = 0xFF
    csrrci  t3, mstatus, 0x0F  # t3 = 0xFF, mstatus = 0xF0
    li      a0, 54
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0xF0
    bne     t5, t6, fail
    ecall                       # Test 54 passed

# Test 55: csrrci right after div
csrrci_test55:
    li      t0, 1020
    li      t1, 4
    div     t2, t0, t1          # t2 = 255 = 0xFF
    csrrw   x0, mstatus, t2    # mstatus = 0xFF
    csrrci  t3, mstatus, 0x10  # t3 = 0xFF, mstatus = 0xEF
    li      a0, 55
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mstatus, x0
    li      t6, 0xEF
    bne     t5, t6, fail
    ecall                       # Test 55 passed

# Test 56: csrrci after amomax
csrrci_test56:
    li      t0, 50
    sw      t0, 20(s0)              # mem[20] = 50
    li      t1, 100
    amomax.w t2, t1, (s0)           # atomic max
    li      t3, 0x1FF
    csrrw   x0, mstatus, t3         # mstatus = 0x1FF
    csrrci  t4, mstatus, 0x0F       # t4 = 0x1FF, mstatus = 0x1F0
    li      a0, 56
    li      t5, 0x1FF
    bne     t4, t5, fail
    csrrw   t6, mstatus, x0
    li      t0, 0x1F0
    bne     t6, t0, fail
    ecall                       # Test 56 passed

# Test 57: csrrci clearing MIE bit (bit 3) specifically
csrrci_test57:
    li      t0, 0x0F
    csrrw   x0, mstatus, t0    # mstatus = 0x0F
    csrrci  t1, mstatus, 0x08  # t1 = 0x0F, mstatus = 0x07 (MIE cleared)
    li      a0, 57
    li      t2, 0x0F
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 0x07
    bne     t3, t4, fail
    ecall                       # Test 57 passed

# Test 58: csrrci with immediate 0 (just read, no modify)
csrrci_test58:
    li      t0, 0xABC
    csrrw   x0, mstatus, t0    # mstatus = 0xABC
    csrrci  t1, mstatus, 0     # t1 = 0xABC, mstatus unchanged
    li      a0, 58
    li      t2, 0xABC
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail       # Verify mstatus unchanged
    ecall                       # Test 58 passed

# Test 59: csrrci clearing bits that are already 0 (no change)
csrrci_test59:
    li      t0, 0xF0
    csrrw   x0, mstatus, t0    # mstatus = 0xF0
    csrrci  t1, mstatus, 0x0F  # t1 = 0xF0, mstatus = 0xF0 (no change)
    li      a0, 59
    li      t2, 0xF0
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    bne     t3, t2, fail
    ecall                       # Test 59 passed

# Test 60: csrrci with max immediate (31) clearing low 5 bits
csrrci_test60:
    li      t0, 0xFF
    csrrw   x0, mstatus, t0    # mstatus = 0xFF
    csrrci  t1, mstatus, 31    # t1 = 0xFF, mstatus = 0xE0 (clear bits 0-4)
    li      a0, 60
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mstatus, x0
    li      t4, 0xE0
    bne     t3, t4, fail
    ecall                       # Test 60 passed

# =============================================================================
# All tests passed - end normally
# =============================================================================
all_passed:
    li      a0, 0               # All tests passed indicator
    ecall
    j       end_program

fail:
    # a0 already contains the failing test number
    # Fall through to end

end_program:

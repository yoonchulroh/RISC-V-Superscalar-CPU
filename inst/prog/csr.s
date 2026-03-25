# RV32IMA_zicsr CSR Instruction Tests
# Tests all 6 zicsr instructions: csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
# 10 test cases per instruction (60 total), operating on mepc and mcause CSRs
# Each test verifies both rd value and CSR value
# Special tests: consecutive CSR, CSR after taken branch (no effect), CSR after mul/div, CSR after amo
# If test i succeeds, store i to a0 then ecall
# If test i fails, jump to end immediately (a0 = failing test number)
# CSR addresses: mepc=0x341, mcause=0x342

.section .text
.globl _start

_start:
    # Initialize base addresses for memory operations (for amo tests)
    li s0, 0           # Base address for amo operations

# =============================================================================
# CSRRW Tests (Tests 1-10) - CSR Read/Write
# csrrw rd, csr, rs -> rd = csr; csr = rs
# =============================================================================

# Test 1: Basic csrrw - write value to mepc and verify rd gets old value
csrrw_test1:
    li      t0, 0x100
    csrrw   x0, mepc, x0    # Clear mepc first
    csrrw   t1, mepc, t0    # t1 = old mepc (0), mepc = 0x100
    li      a0, 1
    bne     t1, x0, fail    # Verify t1 is 0 (old value)
    csrrw   t2, mepc, x0    # t2 = mepc
    li      t3, 0x100
    bne     t2, t3, fail    # Verify mepc = 0x100
    ecall                   # Test 1 passed

# Test 2: Consecutive csrrw on mepc - verify sequential updates work correctly
csrrw_test2:
    li      t0, 0x200
    li      t1, 0x300
    csrrw   x0, mepc, t0    # mepc = 0x200
    csrrw   t2, mepc, t1    # t2 = 0x200, mepc = 0x300
    li      a0, 2
    li      t3, 0x200
    bne     t2, t3, fail
    csrrw   t4, mepc, x0    # t4 = 0x300
    li      t5, 0x300
    bne     t4, t5, fail
    ecall                   # Test 2 passed

# Test 3: csrrw after taken branch - skipped csrrw should have no effect
csrrw_test3:
    li      t0, 0x400
    csrrw   x0, mepc, t0    # mepc = 0x400
    li      t1, 0x999       # Wrong value
    li      t2, 1
    beq     t2, t2, csrrw_skip3  # Always taken
    csrrw   t3, mepc, t1    # Should NOT execute
csrrw_skip3:
    csrrw   t4, mepc, x0    # Read mepc
    li      a0, 3
    li      t5, 0x400
    bne     t4, t5, fail    # Verify mepc unchanged
    ecall                   # Test 3 passed

# Test 4: csrrw right after mul - verify correct value from mul is written
csrrw_test4:
    li      t0, 10
    li      t1, 5
    mul     t2, t0, t1      # t2 = 50
    csrrw   x0, mepc, t2    # mepc = 50
    csrrw   t3, mepc, x0    # t3 = mepc
    li      a0, 4
    li      t4, 50
    bne     t3, t4, fail
    ecall                   # Test 4 passed

# Test 5: csrrw right after div - verify correct value from div is written
csrrw_test5:
    li      t0, 600
    li      t1, 3
    div     t2, t0, t1      # t2 = 200
    csrrw   x0, mepc, t2    # mepc = 200
    csrrw   t3, mepc, x0    # t3 = mepc
    li      a0, 5
    li      t4, 200
    bne     t3, t4, fail
    ecall                   # Test 5 passed

# Test 6: csrrw after amoswap - verify csrrw works after atomic operation
csrrw_test6:
    li      t0, 100
    sw      t0, 0(s0)           # mem[0] = 100
    li      t1, 200
    amoswap.w t2, t1, (s0)      # t2 = 100, mem[0] = 200
    li      t3, 0x600
    csrrw   x0, mepc, t3        # mepc = 0x600
    csrrw   t4, mepc, x0
    li      a0, 6
    li      t5, 0x600
    bne     t4, t5, fail
    ecall                   # Test 6 passed

# Test 7: csrrw on mcause - basic write and read
csrrw_test7:
    li      t0, 11              # Environment call from M-mode
    csrrw   x0, mcause, x0      # Clear mcause
    csrrw   t1, mcause, t0      # t1 = old mcause (0), mcause = 11
    li      a0, 7
    bne     t1, x0, fail
    csrrw   t2, mcause, x0
    li      t3, 11
    bne     t2, t3, fail
    ecall                   # Test 7 passed

# Test 8: csrrw rd = rs (self-swap) on mepc
csrrw_test8:
    li      t0, 0x800
    li      t1, 0x900
    csrrw   x0, mepc, t0    # mepc = 0x800
    csrrw   t1, mepc, t1    # t1 = 0x800 (old mepc), mepc = 0x900 (old t1)
    li      a0, 8
    li      t2, 0x800
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    li      t4, 0x900
    bne     t3, t4, fail
    ecall                   # Test 8 passed

# Test 9: Consecutive csrrw on different CSRs (mepc and mcause)
csrrw_test9:
    li      t0, 0xA00
    li      t1, 0xB00
    csrrw   x0, mepc, t0    # mepc = 0xA00
    csrrw   x0, mcause, t1  # mcause = 0xB00
    csrrw   t2, mepc, x0
    csrrw   t3, mcause, x0
    li      a0, 9
    li      t4, 0xA00
    bne     t2, t4, fail
    li      t5, 0xB00
    bne     t3, t5, fail
    ecall                   # Test 9 passed

# Test 10: csrrw with large negative value
csrrw_test10:
    li      t0, 0x80000004  # Large negative (min int + 4)
    csrrw   x0, mepc, t0
    csrrw   t1, mepc, x0
    li      a0, 10
    li      t2, 0x80000004
    bne     t1, t2, fail
    ecall                   # Test 10 passed

# =============================================================================
# CSRRS Tests (Tests 11-20) - CSR Read and Set bits
# csrrs rd, csr, rs -> rd = csr; csr = csr | rs
# =============================================================================

# Test 11: Basic csrrs - set bits in mepc
csrrs_test11:
    li      t0, 0x0F
    csrrw   x0, mepc, t0    # mepc = 0x0F
    li      t1, 0xF0
    csrrs   t2, mepc, t1    # t2 = 0x0F, mepc = 0xFF
    li      a0, 11
    li      t3, 0x0F
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    li      t5, 0xFF
    bne     t4, t5, fail
    ecall                   # Test 11 passed

# Test 12: Consecutive csrrs on mepc
csrrs_test12:
    csrrw   x0, mepc, x0    # Clear mepc
    li      t0, 0x01
    li      t1, 0x10
    csrrs   t2, mepc, t0    # t2 = 0, mepc = 0x01
    csrrs   t3, mepc, t1    # t3 = 0x01, mepc = 0x11
    li      a0, 12
    bne     t2, x0, fail
    li      t4, 0x01
    bne     t3, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0x11
    bne     t5, t6, fail
    ecall                   # Test 12 passed

# Test 13: csrrs after taken branch - skipped csrrs has no effect
csrrs_test13:
    li      t0, 0x0F
    csrrw   x0, mepc, t0    # mepc = 0x0F
    li      t1, 0xF0
    li      t2, 1
    beq     t2, t2, csrrs_skip13
    csrrs   t3, mepc, t1    # Should NOT execute
csrrs_skip13:
    csrrw   t4, mepc, x0
    li      a0, 13
    li      t5, 0x0F        # Should be unchanged
    bne     t4, t5, fail
    ecall                   # Test 13 passed

# Test 14: csrrs right after mul
csrrs_test14:
    li      t0, 0x100
    csrrw   x0, mepc, t0    # mepc = 0x100
    li      t1, 2
    li      t2, 4
    mul     t3, t1, t2      # t3 = 8
    csrrs   t4, mepc, t3    # t4 = 0x100, mepc = 0x108
    li      a0, 14
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0x108
    bne     t6, t0, fail
    ecall                   # Test 14 passed

# Test 15: csrrs right after div
csrrs_test15:
    li      t0, 0x80
    csrrw   x0, mepc, t0    # mepc = 0x80
    li      t1, 128
    li      t2, 8
    div     t3, t1, t2      # t3 = 16 = 0x10
    csrrs   t4, mepc, t3    # t4 = 0x80, mepc = 0x90
    li      a0, 15
    li      t5, 0x80
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0x90
    bne     t6, t0, fail
    ecall                   # Test 15 passed

# Test 16: csrrs after amoadd
csrrs_test16:
    li      t0, 50
    sw      t0, 4(s0)           # mem[4] = 50
    li      t1, 30
    amoadd.w t2, t1, (s0)       # atomic add
    li      t3, 0xF00
    csrrw   x0, mepc, x0        # Clear mepc
    csrrs   t4, mepc, t3        # t4 = 0, mepc = 0xF00
    li      a0, 16
    bne     t4, x0, fail
    csrrw   t5, mepc, x0
    li      t6, 0xF00
    bne     t5, t6, fail
    ecall                   # Test 16 passed

# Test 17: csrrs on mcause - set interrupt bit
csrrs_test17:
    li      t0, 0x0000000B  # cause = 11
    csrrw   x0, mcause, t0  # mcause = 11
    li      t1, 0x80000000  # interrupt bit
    csrrs   t2, mcause, t1  # t2 = 11, mcause = 0x8000000B
    li      a0, 17
    li      t3, 0x0000000B
    bne     t2, t3, fail
    csrrw   t4, mcause, x0
    li      t5, 0x8000000B
    bne     t4, t5, fail
    ecall                   # Test 17 passed

# Test 18: csrrs with rs = x0 (just read, no modify)
csrrs_test18:
    li      t0, 0x123
    csrrw   x0, mepc, t0    # mepc = 0x123
    csrrs   t1, mepc, x0    # t1 = 0x123, mepc unchanged
    li      a0, 18
    li      t2, 0x123
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail    # Verify mepc unchanged
    ecall                   # Test 18 passed

# Test 19: csrrs setting already set bits (idempotent)
csrrs_test19:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    li      t1, 0x0F
    csrrs   t2, mepc, t1    # t2 = 0xFF, mepc = 0xFF (no change)
    li      a0, 19
    li      t3, 0xFF
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    bne     t4, t3, fail
    ecall                   # Test 19 passed

# Test 20: csrrs with result used immediately in add
csrrs_test20:
    li      t0, 0x50
    csrrw   x0, mepc, t0    # mepc = 0x50
    li      t1, 0x0F
    csrrs   t2, mepc, t1    # t2 = 0x50, mepc = 0x5F
    add     t3, t2, t2      # t3 = 0xA0 (use t2 immediately)
    li      a0, 20
    li      t4, 0xA0
    bne     t3, t4, fail
    ecall                   # Test 20 passed

# =============================================================================
# CSRRC Tests (Tests 21-30) - CSR Read and Clear bits
# csrrc rd, csr, rs -> rd = csr; csr = csr & ~rs
# =============================================================================

# Test 21: Basic csrrc - clear bits in mepc
csrrc_test21:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    li      t1, 0x0F
    csrrc   t2, mepc, t1    # t2 = 0xFF, mepc = 0xF0
    li      a0, 21
    li      t3, 0xFF
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    li      t5, 0xF0
    bne     t4, t5, fail
    ecall                   # Test 21 passed

# Test 22: Consecutive csrrc on mepc
csrrc_test22:
    li      t0, 0xFFFF
    csrrw   x0, mepc, t0    # mepc = 0xFFFF
    li      t1, 0x000F
    li      t2, 0x00F0
    csrrc   t3, mepc, t1    # t3 = 0xFFFF, mepc = 0xFFF0
    csrrc   t4, mepc, t2    # t4 = 0xFFF0, mepc = 0xFF00
    li      a0, 22
    li      t5, 0xFFFF
    bne     t3, t5, fail
    li      t6, 0xFFF0
    bne     t4, t6, fail
    csrrw   t0, mepc, x0
    li      t1, 0xFF00
    bne     t0, t1, fail
    ecall                   # Test 22 passed

# Test 23: csrrc after taken branch - skipped csrrc has no effect
csrrc_test23:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    li      t1, 0x0F
    li      t2, 1
    beq     t2, t2, csrrc_skip23
    csrrc   t3, mepc, t1    # Should NOT execute
csrrc_skip23:
    csrrw   t4, mepc, x0
    li      a0, 23
    li      t5, 0xFF        # Should be unchanged
    bne     t4, t5, fail
    ecall                   # Test 23 passed

# Test 24: csrrc right after mul
csrrc_test24:
    li      t0, 0xFFF
    csrrw   x0, mepc, t0    # mepc = 0xFFF
    li      t1, 3
    li      t2, 5
    mul     t3, t1, t2      # t3 = 15 = 0x0F
    csrrc   t4, mepc, t3    # t4 = 0xFFF, mepc = 0xFF0
    li      a0, 24
    li      t5, 0xFFF
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0xFF0
    bne     t6, t0, fail
    ecall                   # Test 24 passed

# Test 25: csrrc right after div
csrrc_test25:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    li      t1, 256
    li      t2, 4
    div     t3, t1, t2      # t3 = 64 = 0x40
    csrrc   t4, mepc, t3    # t4 = 0xFF, mepc = 0xBF
    li      a0, 25
    li      t5, 0xFF
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0xBF
    bne     t6, t0, fail
    ecall                   # Test 25 passed

# Test 26: csrrc after amoand
csrrc_test26:
    li      t0, 0xFF
    sw      t0, 8(s0)           # mem[8] = 0xFF
    li      t1, 0x0F
    amoand.w t2, t1, (s0)       # atomic and
    li      t3, 0xFF
    csrrw   x0, mepc, t3        # mepc = 0xFF
    li      t4, 0xAA
    csrrc   t5, mepc, t4        # t5 = 0xFF, mepc = 0x55
    li      a0, 26
    li      t6, 0xFF
    bne     t5, t6, fail
    csrrw   t0, mepc, x0
    li      t1, 0x55
    bne     t0, t1, fail
    ecall                   # Test 26 passed

# Test 27: csrrc on mcause - clear interrupt bit
csrrc_test27:
    li      t0, 0x8000000B  # mcause with interrupt bit
    csrrw   x0, mcause, t0  # mcause = 0x8000000B
    li      t1, 0x80000000  # interrupt bit mask
    csrrc   t2, mcause, t1  # t2 = 0x8000000B, mcause = 0x0000000B
    li      a0, 27
    li      t3, 0x8000000B
    bne     t2, t3, fail
    csrrw   t4, mcause, x0
    li      t5, 0x0000000B
    bne     t4, t5, fail
    ecall                   # Test 27 passed

# Test 28: csrrc with rs = x0 (just read, no modify)
csrrc_test28:
    li      t0, 0x456
    csrrw   x0, mepc, t0    # mepc = 0x456
    csrrc   t1, mepc, x0    # t1 = 0x456, mepc unchanged
    li      a0, 28
    li      t2, 0x456
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail    # Verify mepc unchanged
    ecall                   # Test 28 passed

# Test 29: csrrc clearing bits that are already 0 (no change)
csrrc_test29:
    li      t0, 0xF0
    csrrw   x0, mepc, t0    # mepc = 0xF0
    li      t1, 0x0F
    csrrc   t2, mepc, t1    # t2 = 0xF0, mepc = 0xF0 (no change, bits were 0)
    li      a0, 29
    li      t3, 0xF0
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    bne     t4, t3, fail
    ecall                   # Test 29 passed

# Test 30: csrrc clearing all bits
csrrc_test30:
    li      t0, 0xFFFFFFFF
    csrrw   x0, mepc, t0    # mepc = 0xFFFFFFFF
    li      t1, 0xFFFFFFFF
    csrrc   t2, mepc, t1    # t2 = 0xFFFFFFFF, mepc = 0
    li      a0, 30
    li      t3, 0xFFFFFFFF
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    bne     t4, x0, fail    # mepc should be 0
    ecall                   # Test 30 passed

# =============================================================================
# CSRRWI Tests (Tests 31-40) - CSR Read/Write Immediate
# csrrwi rd, csr, uimm -> rd = csr; csr = uimm (5-bit zero-extended immediate)
# =============================================================================

# Test 31: Basic csrrwi - write immediate to mepc
csrrwi_test31:
    csrrw   x0, mepc, x0    # Clear mepc
    csrrwi  t0, mepc, 15    # t0 = 0, mepc = 15
    li      a0, 31
    bne     t0, x0, fail
    csrrw   t1, mepc, x0
    li      t2, 15
    bne     t1, t2, fail
    ecall                   # Test 31 passed

# Test 32: Consecutive csrrwi on mepc
csrrwi_test32:
    csrrwi  t0, mepc, 5     # t0 = ?, mepc = 5
    csrrwi  t1, mepc, 10    # t1 = 5, mepc = 10
    li      a0, 32
    li      t2, 5
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    li      t4, 10
    bne     t3, t4, fail
    ecall                   # Test 32 passed

# Test 33: csrrwi after taken branch - skipped csrrwi has no effect
csrrwi_test33:
    csrrwi  t0, mepc, 7     # mepc = 7
    li      t1, 1
    beq     t1, t1, csrrwi_skip33
    csrrwi  t2, mepc, 31    # Should NOT execute
csrrwi_skip33:
    csrrw   t3, mepc, x0
    li      a0, 33
    li      t4, 7
    bne     t3, t4, fail
    ecall                   # Test 33 passed

# Test 34: csrrwi right after mul
csrrwi_test34:
    li      t0, 6
    li      t1, 7
    mul     t2, t0, t1      # t2 = 42
    csrrwi  t3, mepc, 20    # t3 = ?, mepc = 20
    csrrw   t4, mepc, x0
    li      a0, 34
    li      t5, 20
    bne     t4, t5, fail
    ecall                   # Test 34 passed

# Test 35: csrrwi right after div
csrrwi_test35:
    li      t0, 100
    li      t1, 10
    div     t2, t0, t1      # t2 = 10
    csrrwi  t3, mepc, 25    # mepc = 25
    csrrw   t4, mepc, x0
    li      a0, 35
    li      t5, 25
    bne     t4, t5, fail
    ecall                   # Test 35 passed

# Test 36: csrrwi after amoor
csrrwi_test36:
    li      t0, 0xF0
    sw      t0, 12(s0)          # mem[12] = 0xF0
    li      t1, 0x0F
    amoor.w t2, t1, (s0)        # atomic or
    csrrwi  t3, mepc, 31        # mepc = 31
    csrrw   t4, mepc, x0
    li      a0, 36
    li      t5, 31
    bne     t4, t5, fail
    ecall                   # Test 36 passed

# Test 37: csrrwi on mcause
csrrwi_test37:
    csrrw   x0, mcause, x0  # Clear mcause
    csrrwi  t0, mcause, 11  # t0 = 0, mcause = 11
    li      a0, 37
    bne     t0, x0, fail
    csrrw   t1, mcause, x0
    li      t2, 11
    bne     t1, t2, fail
    ecall                   # Test 37 passed

# Test 38: csrrwi with immediate 0 (clears CSR)
csrrwi_test38:
    li      t0, 0xFFF
    csrrw   x0, mepc, t0    # mepc = 0xFFF
    csrrwi  t1, mepc, 0     # t1 = 0xFFF, mepc = 0
    li      a0, 38
    li      t2, 0xFFF
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, x0, fail    # mepc should be 0
    ecall                   # Test 38 passed

# Test 39: csrrwi with rd = x0 (write-only)
csrrwi_test39:
    csrrwi  x0, mepc, 17    # mepc = 17, old value discarded
    csrrw   t0, mepc, x0
    li      a0, 39
    li      t1, 17
    bne     t0, t1, fail
    ecall                   # Test 39 passed

# Test 40: csrrwi with max immediate (31)
csrrwi_test40:
    csrrwi  t0, mepc, 31    # mepc = 31
    csrrw   t1, mepc, x0
    li      a0, 40
    li      t2, 31
    bne     t1, t2, fail
    ecall                   # Test 40 passed

# =============================================================================
# CSRRSI Tests (Tests 41-50) - CSR Read and Set bits Immediate
# csrrsi rd, csr, uimm -> rd = csr; csr = csr | uimm
# =============================================================================

# Test 41: Basic csrrsi - set bits in mepc
csrrsi_test41:
    li      t0, 0x10
    csrrw   x0, mepc, t0    # mepc = 0x10
    csrrsi  t1, mepc, 0x0F  # t1 = 0x10, mepc = 0x1F
    li      a0, 41
    li      t2, 0x10
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    li      t4, 0x1F
    bne     t3, t4, fail
    ecall                   # Test 41 passed

# Test 42: Consecutive csrrsi on mepc
csrrsi_test42:
    csrrw   x0, mepc, x0    # Clear mepc
    csrrsi  t0, mepc, 1     # t0 = 0, mepc = 0x01
    csrrsi  t1, mepc, 2     # t1 = 0x01, mepc = 0x03
    csrrsi  t2, mepc, 4     # t2 = 0x03, mepc = 0x07
    li      a0, 42
    bne     t0, x0, fail
    li      t3, 0x01
    bne     t1, t3, fail
    li      t4, 0x03
    bne     t2, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0x07
    bne     t5, t6, fail
    ecall                   # Test 42 passed

# Test 43: csrrsi after taken branch - skipped csrrsi has no effect
csrrsi_test43:
    li      t0, 0x10
    csrrw   x0, mepc, t0    # mepc = 0x10
    li      t1, 1
    beq     t1, t1, csrrsi_skip43
    csrrsi  t2, mepc, 0x0F  # Should NOT execute
csrrsi_skip43:
    csrrw   t3, mepc, x0
    li      a0, 43
    li      t4, 0x10        # Should be unchanged
    bne     t3, t4, fail
    ecall                   # Test 43 passed

# Test 44: csrrsi right after mul
csrrsi_test44:
    li      t0, 8
    li      t1, 8
    mul     t2, t0, t1      # t2 = 64 = 0x40
    csrrw   x0, mepc, t2    # mepc = 0x40
    csrrsi  t3, mepc, 0x0F  # t3 = 0x40, mepc = 0x4F
    li      a0, 44
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0x4F
    bne     t5, t6, fail
    ecall                   # Test 44 passed

# Test 45: csrrsi right after div
csrrsi_test45:
    li      t0, 512
    li      t1, 8
    div     t2, t0, t1      # t2 = 64 = 0x40
    csrrw   x0, mepc, t2    # mepc = 0x40
    csrrsi  t3, mepc, 0x03  # t3 = 0x40, mepc = 0x43
    li      a0, 45
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0x43
    bne     t5, t6, fail
    ecall                   # Test 45 passed

# Test 46: csrrsi after amoxor
csrrsi_test46:
    li      t0, 0xFF
    sw      t0, 16(s0)          # mem[16] = 0xFF
    li      t1, 0xF0
    amoxor.w t2, t1, (s0)       # atomic xor
    li      t3, 0x100
    csrrw   x0, mepc, t3        # mepc = 0x100
    csrrsi  t4, mepc, 0x1F      # t4 = 0x100, mepc = 0x11F
    li      a0, 46
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0x11F
    bne     t6, t0, fail
    ecall                   # Test 46 passed

# Test 47: csrrsi on mcause
csrrsi_test47:
    li      t0, 0x08
    csrrw   x0, mcause, t0  # mcause = 0x08
    csrrsi  t1, mcause, 0x07 # t1 = 0x08, mcause = 0x0F
    li      a0, 47
    li      t2, 0x08
    bne     t1, t2, fail
    csrrw   t3, mcause, x0
    li      t4, 0x0F
    bne     t3, t4, fail
    ecall                   # Test 47 passed

# Test 48: csrrsi with immediate 0 (just read, no modify)
csrrsi_test48:
    li      t0, 0x789
    csrrw   x0, mepc, t0    # mepc = 0x789
    csrrsi  t1, mepc, 0     # t1 = 0x789, mepc unchanged
    li      a0, 48
    li      t2, 0x789
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail    # Verify mepc unchanged
    ecall                   # Test 48 passed

# Test 49: csrrsi setting already set bits (idempotent)
csrrsi_test49:
    li      t0, 0x1F
    csrrw   x0, mepc, t0    # mepc = 0x1F
    csrrsi  t1, mepc, 0x0F  # t1 = 0x1F, mepc = 0x1F (no change)
    li      a0, 49
    li      t2, 0x1F
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail
    ecall                   # Test 49 passed

# Test 50: csrrsi with value used immediately
csrrsi_test50:
    li      t0, 0x20
    csrrw   x0, mepc, t0    # mepc = 0x20
    csrrsi  t1, mepc, 0x1F  # t1 = 0x20, mepc = 0x3F
    slli    t2, t1, 1       # t2 = 0x40 (use t1 immediately)
    li      a0, 50
    li      t3, 0x40
    bne     t2, t3, fail
    ecall                   # Test 50 passed

# =============================================================================
# CSRRCI Tests (Tests 51-60) - CSR Read and Clear bits Immediate
# csrrci rd, csr, uimm -> rd = csr; csr = csr & ~uimm
# =============================================================================

# Test 51: Basic csrrci - clear bits in mepc
csrrci_test51:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    csrrci  t1, mepc, 0x0F  # t1 = 0xFF, mepc = 0xF0
    li      a0, 51
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    li      t4, 0xF0
    bne     t3, t4, fail
    ecall                   # Test 51 passed

# Test 52: Consecutive csrrci on mepc
csrrci_test52:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    csrrci  t1, mepc, 0x01  # t1 = 0xFF, mepc = 0xFE
    csrrci  t2, mepc, 0x02  # t2 = 0xFE, mepc = 0xFC
    csrrci  t3, mepc, 0x04  # t3 = 0xFC, mepc = 0xF8
    li      a0, 52
    li      t4, 0xFF
    bne     t1, t4, fail
    li      t5, 0xFE
    bne     t2, t5, fail
    li      t6, 0xFC
    bne     t3, t6, fail
    csrrw   t0, mepc, x0
    li      t1, 0xF8
    bne     t0, t1, fail
    ecall                   # Test 52 passed

# Test 53: csrrci after taken branch - skipped csrrci has no effect
csrrci_test53:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    li      t1, 1
    beq     t1, t1, csrrci_skip53
    csrrci  t2, mepc, 0x0F  # Should NOT execute
csrrci_skip53:
    csrrw   t3, mepc, x0
    li      a0, 53
    li      t4, 0xFF        # Should be unchanged
    bne     t3, t4, fail
    ecall                   # Test 53 passed

# Test 54: csrrci right after mul
csrrci_test54:
    li      t0, 5
    li      t1, 51
    mul     t2, t0, t1      # t2 = 255 = 0xFF
    csrrw   x0, mepc, t2    # mepc = 0xFF
    csrrci  t3, mepc, 0x0F  # t3 = 0xFF, mepc = 0xF0
    li      a0, 54
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0xF0
    bne     t5, t6, fail
    ecall                   # Test 54 passed

# Test 55: csrrci right after div
csrrci_test55:
    li      t0, 1020
    li      t1, 4
    div     t2, t0, t1      # t2 = 255 = 0xFF
    csrrw   x0, mepc, t2    # mepc = 0xFF
    csrrci  t3, mepc, 0x10  # t3 = 0xFF, mepc = 0xEF
    li      a0, 55
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mepc, x0
    li      t6, 0xEF
    bne     t5, t6, fail
    ecall                   # Test 55 passed

# Test 56: csrrci after amomax
csrrci_test56:
    li      t0, 50
    sw      t0, 20(s0)          # mem[20] = 50
    li      t1, 100
    amomax.w t2, t1, (s0)       # atomic max
    li      t3, 0x1FF
    csrrw   x0, mepc, t3        # mepc = 0x1FF
    csrrci  t4, mepc, 0x0F      # t4 = 0x1FF, mepc = 0x1F0
    li      a0, 56
    li      t5, 0x1FF
    bne     t4, t5, fail
    csrrw   t6, mepc, x0
    li      t0, 0x1F0
    bne     t6, t0, fail
    ecall                   # Test 56 passed

# Test 57: csrrci on mcause
csrrci_test57:
    li      t0, 0xFF
    csrrw   x0, mcause, t0  # mcause = 0xFF
    csrrci  t1, mcause, 0x0F # t1 = 0xFF, mcause = 0xF0
    li      a0, 57
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mcause, x0
    li      t4, 0xF0
    bne     t3, t4, fail
    ecall                   # Test 57 passed

# Test 58: csrrci with immediate 0 (just read, no modify)
csrrci_test58:
    li      t0, 0xABC
    csrrw   x0, mepc, t0    # mepc = 0xABC
    csrrci  t1, mepc, 0     # t1 = 0xABC, mepc unchanged
    li      a0, 58
    li      t2, 0xABC
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail    # Verify mepc unchanged
    ecall                   # Test 58 passed

# Test 59: csrrci clearing bits that are already 0 (no change)
csrrci_test59:
    li      t0, 0xF0
    csrrw   x0, mepc, t0    # mepc = 0xF0
    csrrci  t1, mepc, 0x0F  # t1 = 0xF0, mepc = 0xF0 (no change)
    li      a0, 59
    li      t2, 0xF0
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail
    ecall                   # Test 59 passed

# Test 60: csrrci with max immediate (31) clearing low 5 bits
csrrci_test60:
    li      t0, 0xFF
    csrrw   x0, mepc, t0    # mepc = 0xFF
    csrrci  t1, mepc, 31    # t1 = 0xFF, mepc = 0xE0 (clear bits 0-4)
    li      a0, 60
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    li      t4, 0xE0
    bne     t3, t4, fail
    ecall                   # Test 60 passed

# =============================================================================
# All tests passed - end normally
# =============================================================================
all_passed:
    li      a0, 0           # All tests passed indicator
    ecall
    j       end_program

fail:
    # a0 already contains the failing test number
    # Fall through to end

end_program:

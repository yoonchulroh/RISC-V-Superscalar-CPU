# RV32IMA_zicsr Extra CSR Instruction Tests
# Tests all 6 zicsr instructions: csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
# 10 test cases per instruction (60 total), operating on mscratch, mtval, mie, and mip
# mepc, mstatus, mcause are used as auxiliaries where needed (never mtvec)
# Each test verifies both rd value and CSR value
# Special tests: consecutive CSR, CSR after taken branch (no effect), CSR after mul/div, CSR after amo
# For mip: writes should NOT change the value (read-only)
# If test i succeeds, store i to a0 then ecall
# If test i fails, jump to end immediately (a0 = failing test number)
# CSR addresses: mscratch=0x340, mtval=0x343, mie=0x304, mip=0x344

.section .text
.globl _start

_start:
    # Initialize base address for amo operations
    li s0, 0           # Base address for amo operations

# =============================================================================
# CSRRW Tests (Tests 1-10) - CSR Read/Write
# csrrw rd, csr, rs -> rd = csr; csr = rs
# =============================================================================

# Test 1: Basic csrrw - write value to mscratch and verify rd gets old value
csrrw_test1:
    csrrw   x0, mscratch, x0   # Clear mscratch first
    li      t0, 0xDEADBEEF
    csrrw   t1, mscratch, t0   # t1 = old mscratch (0), mscratch = 0xDEADBEEF
    li      a0, 1
    bne     t1, x0, fail       # Verify t1 is 0 (old value)
    csrrw   t2, mscratch, x0   # t2 = mscratch
    li      t3, 0xDEADBEEF
    bne     t2, t3, fail       # Verify mscratch = 0xDEADBEEF
    ecall                       # Test 1 passed

# Test 2: Consecutive csrrw on mscratch - verify sequential updates
csrrw_test2:
    li      t0, 0x11111111
    li      t1, 0x22222222
    csrrw   x0, mscratch, t0   # mscratch = 0x11111111
    csrrw   t2, mscratch, t1   # t2 = 0x11111111, mscratch = 0x22222222
    li      a0, 2
    li      t3, 0x11111111
    bne     t2, t3, fail
    csrrw   t4, mscratch, x0   # t4 = 0x22222222
    li      t5, 0x22222222
    bne     t4, t5, fail
    ecall                       # Test 2 passed

# Test 3: csrrw after taken branch - skipped csrrw should have no effect
csrrw_test3:
    li      t0, 0xCAFEBABE
    csrrw   x0, mscratch, t0   # mscratch = 0xCAFEBABE
    li      t1, 0x99999999     # Wrong value
    li      t2, 1
    beq     t2, t2, csrrw_skip3  # Always taken
    csrrw   t3, mscratch, t1   # Should NOT execute
csrrw_skip3:
    csrrw   t4, mscratch, x0   # Read mscratch
    li      a0, 3
    li      t5, 0xCAFEBABE
    bne     t4, t5, fail       # Verify mscratch unchanged
    ecall                       # Test 3 passed

# Test 4: csrrw right after mul - verify correct value from mul is written
csrrw_test4:
    li      t0, 7
    li      t1, 11
    mul     t2, t0, t1          # t2 = 77
    csrrw   x0, mscratch, t2   # mscratch = 77
    csrrw   t3, mscratch, x0   # t3 = mscratch
    li      a0, 4
    li      t4, 77
    bne     t3, t4, fail
    ecall                       # Test 4 passed

# Test 5: csrrw right after div - verify correct value from div is written
csrrw_test5:
    li      t0, 1000
    li      t1, 7
    div     t2, t0, t1          # t2 = 142
    csrrw   x0, mtval, t2      # mtval = 142
    csrrw   t3, mtval, x0      # t3 = mtval
    li      a0, 5
    li      t4, 142
    bne     t3, t4, fail
    ecall                       # Test 5 passed

# Test 6: csrrw after amoswap - verify csrrw works after atomic operation
csrrw_test6:
    li      t0, 100
    sw      t0, 0(s0)               # mem[0] = 100
    li      t1, 200
    amoswap.w t2, t1, (s0)          # t2 = 100, mem[0] = 200
    li      t3, 0xABCD1234
    csrrw   x0, mtval, t3           # mtval = 0xABCD1234
    csrrw   t4, mtval, x0
    li      a0, 6
    li      t5, 0xABCD1234
    bne     t4, t5, fail
    ecall                       # Test 6 passed

# Test 7: csrrw on mie - basic write and read
csrrw_test7:
    li      t0, 0x00000888      # MEIE | MTIE | MSIE bits
    csrrw   x0, mie, x0         # Clear mie
    csrrw   t1, mie, t0         # t1 = old mie (0), mie = 0x888
    li      a0, 7
    bne     t1, x0, fail
    csrrw   t2, mie, x0
    li      t3, 0x00000888
    bne     t2, t3, fail
    ecall                       # Test 7 passed

# Test 8: csrrw rd = rs (self-swap) on mscratch
csrrw_test8:
    li      t0, 0xAAAA0000
    li      t1, 0x5555FFFF
    csrrw   x0, mscratch, t0   # mscratch = 0xAAAA0000
    csrrw   t1, mscratch, t1   # t1 = 0xAAAA0000 (old mscratch), mscratch = 0x5555FFFF
    li      a0, 8
    li      t2, 0xAAAA0000
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    li      t4, 0x5555FFFF
    bne     t3, t4, fail
    ecall                       # Test 8 passed

# Test 9: Consecutive csrrw on different CSRs (mscratch and mtval)
csrrw_test9:
    li      t0, 0x12340000
    li      t1, 0x56780000
    csrrw   x0, mscratch, t0   # mscratch = 0x12340000
    csrrw   x0, mtval, t1      # mtval = 0x56780000
    csrrw   t2, mscratch, x0
    csrrw   t3, mtval, x0
    li      a0, 9
    li      t4, 0x12340000
    bne     t2, t4, fail
    li      t5, 0x56780000
    bne     t3, t5, fail
    ecall                       # Test 9 passed

# Test 10: csrrw to mip - writes should NOT change mip (read-only)
# mip is driven by hardware (timer_mtip), so writing should have no effect
csrrw_test10:
    csrrw   t0, mip, x0        # Read current mip value
    li      t1, 0xFFFFFFFF
    csrrw   t2, mip, t1        # Try to write 0xFFFFFFFF to mip; t2 = old mip
    bne     t2, t0, fail       # t2 should equal original mip
    csrrw   t3, mip, x0        # Read mip again
    li      a0, 10
    bne     t3, t0, fail       # mip should be unchanged from original
    ecall                       # Test 10 passed

# =============================================================================
# CSRRS Tests (Tests 11-20) - CSR Read and Set bits
# csrrs rd, csr, rs -> rd = csr; csr = csr | rs
# =============================================================================

# Test 11: Basic csrrs - set bits in mscratch
csrrs_test11:
    li      t0, 0x0F0F0F0F
    csrrw   x0, mscratch, t0   # mscratch = 0x0F0F0F0F
    li      t1, 0xF0F0F0F0
    csrrs   t2, mscratch, t1   # t2 = 0x0F0F0F0F, mscratch = 0xFFFFFFFF
    li      a0, 11
    li      t3, 0x0F0F0F0F
    bne     t2, t3, fail
    csrrw   t4, mscratch, x0
    li      t5, 0xFFFFFFFF
    bne     t4, t5, fail
    ecall                       # Test 11 passed

# Test 12: Consecutive csrrs on mtval
csrrs_test12:
    csrrw   x0, mtval, x0      # Clear mtval
    li      t0, 0x000000FF
    li      t1, 0x0000FF00
    csrrs   t2, mtval, t0      # t2 = 0, mtval = 0x000000FF
    csrrs   t3, mtval, t1      # t3 = 0xFF, mtval = 0x0000FFFF
    li      a0, 12
    bne     t2, x0, fail
    li      t4, 0x000000FF
    bne     t3, t4, fail
    csrrw   t5, mtval, x0
    li      t6, 0x0000FFFF
    bne     t5, t6, fail
    ecall                       # Test 12 passed

# Test 13: csrrs after taken branch - skipped csrrs has no effect
csrrs_test13:
    li      t0, 0x0F
    csrrw   x0, mscratch, t0   # mscratch = 0x0F
    li      t1, 0xF0
    li      t2, 1
    beq     t2, t2, csrrs_skip13
    csrrs   t3, mscratch, t1   # Should NOT execute
csrrs_skip13:
    csrrw   t4, mscratch, x0
    li      a0, 13
    li      t5, 0x0F           # Should be unchanged
    bne     t4, t5, fail
    ecall                       # Test 13 passed

# Test 14: csrrs right after mul
csrrs_test14:
    li      t0, 0x100
    csrrw   x0, mtval, t0      # mtval = 0x100
    li      t1, 3
    li      t2, 4
    mul     t3, t1, t2          # t3 = 12 = 0x0C
    csrrs   t4, mtval, t3      # t4 = 0x100, mtval = 0x10C
    li      a0, 14
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mtval, x0
    li      t0, 0x10C
    bne     t6, t0, fail
    ecall                       # Test 14 passed

# Test 15: csrrs right after div
csrrs_test15:
    li      t0, 0x200
    csrrw   x0, mscratch, t0   # mscratch = 0x200
    li      t1, 192
    li      t2, 6
    div     t3, t1, t2          # t3 = 32 = 0x20
    csrrs   t4, mscratch, t3   # t4 = 0x200, mscratch = 0x220
    li      a0, 15
    li      t5, 0x200
    bne     t4, t5, fail
    csrrw   t6, mscratch, x0
    li      t0, 0x220
    bne     t6, t0, fail
    ecall                       # Test 15 passed

# Test 16: csrrs after amoadd
csrrs_test16:
    li      t0, 50
    sw      t0, 4(s0)               # mem[4] = 50
    li      t1, 30
    amoadd.w t2, t1, (s0)           # atomic add
    li      t3, 0xF00
    csrrw   x0, mie, x0             # Clear mie
    csrrs   t4, mie, t3             # t4 = 0, mie = 0xF00
    li      a0, 16
    bne     t4, x0, fail
    csrrw   t5, mie, x0
    li      t6, 0xF00
    bne     t5, t6, fail
    ecall                       # Test 16 passed

# Test 17: csrrs on mie - set timer and external interrupt enable bits
csrrs_test17:
    li      t0, 0x00000080      # MTIE only
    csrrw   x0, mie, t0         # mie = 0x80
    li      t1, 0x00000800      # MEIE bit
    csrrs   t2, mie, t1         # t2 = 0x80, mie = 0x880
    li      a0, 17
    li      t3, 0x80
    bne     t2, t3, fail
    csrrw   t4, mie, x0
    li      t5, 0x880
    bne     t4, t5, fail
    ecall                       # Test 17 passed

# Test 18: csrrs with rs = x0 (just read, no modify)
csrrs_test18:
    li      t0, 0xABCDEF01
    csrrw   x0, mscratch, t0   # mscratch = 0xABCDEF01
    csrrs   t1, mscratch, x0   # t1 = 0xABCDEF01, mscratch unchanged
    li      a0, 18
    li      t2, 0xABCDEF01
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    bne     t3, t2, fail       # Verify mscratch unchanged
    ecall                       # Test 18 passed

# Test 19: csrrs setting already set bits (idempotent) on mtval
csrrs_test19:
    li      t0, 0xFF
    csrrw   x0, mtval, t0      # mtval = 0xFF
    li      t1, 0x0F
    csrrs   t2, mtval, t1      # t2 = 0xFF, mtval = 0xFF (no change)
    li      a0, 19
    li      t3, 0xFF
    bne     t2, t3, fail
    csrrw   t4, mtval, x0
    bne     t4, t3, fail
    ecall                       # Test 19 passed

# Test 20: csrrs on mip - setting bits should have no effect (read-only)
csrrs_test20:
    csrrs   t0, mip, x0        # Read current mip value (no modify since rs=x0)
    li      t1, 0xFFFFFFFF
    csrrs   t2, mip, t1        # Try to set all bits in mip; t2 = old mip
    bne     t2, t0, fail       # t2 should equal original mip
    csrrs   t3, mip, x0        # Read mip again
    li      a0, 20
    bne     t3, t0, fail       # mip should be unchanged
    ecall                       # Test 20 passed

# =============================================================================
# CSRRC Tests (Tests 21-30) - CSR Read and Clear bits
# csrrc rd, csr, rs -> rd = csr; csr = csr & ~rs
# =============================================================================

# Test 21: Basic csrrc - clear bits in mscratch
csrrc_test21:
    li      t0, 0xFFFF0000
    csrrw   x0, mscratch, t0   # mscratch = 0xFFFF0000
    li      t1, 0x0F0F0000
    csrrc   t2, mscratch, t1   # t2 = 0xFFFF0000, mscratch = 0xF0F00000
    li      a0, 21
    li      t3, 0xFFFF0000
    bne     t2, t3, fail
    csrrw   t4, mscratch, x0
    li      t5, 0xF0F00000
    bne     t4, t5, fail
    ecall                       # Test 21 passed

# Test 22: Consecutive csrrc on mtval
csrrc_test22:
    li      t0, 0xFFFFFFFF
    csrrw   x0, mtval, t0      # mtval = 0xFFFFFFFF
    li      t1, 0x000000FF
    li      t2, 0x0000FF00
    csrrc   t3, mtval, t1      # t3 = 0xFFFFFFFF, mtval = 0xFFFFFF00
    csrrc   t4, mtval, t2      # t4 = 0xFFFFFF00, mtval = 0xFFFF0000
    li      a0, 22
    li      t5, 0xFFFFFFFF
    bne     t3, t5, fail
    li      t6, 0xFFFFFF00
    bne     t4, t6, fail
    csrrw   t0, mtval, x0
    li      t1, 0xFFFF0000
    bne     t0, t1, fail
    ecall                       # Test 22 passed

# Test 23: csrrc after taken branch - skipped csrrc has no effect
csrrc_test23:
    li      t0, 0xABCD
    csrrw   x0, mscratch, t0   # mscratch = 0xABCD
    li      t1, 0x00CD
    li      t2, 1
    beq     t2, t2, csrrc_skip23
    csrrc   t3, mscratch, t1   # Should NOT execute
csrrc_skip23:
    csrrw   t4, mscratch, x0
    li      a0, 23
    li      t5, 0xABCD         # Should be unchanged
    bne     t4, t5, fail
    ecall                       # Test 23 passed

# Test 24: csrrc right after mul
csrrc_test24:
    li      t0, 0xFFF
    csrrw   x0, mtval, t0      # mtval = 0xFFF
    li      t1, 5
    li      t2, 7
    mul     t3, t1, t2          # t3 = 35 = 0x23
    csrrc   t4, mtval, t3      # t4 = 0xFFF, mtval = 0xFDC
    li      a0, 24
    li      t5, 0xFFF
    bne     t4, t5, fail
    csrrw   t6, mtval, x0
    li      t0, 0xFDC
    bne     t6, t0, fail
    ecall                       # Test 24 passed

# Test 25: csrrc right after div
csrrc_test25:
    li      t0, 0xFF
    csrrw   x0, mscratch, t0   # mscratch = 0xFF
    li      t1, 240
    li      t2, 5
    div     t3, t1, t2          # t3 = 48 = 0x30
    csrrc   t4, mscratch, t3   # t4 = 0xFF, mscratch = 0xCF
    li      a0, 25
    li      t5, 0xFF
    bne     t4, t5, fail
    csrrw   t6, mscratch, x0
    li      t0, 0xCF
    bne     t6, t0, fail
    ecall                       # Test 25 passed

# Test 26: csrrc after amoand
csrrc_test26:
    li      t0, 0xFF
    sw      t0, 8(s0)               # mem[8] = 0xFF
    li      t1, 0x0F
    amoand.w t2, t1, (s0)           # atomic and
    li      t3, 0x1888
    csrrw   x0, mie, t3             # mie = 0x1888
    li      t4, 0x0808
    csrrc   t5, mie, t4             # t5 = 0x1888, mie = 0x1080
    li      a0, 26
    li      t6, 0x1888
    bne     t5, t6, fail
    csrrw   t0, mie, x0
    li      t1, 0x1080
    bne     t0, t1, fail
    ecall                       # Test 26 passed

# Test 27: csrrc on mtval - clear high bits
csrrc_test27:
    li      t0, 0xFFFF0000
    csrrw   x0, mtval, t0      # mtval = 0xFFFF0000
    li      t1, 0xFF000000      # Clear top byte
    csrrc   t2, mtval, t1      # t2 = 0xFFFF0000, mtval = 0x00FF0000
    li      a0, 27
    li      t3, 0xFFFF0000
    bne     t2, t3, fail
    csrrw   t4, mtval, x0
    li      t5, 0x00FF0000
    bne     t4, t5, fail
    ecall                       # Test 27 passed

# Test 28: csrrc with rs = x0 (just read, no modify) on mscratch
csrrc_test28:
    li      t0, 0x13579BDF
    csrrw   x0, mscratch, t0   # mscratch = 0x13579BDF
    csrrc   t1, mscratch, x0   # t1 = 0x13579BDF, mscratch unchanged
    li      a0, 28
    li      t2, 0x13579BDF
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    bne     t3, t2, fail       # Verify mscratch unchanged
    ecall                       # Test 28 passed

# Test 29: csrrc clearing bits that are already 0 (no change) on mie
csrrc_test29:
    li      t0, 0xF00
    csrrw   x0, mie, t0        # mie = 0xF00
    li      t1, 0x0FF
    csrrc   t2, mie, t1        # t2 = 0xF00, mie = 0xF00 (no change, targeted bits already 0)
    li      a0, 29
    li      t3, 0xF00
    bne     t2, t3, fail
    csrrw   t4, mie, x0
    bne     t4, t3, fail
    ecall                       # Test 29 passed

# Test 30: csrrc on mip - clearing bits should have no effect (read-only)
csrrc_test30:
    csrrc   t0, mip, x0        # Read current mip value
    li      t1, 0xFFFFFFFF
    csrrc   t2, mip, t1        # Try to clear all bits; t2 = old mip
    bne     t2, t0, fail       # t2 should equal original mip
    csrrc   t3, mip, x0        # Read mip again
    li      a0, 30
    bne     t3, t0, fail       # mip should be unchanged
    ecall                       # Test 30 passed

# =============================================================================
# CSRRWI Tests (Tests 31-40) - CSR Read/Write Immediate
# csrrwi rd, csr, uimm -> rd = csr; csr = uimm (5-bit zero-extended immediate)
# =============================================================================

# Test 31: Basic csrrwi - write immediate to mscratch
csrrwi_test31:
    csrrw   x0, mscratch, x0   # Clear mscratch
    csrrwi  t0, mscratch, 15   # t0 = 0, mscratch = 15
    li      a0, 31
    bne     t0, x0, fail
    csrrw   t1, mscratch, x0
    li      t2, 15
    bne     t1, t2, fail
    ecall                       # Test 31 passed

# Test 32: Consecutive csrrwi on mscratch
csrrwi_test32:
    csrrwi  t0, mscratch, 5    # t0 = ?, mscratch = 5
    csrrwi  t1, mscratch, 10   # t1 = 5, mscratch = 10
    li      a0, 32
    li      t2, 5
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    li      t4, 10
    bne     t3, t4, fail
    ecall                       # Test 32 passed

# Test 33: csrrwi after taken branch - skipped csrrwi has no effect
csrrwi_test33:
    csrrwi  t0, mtval, 7       # mtval = 7
    li      t1, 1
    beq     t1, t1, csrrwi_skip33
    csrrwi  t2, mtval, 31      # Should NOT execute
csrrwi_skip33:
    csrrw   t3, mtval, x0
    li      a0, 33
    li      t4, 7
    bne     t3, t4, fail
    ecall                       # Test 33 passed

# Test 34: csrrwi right after mul
csrrwi_test34:
    li      t0, 6
    li      t1, 7
    mul     t2, t0, t1          # t2 = 42
    csrrwi  t3, mscratch, 20   # t3 = ?, mscratch = 20
    csrrw   t4, mscratch, x0
    li      a0, 34
    li      t5, 20
    bne     t4, t5, fail
    ecall                       # Test 34 passed

# Test 35: csrrwi right after div
csrrwi_test35:
    li      t0, 100
    li      t1, 10
    div     t2, t0, t1          # t2 = 10
    csrrwi  t3, mtval, 25      # mtval = 25
    csrrw   t4, mtval, x0
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
    csrrwi  t3, mie, 31             # mie = 31
    csrrw   t4, mie, x0
    li      a0, 36
    li      t5, 31
    bne     t4, t5, fail
    ecall                       # Test 36 passed

# Test 37: csrrwi on mscratch then verify mtval is independent
csrrwi_test37:
    li      t0, 0xABC
    csrrw   x0, mtval, t0      # mtval = 0xABC
    csrrwi  t1, mscratch, 8    # mscratch = 8
    csrrw   t2, mtval, x0      # t2 = mtval should still be 0xABC
    li      a0, 37
    li      t3, 0xABC
    bne     t2, t3, fail
    csrrw   t4, mscratch, x0
    li      t5, 8
    bne     t4, t5, fail
    ecall                       # Test 37 passed

# Test 38: csrrwi with immediate 0 (clears mscratch)
csrrwi_test38:
    li      t0, 0xFFF
    csrrw   x0, mscratch, t0   # mscratch = 0xFFF
    csrrwi  t1, mscratch, 0    # t1 = 0xFFF, mscratch = 0
    li      a0, 38
    li      t2, 0xFFF
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    bne     t3, x0, fail       # mscratch should be 0
    ecall                       # Test 38 passed

# Test 39: csrrwi with rd = x0 (write-only) on mtval
csrrwi_test39:
    csrrwi  x0, mtval, 17      # mtval = 17, old value discarded
    csrrw   t0, mtval, x0
    li      a0, 39
    li      t1, 17
    bne     t0, t1, fail
    ecall                       # Test 39 passed

# Test 40: csrrwi to mip - write should NOT change mip (read-only)
csrrwi_test40:
    csrrw   t0, mip, x0        # Read current mip value
    csrrwi  t1, mip, 31        # Try to write 31 to mip; t1 = old mip
    bne     t1, t0, fail       # t1 should equal original mip
    csrrw   t2, mip, x0        # Read mip again
    li      a0, 40
    bne     t2, t0, fail       # mip should be unchanged
    ecall                       # Test 40 passed

# =============================================================================
# CSRRSI Tests (Tests 41-50) - CSR Read and Set bits Immediate
# csrrsi rd, csr, uimm -> rd = csr; csr = csr | uimm
# =============================================================================

# Test 41: Basic csrrsi - set bits in mscratch
csrrsi_test41:
    li      t0, 0x10
    csrrw   x0, mscratch, t0   # mscratch = 0x10
    csrrsi  t1, mscratch, 0x0F # t1 = 0x10, mscratch = 0x1F
    li      a0, 41
    li      t2, 0x10
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    li      t4, 0x1F
    bne     t3, t4, fail
    ecall                       # Test 41 passed

# Test 42: Consecutive csrrsi on mtval
csrrsi_test42:
    csrrw   x0, mtval, x0      # Clear mtval
    csrrsi  t0, mtval, 1       # t0 = 0, mtval = 0x01
    csrrsi  t1, mtval, 2       # t1 = 0x01, mtval = 0x03
    csrrsi  t2, mtval, 4       # t2 = 0x03, mtval = 0x07
    li      a0, 42
    bne     t0, x0, fail
    li      t3, 0x01
    bne     t1, t3, fail
    li      t4, 0x03
    bne     t2, t4, fail
    csrrw   t5, mtval, x0
    li      t6, 0x07
    bne     t5, t6, fail
    ecall                       # Test 42 passed

# Test 43: csrrsi after taken branch - skipped csrrsi has no effect
csrrsi_test43:
    li      t0, 0x10
    csrrw   x0, mscratch, t0   # mscratch = 0x10
    li      t1, 1
    beq     t1, t1, csrrsi_skip43
    csrrsi  t2, mscratch, 0x0F # Should NOT execute
csrrsi_skip43:
    csrrw   t3, mscratch, x0
    li      a0, 43
    li      t4, 0x10           # Should be unchanged
    bne     t3, t4, fail
    ecall                       # Test 43 passed

# Test 44: csrrsi right after mul on mscratch
csrrsi_test44:
    li      t0, 8
    li      t1, 8
    mul     t2, t0, t1          # t2 = 64 = 0x40
    csrrw   x0, mscratch, t2   # mscratch = 0x40
    csrrsi  t3, mscratch, 0x0F # t3 = 0x40, mscratch = 0x4F
    li      a0, 44
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mscratch, x0
    li      t6, 0x4F
    bne     t5, t6, fail
    ecall                       # Test 44 passed

# Test 45: csrrsi right after div on mtval
csrrsi_test45:
    li      t0, 512
    li      t1, 8
    div     t2, t0, t1          # t2 = 64 = 0x40
    csrrw   x0, mtval, t2      # mtval = 0x40
    csrrsi  t3, mtval, 0x03    # t3 = 0x40, mtval = 0x43
    li      a0, 45
    li      t4, 0x40
    bne     t3, t4, fail
    csrrw   t5, mtval, x0
    li      t6, 0x43
    bne     t5, t6, fail
    ecall                       # Test 45 passed

# Test 46: csrrsi after amoxor on mie
csrrsi_test46:
    li      t0, 0xFF
    sw      t0, 16(s0)              # mem[16] = 0xFF
    li      t1, 0xF0
    amoxor.w t2, t1, (s0)           # atomic xor
    li      t3, 0x100
    csrrw   x0, mie, t3             # mie = 0x100
    csrrsi  t4, mie, 0x1F           # t4 = 0x100, mie = 0x11F
    li      a0, 46
    li      t5, 0x100
    bne     t4, t5, fail
    csrrw   t6, mie, x0
    li      t0, 0x11F
    bne     t6, t0, fail
    ecall                       # Test 46 passed

# Test 47: csrrsi on mscratch with mepc cross-check
csrrsi_test47:
    li      t0, 0x08
    csrrw   x0, mscratch, t0   # mscratch = 0x08
    li      t1, 0x0B
    csrrw   x0, mepc, t1       # mepc = 0x0B
    csrrsi  t2, mscratch, 0x07 # t2 = 0x08, mscratch = 0x0F
    li      a0, 47
    li      t3, 0x08
    bne     t2, t3, fail
    csrrw   t4, mscratch, x0
    li      t5, 0x0F
    bne     t4, t5, fail
    csrrw   t6, mepc, x0       # mepc should be unchanged
    li      t0, 0x0B
    bne     t6, t0, fail
    ecall                       # Test 47 passed

# Test 48: csrrsi with immediate 0 (just read, no modify) on mtval
csrrsi_test48:
    li      t0, 0x789
    csrrw   x0, mtval, t0      # mtval = 0x789
    csrrsi  t1, mtval, 0       # t1 = 0x789, mtval unchanged
    li      a0, 48
    li      t2, 0x789
    bne     t1, t2, fail
    csrrw   t3, mtval, x0
    bne     t3, t2, fail       # Verify mtval unchanged
    ecall                       # Test 48 passed

# Test 49: csrrsi setting already set bits (idempotent) on mscratch
csrrsi_test49:
    li      t0, 0x1F
    csrrw   x0, mscratch, t0   # mscratch = 0x1F
    csrrsi  t1, mscratch, 0x0F # t1 = 0x1F, mscratch = 0x1F (no change)
    li      a0, 49
    li      t2, 0x1F
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    bne     t3, t2, fail
    ecall                       # Test 49 passed

# Test 50: csrrsi on mip - setting bits should have no effect (read-only)
csrrsi_test50:
    csrrsi  t0, mip, 0         # Read current mip value (no modify)
    csrrsi  t1, mip, 0x1F      # Try to set low 5 bits; t1 = old mip
    bne     t1, t0, fail       # t1 should equal original mip
    csrrsi  t2, mip, 0         # Read mip again
    li      a0, 50
    bne     t2, t0, fail       # mip should be unchanged
    ecall                       # Test 50 passed

# =============================================================================
# CSRRCI Tests (Tests 51-60) - CSR Read and Clear bits Immediate
# csrrci rd, csr, uimm -> rd = csr; csr = csr & ~uimm
# =============================================================================

# Test 51: Basic csrrci - clear bits in mscratch
csrrci_test51:
    li      t0, 0xFF
    csrrw   x0, mscratch, t0   # mscratch = 0xFF
    csrrci  t1, mscratch, 0x0F # t1 = 0xFF, mscratch = 0xF0
    li      a0, 51
    li      t2, 0xFF
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    li      t4, 0xF0
    bne     t3, t4, fail
    ecall                       # Test 51 passed

# Test 52: Consecutive csrrci on mtval
csrrci_test52:
    li      t0, 0xFF
    csrrw   x0, mtval, t0      # mtval = 0xFF
    csrrci  t1, mtval, 0x01    # t1 = 0xFF, mtval = 0xFE
    csrrci  t2, mtval, 0x02    # t2 = 0xFE, mtval = 0xFC
    csrrci  t3, mtval, 0x04    # t3 = 0xFC, mtval = 0xF8
    li      a0, 52
    li      t4, 0xFF
    bne     t1, t4, fail
    li      t5, 0xFE
    bne     t2, t5, fail
    li      t6, 0xFC
    bne     t3, t6, fail
    csrrw   t0, mtval, x0
    li      t1, 0xF8
    bne     t0, t1, fail
    ecall                       # Test 52 passed

# Test 53: csrrci after taken branch - skipped csrrci has no effect
csrrci_test53:
    li      t0, 0xFF
    csrrw   x0, mscratch, t0   # mscratch = 0xFF
    li      t1, 1
    beq     t1, t1, csrrci_skip53
    csrrci  t2, mscratch, 0x0F # Should NOT execute
csrrci_skip53:
    csrrw   t3, mscratch, x0
    li      a0, 53
    li      t4, 0xFF           # Should be unchanged
    bne     t3, t4, fail
    ecall                       # Test 53 passed

# Test 54: csrrci right after mul on mtval
csrrci_test54:
    li      t0, 5
    li      t1, 51
    mul     t2, t0, t1          # t2 = 255 = 0xFF
    csrrw   x0, mtval, t2      # mtval = 0xFF
    csrrci  t3, mtval, 0x0F    # t3 = 0xFF, mtval = 0xF0
    li      a0, 54
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mtval, x0
    li      t6, 0xF0
    bne     t5, t6, fail
    ecall                       # Test 54 passed

# Test 55: csrrci right after div on mscratch
csrrci_test55:
    li      t0, 1020
    li      t1, 4
    div     t2, t0, t1          # t2 = 255 = 0xFF
    csrrw   x0, mscratch, t2   # mscratch = 0xFF
    csrrci  t3, mscratch, 0x10 # t3 = 0xFF, mscratch = 0xEF
    li      a0, 55
    li      t4, 0xFF
    bne     t3, t4, fail
    csrrw   t5, mscratch, x0
    li      t6, 0xEF
    bne     t5, t6, fail
    ecall                       # Test 55 passed

# Test 56: csrrci after amomax on mie
csrrci_test56:
    li      t0, 50
    sw      t0, 20(s0)              # mem[20] = 50
    li      t1, 100
    amomax.w t2, t1, (s0)           # atomic max
    li      t3, 0x1FF
    csrrw   x0, mie, t3             # mie = 0x1FF
    csrrci  t4, mie, 0x0F           # t4 = 0x1FF, mie = 0x1F0
    li      a0, 56
    li      t5, 0x1FF
    bne     t4, t5, fail
    csrrw   t6, mie, x0
    li      t0, 0x1F0
    bne     t6, t0, fail
    ecall                       # Test 56 passed

# Test 57: csrrci clearing specific bit in mscratch
csrrci_test57:
    li      t0, 0x0F
    csrrw   x0, mscratch, t0   # mscratch = 0x0F
    csrrci  t1, mscratch, 0x08 # t1 = 0x0F, mscratch = 0x07 (bit 3 cleared)
    li      a0, 57
    li      t2, 0x0F
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    li      t4, 0x07
    bne     t3, t4, fail
    ecall                       # Test 57 passed

# Test 58: csrrci with immediate 0 (just read, no modify) on mtval
csrrci_test58:
    li      t0, 0xABC
    csrrw   x0, mtval, t0      # mtval = 0xABC
    csrrci  t1, mtval, 0       # t1 = 0xABC, mtval unchanged
    li      a0, 58
    li      t2, 0xABC
    bne     t1, t2, fail
    csrrw   t3, mtval, x0
    bne     t3, t2, fail       # Verify mtval unchanged
    ecall                       # Test 58 passed

# Test 59: csrrci clearing bits that are already 0 (no change) on mscratch
csrrci_test59:
    li      t0, 0xF0
    csrrw   x0, mscratch, t0   # mscratch = 0xF0
    csrrci  t1, mscratch, 0x0F # t1 = 0xF0, mscratch = 0xF0 (no change)
    li      a0, 59
    li      t2, 0xF0
    bne     t1, t2, fail
    csrrw   t3, mscratch, x0
    bne     t3, t2, fail
    ecall                       # Test 59 passed

# Test 60: csrrci on mip - clearing bits should have no effect (read-only)
csrrci_test60:
    csrrci  t0, mip, 0         # Read current mip value (no modify)
    csrrci  t1, mip, 0x1F      # Try to clear low 5 bits; t1 = old mip
    bne     t1, t0, fail       # t1 should equal original mip
    csrrci  t2, mip, 0         # Read mip again
    li      a0, 60
    bne     t2, t0, fail       # mip should be unchanged
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

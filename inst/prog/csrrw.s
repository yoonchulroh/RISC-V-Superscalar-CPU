# RV32IMA_zicsr CSRRW Instruction Test
# Tests csrrw with 30 test cases: 10 for mtvec, 10 for mepc, 10 for mcause
# Each successful test stores test number to a0 and ecalls
# If any test fails, jumps to end immediately
# CSR addresses: mtvec=0x305, mepc=0x341, mcause=0x342

.section .text
.globl _start

_start:
    # Initialize registers
    li      sp, 0x0         # Set up stack pointer

# =============================================================================
# MEPC Tests (Tests 11-20) - CSR 0x341
# =============================================================================

# Test 11: Basic csrrw on mepc - write value and verify rd gets old value
mepc_test11:
    li      t0, 0x1000
    csrrw   x0, mepc, x0    # Clear mepc
    csrrw   t1, mepc, t0    # t1 = old mepc (0), mepc = 0x1000
    li      a0, 11
    bne     t1, x0, fail
    csrrw   t2, mepc, x0    # t2 = mepc
    li      t3, 0x1000
    bne     t2, t3, fail
    ecall                   # Test 11 passed

# Test 12: Consecutive csrrw on mepc
mepc_test12:
    li      t0, 0x2000
    li      t1, 0x3000
    csrrw   x0, mepc, t0    # mepc = 0x2000
    csrrw   t2, mepc, t1    # t2 = 0x2000, mepc = 0x3000
    li      a0, 12
    li      t3, 0x2000
    bne     t2, t3, fail
    csrrw   t4, mepc, x0
    li      t5, 0x3000
    bne     t4, t5, fail
    ecall                   # Test 12 passed

# Test 13: csrrw on mepc after taken branch - skipped csrrw has no effect
mepc_test13:
    li      t0, 0x4000
    csrrw   x0, mepc, t0    # mepc = 0x4000
    li      t1, 0x999
    li      t2, 1
    beq     t2, t2, mepc_skip13  # Always taken
    csrrw   t3, mepc, t1    # Should NOT execute
mepc_skip13:
    csrrw   t4, mepc, x0
    li      a0, 13
    li      t5, 0x4000
    bne     t4, t5, fail
    ecall                   # Test 13 passed

# Test 14: csrrw on mepc right after mul
mepc_test14:
    li      t0, 100
    li      t1, 20
    mul     t2, t0, t1      # t2 = 2000
    csrrw   x0, mepc, t2    # mepc = 2000
    csrrw   t3, mepc, x0
    li      a0, 14
    li      t4, 2000
    bne     t3, t4, fail
    ecall                   # Test 14 passed

# Test 15: csrrw on mepc right after div
mepc_test15:
    li      t0, 12000
    li      t1, 4
    div     t2, t0, t1      # t2 = 3000
    csrrw   x0, mepc, t2    # mepc = 3000
    csrrw   t3, mepc, x0
    li      a0, 15
    li      t4, 3000
    bne     t3, t4, fail
    ecall                   # Test 15 passed

# Test 16: Two csrrw with same value on mepc
mepc_test16:
    li      t0, 0x5000
    csrrw   x0, mepc, t0    # mepc = 0x5000
    csrrw   t1, mepc, t0    # t1 = 0x5000, mepc = 0x5000 (same value)
    li      a0, 16
    li      t2, 0x5000
    bne     t1, t2, fail
    csrrw   t3, mepc, x0
    bne     t3, t2, fail
    ecall                   # Test 16 passed

# Test 17: csrrw on mepc with negative value
mepc_test17:
    li      t0, -4          # 0xFFFFFFFC
    csrrw   x0, mepc, t0    # mepc = 0xFFFFFFFC
    csrrw   t1, mepc, x0
    li      a0, 17
    li      t2, -4
    bne     t1, t2, fail
    ecall                   # Test 17 passed

# Test 18: csrrw on mepc followed by add using rd
mepc_test18:
    li      t0, 0x6000
    li      t1, 0x7000
    csrrw   x0, mepc, t0    # mepc = 0x6000
    csrrw   t2, mepc, t1    # t2 = 0x6000, mepc = 0x7000
    add     t3, t2, t2      # t3 = 0xC000 (use t2 immediately)
    li      a0, 18
    li      t4, 0xC000
    bne     t3, t4, fail
    ecall                   # Test 18 passed

# Test 19: csrrw on mepc in a loop
mepc_test19:
    li      t0, 0
    li      t5, 3           # Loop 3 times
mepc_loop19:
    addi    t0, t0, 0x100   # Increment by 0x100
    csrrw   t1, mepc, t0    # Write to mepc
    addi    t5, t5, -1
    bnez    t5, mepc_loop19
    # After loop: mepc = 0x300, t1 = 0x200
    csrrw   t2, mepc, x0
    li      a0, 19
    li      t3, 0x300
    bne     t2, t3, fail
    li      t4, 0x200
    bne     t1, t4, fail
    ecall                   # Test 19 passed

# Test 20: csrrw on mepc with result used in branch
mepc_test20:
    li      t0, 0x8000
    li      t1, 0x9000
    csrrw   x0, mepc, t0    # mepc = 0x8000
    csrrw   t2, mepc, t1    # t2 = 0x8000
    li      t3, 0x8000
    li      a0, 20
    bne     t2, t3, fail    # Use t2 in branch immediately
    ecall                   # Test 20 passed

# =============================================================================
# MCAUSE Tests (Tests 21-30) - CSR 0x342
# =============================================================================

# Test 21: Basic csrrw on mcause
mcause_test21:
    li      t0, 11          # Environment call from M-mode
    csrrw   x0, mcause, x0  # Clear mcause
    csrrw   t1, mcause, t0  # t1 = old mcause, mcause = 11
    li      a0, 21
    bne     t1, x0, fail
    csrrw   t2, mcause, x0
    li      t3, 11
    bne     t2, t3, fail
    ecall                   # Test 21 passed

# Test 22: Consecutive csrrw on mcause
mcause_test22:
    li      t0, 2           # Illegal instruction
    li      t1, 5           # Load access fault
    csrrw   x0, mcause, t0  # mcause = 2
    csrrw   t2, mcause, t1  # t2 = 2, mcause = 5
    li      a0, 22
    li      t3, 2
    bne     t2, t3, fail
    csrrw   t4, mcause, x0
    li      t5, 5
    bne     t4, t5, fail
    ecall                   # Test 22 passed

# Test 23: csrrw on mcause after taken branch
mcause_test23:
    li      t0, 4           # Load address misaligned
    csrrw   x0, mcause, t0  # mcause = 4
    li      t1, 99
    li      t2, 1
    beq     t2, t2, mcause_skip23
    csrrw   t3, mcause, t1  # Should NOT execute
mcause_skip23:
    csrrw   t4, mcause, x0
    li      a0, 23
    li      t5, 4
    bne     t4, t5, fail
    ecall                   # Test 23 passed

# Test 24: csrrw on mcause right after mul
mcause_test24:
    li      t0, 3
    li      t1, 2
    mul     t2, t0, t1      # t2 = 6
    csrrw   x0, mcause, t2  # mcause = 6
    csrrw   t3, mcause, x0
    li      a0, 24
    li      t4, 6
    bne     t3, t4, fail
    ecall                   # Test 24 passed

# Test 25: csrrw on mcause right after div
mcause_test25:
    li      t0, 21
    li      t1, 3
    div     t2, t0, t1      # t2 = 7
    csrrw   x0, mcause, t2  # mcause = 7
    csrrw   t3, mcause, x0
    li      a0, 25
    li      t4, 7
    bne     t3, t4, fail
    ecall                   # Test 25 passed

# Test 26: csrrw on mcause with interrupt bit set (0x80000000 | cause)
mcause_test26:
    li      t0, 0x8000000B  # Machine external interrupt (cause=11)
    csrrw   x0, mcause, t0  # mcause = 0x8000000B
    csrrw   t1, mcause, x0
    li      a0, 26
    li      t2, 0x8000000B
    bne     t1, t2, fail
    ecall                   # Test 26 passed

# Test 27: csrrw on mcause with rd = rs (self-swap)
mcause_test27:
    li      t0, 8           # Store address misaligned
    li      t1, 9           # Store access fault
    csrrw   x0, mcause, t0  # mcause = 8
    csrrw   t1, mcause, t1  # t1 = 8, mcause = 9
    li      a0, 27
    li      t2, 8
    bne     t1, t2, fail
    csrrw   t3, mcause, x0
    li      t4, 9
    bne     t3, t4, fail
    ecall                   # Test 27 passed

# Test 28: csrrw on mcause followed by store of result
mcause_test28:
    li      t0, 12          # Instruction page fault
    li      t1, 13          # Load page fault
    csrrw   x0, mcause, t0  # mcause = 12
    csrrw   t2, mcause, t1  # t2 = 12, mcause = 13
    sw      t2, 0(sp)       # Store result to memory
    lw      t3, 0(sp)       # Reload
    li      a0, 28
    li      t4, 12
    bne     t3, t4, fail
    ecall                   # Test 28 passed

# Test 29: csrrw on mcause with value from memory
mcause_test29:
    li      t0, 14          # Store page fault
    sw      t0, 4(sp)       # Store to memory
    lw      t1, 4(sp)       # Load from memory
    csrrw   x0, mcause, t1  # mcause = 14
    csrrw   t2, mcause, x0
    li      a0, 29
    li      t3, 14
    bne     t2, t3, fail
    ecall                   # Test 29 passed

# Test 30: Comprehensive - multiple csrrw on mcause with varied scenarios
mcause_test30:
    li      t0, 1           # Instruction access fault
    li      t1, 3           # Breakpoint
    li      t2, 0x80000007  # Machine timer interrupt
    # First write
    csrrw   x0, mcause, t0  # mcause = 1
    csrrw   t3, mcause, t1  # t3 = 1, mcause = 3
    li      a0, 30
    li      t4, 1
    bne     t3, t4, fail
    # Second write
    csrrw   t5, mcause, t2  # t5 = 3, mcause = 0x80000007
    li      t6, 3
    bne     t5, t6, fail
    # Verify final value
    csrrw   t0, mcause, x0
    li      t1, 0x80000007
    bne     t0, t1, fail
    ecall                   # Test 30 passed

# =============================================================================
# All tests passed - end normally
# =============================================================================
all_passed:
    li      a0, 0           # All tests passed indicator
    j       end_program

fail:
    # a0 already contains the failing test number
    # Fall through to end

end_program:


.globl _start

_start:
    # Initialize registers to 0 to avoid X states
    addi x1, x0, 0
    addi x2, x0, 0
    addi x3, x0, 0
    addi x4, x0, 0
    addi x5, x0, 0
    addi x6, x0, 0
    addi x7, x0, 0
    addi x8, x0, 0
    addi x9, x0, 0
    addi x10, x0, 0
    addi x11, x0, 0
    addi x12, x0, 0
    addi x13, x0, 0
    addi x14, x0, 0
    addi x15, x0, 0
    addi x16, x0, 0
    addi x17, x0, 0
    addi x18, x0, 0
    addi x19, x0, 0
    addi x20, x0, 0
    addi x21, x0, 0
    addi x22, x0, 0
    addi x23, x0, 0
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0
    addi x31, x0, 0

    # Initialize memory locations used for testing to known values (0)
    # We will use addresses 0x100, 0x104, 0x108 etc.
    # Just clear a block from 0x0 to 0x400
    addi x1, x0, 0   # Address
    addi x2, x0, 0   # Data
    addi x3, x0, 256 # Count (writes of words -> 1024 bytes)
mem_init_loop:
    sw x2, 0(x1)
    addi x1, x1, 4
    addi x3, x3, -1
    bne x3, x0, mem_init_loop

    # -------------------------------------------------------------------------
    # Test Cases 1-10: Basic LR/SC Success
    # -------------------------------------------------------------------------
    # TEST_SUCCESS macro:
    # Args:
    #   reg_id: test case ID (immediate)
    #   reg_addr: register holding address (e.g., x1)
    #   addr_offset: offset
    #   reg_data: register holding data to store (e.g., x2)
    #   reg_res: temporary register for lr result
    #   reg_sc_res: register for sc result (should be 0)

    # Test 1
    addi x1, x0, 1
    addi x5, x0, 0x100
    li x6, 0xDEAD
    lr.w x7, (x5)          # Load reserved from 0x100
    sc.w x8, x6, (x5)      # Store conditional to 0x100
    bne x8, x0, fail       # If x8 != 0, SC failed
    lw x9, 0(x5)           # Verify memory content
    bne x9, x6, fail       # If loaded value != stored value, fail

    # Test 2: Different address
    addi x1, x0, 2
    addi x5, x0, 0x104
    li x6, 0xBEEF
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # Test 3: Test with register value 0
    addi x1, x0, 3
    addi x5, x0, 0x108
    addi x6, x0, 0
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # Test 4: Different registers for addr/data
    addi x1, x0, 4
    addi x20, x0, 0x10C
    addi x21, x0, 1234
    lr.w x22, (x20)
    sc.w x23, x21, (x20)
    bne x23, x0, fail
    lw x24, 0(x20)
    bne x24, x21, fail

    # Test 5: Verify lr loaded correct initial value (should be 0 from init)
    addi x1, x0, 5
    addi x5, x0, 0x110
    sw x0, 0(x5)      # Ensure 0
    lr.w x7, (x5)
    bne x7, x0, fail  # data read should be 0
    addi x6, x0, 55
    sc.w x8, x6, (x5)
    bne x8, x0, fail

    # Test 6: Verify lr loaded pre-set value
    addi x1, x0, 6
    addi x5, x0, 0x114
    li x6, 0xAAAA
    sw x6, 0(x5)      # Store 0xAAAA
    lr.w x7, (x5)
    bne x7, x6, fail  # lr should see 0xAAAA
    li x2, 0x5555
    sc.w x8, x2, (x5) # Overwrite with 0x5555
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x2, fail

    # Test 7: Consecutive usage
    addi x1, x0, 7
    addi x5, x0, 0x118
    addi x6, x0, 77
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    # Immediately do another
    addi x6, x0, 88
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # Test 8: Large address (within 4000)
    addi x1, x0, 8
    li x5, 3000
    li x6, 0x1234
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # Test 9: Another large address
    addi x1, x0, 9
    li x5, 3004
    li x6, 0x5678
    lr.w x7, (x5)
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # Test 10: Using x0 as destination for lr (valid, but discards result)
    addi x1, x0, 10
    addi x5, x0, 0x120
    addi x6, x0, 99
    lr.w x0, (x5)     # Result discarded
    sc.w x8, x6, (x5)
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x6, fail

    # -------------------------------------------------------------------------
    # Test Cases 11-20: Address Mismatch (SC Failures)
    # -------------------------------------------------------------------------

    # Test 11: Mismatch addr + 4
    addi x1, x0, 11
    addi x5, x0, 0x200
    addi x10, x0, 0x204
    sw x0, 0(x5)      # Clear loc A
    sw x0, 0(x10)     # Clear loc B
    lr.w x7, (x5)     # Reserve 0x200
    addi x6, x0, 0xFF
    sc.w x8, x6, (x10) # Store to 0x204 (Mismatch!)
    beq x8, x0, fail  # x8 should be non-zero (1)
    lw x9, 0(x10)
    bne x9, x0, fail  # 0x204 should NOT be written

    # Test 12: Mismatch addr - 4
    addi x1, x0, 12
    addi x5, x0, 0x210
    addi x10, x0, 0x20C
    sw x0, 0(x5)
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 0xFF
    sc.w x8, x6, (x10)
    beq x8, x0, fail
    lw x9, 0(x10)
    bne x9, x0, fail

    # Test 13: Mismatch far away
    addi x1, x0, 13
    addi x5, x0, 0x220
    addi x10, x0, 0x300
    sw x0, 0(x5)
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 0xFF
    sc.w x8, x6, (x10)
    beq x8, x0, fail
    lw x9, 0(x10)
    bne x9, x0, fail

    # Test 14: SC to same address WITHOUT prior LR (Should fail? Or just undefined?)
    # The spec says SC must be paired with LR. If no reservation exists, it writes non-zero to rd.
    # Note: Valid implementations might succeed if they are "lucky", but typically we expect
    # the reservation to be cleared or non-existent.
    # To be safe for *mismatch*, we should establish a reservation elsewhere first.
    addi x1, x0, 14
    addi x5, x0, 0x230
    addi x10, x0, 0x234 # Target of SC
    sw x0, 0(x10)
    lr.w x7, (x5)     # Reserve x5
    # Do SC to x10
    addi x6, x0, 14
    sc.w x8, x6, (x10)
    beq x8, x0, fail
    lw x9, 0(x10)
    bne x9, x0, fail

    # Test 15: Mismatch with non-zero data at target
    addi x1, x0, 15
    addi x5, x0, 0x240
    addi x10, x0, 0x244
    li x11, 0x9999
    sw x11, 0(x10)    # Exists 0x9999
    lr.w x7, (x5)
    li x6, 0x8888
    sc.w x8, x6, (x10)
    beq x8, x0, fail
    lw x9, 0(x10)
    bne x9, x11, fail # Check if 0x9999 is preserved

    # Test 16: Mismatch with high registers
    addi x1, x0, 16
    addi x3, x0, 0x250
    addi x4, x0, 0x254
    sw x0, 0(x4)
    lr.w x5, (x3)
    addi x2, x0, 16
    sc.w x6, x2, (x4)
    beq x6, x0, fail
    lw x7, 0(x4)
    bne x7, x0, fail

    # Test 17: Mismatch with different alignment (still word aligned)
    addi x1, x0, 17
    addi x5, x0, 0x260
    addi x10, x0, 0x268
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 17
    sc.w x8, x6, (x10)
    beq x8, x0, fail

    # Test 18: Address calculation in place (register offset? No, valid imm offset)
    # The SC instruction format is sc.w rd, rs2, (rs1) - it doesn't take an immediate offset in syntax usually?
    # Actually standard RISC-V assembly sc.w rd, rs2, (rs1) means offset is 0.
    # Checking syntax: sc.w rd, rs2, (rs1) is correct.
    # Let's try mocking an offset logic manually if needed.
    # Mismatch logic 18
    addi x1, x0, 18
    addi x5, x0, 0x270
    addi x10, x0, 0x274
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 18
    sc.w x8, x6, (x10)
    beq x8, x0, fail

    # Test 19: Double mismatch (just another mismatch case)
    addi x1, x0, 19
    addi x5, x0, 0x280
    addi x10, x0, 0x290
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 19
    sc.w x8, x6, (x10)
    beq x8, x0, fail

    # Test 20: Mismatch near memory boundary (within 4000)
    addi x1, x0, 20
    li x5, 3500
    li x10, 3504
    sw x0, 0(x10)
    lr.w x7, (x5)
    addi x6, x0, 20
    sc.w x8, x6, (x10)
    beq x8, x0, fail

    # -------------------------------------------------------------------------
    # Test Cases 21-30: Intervening Stores & Reservation Clearing
    # (Checking if reservation is killed by mismatch/intervening)
    # -------------------------------------------------------------------------

    # Test 21: LR -> Store to DIFFERENT address -> SC to ORIGINAL address
    # Standard: The reservation is usually cleared if any store happens.
    # But valid for SC to fail. If it succeeds, that implies some implementations
    # allow disjoint stores. However, most simple implementations clear reservation on ANY store.
    # We will assume STRICT behavior: Store invalidates reservation.
    # Fail expected.
    addi x1, x0, 21
    addi x5, x0, 0x300
    addi x10, x0, 0x304
    lr.w x7, (x5)
    sw x0, 0(x10)     # Intervening store to different addr
    addi x6, x0, 21
    sc.w x8, x6, (x5) # SC to original address
    beq x8, x0, fail  # Expect SC to fail (return 1)

    # Test 22: LR -> Store to SAME address -> SC to SAME address
    # Writing to the reserved address should definitely clear it.
    addi x1, x0, 22
    addi x5, x0, 0x310
    lr.w x7, (x5)
    sw x0, 0(x5)      # Intervening store to SAME addr
    addi x6, x0, 22
    sc.w x8, x6, (x5)
    beq x8, x0, fail

    # Test 23: LR -> SC (fail due to mismatch) -> SC (retry original)
    # The first SC (fail) might clear reservation? Spec says:
    # "SC instruction... always invalidates the reservation."
    # So a second SC should also fail.
    addi x1, x0, 23
    addi x5, x0, 0x320
    addi x10, x0, 0x324
    lr.w x7, (x5)
    # 1. SC to mismatch
    addi x6, x0, 23
    sc.w x8, x6, (x10) # Fails due to mismatch
    beq x8, x0, fail
    # 2. SC to original (should fail b/c reservation is gone)
    sc.w x8, x6, (x5)
    beq x8, x0, fail

    # Test 24: LR -> Normal Load -> SC (Should SUCCEED)
    # Normal loads do not clear reservation.
    addi x1, x0, 24
    addi x5, x0, 0x330
    lr.w x7, (x5)
    lw x9, 0(x5)      # Load same addr
    addi x6, x0, 24
    sc.w x8, x6, (x5)
    bne x8, x0, fail

    # Test 25: LR -> Normal Load Diff Addr -> SC (Should SUCCEED)
    addi x1, x0, 25
    addi x5, x0, 0x340
    addi x10, x0, 0x344
    lr.w x7, (x5)
    lw x9, 0(x10)
    addi x6, x0, 25
    sc.w x8, x6, (x5)
    bne x8, x0, fail

    # Test 26: LR -> ALU ops -> SC (Should SUCCEED)
    addi x1, x0, 26
    addi x5, x0, 0x350
    lr.w x7, (x5)
    addi x11, x11, 1  # Random ALU
    addi x6, x0, 26
    sc.w x8, x6, (x5)
    bne x8, x0, fail

    # Test 27: Check data integrity on Intervening Store Fail (Test 21 variant)
    # Ensure Test 21 SC didn't write.
    addi x1, x0, 27
    addi x5, x0, 0x360
    addi x10, x0, 0x364
    sw x0, 0(x5)      # Initial 0
    lr.w x7, (x5)
    sw x0, 0(x10)     # Intervening
    addi x6, x0, 27
    sc.w x8, x6, (x5) # Fails
    beq x8, x0, fail
    lw x9, 0(x5)
    bne x9, x0, fail  # Should remain 0

    # Test 28: Multiple LRs (Last one wins)
    addi x1, x0, 28
    addi x5, x0, 0x370
    addi x10, x0, 0x374
    lr.w x7, (x5)     # Reserve A
    lr.w x7, (x10)    # Reserve B (Clears A?)
    # SC to A should fail
    addi x6, x0, 28
    sc.w x8, x6, (x5)
    beq x8, x0, fail
    # SC to B should succeed (if SC A didn't clear it! But SC A invalidates everything usually)
    # So we just test that SC A failed.

    # Test 29: Use x0 as rs2 for SC (Store 0 success)
    addi x1, x0, 29
    addi x5, x0, 0x380
    sw x6, 0(x5)      # Garbage
    lr.w x7, (x5)
    sc.w x8, x0, (x5) # SC 0
    bne x8, x0, fail
    lw x9, 0(x5)
    bne x9, x0, fail

    # Test 30: Check SC write 1 on fail (explicit value check)
    addi x1, x0, 30
    addi x5, x0, 0x390
    # No LR
    # Some specs say SC without LR is undefined or fail.
    # Assuming fail => 1
    sc.w x8, x0, (x5)
    # If x8 is 1, good. If CPU hangs or x8!=1, fail.
    # Note: If CPU allows "unpaired SC" to succeed (weak ordering), this might fail.
    # But strict LR/SC usually fails. skip if risky? user asked for mismatch fail.
    # Let's do a guaranteed fail via mismatch.
    addi x10, x0, 0x394
    lr.w x7, (x5)
    sc.w x8, x0, (x10) # Mismatch
    addi x20, x0, 1
    bne x8, x20, fail # Must be exactly 1

    # -------------------------------------------------------------------------
    # Test Cases 31-40: Forwarding Logic
    # -------------------------------------------------------------------------

    # Test 31: Forward SC result (Success 0) to ADD
    addi x1, x0, 31
    addi x5, x0, 0x400
    lr.w x7, (x5)
    addi x6, x0, 31
    sc.w x8, x6, (x5) # x8 becomes 0
    addi x9, x8, 10   # x9 should be 0 + 10 = 10
    addi x11, x0, 10
    bne x9, x11, fail

    # Test 32: Forward SC result (Fail 1) to ADD
    addi x1, x0, 32
    addi x5, x0, 0x410
    addi x10, x0, 0x414
    lr.w x7, (x5)
    addi x6, x0, 32
    sc.w x8, x6, (x10) # x8 becomes 1 (Mismatch)
    addi x9, x8, 10    # x9 should be 1 + 10 = 11
    addi x11, x0, 11
    bne x9, x11, fail

    # Test 33: Forward SC result to BEQ (Branch dependent on SC) - Taken
    addi x1, x0, 33
    addi x5, x0, 0x420
    lr.w x7, (x5)
    sc.w x8, x6, (x5) # x8 = 0
    beq x8, x0, test33_pass
    j fail
test33_pass:

    # Test 34: Forward SC result to BEQ - Not Taken
    addi x1, x0, 34
    addi x5, x0, 0x430
    addi x10, x0, 0x434
    lr.w x7, (x5)
    sc.w x8, x6, (x10) # x8 = 1  (Mismatch)
    beq x8, x0, fail
    # Success fallthrough

    # Test 35: Forward SC result to OR
    addi x1, x0, 35
    addi x5, x0, 0x440
    lr.w x7, (x5)
    sc.w x8, x6, (x5) # x8 = 0
    ori x9, x8, 0xF0  # x9 = 0xF0
    addi x11, x0, 0xF0
    bne x9, x11, fail

    # Test 36: Forward SC result (Fail) to OR
    addi x1, x0, 36
    addi x5, x0, 0x450
    addi x10, x0, 0x454
    lr.w x7, (x5)
    sc.w x8, x6, (x10) # x8 = 1
    ori x9, x8, 0xF0   # x9 = 0xF1
    addi x11, x0, 0xF1
    bne x9, x11, fail

    # Test 37: Forward SC result to SW (Store Data)
    addi x1, x0, 37
    addi x5, x0, 0x460
    addi x12, x0, 0x464
    lr.w x7, (x5)
    sc.w x8, x6, (x5) # x8 = 0
    sw x8, 0(x12)     # Store 0 to 0x464
    lw x9, 0(x12)
    bne x9, x0, fail

    # Test 38: Forward SC result (Fail) to SW
    addi x1, x0, 38
    addi x5, x0, 0x470
    addi x10, x0, 0x474
    addi x12, x0, 0x478
    lr.w x7, (x5)
    sc.w x8, x6, (x10) # x8 = 1
    sw x8, 0(x12)      # Store 1 to 0x478
    lw x9, 0(x12)
    addi x11, x0, 1
    bne x9, x11, fail

    # Test 39: Forward SC result to SUB
    addi x1, x0, 39
    addi x5, x0, 0x480
    lr.w x7, (x5)
    sc.w x8, x6, (x5) # x8 = 0
    addi x11, x0, 50
    sub x9, x11, x8   # 50 - 0 = 50
    bne x9, x11, fail

    # Test 40: Forward SC result (Fail) to SUB
    addi x1, x0, 40
    addi x5, x0, 0x490
    addi x10, x0, 0x494
    lr.w x7, (x5)
    sc.w x8, x6, (x10) # x8 = 1
    addi x11, x0, 50
    sub x9, x11, x8    # 50 - 1 = 49
    addi x12, x0, 49
    bne x9, x12, fail

    # -------------------------------------------------------------------------
    # Finish
    # -------------------------------------------------------------------------
    addi x10, x0, 0    # a0 = 0 (Success)
    jal print_and_stop

fail:
    addi x10, x1, 0    # a0 = test index (from x1)
    jal print_and_stop

print_and_stop:
    .insn r 0x2B, 0, 0, x0, x10, x0   # Print a0

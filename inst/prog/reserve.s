# RV32IMA LR.W and SC.W Instruction Test
# Tests lr.w and sc.w with 50 test cases
# Includes: basic pairs, forwarding tests, mismatched addresses, reservation invalidation, ecall invalidation
# If test i fails, a0 = i. If all pass, a0 = 0.
# All memory addresses < 4000

.text
.globl _start

_start:
    # Initialize base addresses for memory operations
    li s0, 0           # Base address 0
    li s1, 256         # Base address 256
    li s2, 512         # Base address 512
    li s3, 1024        # Base address 1024
    li s4, 2048        # Base address 2048

    # Initialize some memory locations with known values
    li t0, 100
    sw t0, 0(s0)       # mem[0] = 100
    li t0, 200
    sw t0, 4(s0)       # mem[4] = 200
    li t0, 300
    sw t0, 0(s1)       # mem[256] = 300
    li t0, 400
    sw t0, 0(s2)       # mem[512] = 400
    li t0, 500
    sw t0, 0(s3)       # mem[1024] = 500
    li t0, 600
    sw t0, 0(s4)       # mem[2048] = 600

    # ============================================
    # Basic LR.W/SC.W Tests - Tests 1-10
    # ============================================

    # Test 1: Basic lr.w/sc.w pair - should succeed (sc.w returns 0)
    lr.w t0, (s0)           # t0 = mem[0] = 100, reserve address 0
    li t1, 111
    sc.w t2, t1, (s0)       # try store 111 to mem[0], t2 = 0 on success
    li a0, 1
    bne t2, zero, fail      # sc.w should succeed (return 0)
    lw t3, 0(s0)            # verify mem[0] = 111
    li t4, 111
    bne t3, t4, fail

    # Test 2: Verify lr.w loads correct value
    li t0, 222
    sw t0, 0(s1)            # mem[256] = 222
    lr.w t1, (s1)           # t1 should be 222
    li a0, 2
    li t2, 222
    bne t1, t2, fail

    # Test 3: sc.w after lr.w to same address with different value
    lr.w t0, (s0)           # t0 = mem[0] = 111, reserve address 0
    li t1, 333
    sc.w t2, t1, (s0)       # store 333 to mem[0]
    li a0, 3
    bne t2, zero, fail      # should succeed
    lw t3, 0(s0)
    li t4, 333
    bne t3, t4, fail

    # Test 4: Multiple lr.w - only last reservation should be active
    lr.w t0, (s0)           # reserve address 0
    lr.w t1, (s1)           # reserve address 256 (invalidates reservation at 0)
    li t2, 444
    sc.w t3, t2, (s1)       # should succeed on address 256
    li a0, 4
    bne t3, zero, fail
    lw t4, 0(s1)
    li t5, 444
    bne t4, t5, fail

    # Test 5: lr.w returns correct value for negative number
    li t0, -1               # 0xFFFFFFFF
    sw t0, 0(s2)            # mem[512] = -1
    lr.w t1, (s2)           # t1 should be -1
    li a0, 5
    li t2, -1
    bne t1, t2, fail

    # Test 6: sc.w stores negative number correctly
    lr.w t0, (s2)           # reserve address 512
    li t1, -12345
    sc.w t2, t1, (s2)       # store -12345
    li a0, 6
    bne t2, zero, fail
    lw t3, 0(s2)
    li t4, -12345
    bne t3, t4, fail

    # Test 7: lr.w/sc.w with zero value
    lr.w t0, (s3)           # reserve address 1024
    li t1, 0
    sc.w t2, t1, (s3)       # store 0
    li a0, 7
    bne t2, zero, fail
    lw t3, 0(s3)
    bne t3, zero, fail

    # Test 8: lr.w/sc.w with maximum positive value
    lr.w t0, (s4)           # reserve address 2048
    li t1, 0x7FFFFFFF
    sc.w t2, t1, (s4)       # store max positive
    li a0, 8
    bne t2, zero, fail
    lw t3, 0(s4)
    li t4, 0x7FFFFFFF
    bne t3, t4, fail

    # Test 9: lr.w/sc.w with minimum negative value
    lr.w t0, (s0)           # reserve address 0
    li t1, 0x80000000
    sc.w t2, t1, (s0)       # store min negative
    li a0, 9
    bne t2, zero, fail
    lw t3, 0(s0)
    li t4, 0x80000000
    bne t3, t4, fail

    # Test 10: lr.w immediately followed by sc.w (no intervening instructions)
    li t0, 1010
    sw t0, 0(s1)            # mem[256] = 1010
    lr.w t1, (s1)
    sc.w t2, t0, (s1)       # use t0 which is 1010
    li a0, 10
    bne t2, zero, fail

    # ============================================
    # SC.W to Mismatched Address Tests - Tests 11-18
    # sc.w should fail (return 1) and NOT write to memory
    # ============================================

    # Test 11: sc.w to different address than lr.w - should fail
    li t0, 1100
    sw t0, 4(s0)            # mem[4] = 1100
    addi s5, s0, 4          # s5 = address 4
    lr.w t1, (s0)           # reserve address 0
    li t2, 9999
    sc.w t3, t2, (s5)       # try to store to address 4 (not reserved)
    li a0, 11
    li t4, 1
    bne t3, t4, fail        # sc.w should fail (return 1)
    lw t5, 4(s0)            # mem[4] should still be 1100
    li t6, 1100
    bne t5, t6, fail

    # Test 12: sc.w to completely different base address
    lr.w t0, (s0)           # reserve address 0
    li t1, 8888
    sc.w t2, t1, (s1)       # try to store to address 256
    li a0, 12
    li t3, 1
    bne t2, t3, fail        # should fail
    
    # Test 13: sc.w to address 512 when address 256 is reserved
    lr.w t0, (s1)           # reserve address 256
    li t1, 7777
    sc.w t2, t1, (s2)       # try to store to address 512
    li a0, 13
    li t3, 1
    bne t2, t3, fail

    # Test 14: sc.w to address 1024 when address 512 is reserved
    lr.w t0, (s2)           # reserve address 512
    li t1, 6666
    sc.w t2, t1, (s3)       # try to store to address 1024
    li a0, 14
    li t3, 1
    bne t2, t3, fail

    # Test 15: Verify memory unchanged after failed sc.w
    li t0, 1500
    sw t0, 0(s3)            # mem[1024] = 1500
    lr.w t1, (s0)           # reserve address 0
    li t2, 5555
    sc.w t3, t2, (s3)       # try to store to 1024 (should fail)
    li a0, 15
    li t4, 1
    bne t3, t4, fail        # verify sc.w returned 1
    lw t5, 0(s3)            # verify memory unchanged
    li t6, 1500
    bne t5, t6, fail

    # Test 16: Multiple failed sc.w attempts
    li t0, 1600
    sw t0, 0(s4)            # mem[2048] = 1600
    lr.w t1, (s0)           # reserve address 0
    li t2, 4444
    sc.w t3, t2, (s4)       # fail 1
    li a0, 16
    li t4, 1
    bne t3, t4, fail
    sc.w t3, t2, (s3)       # fail 2
    bne t3, t4, fail
    sc.w t3, t2, (s2)       # fail 3
    bne t3, t4, fail
    lw t5, 0(s4)            # verify all memories unchanged
    li t6, 1600
    bne t5, t6, fail

    # Test 17: sc.w without any prior lr.w should fail
    # (Reservation may be cleared, so sc.w should fail)
    li t0, 1700
    sw t0, 0(s1)            # mem[256] = 1700
    li t1, 3333
    # Clear any prior reservation by doing lr.w then another sc.w
    lr.w t2, (s0)
    sc.w t3, t1, (s0)       # consume the reservation
    # Now try sc.w without lr.w
    sc.w t4, t1, (s1)       # should fail (no reservation)
    li a0, 17
    li t5, 1
    bne t4, t5, fail
    lw t6, 0(s1)            # memory should be unchanged
    li t2, 1700
    bne t6, t2, fail

    # Test 18: sc.w to offset address when base is reserved
    li t0, 1800
    sw t0, 8(s0)            # mem[8] = 1800
    addi s5, s0, 8          # s5 = address 8
    lr.w t1, (s0)           # reserve address 0
    li t2, 2222
    sc.w t3, t2, (s5)       # try to store to address 8
    li a0, 18
    li t4, 1
    bne t3, t4, fail
    lw t5, 8(s0)            # verify memory unchanged
    li t6, 1800
    bne t5, t6, fail

    # ============================================
    # SC.W Result Forwarding Tests - Tests 19-28
    # Test if the result of sc.w is correctly forwarded
    # ============================================

    # Test 19: Use sc.w result immediately in next instruction (add)
    lr.w t0, (s0)           # reserve address 0
    li t1, 1900
    sc.w t2, t1, (s0)       # t2 = 0 on success
    add t3, t2, t2          # t3 = t2 + t2 = 0 (forwarding test)
    li a0, 19
    bne t3, zero, fail

    # Test 20: Use sc.w result in branch immediately after
    lr.w t0, (s1)           # reserve address 256
    li t1, 2000
    sc.w t2, t1, (s1)       # t2 = 0 on success
    li a0, 20
    bne t2, zero, fail      # branch using forwarded result

    # Test 21: Use failed sc.w result (should be 1) in arithmetic
    lr.w t0, (s0)           # reserve address 0
    li t1, 2100
    sc.w t2, t1, (s1)       # t2 = 1 on failure (wrong address)
    add t3, t2, t2          # t3 = 1 + 1 = 2 (forwarding test)
    li a0, 21
    li t4, 2
    bne t3, t4, fail

    # Test 22: Chain of operations using sc.w result
    lr.w t0, (s2)           # reserve address 512
    li t1, 2200
    sc.w t2, t1, (s2)       # t2 = 0 on success
    addi t3, t2, 5          # t3 = 0 + 5 = 5
    addi t4, t3, 10         # t4 = 5 + 10 = 15
    li a0, 22
    li t5, 15
    bne t4, t5, fail

    # Test 23: Use sc.w result in store instruction
    li t0, 2300
    sw t0, 0(s3)            # mem[1024] = 2300
    lr.w t1, (s3)
    li t2, 2301
    sc.w t3, t2, (s3)       # t3 = 0 on success
    sw t3, 0(s4)            # store 0 to mem[2048]
    li a0, 23
    lw t4, 0(s4)
    bne t4, zero, fail

    # Test 24: Use failed sc.w result in store instruction
    li t0, 2400
    sw t0, 0(s4)            # mem[2048] = 2400
    lr.w t1, (s0)           # reserve address 0
    li t2, 2401
    sc.w t3, t2, (s3)       # t3 = 1 on failure (wrong address)
    sw t3, 0(s4)            # store 1 to mem[2048]
    li a0, 24
    lw t4, 0(s4)
    li t5, 1
    bne t4, t5, fail

    # Test 25: Use sc.w result in sll (shift left)
    lr.w t0, (s0)           # reserve address 0
    li t1, 2500
    sc.w t2, t1, (s0)       # t2 = 0 on success
    li t3, 100
    sll t4, t3, t2          # t4 = 100 << 0 = 100
    li a0, 25
    li t5, 100
    bne t4, t5, fail

    # Test 26: Use failed sc.w result in sll
    lr.w t0, (s0)           # reserve address 0
    li t1, 2600
    sc.w t2, t1, (s1)       # t2 = 1 on failure
    li t3, 100
    sll t4, t3, t2          # t4 = 100 << 1 = 200
    li a0, 26
    li t5, 200
    bne t4, t5, fail

    # Test 27: Use sc.w result to index into memory
    lr.w t0, (s0)           # reserve address 0
    li t1, 2700
    sc.w t2, t1, (s0)       # t2 = 0 on success
    slli t3, t2, 2          # t3 = 0 * 4 = 0
    add t4, s0, t3          # t4 = s0 + 0 = s0
    lw t5, 0(t4)            # load from mem[0]
    li a0, 27
    li t6, 2700
    bne t5, t6, fail

    # Test 28: Back-to-back sc.w with forwarding
    lr.w t0, (s2)           # reserve address 512
    li t1, 2801
    sc.w t2, t1, (s2)       # t2 = 0, first sc.w succeeds
    addi t3, t2, 1          # t3 = 0 + 1 = 1 (forwarding from first sc.w)
    # Now t2 should be 0, do another lr.w/sc.w
    lr.w t4, (s2)
    li t5, 2802
    sc.w t6, t5, (s2)       # t6 = 0, second sc.w succeeds
    add t0, t3, t6          # t0 = 1 + 0 = 1
    li a0, 28
    li t1, 1
    bne t0, t1, fail

    # ============================================
    # Reservation Invalidation Tests - Tests 29-35
    # ============================================

    # Test 29: Second lr.w invalidates first reservation
    li t0, 2900
    sw t0, 0(s0)            # mem[0] = 2900
    li t0, 2901
    sw t0, 0(s1)            # mem[256] = 2901
    lr.w t1, (s0)           # reserve address 0
    lr.w t2, (s1)           # reserve address 256, invalidate reservation at 0
    li t3, 9999
    sc.w t4, t3, (s0)       # should fail (reservation was at 256, not 0)
    li a0, 29
    li t5, 1
    bne t4, t5, fail
    lw t6, 0(s0)            # memory should be unchanged
    li t0, 2900
    bne t6, t0, fail

    # Test 30: Successful sc.w clears reservation
    lr.w t0, (s0)           # reserve address 0
    li t1, 3000
    sc.w t2, t1, (s0)       # succeeds, clears reservation
    li t3, 3001
    sc.w t4, t3, (s0)       # should fail (no reservation)
    li a0, 30
    li t5, 1
    bne t4, t5, fail
    lw t6, 0(s0)            # memory should be 3000 (from first sc.w)
    li t0, 3000
    bne t6, t0, fail

    # Test 31: Failed sc.w also clears reservation (implementation dependent, but common)
    lr.w t0, (s0)           # reserve address 0
    li t1, 3100
    sc.w t2, t1, (s1)       # fails (wrong address), may clear reservation
    li t3, 3101
    sc.w t4, t3, (s0)       # should fail (reservation cleared by previous failed sc.w)
    li a0, 31
    li t5, 1
    bne t4, t5, fail

    # Test 32: sw between lr.w and sc.w to same address invalidates reservation
    li t0, 3200
    sw t0, 0(s2)            # mem[512] = 3200
    lr.w t1, (s2)           # reserve address 512
    li t2, 3201
    sw t2, 0(s2)            # store to same address (invalidates reservation)
    li t3, 3202
    sc.w t4, t3, (s2)       # should fail
    li a0, 32
    li t5, 1
    bne t4, t5, fail
    lw t6, 0(s2)            # memory should be 3201 (from sw)
    li t0, 3201
    bne t6, t0, fail

    # Test 33: sw between lr.w and sc.w to different address - reservation may persist
    # (This depends on implementation; some clear on any store, others only on reservation address)
    li t0, 3300
    sw t0, 0(s0)            # mem[0] = 3300
    li t0, 3301
    sw t0, 0(s1)            # mem[256] = 3301
    lr.w t1, (s0)           # reserve address 0
    li t2, 3302
    sw t2, 0(s1)            # store to different address (256)
    li t3, 3303
    sc.w t4, t3, (s0)       # may succeed or fail depending on implementation
    li a0, 33
    # For this test, we just verify the result is valid (0 or 1)
    li t5, 1
    blt t5, t4, fail        # fail if t4 > 1

    # Test 34: Verify value after conditional sc.w in test 33
    li a0, 34
    lw t5, 0(s0)
    beq t4, zero, test34_success  # if sc.w succeeded, mem should be 3303
    li t6, 3300
    bne t5, t6, fail        # if sc.w failed, mem should be 3300
    j test35
test34_success:
    li t6, 3303
    bne t5, t6, fail

test35:
    # Test 35: Multiple consecutive lr.w, only last one active
    li t0, 3500
    sw t0, 0(s0)
    li t0, 3501
    sw t0, 0(s1)
    li t0, 3502
    sw t0, 0(s2)
    lr.w t1, (s0)           # reserve 0
    lr.w t2, (s1)           # reserve 256, invalidate 0
    lr.w t3, (s2)           # reserve 512, invalidate 256
    li t4, 9999
    sc.w t5, t4, (s2)       # should succeed (512 is reserved)
    li a0, 35
    bne t5, zero, fail
    lw t6, 0(s2)
    li t0, 9999
    bne t6, t0, fail

    # ============================================
    # Edge Case and Stress Tests - Tests 36-40
    # ============================================

    # Test 36: lr.w and sc.w with same source and destination register
    li t0, 3600
    sw t0, 0(s3)            # mem[1024] = 3600
    lr.w t0, (s3)           # t0 = 3600, reserve 1024
    li t1, 3601
    sc.w t0, t1, (s3)       # t0 = 0 on success (overwrite t0 with result)
    li a0, 36
    bne t0, zero, fail
    lw t2, 0(s3)
    li t3, 3601
    bne t2, t3, fail

    # Test 37: sc.w where rd == rs2 (store value is also destination)
    li t0, 3700
    sw t0, 0(s4)            # mem[2048] = 3700
    lr.w t1, (s4)           # reserve 2048
    li t0, 3701
    sc.w t0, t0, (s4)       # t0 = result of sc.w (should be 0, overwriting 3701)
    li a0, 37
    bne t0, zero, fail
    lw t1, 0(s4)            # verify 3701 was stored before t0 was overwritten
    li t2, 3701
    bne t1, t2, fail

    # Test 38: Long sequence of operations between lr.w and sc.w
    li t0, 3800
    sw t0, 0(s0)            # mem[0] = 3800
    lr.w t0, (s0)           # reserve 0, t0 = 3800
    # Several operations that don't touch memory
    addi t1, t0, 1          # t1 = 3801
    addi t2, t1, 1          # t2 = 3802
    addi t3, t2, 1          # t3 = 3803
    xor t4, t1, t2
    and t5, t2, t3
    or t6, t4, t5
    sll t1, t0, zero
    srl t2, t0, zero
    # Now do sc.w
    li t0, 3899
    sc.w t1, t0, (s0)       # should succeed
    li a0, 38
    bne t1, zero, fail
    lw t2, 0(s0)
    li t3, 3899
    bne t2, t3, fail

    # Test 39: Verify sc.w writes exactly 1 on failure, not just non-zero
    lr.w t0, (s0)           # reserve 0
    li t1, 3999
    sc.w t2, t1, (s1)       # fail (wrong address)
    li a0, 39
    li t3, 1
    bne t2, t3, fail        # must be exactly 1

    # Test 40: Final comprehensive test - success and failure in sequence
    # This tests the full cycle: init, reserve, succeed, fail, verify
    li t0, 4000
    sw t0, 0(s2)            # mem[512] = 4000
    li t0, 4001
    sw t0, 0(s3)            # mem[1024] = 4001
    
    # First: successful lr.w/sc.w
    lr.w t0, (s2)           # reserve 512, t0 = 4000
    li t1, 4002
    sc.w t2, t1, (s2)       # success, t2 = 0
    li a0, 40
    bne t2, zero, fail
    
    # Second: failed sc.w (reservation cleared)
    li t3, 4003
    sc.w t4, t3, (s2)       # fail, t4 = 1
    li t5, 1
    bne t4, t5, fail
    
    # Verify memory states
    lw t6, 0(s2)
    li t0, 4002             # should be from first successful sc.w
    bne t6, t0, fail
    lw t6, 0(s3)
    li t0, 4001             # should be unchanged
    bne t6, t0, fail

    # ============================================
    # ECALL Reservation Invalidation Tests - Tests 41-50
    # ecall should invalidate the lr.w reservation
    # ============================================

    # Reinitialize base addresses (may have been modified)
    li s0, 0           # Base address 0
    li s1, 256         # Base address 256
    li s2, 512         # Base address 512
    li s3, 1024        # Base address 1024
    li s4, 2048        # Base address 2048

    # Test 41: Basic ecall between lr.w and sc.w - sc.w should fail
    li t0, 4100
    sw t0, 0(s0)            # mem[0] = 4100
    lr.w t1, (s0)           # reserve address 0, t1 = 4100
    li a0, 41
    ecall                   # prints 41, should invalidate reservation
    li t2, 4101
    sc.w t3, t2, (s0)       # should fail (reservation invalidated by ecall)
    li a0, 41
    li t4, 1
    bne t3, t4, fail        # sc.w must return 1 (failure)
    lw t5, 0(s0)            # verify memory unchanged
    li t6, 4100
    bne t5, t6, fail

    # Test 42: ecall invalidates reservation at different address (256)
    li t0, 4200
    sw t0, 0(s1)            # mem[256] = 4200
    lr.w t1, (s1)           # reserve address 256
    li a0, 42
    ecall                   # prints 42, invalidate reservation
    li t2, 4201
    sc.w t3, t2, (s1)       # should fail
    li a0, 42
    li t4, 1
    bne t3, t4, fail
    lw t5, 0(s1)
    li t6, 4200
    bne t5, t6, fail

    # Test 43: ecall invalidates reservation at address 512
    li t0, 4300
    sw t0, 0(s2)            # mem[512] = 4300
    lr.w t1, (s2)           # reserve address 512
    li a0, 43
    ecall                   # prints 43, invalidate reservation
    li t2, 4301
    sc.w t3, t2, (s2)       # should fail
    li a0, 43
    li t4, 1
    bne t3, t4, fail
    lw t5, 0(s2)
    li t6, 4300
    bne t5, t6, fail

    # Test 44: After ecall invalidation, new lr.w/sc.w pair should succeed
    li t0, 4400
    sw t0, 0(s0)            # mem[0] = 4400
    lr.w t1, (s0)           # reserve address 0
    li a0, 44
    ecall                   # prints 44, invalidate reservation
    # Now do a fresh lr.w/sc.w pair - should succeed
    lr.w t1, (s0)           # new reservation at address 0
    li t2, 4401
    sc.w t3, t2, (s0)       # should succeed
    li a0, 44
    bne t3, zero, fail      # sc.w must return 0 (success)
    lw t4, 0(s0)
    li t5, 4401
    bne t4, t5, fail

    # Test 45: Multiple ecalls between lr.w and sc.w
    li t0, 4500
    sw t0, 0(s1)            # mem[256] = 4500
    lr.w t1, (s1)           # reserve address 256
    li a0, 45
    ecall                   # first ecall, prints 45
    li a0, 45
    ecall                   # second ecall, prints 45 again
    li t2, 4501
    sc.w t3, t2, (s1)       # should fail
    li a0, 45
    li t4, 1
    bne t3, t4, fail
    lw t5, 0(s1)
    li t6, 4500
    bne t5, t6, fail

    # Test 46: ecall with arithmetic between lr.w and sc.w
    li t0, 4600
    sw t0, 0(s2)            # mem[512] = 4600
    lr.w t1, (s2)           # reserve address 512, t1 = 4600
    addi t2, t1, 1          # t2 = 4601
    xor t3, t1, t2          # some arithmetic
    li a0, 46
    ecall                   # prints 46, invalidate reservation
    li t4, 4602
    sc.w t5, t4, (s2)       # should fail
    li a0, 46
    li t6, 1
    bne t5, t6, fail
    lw t0, 0(s2)
    li t1, 4600
    bne t0, t1, fail

    # Test 47: ecall immediately after lr.w (no other instructions between)
    li t0, 4700
    sw t0, 0(s3)            # mem[1024] = 4700
    lr.w t1, (s3)           # reserve address 1024
    li a0, 47
    ecall                   # immediately after lr.w, prints 47
    li t2, 4701
    sc.w t3, t2, (s3)       # should fail
    li a0, 47
    li t4, 1
    bne t3, t4, fail
    lw t5, 0(s3)
    li t6, 4700
    bne t5, t6, fail

    # Test 48: ecall invalidates, then lr.w to different address succeeds
    li t0, 4800
    sw t0, 0(s0)            # mem[0] = 4800
    li t0, 4801
    sw t0, 0(s4)            # mem[2048] = 4801
    lr.w t1, (s0)           # reserve address 0
    li a0, 48
    ecall                   # prints 48, invalidate reservation at address 0
    # Now reserve a different address
    lr.w t2, (s4)           # reserve address 2048
    li t3, 4802
    sc.w t4, t3, (s4)       # should succeed (new reservation)
    li a0, 48
    bne t4, zero, fail
    lw t5, 0(s4)
    li t6, 4802
    bne t5, t6, fail
    # Original address 0 should be unchanged
    lw t5, 0(s0)
    li t6, 4800
    bne t5, t6, fail

    # Test 49: sc.w result is exactly 1 after ecall invalidation
    li t0, 4900
    sw t0, 0(s3)            # mem[1024] = 4900
    lr.w t1, (s3)           # reserve address 1024
    li a0, 49
    ecall                   # prints 49, invalidate reservation
    li t2, 4901
    sc.w t3, t2, (s3)       # should fail with exactly 1
    li a0, 49
    li t4, 1
    bne t3, t4, fail        # must be exactly 1, not just non-zero

    # Test 50: Full cycle - lr.w, ecall (invalidate), lr.w, sc.w (succeed), sc.w (fail)
    li t0, 5000
    sw t0, 0(s2)            # mem[512] = 5000
    lr.w t1, (s2)           # reserve address 512
    li a0, 50
    ecall                   # prints 50, invalidate reservation
    # Verify sc.w fails
    li t2, 5001
    sc.w t3, t2, (s2)       # should fail
    li a0, 50
    li t4, 1
    bne t3, t4, fail
    # Now do a new lr.w/sc.w pair
    lr.w t1, (s2)           # new reservation at 512
    li t2, 5002
    sc.w t3, t2, (s2)       # should succeed
    bne t3, zero, fail
    # Verify sc.w wrote correctly
    lw t4, 0(s2)
    li t5, 5002
    bne t4, t5, fail
    # One more sc.w without lr.w should fail
    li t2, 5003
    sc.w t3, t2, (s2)       # should fail (reservation consumed)
    li t4, 1
    bne t3, t4, fail

    # ============================================
    # All tests passed
    # ============================================
    li a0, 0

fail:
    ecall
    
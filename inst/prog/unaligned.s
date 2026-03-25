# RV32IMA_zicsr Unaligned Memory Access Test
# Tests unaligned loads and stores with little-endian format
# 40 test cases covering various unaligned memory access scenarios
# If test i succeeds, store i to a0 and ecall
# If test i fails, jump to fail immediately

.text
.globl _start

_start:
    # Initialize base addresses for memory operations
    li s0, 256          # Base address (word-aligned)
    li s1, 512          # Base address 2
    li s2, 768          # Base address 3

    # ============================================
    # Word Store to Unaligned Address Tests (4x+1)
    # ============================================

    # Test 1: Store word at address 4x+1, verify with byte loads
    # Store 0x12345678 at address 257 (256+1)
    li t0, 0x12345678
    addi t1, s0, 1          # t1 = 257 (4x+1 = 64*4+1)
    sw t0, 0(t1)            # Unaligned word store
    # Little-endian: mem[257]=0x78, mem[258]=0x56, mem[259]=0x34, mem[260]=0x12
    lbu t2, 0(t1)           # Load byte 0 -> should be 0x78
    li t3, 0x78
    bne t2, t3, fail
    lbu t2, 1(t1)           # Load byte 1 -> should be 0x56
    li t3, 0x56
    bne t2, t3, fail
    lbu t2, 2(t1)           # Load byte 2 -> should be 0x34
    li t3, 0x34
    bne t2, t3, fail
    lbu t2, 3(t1)           # Load byte 3 -> should be 0x12
    li t3, 0x12
    bne t2, t3, fail
    li a0, 1
    ecall

    # Test 2: Store word at address 4x+1, load back as unaligned word
    li t0, 0xDEADBEEF
    addi t1, s0, 5          # t1 = 261 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)            # Unaligned word load
    bne t0, t2, fail
    li a0, 2
    ecall

    # Test 3: Store word at address 4x+2, verify with byte loads
    li t0, 0xCAFEBABE
    addi t1, s0, 10         # t1 = 266 (4x+2 = 66*4+2)
    sw t0, 0(t1)
    # Little-endian: mem[266]=0xBE, mem[267]=0xBA, mem[268]=0xFE, mem[269]=0xCA
    lbu t2, 0(t1)
    li t3, 0xBE
    bne t2, t3, fail
    lbu t2, 1(t1)
    li t3, 0xBA
    bne t2, t3, fail
    lbu t2, 2(t1)
    li t3, 0xFE
    bne t2, t3, fail
    lbu t2, 3(t1)
    li t3, 0xCA
    bne t2, t3, fail
    li a0, 3
    ecall

    # Test 4: Store word at address 4x+2, load back as unaligned word
    li t0, 0x11223344
    addi t1, s0, 14         # t1 = 270 (4x+2)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 4
    ecall

    # Test 5: Store word at address 4x+3, verify with byte loads
    li t0, 0xAABBCCDD
    addi t1, s0, 19         # t1 = 275 (4x+3 = 68*4+3)
    sw t0, 0(t1)
    # Little-endian: mem[275]=0xDD, mem[276]=0xCC, mem[277]=0xBB, mem[278]=0xAA
    lbu t2, 0(t1)
    li t3, 0xDD
    bne t2, t3, fail
    lbu t2, 1(t1)
    li t3, 0xCC
    bne t2, t3, fail
    lbu t2, 2(t1)
    li t3, 0xBB
    bne t2, t3, fail
    lbu t2, 3(t1)
    li t3, 0xAA
    bne t2, t3, fail
    li a0, 5
    ecall

    # Test 6: Store word at address 4x+3, load back as unaligned word
    li t0, 0x99887766
    addi t1, s0, 23         # t1 = 279 (4x+3)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 6
    ecall

    # ============================================
    # Half-word Store to Unaligned Address Tests (2x+1)
    # ============================================

    # Test 7: Store half-word at address 2x+1, verify with byte loads
    li t0, 0x1234
    addi t1, s0, 33         # t1 = 289 (odd address)
    sh t0, 0(t1)
    # Little-endian: mem[289]=0x34, mem[290]=0x12
    lbu t2, 0(t1)
    li t3, 0x34
    bne t2, t3, fail
    lbu t2, 1(t1)
    li t3, 0x12
    bne t2, t3, fail
    li a0, 7
    ecall

    # Test 8: Store half-word at odd address, load back as unaligned half
    li t0, 0x5678
    addi t1, s0, 35         # t1 = 291 (odd address)
    sh t0, 0(t1)
    lhu t2, 0(t1)
    bne t0, t2, fail
    li a0, 8
    ecall

    # Test 9: Store half-word with sign bit at odd address, unsigned load
    li t0, 0xABCD
    addi t1, s0, 37         # t1 = 293 (odd address)
    sh t0, 0(t1)
    lhu t2, 0(t1)
    li t3, 0x0000ABCD
    bne t2, t3, fail
    li a0, 9
    ecall

    # Test 10: Store half-word with sign bit at odd address, signed load
    li t0, 0x8000           # -32768 as signed half
    addi t1, s0, 39         # t1 = 295 (odd address)
    sh t0, 0(t1)
    lh t2, 0(t1)
    li t3, 0xFFFF8000       # Expected sign-extended value
    bne t2, t3, fail
    li a0, 10
    ecall

    # ============================================
    # Mixed Unaligned Access Tests
    # ============================================

    # Test 11: Store word at 4x+1, load as two unaligned half-words
    li t0, 0x12345678
    addi t1, s1, 1          # t1 = 513 (4x+1)
    sw t0, 0(t1)
    lhu t2, 0(t1)           # Lower half at 513
    li t3, 0x5678
    bne t2, t3, fail
    lhu t2, 2(t1)           # Upper half at 515
    li t3, 0x1234
    bne t2, t3, fail
    li a0, 11
    ecall

    # Test 12: Store word at 4x+2, load as two half-words (one aligned, one not)
    li t0, 0xAABBCCDD
    addi t1, s1, 6          # t1 = 518 (4x+2)
    sw t0, 0(t1)
    lhu t2, 0(t1)           # Half at 518 (aligned)
    li t3, 0xCCDD
    bne t2, t3, fail
    lhu t2, 2(t1)           # Half at 520 (aligned)
    li t3, 0xAABB
    bne t2, t3, fail
    li a0, 12
    ecall

    # Test 13: Store two consecutive half-words at odd addresses, load as word
    li t0, 0x1111
    li t1, 0x2222
    addi t2, s1, 9          # t2 = 521 (odd)
    sh t0, 0(t2)            # Store 0x1111 at 521-522
    sh t1, 2(t2)            # Store 0x2222 at 523-524
    lw t3, 0(t2)            # Load word at 521 (unaligned)
    li t4, 0x22221111       # Expected: little-endian
    bne t3, t4, fail
    li a0, 13
    ecall

    # Test 14: Store bytes forming a pattern, load as unaligned word
    addi t0, s1, 17         # t0 = 529 (4x+1)
    li t1, 0x11
    sb t1, 0(t0)
    li t1, 0x22
    sb t1, 1(t0)
    li t1, 0x33
    sb t1, 2(t0)
    li t1, 0x44
    sb t1, 3(t0)
    lw t2, 0(t0)            # Load unaligned word
    li t3, 0x44332211       # Little-endian
    bne t2, t3, fail
    li a0, 14
    ecall

    # Test 15: Store bytes forming a pattern, load as unaligned half-words
    addi t0, s1, 21         # t0 = 533 (odd)
    li t1, 0xAA
    sb t1, 0(t0)
    li t1, 0xBB
    sb t1, 1(t0)
    li t1, 0xCC
    sb t1, 2(t0)
    li t1, 0xDD
    sb t1, 3(t0)
    lhu t2, 0(t0)           # Half at 533
    li t3, 0xBBAA
    bne t2, t3, fail
    lhu t2, 2(t0)           # Half at 535
    li t3, 0xDDCC
    bne t2, t3, fail
    li a0, 15
    ecall

    # ============================================
    # Negative/Signed Value Unaligned Tests
    # ============================================

    # Test 16: Store negative word at unaligned address
    li t0, -1               # 0xFFFFFFFF
    addi t1, s1, 25         # t1 = 537 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 16
    ecall

    # Test 17: Store negative word, verify all bytes are 0xFF
    li t0, -1
    addi t1, s1, 29         # t1 = 541 (4x+1)
    sw t0, 0(t1)
    lbu t2, 0(t1)
    li t3, 0xFF
    bne t2, t3, fail
    lbu t2, 1(t1)
    bne t2, t3, fail
    lbu t2, 2(t1)
    bne t2, t3, fail
    lbu t2, 3(t1)
    bne t2, t3, fail
    li a0, 17
    ecall

    # Test 18: Store MIN_INT at unaligned address
    li t0, 0x80000000       # MIN_INT
    addi t1, s1, 33         # t1 = 545 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 18
    ecall

    # Test 19: Store MIN_INT, verify byte pattern (0x00, 0x00, 0x00, 0x80)
    li t0, 0x80000000
    addi t1, s1, 37         # t1 = 549 (4x+1)
    sw t0, 0(t1)
    lbu t2, 0(t1)
    li t3, 0x00
    bne t2, t3, fail
    lbu t2, 1(t1)
    bne t2, t3, fail
    lbu t2, 2(t1)
    bne t2, t3, fail
    lbu t2, 3(t1)
    li t3, 0x80
    bne t2, t3, fail
    li a0, 19
    ecall

    # Test 20: Store negative half at odd address, signed load
    li t0, -100             # 0xFF9C as 16-bit
    addi t1, s1, 41         # t1 = 553 (odd)
    sh t0, 0(t1)
    lh t2, 0(t1)
    li t3, -100
    bne t2, t3, fail
    li a0, 20
    ecall

    # ============================================
    # Consecutive Unaligned Operations
    # ============================================

    # Test 21: Back-to-back unaligned word stores
    li t0, 0x11111111
    li t1, 0x22222222
    li t2, 0x33333333
    addi t3, s2, 1          # t3 = 769 (4x+1)
    sw t0, 0(t3)
    sw t1, 4(t3)            # Next unaligned word at 773
    sw t2, 8(t3)            # Next unaligned word at 777
    lw t4, 0(t3)
    bne t0, t4, fail
    lw t4, 4(t3)
    bne t1, t4, fail
    lw t4, 8(t3)
    bne t2, t4, fail
    li a0, 21
    ecall

    # Test 22: Back-to-back unaligned half stores at odd addresses
    li t0, 0x1234
    li t1, 0x5678
    li t2, 0x9ABC
    addi t3, s2, 17         # t3 = 785 (odd)
    sh t0, 0(t3)
    sh t1, 2(t3)
    sh t2, 4(t3)
    lhu t4, 0(t3)
    bne t0, t4, fail
    lhu t4, 2(t3)
    bne t1, t4, fail
    lhu t4, 4(t3)
    bne t2, t4, fail
    li a0, 22
    ecall

    # Test 23: Interleaved aligned and unaligned stores
    li t0, 0xAAAAAAAA       # Aligned
    li t1, 0xBBBBBBBB       # Unaligned
    li t2, 0xCCCCCCCC       # Aligned
    addi t3, s2, 24         # t3 = 792 (aligned)
    addi t4, s2, 29         # t4 = 797 (4x+1)
    addi t5, s2, 36         # t5 = 804 (aligned)
    sw t0, 0(t3)
    sw t1, 0(t4)
    sw t2, 0(t5)
    lw t6, 0(t3)
    bne t0, t6, fail
    lw t6, 0(t4)
    bne t1, t6, fail
    lw t6, 0(t5)
    bne t2, t6, fail
    li a0, 23
    ecall

    # Test 24: Store then immediate load (RAW hazard with unaligned)
    li t0, 0xFEDCBA98
    addi t1, s2, 41         # t1 = 809 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)            # Immediate load after unaligned store
    bne t0, t2, fail
    li a0, 24
    ecall

    # Test 25: Multiple loads from same unaligned address
    li t0, 0x12345678
    addi t1, s2, 45         # t1 = 813 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    lw t3, 0(t1)
    lw t4, 0(t1)
    bne t0, t2, fail
    bne t0, t3, fail
    bne t0, t4, fail
    li a0, 25
    ecall

    # ============================================
    # Edge Cases with Pattern Values
    # ============================================

    # Test 26: Checkerboard pattern (0x55555555) at unaligned address
    li t0, 0x55555555
    addi t1, s2, 49         # t1 = 817 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    # Verify individual bytes
    lbu t2, 0(t1)
    li t3, 0x55
    bne t2, t3, fail
    lbu t2, 1(t1)
    bne t2, t3, fail
    lbu t2, 2(t1)
    bne t2, t3, fail
    lbu t2, 3(t1)
    bne t2, t3, fail
    li a0, 26
    ecall

    # Test 27: Inverted checkerboard (0xAAAAAAAA) at unaligned address
    li t0, 0xAAAAAAAA
    addi t1, s2, 53         # t1 = 821 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    lbu t2, 0(t1)
    li t3, 0xAA
    bne t2, t3, fail
    li a0, 27
    ecall

    # Test 28: All zeros at unaligned address
    li t0, 0x00000000
    addi t1, s2, 57         # t1 = 825 (4x+1)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 28
    ecall

    # Test 29: Store 0x01020304 and verify little-endian order
    li t0, 0x01020304
    addi t1, s2, 61         # t1 = 829 (4x+1)
    sw t0, 0(t1)
    # Little-endian: mem[829]=0x04, mem[830]=0x03, mem[831]=0x02, mem[832]=0x01
    lbu t2, 0(t1)
    li t3, 0x04
    bne t2, t3, fail
    lbu t2, 1(t1)
    li t3, 0x03
    bne t2, t3, fail
    lbu t2, 2(t1)
    li t3, 0x02
    bne t2, t3, fail
    lbu t2, 3(t1)
    li t3, 0x01
    bne t2, t3, fail
    li a0, 29
    ecall

    # Test 30: Store at 4x+2 address, verify byte order
    li t0, 0xF0E0D0C0
    addi t1, s2, 66         # t1 = 834 (4x+2)
    sw t0, 0(t1)
    lbu t2, 0(t1)
    li t3, 0xC0
    bne t2, t3, fail
    lbu t2, 1(t1)
    li t3, 0xD0
    bne t2, t3, fail
    lbu t2, 2(t1)
    li t3, 0xE0
    bne t2, t3, fail
    lbu t2, 3(t1)
    li t3, 0xF0
    bne t2, t3, fail
    li a0, 30
    ecall

    # ============================================
    # Unaligned Access Across Word Boundaries
    # ============================================

    # Test 31: Store word at 4x+3, spans into next word
    li t0, 0xDEADC0DE
    addi t1, s2, 71         # t1 = 839 (4x+3 = 209*4+3)
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 31
    ecall

    # Test 32: Half-word spanning word boundary (at 4x+3)
    li t0, 0x1234
    addi t1, s2, 75         # t1 = 843 (4x+3)
    sh t0, 0(t1)
    lhu t2, 0(t1)
    bne t0, t2, fail
    li a0, 32
    ecall

    # Test 33: Store word, modify one byte, verify word
    li t0, 0x12345678
    addi t1, s2, 77         # t1 = 845 (4x+1)
    sw t0, 0(t1)
    li t2, 0xFF
    sb t2, 1(t1)            # Modify byte 1
    lw t3, 0(t1)
    li t4, 0x1234FF78       # Expected: byte 1 changed
    bne t3, t4, fail
    li a0, 33
    ecall

    # Test 34: Store word, modify half-word, verify word
    li t0, 0xAAAABBBB
    addi t1, s2, 81         # t1 = 849 (4x+1)
    sw t0, 0(t1)
    li t2, 0x1111
    sh t2, 0(t1)            # Modify lower half
    lw t3, 0(t1)
    li t4, 0xAAAA1111       # Expected: lower half changed
    bne t3, t4, fail
    li a0, 34
    ecall

    # Test 35: Store word, modify upper half, verify word
    li t0, 0xCCCCDDDD
    addi t1, s2, 85         # t1 = 853 (4x+1)
    sw t0, 0(t1)
    li t2, 0x2222
    sh t2, 2(t1)            # Modify upper half
    lw t3, 0(t1)
    li t4, 0x2222DDDD       # Expected: upper half changed
    bne t3, t4, fail
    li a0, 35
    ecall

    # ============================================
    # Sign Extension with Unaligned Access
    # ============================================

    # Test 36: Unaligned half-word with sign bit, signed load
    li t0, 0xFFFF
    addi t1, s2, 89         # t1 = 857 (odd)
    sh t0, 0(t1)
    lh t2, 0(t1)
    li t3, -1               # Sign-extended to 0xFFFFFFFF
    bne t2, t3, fail
    li a0, 36
    ecall

    # Test 37: Unaligned half-word (0x8001) signed load
    li t0, 0x8001
    addi t1, s2, 91         # t1 = 859 (odd)
    sh t0, 0(t1)
    lh t2, 0(t1)
    li t3, 0xFFFF8001       # Sign-extended
    bne t2, t3, fail
    li a0, 37
    ecall

    # Test 38: Store word with mixed sign patterns, load as signed halves
    li t0, 0x80007FFF       # Upper half negative, lower half max positive
    addi t1, s2, 93         # t1 = 861 (4x+1)
    sw t0, 0(t1)
    lh t2, 0(t1)            # Load lower half signed
    li t3, 0x00007FFF       # Sign-extended (positive)
    bne t2, t3, fail
    lh t2, 2(t1)            # Load upper half signed
    li t3, 0xFFFF8000       # Sign-extended (negative)
    bne t2, t3, fail
    li a0, 38
    ecall

    # ============================================
    # Final Stress Tests
    # ============================================

    # Test 39: Rapid alternating aligned/unaligned stores and loads
    li t0, 0x11111111
    li t1, 0x22222222
    addi t2, s2, 100        # 868 (aligned)
    addi t3, s2, 105        # 873 (4x+1)
    sw t0, 0(t2)            # Aligned store
    sw t1, 0(t3)            # Unaligned store
    lw t4, 0(t3)            # Unaligned load
    lw t5, 0(t2)            # Aligned load
    bne t1, t4, fail
    bne t0, t5, fail
    li a0, 39
    ecall

    # Test 40: Complex pattern - store bytes, load as unaligned word
    # Then overwrite with unaligned word, verify
    addi t0, s2, 109        # t0 = 877 (4x+1)
    li t1, 0x01
    sb t1, 0(t0)
    li t1, 0x02
    sb t1, 1(t0)
    li t1, 0x03
    sb t1, 2(t0)
    li t1, 0x04
    sb t1, 3(t0)
    lw t2, 0(t0)            # Load as word
    li t3, 0x04030201
    bne t2, t3, fail
    # Now overwrite with a different word
    li t4, 0xFEDCBA98
    sw t4, 0(t0)
    lw t5, 0(t0)
    bne t4, t5, fail
    # Verify bytes are correct
    lbu t6, 0(t0)
    li t1, 0x98
    bne t6, t1, fail
    lbu t6, 1(t0)
    li t1, 0xBA
    bne t6, t1, fail
    lbu t6, 2(t0)
    li t1, 0xDC
    bne t6, t1, fail
    lbu t6, 3(t0)
    li t1, 0xFE
    bne t6, t1, fail
    li a0, 40
    ecall

fail:

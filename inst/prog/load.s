# RV32I Load/Store Instruction Test
# Tests: lw, lhu, lh, lbu, lb, sw, sh, sb
# If all tests pass, a0 = 0; otherwise a0 = 1
# All memory addresses < 400 decimal
# Alignment: byte - any, half - multiple of 2, word - multiple of 4

.text
.globl _start

_start:
    # Initialize a0 to 0 (assume pass)
    li a0, 0
    
    # Base addresses for testing (all < 400)
    li s0, 100      # Base address for word-aligned tests
    li s1, 200      # Base address for half-aligned tests
    li s2, 300      # Base address for byte tests

    # ============================================================
    # TEST 1: Basic SW/LW (Word Store/Load)
    # ============================================================
    li t0, 0x12345678
    sw t0, 0(s0)        # Store word at address 100
    lw t1, 0(s0)        # Load word from address 100
    bne t0, t1, fail    # Check if values match

    # Back-to-back SW/LW
    li t0, 0xDEADBEEF
    sw t0, 4(s0)        # Store word at address 104
    lw t1, 4(s0)        # Immediately load back
    bne t0, t1, fail

    li t0, 0xCAFEBABE
    sw t0, 8(s0)        # Store word at address 108
    lw t1, 8(s0)        # Load back
    bne t0, t1, fail

    # Multiple back-to-back stores then loads
    li t0, 0x11111111
    li t2, 0x22222222
    li t3, 0x33333333
    sw t0, 12(s0)       # Store at 112
    sw t2, 16(s0)       # Store at 116
    sw t3, 20(s0)       # Store at 120
    lw t4, 12(s0)       # Load from 112
    lw t5, 16(s0)       # Load from 116
    lw t6, 20(s0)       # Load from 120
    bne t0, t4, fail
    bne t2, t5, fail
    bne t3, t6, fail

    # ============================================================
    # TEST 2: SH/LH/LHU (Half-word Store/Load)
    # ============================================================
    # Positive half-word
    li t0, 0x1234
    sh t0, 0(s1)        # Store half at address 200
    lh t1, 0(s1)        # Load half (signed) from 200
    lhu t2, 0(s1)       # Load half (unsigned) from 200
    bne t0, t1, fail
    bne t0, t2, fail

    # Negative half-word (sign extension test)
    li t0, 0xFFFF8765   # -30875 in signed
    sh t0, 2(s1)        # Store half at address 202
    lh t1, 2(s1)        # Load signed - should sign extend
    lhu t2, 2(s1)       # Load unsigned - should zero extend
    li t3, 0xFFFF8765   # Expected for signed
    li t4, 0x00008765   # Expected for unsigned
    bne t1, t3, fail
    bne t2, t4, fail

    # Back-to-back SH/LH
    li t0, 0x5555
    sh t0, 4(s1)        # Store at 204
    lh t1, 4(s1)        # Immediate load
    bne t0, t1, fail

    li t0, 0xAAAA
    sh t0, 6(s1)        # Store at 206 (sign bit set)
    lhu t1, 6(s1)       # Load unsigned
    li t2, 0x0000AAAA
    bne t1, t2, fail
    lh t1, 6(s1)        # Load signed
    li t2, 0xFFFFAAAA
    bne t1, t2, fail

    # Multiple back-to-back half stores then loads
    li t0, 0x1111
    li t2, 0x2222
    li t3, 0x3333
    sh t0, 8(s1)        # Store at 208
    sh t2, 10(s1)       # Store at 210
    sh t3, 12(s1)       # Store at 212
    lh t4, 8(s1)        # Load from 208
    lh t5, 10(s1)       # Load from 210
    lh t6, 12(s1)       # Load from 212
    bne t0, t4, fail
    bne t2, t5, fail
    bne t3, t6, fail

    # ============================================================
    # TEST 3: SB/LB/LBU (Byte Store/Load)
    # ============================================================
    # Positive byte
    li t0, 0x12
    sb t0, 0(s2)        # Store byte at address 300
    lb t1, 0(s2)        # Load byte (signed) from 300
    lbu t2, 0(s2)       # Load byte (unsigned) from 300
    bne t0, t1, fail
    bne t0, t2, fail

    # Negative byte (sign extension test)
    li t0, 0xFFFFFF85   # -123 in signed
    sb t0, 1(s2)        # Store byte at address 301
    lb t1, 1(s2)        # Load signed - should sign extend
    lbu t2, 1(s2)       # Load unsigned - should zero extend
    li t3, 0xFFFFFF85   # Expected for signed
    li t4, 0x00000085   # Expected for unsigned
    bne t1, t3, fail
    bne t2, t4, fail

    # Back-to-back SB/LB at consecutive addresses
    li t0, 0x11
    li t2, 0x22
    li t3, 0x33
    li t4, 0x44
    sb t0, 2(s2)        # Store at 302
    sb t2, 3(s2)        # Store at 303
    sb t3, 4(s2)        # Store at 304
    sb t4, 5(s2)        # Store at 305
    lb t5, 2(s2)        # Load from 302
    lb t6, 3(s2)        # Load from 303
    lb a1, 4(s2)        # Load from 304
    lb a2, 5(s2)        # Load from 305
    bne t0, t5, fail
    bne t2, t6, fail
    bne t3, a1, fail
    bne t4, a2, fail

    # Immediate back-to-back byte store/load
    li t0, 0x7F
    sb t0, 6(s2)        # Store at 306
    lb t1, 6(s2)        # Immediate load
    bne t0, t1, fail

    li t0, 0x80          # Sign bit set
    sb t0, 7(s2)         # Store at 307
    lbu t1, 7(s2)        # Load unsigned
    li t2, 0x00000080
    bne t1, t2, fail
    lb t1, 7(s2)         # Load signed
    li t2, 0xFFFFFF80
    bne t1, t2, fail

    # ============================================================
    # TEST 4: Mixed Word/Half/Byte Operations
    # ============================================================
    # Store a word, then load individual bytes
    li t0, 0xAABBCCDD
    sw t0, 24(s0)       # Store word at 124
    lbu t1, 24(s0)      # Load byte 0 (LSB) - should be 0xDD
    lbu t2, 25(s0)      # Load byte 1 - should be 0xCC
    lbu t3, 26(s0)      # Load byte 2 - should be 0xBB
    lbu t4, 27(s0)      # Load byte 3 (MSB) - should be 0xAA
    li t5, 0xDD
    li t6, 0xCC
    li a1, 0xBB
    li a2, 0xAA
    bne t1, t5, fail
    bne t2, t6, fail
    bne t3, a1, fail
    bne t4, a2, fail

    # Store a word, then load half-words
    li t0, 0x12345678
    sw t0, 28(s0)       # Store word at 128
    lhu t1, 28(s0)      # Load lower half - should be 0x5678
    lhu t2, 30(s0)      # Load upper half - should be 0x1234
    li t3, 0x5678
    li t4, 0x1234
    bne t1, t3, fail
    bne t2, t4, fail

    # Store bytes to form a word, then load word
    li t0, 0x11
    li t1, 0x22
    li t2, 0x33
    li t3, 0x44
    sb t0, 32(s0)       # Store at 132 (byte 0)
    sb t1, 33(s0)       # Store at 133 (byte 1)
    sb t2, 34(s0)       # Store at 134 (byte 2)
    sb t3, 35(s0)       # Store at 135 (byte 3)
    lw t4, 32(s0)       # Load word from 132
    li t5, 0x44332211   # Expected (little-endian)
    bne t4, t5, fail

    # Store half-words to form a word, then load word
    li t0, 0xABCD
    li t1, 0xEF01
    sh t0, 36(s0)       # Store at 136 (lower half)
    sh t1, 38(s0)       # Store at 138 (upper half)
    lw t2, 36(s0)       # Load word from 136
    li t3, 0xEF01ABCD   # Expected (little-endian)
    bne t2, t3, fail

    # ============================================================
    # TEST 5: Edge Cases - Sign Extension Boundaries
    # ============================================================
    # Byte: 0x7F (max positive) and 0x80 (min negative)
    li t0, 0x7F
    sb t0, 8(s2)        # Store at 308
    lb t1, 8(s2)        # Load signed
    li t2, 0x0000007F
    bne t1, t2, fail

    li t0, 0x80
    sb t0, 9(s2)        # Store at 309
    lb t1, 9(s2)        # Load signed - should be negative
    li t2, 0xFFFFFF80
    bne t1, t2, fail

    # Half: 0x7FFF (max positive) and 0x8000 (min negative)
    li t0, 0x7FFF
    sh t0, 14(s1)       # Store at 214
    lh t1, 14(s1)       # Load signed
    li t2, 0x00007FFF
    bne t1, t2, fail

    li t0, 0x8000
    sh t0, 16(s1)       # Store at 216
    lh t1, 16(s1)       # Load signed - should be negative
    li t2, 0xFFFF8000
    bne t1, t2, fail

    # ============================================================
    # TEST 6: Back-to-Back Different Size Operations
    # ============================================================
    # Store word, immediately store byte to same location
    li t0, 0xFFFFFFFF
    sw t0, 40(s0)       # Store word at 140
    li t0, 0x00
    sb t0, 40(s0)       # Store byte at 140 (overwrite LSB)
    lw t1, 40(s0)       # Load word
    li t2, 0xFFFFFF00
    bne t1, t2, fail

    # Store word, immediately store half to same location
    li t0, 0xFFFFFFFF
    sw t0, 44(s0)       # Store word at 144
    li t0, 0x0000
    sh t0, 44(s0)       # Store half at 144 (overwrite lower half)
    lw t1, 44(s0)       # Load word
    li t2, 0xFFFF0000
    bne t1, t2, fail

    # Store byte, then store half (overlapping)
    li t0, 0x11
    sb t0, 48(s0)       # Store byte at 148
    li t0, 0x2233
    sh t0, 48(s0)       # Store half at 148 (overwrites byte)
    lhu t1, 48(s0)
    li t2, 0x2233
    bne t1, t2, fail

    # ============================================================
    # TEST 7: Byte Access at Non-Aligned Addresses
    # ============================================================
    # Store and load bytes at addresses not aligned to 2 or 4
    li t0, 0xAA
    sb t0, 51(s0)       # Store at 151 (odd address)
    lb t1, 51(s0)
    li t2, 0xFFFFFFAA
    bne t1, t2, fail

    li t0, 0x55
    sb t0, 53(s0)       # Store at 153 (odd address)
    lbu t1, 53(s0)
    li t2, 0x00000055
    bne t1, t2, fail

    li t0, 0xBB
    sb t0, 55(s0)       # Store at 155 (odd address)
    lb t1, 55(s0)
    li t2, 0xFFFFFFBB
    bne t1, t2, fail

    # ============================================================
    # TEST 8: More Back-to-Back Store/Load Patterns
    # ============================================================
    # Pattern: SW, SW, LW, LW (interleaved)
    li t0, 0x11223344
    li t1, 0x55667788
    sw t0, 56(s0)       # Store at 156
    sw t1, 60(s0)       # Store at 160
    lw t2, 56(s0)       # Load from 156
    lw t3, 60(s0)       # Load from 160
    bne t0, t2, fail
    bne t1, t3, fail

    # Pattern: SB, SB, SB, SB, LB, LB, LB, LB
    li t0, 0x01
    li t1, 0x02
    li t2, 0x03
    li t3, 0x04
    sb t0, 10(s2)       # Store at 310
    sb t1, 11(s2)       # Store at 311
    sb t2, 12(s2)       # Store at 312
    sb t3, 13(s2)       # Store at 313
    lb t4, 10(s2)       # Load from 310
    lb t5, 11(s2)       # Load from 311
    lb t6, 12(s2)       # Load from 312
    lb a1, 13(s2)       # Load from 313
    bne t0, t4, fail
    bne t1, t5, fail
    bne t2, t6, fail
    bne t3, a1, fail

    # Pattern: SH, LH, SH, LH (alternating)
    li t0, 0x1234
    sh t0, 18(s1)       # Store at 218
    lh t1, 18(s1)       # Load from 218
    bne t0, t1, fail
    li t0, 0x5678
    sh t0, 20(s1)       # Store at 220
    lh t1, 20(s1)       # Load from 220
    bne t0, t1, fail

    # ============================================================
    # TEST 9: Pattern Fill and Verify
    # ============================================================
    # Fill memory with a pattern using words
    li t0, 0xDEADBEEF
    sw t0, 64(s0)       # Store at 164
    sw t0, 68(s0)       # Store at 168
    sw t0, 72(s0)       # Store at 172
    sw t0, 76(s0)       # Store at 176
    
    # Verify the pattern
    lw t1, 64(s0)
    lw t2, 68(s0)
    lw t3, 72(s0)
    lw t4, 76(s0)
    bne t0, t1, fail
    bne t0, t2, fail
    bne t0, t3, fail
    bne t0, t4, fail

    # Fill memory with bytes
    li t0, 0xFF
    sb t0, 12(s2)       # Store at 314
    sb t0, 13(s2)       # Store at 315
    sb t0, 14(s2)       # Store at 316
    sb t0, 15(s2)       # Store at 317
    
    # Verify using word load (address 312 = s2 + 12)
    lw t1, 12(s2)
    li t2, 0xFFFFFFFF
    bne t1, t2, fail

    # ============================================================
    # TEST 10: Extensive Back-to-Back Load/Store Stress Test
    # ============================================================
    # Rapid word store/load sequence
    li t0, 0x11111111
    sw t0, 80(s0)       # Store at 180
    lw t1, 80(s0)       # Immediate load
    bne t0, t1, fail
    li t0, 0x22222222
    sw t0, 80(s0)       # Overwrite at 180
    lw t1, 80(s0)       # Immediate load
    bne t0, t1, fail
    li t0, 0x33333333
    sw t0, 80(s0)       # Overwrite again at 180
    lw t1, 80(s0)       # Immediate load
    bne t0, t1, fail

    # Rapid half-word store/load sequence
    li t0, 0x4444
    sh t0, 22(s1)       # Store at 222
    lh t1, 22(s1)       # Immediate load
    bne t0, t1, fail
    li t0, 0x5555
    sh t0, 22(s1)       # Overwrite at 222
    lhu t1, 22(s1)      # Immediate load unsigned
    bne t0, t1, fail
    li t0, 0x6666
    sh t0, 22(s1)       # Overwrite again
    lh t1, 22(s1)       # Immediate load
    bne t0, t1, fail

    # Rapid byte store/load sequence
    li t0, 0x77
    sb t0, 16(s2)       # Store at 316
    lb t1, 16(s2)       # Immediate load
    bne t0, t1, fail
    li t0, 0x88
    sb t0, 16(s2)       # Overwrite at 316
    lbu t1, 16(s2)      # Immediate load unsigned
    li t2, 0x00000088
    bne t1, t2, fail
    li t0, 0x99
    sb t0, 16(s2)       # Overwrite again
    lb t1, 16(s2)       # Immediate load signed
    li t2, 0xFFFFFF99
    bne t1, t2, fail

    # ============================================================
    # TEST 11: Alternating Signed/Unsigned Load Verification
    # ============================================================
    # Store patterns with high bit set and verify both signed/unsigned
    li t0, 0xFF
    sb t0, 17(s2)       # Store at 317
    lb t1, 17(s2)       # Signed load
    li t2, 0xFFFFFFFF
    bne t1, t2, fail
    lbu t1, 17(s2)      # Unsigned load
    li t2, 0x000000FF
    bne t1, t2, fail

    li t0, 0xFE
    sb t0, 18(s2)       # Store at 318
    lb t1, 18(s2)       # Signed load
    li t2, 0xFFFFFFFE
    bne t1, t2, fail
    lbu t1, 18(s2)      # Unsigned load
    li t2, 0x000000FE
    bne t1, t2, fail

    li t0, 0xFFFF
    sh t0, 24(s1)       # Store at 224
    lh t1, 24(s1)       # Signed load
    li t2, 0xFFFFFFFF
    bne t1, t2, fail
    lhu t1, 24(s1)      # Unsigned load
    li t2, 0x0000FFFF
    bne t1, t2, fail

    li t0, 0xFFFE
    sh t0, 26(s1)       # Store at 226
    lh t1, 26(s1)       # Signed load
    li t2, 0xFFFFFFFE
    bne t1, t2, fail
    lhu t1, 26(s1)      # Unsigned load
    li t2, 0x0000FFFE
    bne t1, t2, fail

    # ============================================================
    # TEST 12: Word Overlap Modification Tests
    # ============================================================
    # Store word, modify individual bytes, verify
    li t0, 0x00000000
    sw t0, 84(s0)       # Store zeros at 184
    li t0, 0xAA
    sb t0, 84(s0)       # Modify byte 0 at 184
    lw t1, 84(s0)
    li t2, 0x000000AA
    bne t1, t2, fail

    li t0, 0xBB
    sb t0, 85(s0)       # Modify byte 1 at 185
    lw t1, 84(s0)
    li t2, 0x0000BBAA
    bne t1, t2, fail

    li t0, 0xCC
    sb t0, 86(s0)       # Modify byte 2 at 186
    lw t1, 84(s0)
    li t2, 0x00CCBBAA
    bne t1, t2, fail

    li t0, 0xDD
    sb t0, 87(s0)       # Modify byte 3 at 187
    lw t1, 84(s0)
    li t2, 0xDDCCBBAA
    bne t1, t2, fail

    # Store word, modify individual half-words, verify
    li t0, 0x00000000
    sw t0, 88(s0)       # Store zeros at 188
    li t0, 0x1234
    sh t0, 88(s0)       # Modify lower half at 188
    lw t1, 88(s0)
    li t2, 0x00001234
    bne t1, t2, fail

    li t0, 0x5678
    sh t0, 90(s0)       # Modify upper half at 190
    lw t1, 88(s0)
    li t2, 0x56781234
    bne t1, t2, fail

    # ============================================================
    # TEST 13: All Zero and All One Patterns
    # ============================================================
    # All zeros - word
    li t0, 0x00000000
    sw t0, 92(s0)       # Store at 192
    lw t1, 92(s0)
    bne t0, t1, fail

    # All ones - word
    li t0, 0xFFFFFFFF
    sw t0, 96(s0)       # Store at 196
    lw t1, 96(s0)
    bne t0, t1, fail

    # All zeros - half
    li t0, 0x0000
    sh t0, 28(s1)       # Store at 228
    lh t1, 28(s1)
    bne t0, t1, fail
    lhu t2, 28(s1)
    bne t0, t2, fail

    # All ones - half (0xFFFF)
    li t0, 0xFFFF
    sh t0, 30(s1)       # Store at 230
    lhu t1, 30(s1)
    li t2, 0x0000FFFF
    bne t1, t2, fail
    lh t1, 30(s1)
    li t2, 0xFFFFFFFF
    bne t1, t2, fail

    # All zeros - byte
    li t0, 0x00
    sb t0, 19(s2)       # Store at 319
    lb t1, 19(s2)
    bne t0, t1, fail
    lbu t2, 19(s2)
    bne t0, t2, fail

    # All ones - byte (0xFF)
    li t0, 0xFF
    sb t0, 20(s2)       # Store at 320
    lbu t1, 20(s2)
    li t2, 0x000000FF
    bne t1, t2, fail
    lb t1, 20(s2)
    li t2, 0xFFFFFFFF
    bne t1, t2, fail

    # ============================================================
    # TEST 14: Checkerboard Patterns
    # ============================================================
    # 0x55 pattern (01010101)
    li t0, 0x55
    sb t0, 21(s2)       # Store at 321
    lb t1, 21(s2)
    li t2, 0x00000055
    bne t1, t2, fail

    # 0xAA pattern (10101010)
    li t0, 0xAA
    sb t0, 22(s2)       # Store at 322
    lb t1, 22(s2)
    li t2, 0xFFFFFFAA
    bne t1, t2, fail
    lbu t1, 22(s2)
    li t2, 0x000000AA
    bne t1, t2, fail

    # 0x5555 half pattern
    li t0, 0x5555
    sh t0, 32(s1)       # Store at 232
    lh t1, 32(s1)
    li t2, 0x00005555
    bne t1, t2, fail

    # 0xAAAA half pattern
    li t0, 0xAAAA
    sh t0, 34(s1)       # Store at 234
    lh t1, 34(s1)
    li t2, 0xFFFFAAAA
    bne t1, t2, fail
    lhu t1, 34(s1)
    li t2, 0x0000AAAA
    bne t1, t2, fail

    # 0x55555555 word pattern
    li t0, 0x55555555
    sw t0, 0(s0)        # Store at 100 (reuse)
    lw t1, 0(s0)
    bne t0, t1, fail

    # 0xAAAAAAAA word pattern
    li t0, 0xAAAAAAAA
    sw t0, 4(s0)        # Store at 104 (reuse)
    lw t1, 4(s0)
    bne t0, t1, fail

    # ============================================================
    # TEST 15: Final Comprehensive Back-to-Back Stress
    # ============================================================
    # Long sequence of alternating store types
    li t0, 0x11223344
    sw t0, 8(s0)        # Word at 108
    li t0, 0x55
    sb t0, 12(s0)       # Byte at 112
    li t0, 0x6677
    sh t0, 14(s0)       # Half at 114
    li t0, 0x88
    sb t0, 13(s0)       # Byte at 113
    li t0, 0x99AABBCC
    sw t0, 16(s0)       # Word at 116

    # Verify all the above
    lw t1, 8(s0)
    li t2, 0x11223344
    bne t1, t2, fail

    lbu t1, 12(s0)
    li t2, 0x00000055
    bne t1, t2, fail

    lhu t1, 14(s0)
    li t2, 0x00006677
    bne t1, t2, fail

    lbu t1, 13(s0)
    li t2, 0x00000088
    bne t1, t2, fail

    lw t1, 16(s0)
    li t2, 0x99AABBCC
    bne t1, t2, fail

    # Triple back-to-back loads from same location
    li t0, 0xDEADC0DE
    sw t0, 20(s0)       # Store at 120
    lw t1, 20(s0)       # Load 1
    lw t2, 20(s0)       # Load 2
    lw t3, 20(s0)       # Load 3
    bne t0, t1, fail
    bne t0, t2, fail
    bne t0, t3, fail

    # Triple back-to-back stores to same location
    li t0, 0x11111111
    sw t0, 24(s0)       # Store 1 at 124
    li t0, 0x22222222
    sw t0, 24(s0)       # Store 2 at 124
    li t0, 0x33333333
    sw t0, 24(s0)       # Store 3 at 124
    lw t1, 24(s0)
    bne t0, t1, fail

    # Mixed half and byte back-to-back at aligned boundary
    li t0, 0x1234
    sh t0, 36(s1)       # Half at 236
    li t0, 0xAB
    sb t0, 36(s1)       # Byte at 236 (overwrite low byte)
    lhu t1, 36(s1)
    li t2, 0x000012AB
    bne t1, t2, fail

    # Back-to-back different address loads
    li t0, 0x11112222
    li t1, 0x33334444
    li t2, 0x55556666
    sw t0, 28(s0)       # Store at 128
    sw t1, 32(s0)       # Store at 132
    sw t2, 36(s0)       # Store at 136
    lw t3, 28(s0)       # Load from 128
    lw t4, 32(s0)       # Load from 132
    lw t5, 36(s0)       # Load from 136
    lw t6, 28(s0)       # Load from 128 again
    bne t0, t3, fail
    bne t1, t4, fail
    bne t2, t5, fail
    bne t0, t6, fail

    # ============================================================
    # TEST 16: Unaligned Byte Access Within Words
    # ============================================================
    # Store a word, then access each byte position
    li t0, 0xDEADBEEF
    sw t0, 40(s0)       # Store at 140
    
    # Access byte 0 (address 140)
    lbu t1, 40(s0)
    li t2, 0xEF
    bne t1, t2, fail
    
    # Access byte 1 (address 141)
    lbu t1, 41(s0)
    li t2, 0xBE
    bne t1, t2, fail
    
    # Access byte 2 (address 142)
    lbu t1, 42(s0)
    li t2, 0xAD
    bne t1, t2, fail
    
    # Access byte 3 (address 143)
    lbu t1, 43(s0)
    li t2, 0xDE
    bne t1, t2, fail

    # Signed byte loads with sign extension check
    lb t1, 40(s0)       # 0xEF -> sign extended
    li t2, 0xFFFFFFEF
    bne t1, t2, fail
    
    lb t1, 41(s0)       # 0xBE -> sign extended
    li t2, 0xFFFFFFBE
    bne t1, t2, fail
    
    lb t1, 42(s0)       # 0xAD -> sign extended
    li t2, 0xFFFFFFAD
    bne t1, t2, fail
    
    lb t1, 43(s0)       # 0xDE -> sign extended
    li t2, 0xFFFFFFDE
    bne t1, t2, fail

    # ============================================================
    # TEST 17: Half-Word Boundary Access
    # ============================================================
    # Store a word, then access each half-word position
    li t0, 0x12345678
    sw t0, 44(s0)       # Store at 144
    
    # Access lower half (address 144)
    lhu t1, 44(s0)
    li t2, 0x5678
    bne t1, t2, fail
    
    # Access upper half (address 146)
    lhu t1, 46(s0)
    li t2, 0x1234
    bne t1, t2, fail
    
    # Signed half loads
    li t0, 0x8000FFFF
    sw t0, 48(s0)       # Store at 148
    
    lh t1, 48(s0)       # 0xFFFF -> -1
    li t2, 0xFFFFFFFF
    bne t1, t2, fail
    
    lh t1, 50(s0)       # 0x8000 -> -32768
    li t2, 0xFFFF8000
    bne t1, t2, fail

    # ============================================================
    # TEST 18: Sequential Address Store/Load
    # ============================================================
    # Store bytes at sequential odd addresses
    li t0, 0x01
    sb t0, 23(s2)       # Store at 323
    li t0, 0x02
    sb t0, 25(s2)       # Store at 325
    li t0, 0x03
    sb t0, 27(s2)       # Store at 327
    li t0, 0x04
    sb t0, 29(s2)       # Store at 329
    
    # Load and verify
    lb t1, 23(s2)
    li t2, 0x01
    bne t1, t2, fail
    
    lb t1, 25(s2)
    li t2, 0x02
    bne t1, t2, fail
    
    lb t1, 27(s2)
    li t2, 0x03
    bne t1, t2, fail
    
    lb t1, 29(s2)
    li t2, 0x04
    bne t1, t2, fail

    # Store half-words at sequential aligned addresses
    li t0, 0x1111
    sh t0, 38(s1)       # Store at 238
    li t0, 0x2222
    sh t0, 40(s1)       # Store at 240
    li t0, 0x3333
    sh t0, 42(s1)       # Store at 242
    li t0, 0x4444
    sh t0, 44(s1)       # Store at 244
    
    # Load and verify
    lhu t1, 38(s1)
    li t2, 0x1111
    bne t1, t2, fail
    
    lhu t1, 40(s1)
    li t2, 0x2222
    bne t1, t2, fail
    
    lhu t1, 42(s1)
    li t2, 0x3333
    bne t1, t2, fail
    
    lhu t1, 44(s1)
    li t2, 0x4444
    bne t1, t2, fail

    # ============================================================
    # TEST 19: Cross-Boundary Verification
    # ============================================================
    # Verify that storing a half doesn't affect adjacent memory
    li t0, 0x00000000
    sw t0, 52(s0)       # Clear word at 152
    li t0, 0xFFFF
    sh t0, 52(s0)       # Store half at 152
    lhu t1, 54(s0)      # Load upper half at 154
    li t2, 0x0000
    bne t1, t2, fail

    # Verify that storing a byte doesn't affect adjacent memory
    li t0, 0x00000000
    sw t0, 56(s0)       # Clear word at 156
    li t0, 0xFF
    sb t0, 56(s0)       # Store byte at 156
    lbu t1, 57(s0)      # Load next byte at 157
    li t2, 0x00
    bne t1, t2, fail
    lbu t1, 58(s0)      # Load byte at 158
    bne t1, t2, fail
    lbu t1, 59(s0)      # Load byte at 159
    bne t1, t2, fail

    # ============================================================
    # TEST 20: Final Comprehensive Check
    # ============================================================
    # Store unique values at multiple locations
    li t0, 0xCAFEBABE
    sw t0, 60(s0)       # Store at 160
    li t0, 0xDEADBEEF
    sw t0, 64(s0)       # Store at 164
    li t0, 0xBEEFCAFE
    sw t0, 68(s0)       # Store at 168
    li t0, 0xFACEB00C
    sw t0, 72(s0)       # Store at 172

    # Interleaved loads to verify no data corruption
    lw t1, 64(s0)       # Load from 164
    li t2, 0xDEADBEEF
    bne t1, t2, fail
    
    lw t1, 60(s0)       # Load from 160
    li t2, 0xCAFEBABE
    bne t1, t2, fail
    
    lw t1, 72(s0)       # Load from 172
    li t2, 0xFACEB00C
    bne t1, t2, fail
    
    lw t1, 68(s0)       # Load from 168
    li t2, 0xBEEFCAFE
    bne t1, t2, fail

    # All tests passed
    li a0, 0
    j done

fail:
    li a0, 1

done:
    # Custom instructions to print result and stop
    .insn r 0x2B, 0, 0, x0, a0, x0 # Print a0
    
# Data Hazard Test Program
# Tests dependencies between instructions at various distances (1, 2, 3, ... instructions apart)
# Only R-type and I-type instructions, no branches/jumps/memory operations
# Final result stored in a0

.text
.globl _start
_start:
    # Initialize registers
    addi x1, x0, 1          # x1 = 1
    addi x2, x0, 2          # x2 = 2
    addi x3, x0, 3          # x3 = 3
    addi x4, x0, 4          # x4 = 4
    addi x5, x0, 5          # x5 = 5
    addi x6, x0, 6          # x6 = 6
    addi x7, x0, 7          # x7 = 7
    addi x8, x0, 8          # x8 = 8
    addi x9, x0, 9          # x9 = 9
    addi x10, x0, 0         # a0 = 0 (accumulator for final result)
    addi x11, x0, 11        # x11 = 11
    addi x12, x0, 12        # x12 = 12
    addi x13, x0, 13        # x13 = 13
    addi x14, x0, 14        # x14 = 14
    addi x15, x0, 15        # x15 = 15
    addi x16, x0, 16        # x16 = 16
    addi x17, x0, 17        # x17 = 17
    addi x18, x0, 18        # x18 = 18
    addi x19, x0, 19        # x19 = 19
    addi x20, x0, 20        # x20 = 20

    # ========================================
    # TEST 1: Dependencies 1 instruction apart (RAW hazard, back-to-back)
    # ========================================
    addi x21, x0, 100       # x21 = 100
    add x22, x21, x1        # x22 = 100 + 1 = 101 (depends on x21, 1 apart)
    add x23, x22, x2        # x23 = 101 + 2 = 103 (depends on x22, 1 apart)
    add x24, x23, x3        # x24 = 103 + 3 = 106 (depends on x23, 1 apart)
    add x25, x24, x4        # x25 = 106 + 4 = 110 (depends on x24, 1 apart)
    add x26, x25, x5        # x26 = 110 + 5 = 115 (depends on x25, 1 apart)
    add x27, x26, x6        # x27 = 115 + 6 = 121 (depends on x26, 1 apart)
    add x28, x27, x7        # x28 = 121 + 7 = 128 (depends on x27, 1 apart)
    add x29, x28, x8        # x29 = 128 + 8 = 136 (depends on x28, 1 apart)
    add x30, x29, x9        # x30 = 136 + 9 = 145 (depends on x29, 1 apart)
    add x31, x30, x11       # x31 = 145 + 11 = 156 (depends on x30, 1 apart)
    add a0, a0, x31         # a0 += 156

    # ========================================
    # TEST 2: Dependencies 2 instructions apart
    # ========================================
    addi x21, x0, 200       # x21 = 200
    addi x22, x0, 0         # filler
    add x23, x21, x1        # x23 = 200 + 1 = 201 (depends on x21, 2 apart)
    addi x24, x0, 0         # filler
    add x25, x23, x2        # x25 = 201 + 2 = 203 (depends on x23, 2 apart)
    addi x26, x0, 0         # filler
    add x27, x25, x3        # x27 = 203 + 3 = 206 (depends on x25, 2 apart)
    addi x28, x0, 0         # filler
    add x29, x27, x4        # x29 = 206 + 4 = 210 (depends on x27, 2 apart)
    addi x30, x0, 0         # filler
    add x31, x29, x5        # x31 = 210 + 5 = 215 (depends on x29, 2 apart)
    add a0, a0, x31         # a0 += 215, now a0 = 371

    # ========================================
    # TEST 3: Dependencies 3 instructions apart
    # ========================================
    addi x21, x0, 300       # x21 = 300
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    add x24, x21, x1        # x24 = 300 + 1 = 301 (depends on x21, 3 apart)
    addi x25, x0, 0         # filler 1
    addi x26, x0, 0         # filler 2
    add x27, x24, x2        # x27 = 301 + 2 = 303 (depends on x24, 3 apart)
    addi x28, x0, 0         # filler 1
    addi x29, x0, 0         # filler 2
    add x30, x27, x3        # x30 = 303 + 3 = 306 (depends on x27, 3 apart)
    addi x31, x0, 0         # filler 1
    addi x22, x0, 0         # filler 2
    add x23, x30, x4        # x23 = 306 + 4 = 310 (depends on x30, 3 apart)
    add a0, a0, x23         # a0 += 310, now a0 = 681

    # ========================================
    # TEST 4: Dependencies 4 instructions apart
    # ========================================
    addi x21, x0, 400       # x21 = 400
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    add x25, x21, x1        # x25 = 400 + 1 = 401 (depends on x21, 4 apart)
    addi x26, x0, 0         # filler 1
    addi x27, x0, 0         # filler 2
    addi x28, x0, 0         # filler 3
    add x29, x25, x2        # x29 = 401 + 2 = 403 (depends on x25, 4 apart)
    addi x30, x0, 0         # filler 1
    addi x31, x0, 0         # filler 2
    addi x22, x0, 0         # filler 3
    add x23, x29, x3        # x23 = 403 + 3 = 406 (depends on x29, 4 apart)
    add a0, a0, x23         # a0 += 406, now a0 = 1087

    # ========================================
    # TEST 5: Dependencies 5 instructions apart
    # ========================================
    addi x21, x0, 500       # x21 = 500
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    add x26, x21, x1        # x26 = 500 + 1 = 501 (depends on x21, 5 apart)
    addi x27, x0, 0         # filler 1
    addi x28, x0, 0         # filler 2
    addi x29, x0, 0         # filler 3
    addi x30, x0, 0         # filler 4
    add x31, x26, x2        # x31 = 501 + 2 = 503 (depends on x26, 5 apart)
    add a0, a0, x31         # a0 += 503, now a0 = 1590

    # ========================================
    # TEST 6: Mixed distance dependencies with different operations
    # ========================================
    addi x21, x0, 50        # x21 = 50
    slli x22, x21, 1        # x22 = 50 << 1 = 100 (1 apart)
    add x23, x22, x21       # x23 = 100 + 50 = 150 (1 apart from x22, 2 apart from x21)
    sub x24, x23, x1        # x24 = 150 - 1 = 149 (1 apart)
    xor x25, x24, x2        # x25 = 149 ^ 2 = 151 (1 apart)
    or x26, x25, x3         # x26 = 151 | 3 = 151 (1 apart)
    and x27, x26, x15       # x27 = 151 & 15 = 7 (1 apart)
    slli x28, x27, 2        # x28 = 7 << 2 = 28 (1 apart)
    srli x29, x28, 1        # x29 = 28 >> 1 = 14 (1 apart)
    add x30, x29, x28       # x30 = 14 + 28 = 42 (1 apart from x29, 2 apart from x28)
    add a0, a0, x30         # a0 += 42, now a0 = 1632

    # ========================================
    # TEST 7: Long chain of 1-apart dependencies (stress test)
    # ========================================
    addi x21, x0, 1         # x21 = 1
    add x22, x21, x21       # x22 = 2
    add x23, x22, x22       # x23 = 4
    add x24, x23, x23       # x24 = 8
    add x25, x24, x24       # x25 = 16
    add x26, x25, x25       # x26 = 32
    add x27, x26, x26       # x27 = 64
    add x28, x27, x27       # x28 = 128
    add x29, x28, x28       # x29 = 256
    add x30, x29, x29       # x30 = 512
    add x31, x30, x30       # x31 = 1024
    add a0, a0, x31         # a0 += 1024, now a0 = 2656

    # ========================================
    # TEST 8: Alternating operations with 1-apart dependencies
    # ========================================
    addi x21, x0, 1000      # x21 = 1000
    addi x22, x21, 1        # x22 = 1001
    sub x23, x22, x1        # x23 = 1000 (back to 1000)
    addi x24, x23, 5        # x24 = 1005
    sub x25, x24, x3        # x25 = 1002
    addi x26, x25, 10       # x26 = 1012
    sub x27, x26, x5        # x27 = 1007
    addi x28, x27, 20       # x28 = 1027
    sub x29, x28, x7        # x29 = 1020
    addi x30, x29, 30       # x30 = 1050
    sub x31, x30, x9        # x31 = 1041
    add a0, a0, x31         # a0 += 1041, now a0 = 3697

    # ========================================
    # TEST 9: Multiple read dependencies (WAR hazard test - not an issue in simple pipeline)
    # ========================================
    addi x21, x0, 100       # x21 = 100
    add x22, x21, x1        # x22 = 101, reads x21
    add x23, x21, x2        # x23 = 102, reads x21
    add x24, x21, x3        # x24 = 103, reads x21
    add x25, x21, x4        # x25 = 104, reads x21
    add x26, x22, x23       # x26 = 101 + 102 = 203
    add x27, x24, x25       # x27 = 103 + 104 = 207
    add x28, x26, x27       # x28 = 203 + 207 = 410
    add a0, a0, x28         # a0 += 410, now a0 = 4107

    # ========================================
    # TEST 10: Shift operations chain
    # ========================================
    addi x21, x0, 1         # x21 = 1
    slli x22, x21, 1        # x22 = 2
    slli x23, x22, 1        # x23 = 4
    slli x24, x23, 1        # x24 = 8
    slli x25, x24, 1        # x25 = 16
    slli x26, x25, 1        # x26 = 32
    slli x27, x26, 1        # x27 = 64
    slli x28, x27, 1        # x28 = 128
    slli x29, x28, 1        # x29 = 256
    slli x30, x29, 1        # x30 = 512
    add a0, a0, x30         # a0 += 512, now a0 = 4619

    # ========================================
    # TEST 11: Right shift chain
    # ========================================
    addi x21, x0, 1024      # x21 = 1024
    srli x22, x21, 1        # x22 = 512
    srli x23, x22, 1        # x23 = 256
    srli x24, x23, 1        # x24 = 128
    srli x25, x24, 1        # x25 = 64
    srli x26, x25, 1        # x26 = 32
    srli x27, x26, 1        # x27 = 16
    srli x28, x27, 1        # x28 = 8
    srli x29, x28, 1        # x29 = 4
    srli x30, x29, 1        # x30 = 2
    add a0, a0, x30         # a0 += 2, now a0 = 4621

    # ========================================
    # TEST 12: Arithmetic right shift chain (signed)
    # ========================================
    addi x21, x0, -1024     # x21 = -1024
    srai x22, x21, 1        # x22 = -512
    srai x23, x22, 1        # x23 = -256
    srai x24, x23, 1        # x24 = -128
    srai x25, x24, 1        # x25 = -64
    srai x26, x25, 1        # x26 = -32
    srai x27, x26, 1        # x27 = -16
    srai x28, x27, 1        # x28 = -8
    srai x29, x28, 1        # x29 = -4
    srai x30, x29, 1        # x30 = -2
    sub a0, a0, x30         # a0 -= (-2) = a0 + 2, now a0 = 4623

    # ========================================
    # TEST 13: XOR chain
    # ========================================
    addi x21, x0, 0x5A      # x21 = 0x5A (90)
    xori x22, x21, 0xFF     # x22 = 0x5A ^ 0xFF = 0xA5 (165)
    xori x23, x22, 0x0F     # x23 = 0xA5 ^ 0x0F = 0xAA (170)
    xori x24, x23, 0xAA     # x24 = 0xAA ^ 0xAA = 0 (0)
    addi x25, x24, 100      # x25 = 0 + 100 = 100
    xor x26, x25, x1        # x26 = 100 ^ 1 = 101
    xor x27, x26, x2        # x27 = 101 ^ 2 = 103
    xor x28, x27, x3        # x28 = 103 ^ 3 = 100
    add a0, a0, x28         # a0 += 100, now a0 = 4723

    # ========================================
    # TEST 14: OR chain
    # ========================================
    addi x21, x0, 1         # x21 = 1
    ori x22, x21, 2         # x22 = 1 | 2 = 3
    ori x23, x22, 4         # x23 = 3 | 4 = 7
    ori x24, x23, 8         # x24 = 7 | 8 = 15
    ori x25, x24, 16        # x25 = 15 | 16 = 31
    ori x26, x25, 32        # x26 = 31 | 32 = 63
    ori x27, x26, 64        # x27 = 63 | 64 = 127
    ori x28, x27, 128       # x28 = 127 | 128 = 255
    add a0, a0, x28         # a0 += 255, now a0 = 4978

    # ========================================
    # TEST 15: AND chain
    # ========================================
    addi x21, x0, 0x7FF     # x21 = 2047
    andi x22, x21, 0x3FF    # x22 = 2047 & 1023 = 1023
    andi x23, x22, 0x1FF    # x23 = 1023 & 511 = 511
    andi x24, x23, 0x0FF    # x24 = 511 & 255 = 255
    andi x25, x24, 0x07F    # x25 = 255 & 127 = 127
    andi x26, x25, 0x03F    # x26 = 127 & 63 = 63
    andi x27, x26, 0x01F    # x27 = 63 & 31 = 31
    andi x28, x27, 0x00F    # x28 = 31 & 15 = 15
    add a0, a0, x28         # a0 += 15, now a0 = 4993

    # ========================================
    # TEST 16: SLT chain (set less than)
    # ========================================
    addi x21, x0, 10        # x21 = 10
    slti x22, x21, 20       # x22 = (10 < 20) = 1
    add x23, x22, x21       # x23 = 1 + 10 = 11
    slti x24, x23, 15       # x24 = (11 < 15) = 1
    add x25, x24, x23       # x25 = 1 + 11 = 12
    slti x26, x25, 10       # x26 = (12 < 10) = 0
    add x27, x26, x25       # x27 = 0 + 12 = 12
    slti x28, x27, 100      # x28 = (12 < 100) = 1
    add x29, x28, x27       # x29 = 1 + 12 = 13
    add a0, a0, x29         # a0 += 13, now a0 = 5006

    # ========================================
    # TEST 17: SLTU chain (set less than unsigned)
    # ========================================
    addi x21, x0, -1        # x21 = 0xFFFFFFFF (max unsigned)
    sltiu x22, x21, 100     # x22 = (0xFFFFFFFF < 100) = 0
    addi x23, x22, 50       # x23 = 0 + 50 = 50
    sltiu x24, x23, 100     # x24 = (50 < 100) = 1
    add x25, x24, x23       # x25 = 1 + 50 = 51
    sltiu x26, x25, 50      # x26 = (51 < 50) = 0
    add x27, x26, x25       # x27 = 0 + 51 = 51
    add a0, a0, x27         # a0 += 51, now a0 = 5057

    # ========================================
    # TEST 18: Complex multi-source dependency
    # ========================================
    addi x21, x0, 100       # x21 = 100
    addi x22, x0, 200       # x22 = 200
    add x23, x21, x22       # x23 = 300, depends on x21 (2 apart) and x22 (1 apart)
    addi x24, x0, 50        # x24 = 50
    add x25, x23, x24       # x25 = 350, depends on x23 (2 apart) and x24 (1 apart)
    addi x26, x0, 25        # x26 = 25
    add x27, x25, x26       # x27 = 375, depends on x25 (2 apart) and x26 (1 apart)
    add a0, a0, x27         # a0 += 375, now a0 = 5432

    # ========================================
    # TEST 19: Stress test - very long 1-apart chain
    # ========================================
    addi x21, x0, 1         # x21 = 1
    addi x22, x21, 1        # x22 = 2
    addi x23, x22, 1        # x23 = 3
    addi x24, x23, 1        # x24 = 4
    addi x25, x24, 1        # x25 = 5
    addi x26, x25, 1        # x26 = 6
    addi x27, x26, 1        # x27 = 7
    addi x28, x27, 1        # x28 = 8
    addi x29, x28, 1        # x29 = 9
    addi x30, x29, 1        # x30 = 10
    addi x31, x30, 1        # x31 = 11
    add a0, a0, x31         # a0 += 11, now a0 = 5443

    # ========================================
    # TEST 20: Mixed R-type operations
    # ========================================
    addi x21, x0, 0x123     # x21 = 291
    addi x22, x0, 0x456     # x22 = 1110
    add x23, x21, x22       # x23 = 1401
    sub x24, x22, x21       # x24 = 819
    and x25, x23, x24       # x25 = 1401 & 819 = 305
    or x26, x23, x24        # x26 = 1401 | 819 = 1915
    xor x27, x25, x26       # x27 = 305 ^ 1915 = 1610
    sll x28, x1, x2         # x28 = 1 << 2 = 4
    add x29, x27, x28       # x29 = 1610 + 4 = 1614
    srl x30, x29, x1        # x30 = 1614 >> 1 = 807
    add a0, a0, x30         # a0 += 807, now a0 = 6250

    # ========================================
    # TEST 21: 6 instructions apart dependency
    # ========================================
    addi x21, x0, 600       # x21 = 600
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    addi x26, x0, 0         # filler 5
    add x27, x21, x1        # x27 = 600 + 1 = 601 (depends on x21, 6 apart)
    add a0, a0, x27         # a0 += 601, now a0 = 6851

    # ========================================
    # TEST 22: 7 instructions apart dependency
    # ========================================
    addi x21, x0, 700       # x21 = 700
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    addi x26, x0, 0         # filler 5
    addi x27, x0, 0         # filler 6
    add x28, x21, x1        # x28 = 700 + 1 = 701 (depends on x21, 7 apart)
    add a0, a0, x28         # a0 += 701, now a0 = 7552

    # ========================================
    # TEST 23: 8 instructions apart dependency
    # ========================================
    addi x21, x0, 800       # x21 = 800
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    addi x26, x0, 0         # filler 5
    addi x27, x0, 0         # filler 6
    addi x28, x0, 0         # filler 7
    add x29, x21, x1        # x29 = 800 + 1 = 801 (depends on x21, 8 apart)
    add a0, a0, x29         # a0 += 801, now a0 = 8353

    # ========================================
    # TEST 24: 9 instructions apart dependency
    # ========================================
    addi x21, x0, 900       # x21 = 900
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    addi x26, x0, 0         # filler 5
    addi x27, x0, 0         # filler 6
    addi x28, x0, 0         # filler 7
    addi x29, x0, 0         # filler 8
    add x30, x21, x1        # x30 = 900 + 1 = 901 (depends on x21, 9 apart)
    add a0, a0, x30         # a0 += 901, now a0 = 9254

    # ========================================
    # TEST 25: 10 instructions apart dependency
    # ========================================
    addi x21, x0, 1000      # x21 = 1000
    addi x22, x0, 0         # filler 1
    addi x23, x0, 0         # filler 2
    addi x24, x0, 0         # filler 3
    addi x25, x0, 0         # filler 4
    addi x26, x0, 0         # filler 5
    addi x27, x0, 0         # filler 6
    addi x28, x0, 0         # filler 7
    addi x29, x0, 0         # filler 8
    addi x30, x0, 0         # filler 9
    add x31, x21, x1        # x31 = 1000 + 1 = 1001 (depends on x21, 10 apart)
    add a0, a0, x31         # a0 += 1001, now a0 = 10255

    # ========================================
    # TEST 26: Interleaved dependency chains
    # ========================================
    addi x21, x0, 10        # Chain A: x21 = 10
    addi x22, x0, 20        # Chain B: x22 = 20
    add x23, x21, x1        # Chain A: x23 = 11 (x21 + 1)
    add x24, x22, x2        # Chain B: x24 = 22 (x22 + 2)
    add x25, x23, x3        # Chain A: x25 = 14 (x23 + 3)
    add x26, x24, x4        # Chain B: x26 = 26 (x24 + 4)
    add x27, x25, x5        # Chain A: x27 = 19 (x25 + 5)
    add x28, x26, x6        # Chain B: x28 = 32 (x26 + 6)
    add x29, x27, x28       # Merge: x29 = 19 + 32 = 51
    add a0, a0, x29         # a0 += 51, now a0 = 10306

    # ========================================
    # TEST 27: Three parallel chains merging
    # ========================================
    addi x21, x0, 5         # Chain A
    addi x22, x0, 10        # Chain B
    addi x23, x0, 15        # Chain C
    add x24, x21, x21       # Chain A: 10
    add x25, x22, x22       # Chain B: 20
    add x26, x23, x23       # Chain C: 30
    add x27, x24, x24       # Chain A: 20
    add x28, x25, x25       # Chain B: 40
    add x29, x26, x26       # Chain C: 60
    add x30, x27, x28       # Merge A+B: 60
    add x31, x30, x29       # Merge with C: 120
    add a0, a0, x31         # a0 += 120, now a0 = 10426

    # ========================================
    # TEST 28: Complex expression tree
    # ========================================
    addi x21, x0, 2         # a = 2
    addi x22, x0, 3         # b = 3
    addi x23, x0, 4         # c = 4
    addi x24, x0, 5         # d = 5
    add x25, x21, x22       # a + b = 5
    add x26, x23, x24       # c + d = 9
    add x27, x25, x26       # (a+b) + (c+d) = 14
    slli x28, x27, 2        # 14 * 4 = 56
    add a0, a0, x28         # a0 += 56, now a0 = 10482

    # ========================================
    # TEST 29: Bit manipulation chain
    # ========================================
    addi x21, x0, 0x155     # x21 = 0x155 (341)
    slli x22, x21, 4        # x22 = 0x1550 (5456)
    srli x23, x22, 2        # x23 = 0x554 (1364)
    andi x24, x23, 0x0FF    # x24 = 0x54 (84)
    ori x25, x24, 0x100     # x25 = 0x154 (340)
    xori x26, x25, 0x055    # x26 = 0x101 (257)
    add a0, a0, x26         # a0 += 257, now a0 = 10739

    # ========================================
    # TEST 30: Register reuse stress test
    # ========================================
    addi x21, x0, 1         # x21 = 1
    add x21, x21, x21       # x21 = 2 (self-dependency, 1 apart)
    add x21, x21, x21       # x21 = 4
    add x21, x21, x21       # x21 = 8
    add x21, x21, x21       # x21 = 16
    add x21, x21, x21       # x21 = 32
    add x21, x21, x21       # x21 = 64
    add x21, x21, x21       # x21 = 128
    add x21, x21, x21       # x21 = 256
    add x21, x21, x21       # x21 = 512
    add a0, a0, x21         # a0 += 512, now a0 = 11251

    # ========================================
    # TEST 31: More register reuse
    # ========================================
    addi x22, x0, 100       # x22 = 100
    addi x22, x22, 10       # x22 = 110
    addi x22, x22, 10       # x22 = 120
    addi x22, x22, 10       # x22 = 130
    addi x22, x22, 10       # x22 = 140
    addi x22, x22, 10       # x22 = 150
    addi x22, x22, 10       # x22 = 160
    addi x22, x22, 10       # x22 = 170
    addi x22, x22, 10       # x22 = 180
    addi x22, x22, 10       # x22 = 190
    add a0, a0, x22         # a0 += 190, now a0 = 11441

    # ========================================
    # TEST 32: Alternating add/sub on same register
    # ========================================
    addi x23, x0, 500       # x23 = 500
    addi x23, x23, 100      # x23 = 600
    addi x23, x23, -50      # x23 = 550
    addi x23, x23, 75       # x23 = 625
    addi x23, x23, -25      # x23 = 600
    addi x23, x23, 100      # x23 = 700
    addi x23, x23, -100     # x23 = 600
    addi x23, x23, 50       # x23 = 650
    addi x23, x23, -50      # x23 = 600
    addi x23, x23, 100      # x23 = 700
    add a0, a0, x23         # a0 += 700, now a0 = 12141

    # ========================================
    # TEST 33: SLL/SRL alternating
    # ========================================
    addi x24, x0, 0x111     # x24 = 273
    slli x24, x24, 1        # x24 = 546
    srli x24, x24, 1        # x24 = 273
    slli x24, x24, 2        # x24 = 1092
    srli x24, x24, 2        # x24 = 273
    slli x24, x24, 3        # x24 = 2184
    srli x24, x24, 3        # x24 = 273
    slli x24, x24, 4        # x24 = 4368
    srli x24, x24, 4        # x24 = 273
    slli x24, x24, 5        # x24 = 8736
    srli x24, x24, 4        # x24 = 546
    add a0, a0, x24         # a0 += 546, now a0 = 12687

    # ========================================
    # TEST 34: Multiple operand dependencies
    # ========================================
    addi x21, x0, 10        # x21 = 10
    addi x22, x0, 20        # x22 = 20
    add x23, x21, x22       # x23 = 30, needs x21 (2 apart), x22 (1 apart)
    add x24, x22, x23       # x24 = 50, needs x22 (2 apart), x23 (1 apart)
    add x25, x23, x24       # x25 = 80, needs x23 (2 apart), x24 (1 apart)
    add x26, x24, x25       # x26 = 130, needs x24 (2 apart), x25 (1 apart)
    add x27, x25, x26       # x27 = 210, needs x25 (2 apart), x26 (1 apart)
    add x28, x26, x27       # x28 = 340, needs x26 (2 apart), x27 (1 apart)
    add x29, x27, x28       # x29 = 550, needs x27 (2 apart), x28 (1 apart)
    add x30, x28, x29       # x30 = 890, needs x28 (2 apart), x29 (1 apart)
    add a0, a0, x30         # a0 += 890, now a0 = 13577

    # ========================================
    # TEST 35: Long filler test (10+ apart)
    # ========================================
    addi x21, x0, 1234      # x21 = 1234
    addi x22, x0, 1         # filler
    addi x23, x0, 2         # filler
    addi x24, x0, 3         # filler
    addi x25, x0, 4         # filler
    addi x26, x0, 5         # filler
    addi x27, x0, 6         # filler
    addi x28, x0, 7         # filler
    addi x29, x0, 8         # filler
    addi x30, x0, 9         # filler
    addi x31, x0, 10        # filler
    add x22, x21, x1        # x22 = 1234 + 1 = 1235 (11 apart)
    add a0, a0, x22         # a0 += 1235, now a0 = 14812

    # ========================================
    # TEST 36: Fibonacci-like sequence
    # ========================================
    addi x21, x0, 1         # fib(1) = 1
    addi x22, x0, 1         # fib(2) = 1
    add x23, x21, x22       # fib(3) = 2
    add x24, x22, x23       # fib(4) = 3
    add x25, x23, x24       # fib(5) = 5
    add x26, x24, x25       # fib(6) = 8
    add x27, x25, x26       # fib(7) = 13
    add x28, x26, x27       # fib(8) = 21
    add x29, x27, x28       # fib(9) = 34
    add x30, x28, x29       # fib(10) = 55
    add x31, x29, x30       # fib(11) = 89
    add a0, a0, x31         # a0 += 89, now a0 = 14901

    # ========================================
    # TEST 37: More shift operations
    # ========================================
    addi x21, x0, 0xABC     # x21 = 2748
    slli x22, x21, 8        # x22 = 0xABC00 = 703488
    srli x23, x22, 12       # x23 = 0xAB = 171
    slli x24, x23, 4        # x24 = 0xAB0 = 2736
    srli x25, x24, 4        # x25 = 0xAB = 171
    add a0, a0, x25         # a0 += 171, now a0 = 15072

    # ========================================
    # TEST 38: Complex XOR pattern
    # ========================================
    addi x21, x0, 0x555     # x21 = 1365
    addi x22, x0, 0x333     # x22 = 819
    xor x23, x21, x22       # x23 = 1365 ^ 819 = 1638
    xor x24, x23, x21       # x24 = 1638 ^ 1365 = 819
    xor x25, x24, x22       # x25 = 819 ^ 819 = 0
    addi x26, x25, 200      # x26 = 200
    add a0, a0, x26         # a0 += 200, now a0 = 15272

    # ========================================
    # TEST 39: Negative number handling
    # ========================================
    addi x21, x0, -100      # x21 = -100
    addi x22, x21, 50       # x22 = -50
    addi x23, x22, 50       # x23 = 0
    addi x24, x23, 100      # x24 = 100
    addi x25, x24, -50      # x25 = 50
    add x26, x24, x25       # x26 = 150
    add a0, a0, x26         # a0 += 150, now a0 = 15422

    # ========================================
    # TEST 40: Sub with dependencies
    # ========================================
    addi x21, x0, 1000      # x21 = 1000
    sub x22, x21, x1        # x22 = 999
    sub x23, x22, x2        # x23 = 997
    sub x24, x23, x3        # x24 = 994
    sub x25, x24, x4        # x25 = 990
    sub x26, x25, x5        # x26 = 985
    sub x27, x26, x6        # x27 = 979
    sub x28, x27, x7        # x28 = 972
    sub x29, x28, x8        # x29 = 964
    sub x30, x29, x9        # x30 = 955
    add a0, a0, x30         # a0 += 955, now a0 = 16377

    # ========================================
    # TEST 41: SLT with dependencies
    # ========================================
    addi x21, x0, 50        # x21 = 50
    slti x22, x21, 100      # x22 = 1
    add x23, x21, x22       # x23 = 51
    slti x24, x23, 52       # x24 = 1
    add x25, x23, x24       # x25 = 52
    slti x26, x25, 52       # x26 = 0
    add x27, x25, x26       # x27 = 52
    add a0, a0, x27         # a0 += 52, now a0 = 16429

    # ========================================
    # TEST 42: More R-type variety
    # ========================================
    addi x21, x0, 64        # x21 = 64
    addi x22, x0, 32        # x22 = 32
    add x23, x21, x22       # x23 = 96
    sub x24, x21, x22       # x24 = 32
    and x25, x23, x24       # x25 = 96 & 32 = 32
    or x26, x23, x24        # x26 = 96 | 32 = 96
    xor x27, x25, x26       # x27 = 32 ^ 96 = 64
    add a0, a0, x27         # a0 += 64, now a0 = 16493

    # ========================================
    # TEST 43: Power of 2 construction
    # ========================================
    addi x21, x0, 1         # 2^0 = 1
    slli x22, x21, 1        # 2^1 = 2
    slli x23, x21, 2        # 2^2 = 4
    slli x24, x21, 3        # 2^3 = 8
    slli x25, x21, 4        # 2^4 = 16
    slli x26, x21, 5        # 2^5 = 32
    add x27, x22, x23       # 2 + 4 = 6
    add x28, x24, x25       # 8 + 16 = 24
    add x29, x26, x27       # 32 + 6 = 38
    add x30, x28, x29       # 24 + 38 = 62
    add a0, a0, x30         # a0 += 62, now a0 = 16555

    # ========================================
    # TEST 44: Accumulator pattern
    # ========================================
    addi x21, x0, 0         # acc = 0
    addi x21, x21, 1        # acc = 1
    addi x21, x21, 2        # acc = 3
    addi x21, x21, 3        # acc = 6
    addi x21, x21, 4        # acc = 10
    addi x21, x21, 5        # acc = 15
    addi x21, x21, 6        # acc = 21
    addi x21, x21, 7        # acc = 28
    addi x21, x21, 8        # acc = 36
    addi x21, x21, 9        # acc = 45
    addi x21, x21, 10       # acc = 55
    add a0, a0, x21         # a0 += 55, now a0 = 16610

    # ========================================
    # TEST 45: Another Fibonacci variant
    # ========================================
    addi x21, x0, 2         # a = 2
    addi x22, x0, 3         # b = 3
    add x23, x21, x22       # 5
    add x24, x22, x23       # 8
    add x25, x23, x24       # 13
    add x26, x24, x25       # 21
    add x27, x25, x26       # 34
    add x28, x26, x27       # 55
    add a0, a0, x28         # a0 += 55, now a0 = 16665

    # ========================================
    # TEST 46: Signed comparison chain
    # ========================================
    addi x21, x0, -10       # x21 = -10
    addi x22, x0, 10        # x22 = 10
    slt x23, x21, x22       # x23 = 1 (-10 < 10)
    add x24, x23, x22       # x24 = 11
    slt x25, x22, x24       # x25 = 1 (10 < 11)
    add x26, x25, x24       # x26 = 12
    slt x27, x26, x22       # x27 = 0 (12 < 10 is false)
    add x28, x27, x26       # x28 = 12
    add a0, a0, x28         # a0 += 12, now a0 = 16677

    # ========================================
    # TEST 47: Unsigned comparison chain
    # ========================================
    addi x21, x0, -1        # x21 = 0xFFFFFFFF
    addi x22, x0, 100       # x22 = 100
    sltu x23, x22, x21      # x23 = 1 (100 < 0xFFFFFFFF unsigned)
    add x24, x23, x22       # x24 = 101
    sltu x25, x24, x21      # x25 = 1 (101 < 0xFFFFFFFF unsigned)
    add x26, x25, x24       # x26 = 102
    add a0, a0, x26         # a0 += 102, now a0 = 16779

    # ========================================
    # TEST 48: Mixed immediate and register ops
    # ========================================
    addi x21, x0, 100       # x21 = 100
    add x22, x21, x1        # x22 = 101
    addi x23, x22, 10       # x23 = 111
    add x24, x23, x2        # x24 = 113
    addi x25, x24, 20       # x25 = 133
    add x26, x25, x3        # x26 = 136
    addi x27, x26, 30       # x27 = 166
    add x28, x27, x4        # x28 = 170
    add a0, a0, x28         # a0 += 170, now a0 = 16949

    # ========================================
    # TEST 49: Final stress test
    # ========================================
    addi x21, x0, 1         # Start
    add x22, x21, x21       # 2
    add x23, x22, x21       # 3
    add x24, x23, x22       # 5
    add x25, x24, x23       # 8
    add x26, x25, x24       # 13
    add x27, x26, x25       # 21
    add x28, x27, x26       # 34
    add x29, x28, x27       # 55
    add x30, x29, x28       # 89
    add x31, x30, x29       # 144
    add a0, a0, x31         # a0 += 144, now a0 = 17093

    # ========================================
    # TEST 50: Very long dependency chain
    # ========================================
    addi x21, x0, 1
    addi x22, x21, 1        # 2
    addi x23, x22, 1        # 3
    addi x24, x23, 1        # 4
    addi x25, x24, 1        # 5
    addi x26, x25, 1        # 6
    addi x27, x26, 1        # 7
    addi x28, x27, 1        # 8
    addi x29, x28, 1        # 9
    addi x30, x29, 1        # 10
    addi x31, x30, 1        # 11
    add a0, a0, x31         # a0 += 11, now a0 = 17104

    # ========================================
    # Final checksum computation
    # ========================================
    # Expected final a0 = 17104

    # Print result and stop
    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0

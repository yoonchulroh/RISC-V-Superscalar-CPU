# RV32IMA Atomic Memory Operation (AMO) Instruction Tests
# Tests: amoswap.w, amoadd.w, amoand.w, amoor.w, amoxor.w, amomax.w, amomin.w
# 10 test cases per instruction (70 total)
# Each test verifies both destination register value and memory value
# Special tests: mul/div before AMO, consecutive AMO, memory access before/after AMO,
#                register update right before AMO
# If test i fails, a0 = i. If all pass, a0 = 0.
# All memory addresses < 4000

.text
.globl _start

_start:
    # Initialize base addresses for memory operations
    # We'll use different base addresses and compute specific addresses as needed
    li s0, 0           # Base address 0
    li s1, 256         # Base address 256
    li s2, 512         # Base address 512
    li s3, 1024        # Base address 1024
    li s4, 2048        # Base address 2048
    li s5, 3072        # Base address 3072
    li s6, 3584        # Base address 3584

    # ============================================
    # AMOSWAP.W Tests - Tests 1-10
    # amoswap.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = rs2
    # ============================================

    # Test 1: Basic amoswap.w
    li t0, 100
    sw t0, 0(s0)            # mem[0] = 100
    li t1, 200
    amoswap.w t2, t1, (s0)  # t2 = 100 (old mem), mem[0] = 200
    li a0, 1
    li t3, 100
    bne t2, t3, fail        # Check t2 = 100
    lw t4, 0(s0)
    li t5, 200
    bne t4, t5, fail        # Check mem[0] = 200

    # Test 2: amoswap.w with negative value
    li t0, -50
    sw t0, 0(s1)            # mem[256] = -50
    li t1, 500
    amoswap.w t2, t1, (s1)  # t2 = -50, mem[256] = 500
    li a0, 2
    li t3, -50
    bne t2, t3, fail
    lw t4, 0(s1)
    li t5, 500
    bne t4, t5, fail

    # Test 3: amoswap.w with zero value in memory
    sw zero, 0(s2)          # mem[512] = 0
    li t1, 999
    amoswap.w t2, t1, (s2)  # t2 = 0, mem[512] = 999
    li a0, 3
    bne t2, zero, fail
    lw t4, 0(s2)
    li t5, 999
    bne t4, t5, fail

    # Test 4: amoswap.w swapping zero to memory
    li t0, 777
    sw t0, 0(s3)            # mem[1024] = 777
    amoswap.w t2, zero, (s3) # t2 = 777, mem[1024] = 0
    li a0, 4
    li t3, 777
    bne t2, t3, fail
    lw t4, 0(s3)
    bne t4, zero, fail

    # Test 5: mul instruction right before amoswap.w
    li t0, 100
    sw t0, 0(s4)            # mem[2048] = 100
    li t1, 10
    li t2, 20
    mul t3, t1, t2          # t3 = 200
    amoswap.w t4, t3, (s4)  # t4 = 100, mem[2048] = 200
    li a0, 5
    li t5, 100
    bne t4, t5, fail
    lw t6, 0(s4)
    li t0, 200
    bne t6, t0, fail

    # Test 6: Consecutive amoswap.w instructions
    li t0, 1000
    sw t0, 0(s5)            # mem[3072] = 1000
    li t1, 2000
    li t2, 3000
    amoswap.w t3, t1, (s5)  # t3 = 1000, mem[3072] = 2000
    amoswap.w t4, t2, (s5)  # t4 = 2000, mem[3072] = 3000
    li a0, 6
    li t5, 1000
    bne t3, t5, fail
    li t5, 2000
    bne t4, t5, fail
    lw t6, 0(s5)
    li t0, 3000
    bne t6, t0, fail

    # Test 7: Memory load right before amoswap.w
    li t0, 400
    sw t0, 0(s6)            # mem[3584] = 400
    addi s7, s6, 4          # s7 = 3588
    li t0, 500
    sw t0, 0(s7)            # mem[3588] = 500
    lw t1, 0(s6)            # t1 = 400
    li t2, 600
    amoswap.w t3, t2, (s7)  # t3 = 500, mem[3588] = 600
    li a0, 7
    li t4, 400
    bne t1, t4, fail        # verify load result
    li t4, 500
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 600
    bne t5, t6, fail

    # Test 8: Memory store right after amoswap.w
    addi s7, s0, 4          # s7 = 4
    li t0, 700
    sw t0, 0(s7)            # mem[4] = 700
    li t1, 800
    amoswap.w t2, t1, (s7)  # t2 = 700, mem[4] = 800
    addi s8, s0, 8          # s8 = 8
    li t3, 900
    sw t3, 0(s8)            # mem[8] = 900
    li a0, 8
    li t4, 700
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 800
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 900
    bne t5, t6, fail

    # Test 9: Register update right before amoswap.w (forwarding test)
    addi s7, s0, 12         # s7 = 12
    li t0, 111
    sw t0, 0(s7)            # mem[12] = 111
    li t1, 50
    addi t2, t1, 100        # t2 = 150 (computed just before AMO)
    amoswap.w t3, t2, (s7)  # t3 = 111, mem[12] = 150
    li a0, 9
    li t4, 111
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 150
    bne t5, t6, fail

    # Test 10: amoswap.w with max positive and min negative values
    addi s7, s0, 16         # s7 = 16
    li t0, 0x7FFFFFFF
    sw t0, 0(s7)            # mem[16] = MAX_INT
    li t1, 0x80000000
    amoswap.w t2, t1, (s7)  # t2 = MAX_INT, mem[16] = MIN_INT
    li a0, 10
    li t3, 0x7FFFFFFF
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x80000000
    bne t4, t5, fail

    # ============================================
    # AMOADD.W Tests - Tests 11-20
    # amoadd.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = mem[rs1] + rs2
    # ============================================

    # Test 11: Basic amoadd.w
    li t0, 100
    sw t0, 0(s1)            # mem[256] = 100
    li t1, 50
    amoadd.w t2, t1, (s1)   # t2 = 100, mem[256] = 150
    li a0, 11
    li t3, 100
    bne t2, t3, fail
    lw t4, 0(s1)
    li t5, 150
    bne t4, t5, fail

    # Test 12: amoadd.w with negative addend
    addi s7, s1, 4          # s7 = 260
    li t0, 200
    sw t0, 0(s7)            # mem[260] = 200
    li t1, -50
    amoadd.w t2, t1, (s7)   # t2 = 200, mem[260] = 150
    li a0, 12
    li t3, 200
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 150
    bne t4, t5, fail

    # Test 13: amoadd.w with negative value in memory
    addi s7, s1, 8          # s7 = 264
    li t0, -100
    sw t0, 0(s7)            # mem[264] = -100
    li t1, 250
    amoadd.w t2, t1, (s7)   # t2 = -100, mem[264] = 150
    li a0, 13
    li t3, -100
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 150
    bne t4, t5, fail

    # Test 14: amoadd.w adding zero
    addi s7, s1, 12         # s7 = 268
    li t0, 333
    sw t0, 0(s7)            # mem[268] = 333
    amoadd.w t2, zero, (s7) # t2 = 333, mem[268] = 333
    li a0, 14
    li t3, 333
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, t3, fail

    # Test 15: div instruction right before amoadd.w
    addi s7, s1, 16         # s7 = 272
    li t0, 100
    sw t0, 0(s7)            # mem[272] = 100
    li t1, 100
    li t2, 4
    div t3, t1, t2          # t3 = 25
    amoadd.w t4, t3, (s7)   # t4 = 100, mem[272] = 125
    li a0, 15
    li t5, 100
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 125
    bne t6, t0, fail

    # Test 16: Consecutive amoadd.w instructions
    addi s7, s1, 20         # s7 = 276
    li t0, 10
    sw t0, 0(s7)            # mem[276] = 10
    li t1, 5
    li t2, 7
    amoadd.w t3, t1, (s7)   # t3 = 10, mem[276] = 15
    amoadd.w t4, t2, (s7)   # t4 = 15, mem[276] = 22
    li a0, 16
    li t5, 10
    bne t3, t5, fail
    li t5, 15
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 22
    bne t6, t0, fail

    # Test 17: Memory load right before amoadd.w
    addi s7, s1, 24         # s7 = 280
    addi s8, s1, 28         # s8 = 284
    li t0, 50
    sw t0, 0(s7)            # mem[280] = 50
    li t0, 30
    sw t0, 0(s8)            # mem[284] = 30
    lw t1, 0(s7)            # t1 = 50
    li t2, 20
    amoadd.w t3, t2, (s8)   # t3 = 30, mem[284] = 50
    li a0, 17
    li t4, 50
    bne t1, t4, fail
    li t4, 30
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 50
    bne t5, t6, fail

    # Test 18: Memory store right after amoadd.w
    addi s7, s1, 32         # s7 = 288
    addi s8, s1, 36         # s8 = 292
    li t0, 60
    sw t0, 0(s7)            # mem[288] = 60
    li t1, 40
    amoadd.w t2, t1, (s7)   # t2 = 60, mem[288] = 100
    li t3, 999
    sw t3, 0(s8)            # mem[292] = 999
    li a0, 18
    li t4, 60
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 100
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 999
    bne t5, t6, fail

    # Test 19: Register update right before amoadd.w (forwarding test)
    addi s7, s1, 40         # s7 = 296
    li t0, 80
    sw t0, 0(s7)            # mem[296] = 80
    li t1, 15
    addi t2, t1, 5          # t2 = 20
    amoadd.w t3, t2, (s7)   # t3 = 80, mem[296] = 100
    li a0, 19
    li t4, 80
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 100
    bne t5, t6, fail

    # Test 20: amoadd.w overflow test
    addi s7, s1, 44         # s7 = 300
    li t0, 0x7FFFFFF0
    sw t0, 0(s7)            # mem[300] = 0x7FFFFFF0
    li t1, 0x20
    amoadd.w t2, t1, (s7)   # t2 = 0x7FFFFFF0, mem[300] = 0x80000010 (overflow)
    li a0, 20
    li t3, 0x7FFFFFF0
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x80000010
    bne t4, t5, fail

    # ============================================
    # AMOAND.W Tests - Tests 21-30
    # amoand.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = mem[rs1] & rs2
    # ============================================

    # Test 21: Basic amoand.w
    li t0, 0xFF
    sw t0, 0(s2)            # mem[512] = 0xFF
    li t1, 0x0F
    amoand.w t2, t1, (s2)   # t2 = 0xFF, mem[512] = 0x0F
    li a0, 21
    li t3, 0xFF
    bne t2, t3, fail
    lw t4, 0(s2)
    li t5, 0x0F
    bne t4, t5, fail

    # Test 22: amoand.w with all bits set
    addi s7, s2, 4          # s7 = 516
    li t0, 0xFFFFFFFF
    sw t0, 0(s7)            # mem[516] = 0xFFFFFFFF
    li t1, 0x12345678
    amoand.w t2, t1, (s7)   # t2 = 0xFFFFFFFF, mem[516] = 0x12345678
    li a0, 22
    li t3, 0xFFFFFFFF
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x12345678
    bne t4, t5, fail

    # Test 23: amoand.w result is zero
    addi s7, s2, 8          # s7 = 520
    li t0, 0xAAAAAAAA
    sw t0, 0(s7)            # mem[520] = 0xAAAAAAAA
    li t1, 0x55555555
    amoand.w t2, t1, (s7)   # t2 = 0xAAAAAAAA, mem[520] = 0
    li a0, 23
    li t3, 0xAAAAAAAA
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, zero, fail

    # Test 24: amoand.w with zero operand
    addi s7, s2, 12         # s7 = 524
    li t0, 0x12345678
    sw t0, 0(s7)            # mem[524] = 0x12345678
    amoand.w t2, zero, (s7) # t2 = 0x12345678, mem[524] = 0
    li a0, 24
    li t3, 0x12345678
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, zero, fail

    # Test 25: mul instruction right before amoand.w
    addi s7, s2, 16         # s7 = 528
    li t0, 0xFF00FF00
    sw t0, 0(s7)            # mem[528] = 0xFF00FF00
    li t1, 0x10
    li t2, 0x00FF00FF
    mul t3, t1, t2          # t3 = 0x0FF00FF0
    amoand.w t4, t3, (s7)   # t4 = 0xFF00FF00, mem[528] = 0x0F000F00
    li a0, 25
    li t5, 0xFF00FF00
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x0F000F00
    bne t6, t0, fail

    # Test 26: Consecutive amoand.w instructions
    addi s7, s2, 20         # s7 = 532
    li t0, 0xFFFF
    sw t0, 0(s7)            # mem[532] = 0xFFFF
    li t1, 0x0FFF
    li t2, 0x00FF
    amoand.w t3, t1, (s7)   # t3 = 0xFFFF, mem[532] = 0x0FFF
    amoand.w t4, t2, (s7)   # t4 = 0x0FFF, mem[532] = 0x00FF
    li a0, 26
    li t5, 0xFFFF
    bne t3, t5, fail
    li t5, 0x0FFF
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x00FF
    bne t6, t0, fail

    # Test 27: Memory load right before amoand.w
    addi s7, s2, 24         # s7 = 536
    addi s8, s2, 28         # s8 = 540
    li t0, 0xABCD
    sw t0, 0(s7)            # mem[536] = 0xABCD
    li t0, 0x1234
    sw t0, 0(s8)            # mem[540] = 0x1234
    lw t1, 0(s7)            # t1 = 0xABCD
    li t2, 0xFF00
    amoand.w t3, t2, (s8)   # t3 = 0x1234, mem[540] = 0x1200
    li a0, 27
    li t4, 0xABCD
    bne t1, t4, fail
    li t4, 0x1234
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 0x1200
    bne t5, t6, fail

    # Test 28: Memory store right after amoand.w
    addi s7, s2, 32         # s7 = 544
    addi s8, s2, 36         # s8 = 548
    li t0, 0xFF0F
    sw t0, 0(s7)            # mem[544] = 0xFF0F
    li t1, 0x0F0F
    amoand.w t2, t1, (s7)   # t2 = 0xFF0F, mem[544] = 0x0F0F
    li t3, 0x7777
    sw t3, 0(s8)            # mem[548] = 0x7777
    li a0, 28
    li t4, 0xFF0F
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 0x0F0F
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 0x7777
    bne t5, t6, fail

    # Test 29: Register update right before amoand.w (forwarding test)
    addi s7, s2, 40         # s7 = 552
    li t0, 0xFFF0
    sw t0, 0(s7)            # mem[552] = 0xFFF0
    li t1, 0xFF00
    ori t2, t1, 0xFF        # t2 = 0xFFFF
    amoand.w t3, t2, (s7)   # t3 = 0xFFF0, mem[552] = 0xFFF0
    li a0, 29
    li t4, 0xFFF0
    bne t3, t4, fail
    lw t5, 0(s7)
    bne t5, t4, fail

    # Test 30: amoand.w with negative values
    addi s7, s2, 44         # s7 = 556
    li t0, -1               # 0xFFFFFFFF
    sw t0, 0(s7)            # mem[556] = 0xFFFFFFFF
    li t1, 0xFF00FF00
    amoand.w t2, t1, (s7)   # t2 = 0xFFFFFFFF, mem[556] = 0xFF00FF00
    li a0, 30
    li t3, -1
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0xFF00FF00
    bne t4, t5, fail

    # ============================================
    # AMOOR.W Tests - Tests 31-40
    # amoor.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = mem[rs1] | rs2
    # ============================================

    # Test 31: Basic amoor.w
    li t0, 0x0F
    sw t0, 0(s3)            # mem[1024] = 0x0F
    li t1, 0xF0
    amoor.w t2, t1, (s3)    # t2 = 0x0F, mem[1024] = 0xFF
    li a0, 31
    li t3, 0x0F
    bne t2, t3, fail
    lw t4, 0(s3)
    li t5, 0xFF
    bne t4, t5, fail

    # Test 32: amoor.w with zero operand
    addi s7, s3, 4          # s7 = 1028
    li t0, 0x5555
    sw t0, 0(s7)            # mem[1028] = 0x5555
    amoor.w t2, zero, (s7)  # t2 = 0x5555, mem[1028] = 0x5555
    li a0, 32
    li t3, 0x5555
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, t3, fail

    # Test 33: amoor.w combining disjoint bits
    addi s7, s3, 8          # s7 = 1032
    li t0, 0xAAAAAAAA
    sw t0, 0(s7)            # mem[1032] = 0xAAAAAAAA
    li t1, 0x55555555
    amoor.w t2, t1, (s7)    # t2 = 0xAAAAAAAA, mem[1032] = 0xFFFFFFFF
    li a0, 33
    li t3, 0xAAAAAAAA
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0xFFFFFFFF
    bne t4, t5, fail

    # Test 34: amoor.w with overlapping bits
    addi s7, s3, 12         # s7 = 1036
    li t0, 0xFF00
    sw t0, 0(s7)            # mem[1036] = 0xFF00
    li t1, 0x0FF0
    amoor.w t2, t1, (s7)    # t2 = 0xFF00, mem[1036] = 0xFFF0
    li a0, 34
    li t3, 0xFF00
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0xFFF0
    bne t4, t5, fail

    # Test 35: rem instruction right before amoor.w
    addi s7, s3, 16         # s7 = 1040
    li t0, 0x100
    sw t0, 0(s7)            # mem[1040] = 0x100
    li t1, 1000
    li t2, 300
    rem t3, t1, t2          # t3 = 100 = 0x64
    amoor.w t4, t3, (s7)    # t4 = 0x100, mem[1040] = 0x164
    li a0, 35
    li t5, 0x100
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x164
    bne t6, t0, fail

    # Test 36: Consecutive amoor.w instructions
    addi s7, s3, 20         # s7 = 1044
    li t0, 0x0001
    sw t0, 0(s7)            # mem[1044] = 0x0001
    li t1, 0x0010
    li t2, 0x0100
    amoor.w t3, t1, (s7)    # t3 = 0x0001, mem[1044] = 0x0011
    amoor.w t4, t2, (s7)    # t4 = 0x0011, mem[1044] = 0x0111
    li a0, 36
    li t5, 0x0001
    bne t3, t5, fail
    li t5, 0x0011
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x0111
    bne t6, t0, fail

    # Test 37: Memory load right before amoor.w
    addi s7, s3, 24         # s7 = 1048
    addi s8, s3, 28         # s8 = 1052
    li t0, 0x8888
    sw t0, 0(s7)            # mem[1048] = 0x8888
    li t0, 0x0008
    sw t0, 0(s8)            # mem[1052] = 0x0008
    lw t1, 0(s7)            # t1 = 0x8888
    li t2, 0x0080
    amoor.w t3, t2, (s8)    # t3 = 0x0008, mem[1052] = 0x0088
    li a0, 37
    li t4, 0x8888
    bne t1, t4, fail
    li t4, 0x0008
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 0x0088
    bne t5, t6, fail

    # Test 38: Memory store right after amoor.w
    addi s7, s3, 32         # s7 = 1056
    addi s8, s3, 36         # s8 = 1060
    li t0, 0x1000
    sw t0, 0(s7)            # mem[1056] = 0x1000
    li t1, 0x0100
    amoor.w t2, t1, (s7)    # t2 = 0x1000, mem[1056] = 0x1100
    li t3, 0x2222
    sw t3, 0(s8)            # mem[1060] = 0x2222
    li a0, 38
    li t4, 0x1000
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 0x1100
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 0x2222
    bne t5, t6, fail

    # Test 39: Register update right before amoor.w (forwarding test)
    addi s7, s3, 40         # s7 = 1064
    li t0, 0x00C0
    sw t0, 0(s7)            # mem[1064] = 0x00C0
    li t1, 0x0003
    slli t2, t1, 2          # t2 = 0x000C
    amoor.w t3, t2, (s7)    # t3 = 0x00C0, mem[1064] = 0x00CC
    li a0, 39
    li t4, 0x00C0
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 0x00CC
    bne t5, t6, fail

    # Test 40: amoor.w with all zeros in memory
    addi s7, s3, 44         # s7 = 1068
    sw zero, 0(s7)          # mem[1068] = 0
    li t1, 0x12345678
    amoor.w t2, t1, (s7)    # t2 = 0, mem[1068] = 0x12345678
    li a0, 40
    bne t2, zero, fail
    lw t4, 0(s7)
    li t5, 0x12345678
    bne t4, t5, fail

    # ============================================
    # AMOXOR.W Tests - Tests 41-50
    # amoxor.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = mem[rs1] ^ rs2
    # ============================================

    # Test 41: Basic amoxor.w
    li t0, 0xFF
    sw t0, 0(s4)            # mem[2048] = 0xFF
    li t1, 0xF0
    amoxor.w t2, t1, (s4)   # t2 = 0xFF, mem[2048] = 0x0F
    li a0, 41
    li t3, 0xFF
    bne t2, t3, fail
    lw t4, 0(s4)
    li t5, 0x0F
    bne t4, t5, fail

    # Test 42: amoxor.w with same value (result zero)
    addi s7, s4, 4          # s7 = 2052
    li t0, 0x12345678
    sw t0, 0(s7)            # mem[2052] = 0x12345678
    li t1, 0x12345678
    amoxor.w t2, t1, (s7)   # t2 = 0x12345678, mem[2052] = 0
    li a0, 42
    li t3, 0x12345678
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, zero, fail

    # Test 43: amoxor.w with zero operand (identity)
    addi s7, s4, 8          # s7 = 2056
    li t0, 0xABCDEF00
    sw t0, 0(s7)            # mem[2056] = 0xABCDEF00
    amoxor.w t2, zero, (s7) # t2 = 0xABCDEF00, mem[2056] = 0xABCDEF00
    li a0, 43
    li t3, 0xABCDEF00
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, t3, fail

    # Test 44: amoxor.w toggling all bits
    addi s7, s4, 12         # s7 = 2060
    li t0, 0xAAAAAAAA
    sw t0, 0(s7)            # mem[2060] = 0xAAAAAAAA
    li t1, 0xFFFFFFFF
    amoxor.w t2, t1, (s7)   # t2 = 0xAAAAAAAA, mem[2060] = 0x55555555
    li a0, 44
    li t3, 0xAAAAAAAA
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x55555555
    bne t4, t5, fail

    # Test 45: divu instruction right before amoxor.w
    addi s7, s4, 16         # s7 = 2064
    li t0, 0xFF
    sw t0, 0(s7)            # mem[2064] = 0xFF
    li t1, 256
    li t2, 2
    divu t3, t1, t2         # t3 = 128 = 0x80
    amoxor.w t4, t3, (s7)   # t4 = 0xFF, mem[2064] = 0x7F
    li a0, 45
    li t5, 0xFF
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x7F
    bne t6, t0, fail

    # Test 46: Consecutive amoxor.w instructions
    addi s7, s4, 20         # s7 = 2068
    li t0, 0x00FF
    sw t0, 0(s7)            # mem[2068] = 0x00FF
    li t1, 0x0F0F
    li t2, 0x00F0
    amoxor.w t3, t1, (s7)   # t3 = 0x00FF, mem[2068] = 0x0FF0
    amoxor.w t4, t2, (s7)   # t4 = 0x0FF0, mem[2068] = 0x0F00
    li a0, 46
    li t5, 0x00FF
    bne t3, t5, fail
    li t5, 0x0FF0
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 0x0F00
    bne t6, t0, fail

    # Test 47: Memory load right before amoxor.w
    addi s7, s4, 24         # s7 = 2072
    addi s8, s4, 28         # s8 = 2076
    li t0, 0x3333
    sw t0, 0(s7)            # mem[2072] = 0x3333
    li t0, 0x5555
    sw t0, 0(s8)            # mem[2076] = 0x5555
    lw t1, 0(s7)            # t1 = 0x3333
    li t2, 0xFFFF
    amoxor.w t3, t2, (s8)   # t3 = 0x5555, mem[2076] = 0xAAAA
    li a0, 47
    li t4, 0x3333
    bne t1, t4, fail
    li t4, 0x5555
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 0xAAAA
    bne t5, t6, fail

    # Test 48: Memory store right after amoxor.w
    addi s7, s4, 32         # s7 = 2080
    addi s8, s4, 36         # s8 = 2084
    li t0, 0x7070
    sw t0, 0(s7)            # mem[2080] = 0x7070
    li t1, 0x0707
    amoxor.w t2, t1, (s7)   # t2 = 0x7070, mem[2080] = 0x7777
    li t3, 0x4444
    sw t3, 0(s8)            # mem[2084] = 0x4444
    li a0, 48
    li t4, 0x7070
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 0x7777
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 0x4444
    bne t5, t6, fail

    # Test 49: Register update right before amoxor.w (forwarding test)
    addi s7, s4, 40         # s7 = 2088
    li t0, 0x00AA
    sw t0, 0(s7)            # mem[2088] = 0x00AA
    li t1, 0x0055
    xori t2, t1, 0xFF       # t2 = 0x00AA
    amoxor.w t3, t2, (s7)   # t3 = 0x00AA, mem[2088] = 0
    li a0, 49
    li t4, 0x00AA
    bne t3, t4, fail
    lw t5, 0(s7)
    bne t5, zero, fail

    # Test 50: Double XOR returns original value
    addi s7, s4, 44         # s7 = 2092
    li t0, 0x12345678
    sw t0, 0(s7)            # mem[2092] = 0x12345678
    li t1, 0xABCDEF00
    amoxor.w t2, t1, (s7)   # First XOR
    amoxor.w t3, t1, (s7)   # Second XOR with same value
    li a0, 50
    lw t4, 0(s7)            # Should be original value
    li t5, 0x12345678
    bne t4, t5, fail

    # ============================================
    # AMOMAX.W Tests - Tests 51-60
    # amomax.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = max(mem[rs1], rs2) (signed)
    # ============================================

    # Test 51: Basic amomax.w - rs2 is larger
    li t0, 100
    sw t0, 0(s5)            # mem[3072] = 100
    li t1, 200
    amomax.w t2, t1, (s5)   # t2 = 100, mem[3072] = 200
    li a0, 51
    li t3, 100
    bne t2, t3, fail
    lw t4, 0(s5)
    li t5, 200
    bne t4, t5, fail

    # Test 52: amomax.w - mem is larger
    addi s7, s5, 4          # s7 = 3076
    li t0, 500
    sw t0, 0(s7)            # mem[3076] = 500
    li t1, 300
    amomax.w t2, t1, (s7)   # t2 = 500, mem[3076] = 500
    li a0, 52
    li t3, 500
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 500
    bne t4, t5, fail

    # Test 53: amomax.w with negative values
    addi s7, s5, 8          # s7 = 3080
    li t0, -100
    sw t0, 0(s7)            # mem[3080] = -100
    li t1, -50
    amomax.w t2, t1, (s7)   # t2 = -100, mem[3080] = -50 (larger)
    li a0, 53
    li t3, -100
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, -50
    bne t4, t5, fail

    # Test 54: amomax.w with positive and negative
    addi s7, s5, 12         # s7 = 3084
    li t0, -10
    sw t0, 0(s7)            # mem[3084] = -10
    li t1, 10
    amomax.w t2, t1, (s7)   # t2 = -10, mem[3084] = 10 (positive is larger)
    li a0, 54
    li t3, -10
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 10
    bne t4, t5, fail

    # Test 55: mul instruction right before amomax.w
    addi s7, s5, 16         # s7 = 3088
    li t0, 50
    sw t0, 0(s7)            # mem[3088] = 50
    li t1, 10
    li t2, 10
    mul t3, t1, t2          # t3 = 100
    amomax.w t4, t3, (s7)   # t4 = 50, mem[3088] = 100
    li a0, 55
    li t5, 50
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 100
    bne t6, t0, fail

    # Test 56: Consecutive amomax.w instructions
    addi s7, s5, 20         # s7 = 3092
    li t0, 10
    sw t0, 0(s7)            # mem[3092] = 10
    li t1, 30
    li t2, 20
    amomax.w t3, t1, (s7)   # t3 = 10, mem[3092] = 30
    amomax.w t4, t2, (s7)   # t4 = 30, mem[3092] = 30 (30 > 20)
    li a0, 56
    li t5, 10
    bne t3, t5, fail
    li t5, 30
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 30
    bne t6, t0, fail

    # Test 57: Memory load right before amomax.w
    addi s7, s5, 24         # s7 = 3096
    addi s8, s5, 28         # s8 = 3100
    li t0, 150
    sw t0, 0(s7)            # mem[3096] = 150
    li t0, 75
    sw t0, 0(s8)            # mem[3100] = 75
    lw t1, 0(s7)            # t1 = 150
    li t2, 200
    amomax.w t3, t2, (s8)   # t3 = 75, mem[3100] = 200
    li a0, 57
    li t4, 150
    bne t1, t4, fail
    li t4, 75
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 200
    bne t5, t6, fail

    # Test 58: Memory store right after amomax.w
    addi s7, s5, 32         # s7 = 3104
    addi s8, s5, 36         # s8 = 3108
    li t0, 80
    sw t0, 0(s7)            # mem[3104] = 80
    li t1, 120
    amomax.w t2, t1, (s7)   # t2 = 80, mem[3104] = 120
    li t3, 999
    sw t3, 0(s8)            # mem[3108] = 999
    li a0, 58
    li t4, 80
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 120
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 999
    bne t5, t6, fail

    # Test 59: Register update right before amomax.w (forwarding test)
    addi s7, s5, 40         # s7 = 3112
    li t0, 60
    sw t0, 0(s7)            # mem[3112] = 60
    li t1, 30
    addi t2, t1, 50         # t2 = 80
    amomax.w t3, t2, (s7)   # t3 = 60, mem[3112] = 80
    li a0, 59
    li t4, 60
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 80
    bne t5, t6, fail

    # Test 60: amomax.w with equal values
    addi s7, s5, 44         # s7 = 3116
    li t0, 777
    sw t0, 0(s7)            # mem[3116] = 777
    li t1, 777
    amomax.w t2, t1, (s7)   # t2 = 777, mem[3116] = 777
    li a0, 60
    li t3, 777
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, t3, fail

    # ============================================
    # AMOMIN.W Tests - Tests 61-70
    # amomin.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = min(mem[rs1], rs2) (signed)
    # ============================================

    # Test 61: Basic amomin.w - rs2 is smaller
    li t0, 200
    sw t0, 0(s6)            # mem[3584] = 200
    li t1, 100
    amomin.w t2, t1, (s6)   # t2 = 200, mem[3584] = 100
    li a0, 61
    li t3, 200
    bne t2, t3, fail
    lw t4, 0(s6)
    li t5, 100
    bne t4, t5, fail

    # Test 62: amomin.w - mem is smaller
    addi s7, s6, 4          # s7 = 3588
    li t0, 50
    sw t0, 0(s7)            # mem[3588] = 50
    li t1, 300
    amomin.w t2, t1, (s7)   # t2 = 50, mem[3588] = 50
    li a0, 62
    li t3, 50
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 50
    bne t4, t5, fail

    # Test 63: amomin.w with negative values
    addi s7, s6, 8          # s7 = 3592
    li t0, -50
    sw t0, 0(s7)            # mem[3592] = -50
    li t1, -100
    amomin.w t2, t1, (s7)   # t2 = -50, mem[3592] = -100 (smaller)
    li a0, 63
    li t3, -50
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, -100
    bne t4, t5, fail

    # Test 64: amomin.w with positive and negative
    addi s7, s6, 12         # s7 = 3596
    li t0, 10
    sw t0, 0(s7)            # mem[3596] = 10
    li t1, -10
    amomin.w t2, t1, (s7)   # t2 = 10, mem[3596] = -10 (negative is smaller)
    li a0, 64
    li t3, 10
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, -10
    bne t4, t5, fail

    # Test 65: div instruction right before amomin.w
    addi s7, s6, 16         # s7 = 3600
    li t0, 100
    sw t0, 0(s7)            # mem[3600] = 100
    li t1, 100
    li t2, 4
    div t3, t1, t2          # t3 = 25
    amomin.w t4, t3, (s7)   # t4 = 100, mem[3600] = 25
    li a0, 65
    li t5, 100
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 25
    bne t6, t0, fail

    # Test 66: Consecutive amomin.w instructions
    addi s7, s6, 20         # s7 = 3604
    li t0, 50
    sw t0, 0(s7)            # mem[3604] = 50
    li t1, 30
    li t2, 40
    amomin.w t3, t1, (s7)   # t3 = 50, mem[3604] = 30
    amomin.w t4, t2, (s7)   # t4 = 30, mem[3604] = 30 (30 < 40)
    li a0, 66
    li t5, 50
    bne t3, t5, fail
    li t5, 30
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 30
    bne t6, t0, fail

    # Test 67: Memory load right before amomin.w
    addi s7, s6, 24         # s7 = 3608
    addi s8, s6, 28         # s8 = 3612
    li t0, 300
    sw t0, 0(s7)            # mem[3608] = 300
    li t0, 500
    sw t0, 0(s8)            # mem[3612] = 500
    lw t1, 0(s7)            # t1 = 300
    li t2, 100
    amomin.w t3, t2, (s8)   # t3 = 500, mem[3612] = 100
    li a0, 67
    li t4, 300
    bne t1, t4, fail
    li t4, 500
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 100
    bne t5, t6, fail

    # Test 68: Memory store right after amomin.w
    addi s7, s6, 32         # s7 = 3616
    addi s8, s6, 36         # s8 = 3620
    li t0, 250
    sw t0, 0(s7)            # mem[3616] = 250
    li t1, 150
    amomin.w t2, t1, (s7)   # t2 = 250, mem[3616] = 150
    li t3, 888
    sw t3, 0(s8)            # mem[3620] = 888
    li a0, 68
    li t4, 250
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 150
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 888
    bne t5, t6, fail

    # Test 69: Register update right before amomin.w (forwarding test)
    addi s7, s6, 40         # s7 = 3624
    li t0, 90
    sw t0, 0(s7)            # mem[3624] = 90
    li t1, 100
    addi t2, t1, -50        # t2 = 50
    amomin.w t3, t2, (s7)   # t3 = 90, mem[3624] = 50
    li a0, 69
    li t4, 90
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 50
    bne t5, t6, fail

    # Test 70: amomin.w with equal values
    addi s7, s6, 44         # s7 = 3628
    li t0, 333
    sw t0, 0(s7)            # mem[3628] = 333
    li t1, 333
    amomin.w t2, t1, (s7)   # t2 = 333, mem[3628] = 333
    li a0, 70
    li t3, 333
    bne t2, t3, fail
    lw t4, 0(s7)
    bne t4, t3, fail

    # ============================================
    # AMOMAXU.W Tests - Tests 71-80
    # amomaxu.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = max(mem[rs1], rs2) (unsigned)
    # ============================================

    # Test 71: Basic amomaxu.w - rs2 is larger
    addi s7, s6, 48         # s7 = 3632
    li t0, 100
    sw t0, 0(s7)            # mem[3632] = 100
    li t1, 200
    amomaxu.w t2, t1, (s7)  # t2 = 100, mem[3632] = 200
    li a0, 71
    li t3, 100
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 200
    bne t4, t5, fail

    # Test 72: amomaxu.w - mem is larger
    addi s7, s6, 52         # s7 = 3636
    li t0, 500
    sw t0, 0(s7)            # mem[3636] = 500
    li t1, 300
    amomaxu.w t2, t1, (s7)  # t2 = 500, mem[3636] = 500
    li a0, 72
    li t3, 500
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 500
    bne t4, t5, fail

    # Test 73: amomaxu.w with "negative" value (large unsigned)
    # -1 = 0xFFFFFFFF is the largest unsigned value
    addi s7, s6, 56         # s7 = 3640
    li t0, 100
    sw t0, 0(s7)            # mem[3640] = 100
    li t1, -1               # t1 = 0xFFFFFFFF (largest unsigned)
    amomaxu.w t2, t1, (s7)  # t2 = 100, mem[3640] = 0xFFFFFFFF
    li a0, 73
    li t3, 100
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, -1
    bne t4, t5, fail

    # Test 74: amomaxu.w - mem has "negative" (large unsigned)
    addi s7, s6, 60         # s7 = 3644
    li t0, -1               # 0xFFFFFFFF
    sw t0, 0(s7)            # mem[3644] = 0xFFFFFFFF
    li t1, 100
    amomaxu.w t2, t1, (s7)  # t2 = 0xFFFFFFFF, mem[3644] = 0xFFFFFFFF (larger)
    li a0, 74
    li t3, -1
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, -1
    bne t4, t5, fail

    # Test 75: mul instruction right before amomaxu.w
    addi s7, s6, 64         # s7 = 3648
    li t0, 50
    sw t0, 0(s7)            # mem[3648] = 50
    li t1, 10
    li t2, 10
    mul t3, t1, t2          # t3 = 100
    amomaxu.w t4, t3, (s7)  # t4 = 50, mem[3648] = 100
    li a0, 75
    li t5, 50
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 100
    bne t6, t0, fail

    # Test 76: Consecutive amomaxu.w instructions
    addi s7, s6, 68         # s7 = 3652
    li t0, 10
    sw t0, 0(s7)            # mem[3652] = 10
    li t1, 30
    li t2, 20
    amomaxu.w t3, t1, (s7)  # t3 = 10, mem[3652] = 30
    amomaxu.w t4, t2, (s7)  # t4 = 30, mem[3652] = 30 (30 > 20)
    li a0, 76
    li t5, 10
    bne t3, t5, fail
    li t5, 30
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 30
    bne t6, t0, fail

    # Test 77: Memory load right before amomaxu.w
    addi s7, s6, 72         # s7 = 3656
    addi s8, s6, 76         # s8 = 3660
    li t0, 150
    sw t0, 0(s7)            # mem[3656] = 150
    li t0, 75
    sw t0, 0(s8)            # mem[3660] = 75
    lw t1, 0(s7)            # t1 = 150
    li t2, 200
    amomaxu.w t3, t2, (s8)  # t3 = 75, mem[3660] = 200
    li a0, 77
    li t4, 150
    bne t1, t4, fail
    li t4, 75
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 200
    bne t5, t6, fail

    # Test 78: Memory store right after amomaxu.w
    addi s7, s6, 80         # s7 = 3664
    addi s8, s6, 84         # s8 = 3668
    li t0, 80
    sw t0, 0(s7)            # mem[3664] = 80
    li t1, 120
    amomaxu.w t2, t1, (s7)  # t2 = 80, mem[3664] = 120
    li t3, 999
    sw t3, 0(s8)            # mem[3668] = 999
    li a0, 78
    li t4, 80
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 120
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 999
    bne t5, t6, fail

    # Test 79: Register update right before amomaxu.w (forwarding test)
    addi s7, s6, 88         # s7 = 3672
    li t0, 60
    sw t0, 0(s7)            # mem[3672] = 60
    li t1, 30
    addi t2, t1, 50         # t2 = 80
    amomaxu.w t3, t2, (s7)  # t3 = 60, mem[3672] = 80
    li a0, 79
    li t4, 60
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 80
    bne t5, t6, fail

    # Test 80: amomaxu.w comparing 0x80000000 and 0x7FFFFFFF
    # Unsigned: 0x80000000 > 0x7FFFFFFF (opposite of signed)
    addi s7, s6, 92         # s7 = 3676
    li t0, 0x7FFFFFFF
    sw t0, 0(s7)            # mem[3676] = 0x7FFFFFFF
    li t1, 0x80000000
    amomaxu.w t2, t1, (s7)  # t2 = 0x7FFFFFFF, mem[3676] = 0x80000000 (larger unsigned)
    li a0, 80
    li t3, 0x7FFFFFFF
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x80000000
    bne t4, t5, fail

    # ============================================
    # AMOMINU.W Tests - Tests 81-90
    # amominu.w rd, rs2, (rs1): rd = mem[rs1]; mem[rs1] = min(mem[rs1], rs2) (unsigned)
    # ============================================

    # Test 81: Basic amominu.w - rs2 is smaller
    addi s7, s6, 96         # s7 = 3680
    li t0, 200
    sw t0, 0(s7)            # mem[3680] = 200
    li t1, 100
    amominu.w t2, t1, (s7)  # t2 = 200, mem[3680] = 100
    li a0, 81
    li t3, 200
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 100
    bne t4, t5, fail

    # Test 82: amominu.w - mem is smaller
    addi s7, s6, 100        # s7 = 3684
    li t0, 50
    sw t0, 0(s7)            # mem[3684] = 50
    li t1, 300
    amominu.w t2, t1, (s7)  # t2 = 50, mem[3684] = 50
    li a0, 82
    li t3, 50
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 50
    bne t4, t5, fail

    # Test 83: amominu.w with "negative" value (large unsigned)
    # -1 = 0xFFFFFFFF is the largest unsigned, so 100 is smaller
    addi s7, s6, 104        # s7 = 3688
    li t0, -1               # 0xFFFFFFFF
    sw t0, 0(s7)            # mem[3688] = 0xFFFFFFFF
    li t1, 100
    amominu.w t2, t1, (s7)  # t2 = 0xFFFFFFFF, mem[3688] = 100 (smaller)
    li a0, 83
    li t3, -1
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 100
    bne t4, t5, fail

    # Test 84: amominu.w - rs2 has "negative" (large unsigned)
    addi s7, s6, 108        # s7 = 3692
    li t0, 100
    sw t0, 0(s7)            # mem[3692] = 100
    li t1, -1               # 0xFFFFFFFF
    amominu.w t2, t1, (s7)  # t2 = 100, mem[3692] = 100 (smaller)
    li a0, 84
    li t3, 100
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 100
    bne t4, t5, fail

    # Test 85: div instruction right before amominu.w
    addi s7, s6, 112        # s7 = 3696
    li t0, 100
    sw t0, 0(s7)            # mem[3696] = 100
    li t1, 100
    li t2, 4
    div t3, t1, t2          # t3 = 25
    amominu.w t4, t3, (s7)  # t4 = 100, mem[3696] = 25
    li a0, 85
    li t5, 100
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 25
    bne t6, t0, fail

    # Test 86: Consecutive amominu.w instructions
    addi s7, s6, 116        # s7 = 3700
    li t0, 50
    sw t0, 0(s7)            # mem[3700] = 50
    li t1, 30
    li t2, 40
    amominu.w t3, t1, (s7)  # t3 = 50, mem[3700] = 30
    amominu.w t4, t2, (s7)  # t4 = 30, mem[3700] = 30 (30 < 40)
    li a0, 86
    li t5, 50
    bne t3, t5, fail
    li t5, 30
    bne t4, t5, fail
    lw t6, 0(s7)
    li t0, 30
    bne t6, t0, fail

    # Test 87: Memory load right before amominu.w
    addi s7, s6, 120        # s7 = 3704
    addi s8, s6, 124        # s8 = 3708
    li t0, 300
    sw t0, 0(s7)            # mem[3704] = 300
    li t0, 500
    sw t0, 0(s8)            # mem[3708] = 500
    lw t1, 0(s7)            # t1 = 300
    li t2, 100
    amominu.w t3, t2, (s8)  # t3 = 500, mem[3708] = 100
    li a0, 87
    li t4, 300
    bne t1, t4, fail
    li t4, 500
    bne t3, t4, fail
    lw t5, 0(s8)
    li t6, 100
    bne t5, t6, fail

    # Test 88: Memory store right after amominu.w
    addi s7, s6, 128        # s7 = 3712
    addi s8, s6, 132        # s8 = 3716
    li t0, 250
    sw t0, 0(s7)            # mem[3712] = 250
    li t1, 150
    amominu.w t2, t1, (s7)  # t2 = 250, mem[3712] = 150
    li t3, 888
    sw t3, 0(s8)            # mem[3716] = 888
    li a0, 88
    li t4, 250
    bne t2, t4, fail
    lw t5, 0(s7)
    li t6, 150
    bne t5, t6, fail
    lw t5, 0(s8)
    li t6, 888
    bne t5, t6, fail

    # Test 89: Register update right before amominu.w (forwarding test)
    addi s7, s6, 136        # s7 = 3720
    li t0, 90
    sw t0, 0(s7)            # mem[3720] = 90
    li t1, 100
    addi t2, t1, -50        # t2 = 50
    amominu.w t3, t2, (s7)  # t3 = 90, mem[3720] = 50
    li a0, 89
    li t4, 90
    bne t3, t4, fail
    lw t5, 0(s7)
    li t6, 50
    bne t5, t6, fail

    # Test 90: amominu.w comparing 0x80000000 and 0x7FFFFFFF
    # Unsigned: 0x7FFFFFFF < 0x80000000 (opposite of signed)
    addi s7, s6, 140        # s7 = 3724
    li t0, 0x80000000
    sw t0, 0(s7)            # mem[3724] = 0x80000000
    li t1, 0x7FFFFFFF
    amominu.w t2, t1, (s7)  # t2 = 0x80000000, mem[3724] = 0x7FFFFFFF (smaller unsigned)
    li a0, 90
    li t3, 0x80000000
    bne t2, t3, fail
    lw t4, 0(s7)
    li t5, 0x7FFFFFFF
    bne t4, t5, fail

    # ============================================
    # All tests passed
    # ============================================
    li a0, 0

fail:
    ecall

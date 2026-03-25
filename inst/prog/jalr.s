.section .text
    .globl _start

_start:
    # Initialize a0 to 0. This register will track successful returns.
    addi a0, x0, 0
    addi t1, x0, 1024

loop:
    # --- Call Site 1 ---
    # jal rd=ra (x1) hints the hardware to PUSH to RAS
    jal ra, target_func
    # Upon return, increment counter
    addi a0, a0, 1

    # --- Call Site 2 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 3 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 4 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 5 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 6 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 7 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 8 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 9 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 10 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 11 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 12 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 13 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 14 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 15 ---
    jal ra, target_func
    addi a0, a0, 1

    # --- Call Site 16 ---
    jal ra, target_func
    addi a0, a0, 1

    blt a0, t1, loop
    jal x0, end


# --- Shared Function ---
target_func:
    # Perform some dummy work (optional)
    addi t0, x0, 1
    
    # Return to caller
    # jalr rd=x0, rs1=ra (x1) hints the hardware to POP from RAS
    jalr x0, ra, 0

# --- End of Test ---
end:
    # If successful, a0 should equal 16 (0x10)
    .insn r 0x2B, 0, 0, x0, a0, x0   # Print a0

# Prints a1 bytes from memory starting at address a0.
# "Print" uses custom instruction: .insn r 0x2B, 1, 0, x0, reg, x0

.globl print_string

print_string:
    beqz a1, done           # If a1 == 0, nothing to print
loop:
    lb t0, 0(a0)            # Load byte from memory at a0
    .insn r 0x2B, 1, 0, x0, t0, x0  # Print the byte in t0
    addi a0, a0, 1          # Advance to next byte
    addi a1, a1, -1         # Decrement remaining count
    bnez a1, loop            # Loop if bytes remain
done:
    jalr x0, 0(x1)
    
NAME=${1:-code}

# For system code only
TRAP_START=64
PROGRAM_START=1024
INITIAL_MSTATUS=6272
DMEM_SIZE=32768
INITIAL_SP=1024
INITIAL_KSP=$DMEM_SIZE

# Used in user programs
MTIME_ADDRESS=$DMEM_SIZE
MTIMECMP_ADDRESS=$((DMEM_SIZE+4))

cat << EOF > constants.S
.equ TRAP_START, $TRAP_START
.equ PROGRAM_START, $PROGRAM_START
.equ INITIAL_MSTATUS, $INITIAL_MSTATUS
.equ DMEM_SIZE, $DMEM_SIZE
.equ MTIME_ADDRESS, $MTIME_ADDRESS
.equ MTIMECMP_ADDRESS, $MTIMECMP_ADDRESS
.equ INITIAL_SP, $INITIAL_SP
.equ INITIAL_KSP, $INITIAL_KSP
EOF

cat << EOF > constants.ld
TRAP_START = $TRAP_START;
PROGRAM_START = $PROGRAM_START;
INITIAL_MSTATUS = $INITIAL_MSTATUS;
DMEM_SIZE = $DMEM_SIZE;
MTIME_ADDRESS = $MTIME_ADDRESS;
MTIMECMP_ADDRESS = $MTIMECMP_ADDRESS;
INITIAL_SP = $INITIAL_SP;
INITIAL_KSP = $INITIAL_KSP;
EOF

riscv64-unknown-elf-as -march=rv32ima_zicsr -mabi=ilp32 --defsym MTIME_ADDRESS=$MTIME_ADDRESS --defsym MTIMECMP_ADDRESS=$MTIMECMP_ADDRESS -o main.o $NAME.s
riscv64-unknown-elf-as -march=rv32ima_zicsr -mabi=ilp32 -o trap.o trap.s
riscv64-unknown-elf-as -march=rv32ima_zicsr -mabi=ilp32 -o terminate.o terminate.s
riscv64-unknown-elf-as -march=rv32ima_zicsr -mabi=ilp32 -o start.o start.s
riscv64-unknown-elf-as -march=rv32ima_zicsr -mabi=ilp32 -o print_string.o print_string.s

riscv64-unknown-elf-ld -m elf32lriscv -nostdlib -T linker.ld -o main.elf trap.o terminate.o start.o print_string.o main.o
riscv64-unknown-elf-objcopy -O binary --only-section=.text main.elf main.bin
hexdump -v -e '1/4 "%08x\n"' main.bin > main.hex
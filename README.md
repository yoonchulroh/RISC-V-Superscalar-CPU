# RISC-V Superscalar CPU

A 2-way superscalar, in-order RISC-V processor written in Verilog, implementing
**RV32IMA_Zicsr** with machine-mode traps, a timer interrupt, branch prediction,
and a UART front panel. It runs in Verilator and synthesizes for an FPGA.

Programs are assembled with the standard `riscv64-unknown-elf` toolchain, streamed
into the core over UART, and print their output back over the same link.

---

## Features

- **2-way superscalar, in-order dual issue** with an asymmetric second pipe
- **Six pipeline stages** — IF, ID, EX, BR, MEM, WB — behind a separate PC-select/predict stage
- **Full forwarding** between both pipes at every stage, plus a separate CSR forwarding path
- **Branch prediction**: gshare (global history XOR PC index) with a 2-bit counter table, a tagged branch-target buffer, and a return-address stack
- **RV32M** in the main pipe: a 3-stage pipelined multiplier and an iterative divider
- **RV32A**: `lr.w` / `sc.w` with a reservation set, and the AMO instructions expanded into micro-ops by the decoder
- **Zicsr + machine mode**: `mstatus`, `mtvec`, `mepc`, `mcause`, `mscratch`, `mtval`, `mie`, `mip`, with `ecall`, `ebreak`, `mret`, illegal-instruction, instruction-access-fault and misaligned-fetch traps
- **Memory-mapped timer** (`mtime` / `mtimecmp`) driving the machine timer interrupt
- **Byte-banked data memory** that handles fully unaligned loads and stores in one access
- **UART bootloader and console** — instructions in, printed values out

---

## Getting started

### Run a program in simulation

```bash
cd inst
./verilator.sh prog/fibonacci
```

### Run on hardware

Synthesize `srcs/top.v` in Vivado (add all of `srcs/` except `top_for_verilator.v`,
and add a `clk_wiz_0` IP that produces the CPU clock from the board oscillator).
Then build the host tool and run:

```bash
cd inst
g++ -O2 -pthread -o host host.cpp
./run.sh prog/fibonacci
```

Adjust `SERIAL_PORT` in `host.cpp` if your board does not appear as `/dev/ttyUSB1`.
`CLK_FREQUENCY` in `top.v` (50 MHz by default) must match the clock the wizard
produces, since it sets the UART divisor.

---

## Test programs

`inst/prog/` contains the programs used to exercise each part of the design:

| Area | Programs |
| --- | --- |
| Base integer | `fibonacci`, `naturalsum`, `register`, `load`, `parallel-ritype`, `data-hazard` |
| Control flow | `branch`, `jump`, `jalr`, `two-bit-prediction`, `gshare`, `mpki` |
| M extension | `multiplier`, `divider`, `mul_test`, `all_mul`, `all_div` |
| A extension | `atomic`, `atomic2`, `reserve`, `reserve2` |
| CSRs and traps | `csr`, `csrrw`, `extra-csr`, `mstatus`, `mcause`, `ecall`, `context_save` |
| Memory | `unaligned` |
| End to end | `helloworld`, `comprehensive` |

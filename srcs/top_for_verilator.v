`timescale 1ns / 1ps

module top (
    input clk,
    input reset,
    input uart_input,
    output uart_output);

    parameter CLK_FREQUENCY = 100_000_000;
    parameter BAUD_RATE = 115_200;
    parameter BUFFER_SIZE = 200;
    parameter MAX_BITS_TO_SEND = 32;
    parameter MEM_SIZE = 32768;
    parameter NEXT_PC_PREDICTOR_BUFFER_SIZE = 64;
    parameter GLOBAL_HISTORY_REGISTER_SIZE = 3;
    parameter RETURN_ADDRESS_STACK_SIZE = 8;
    parameter REGISTER_COUNT = 32;
    parameter PROGRAM_START_ADDRESS = 0;

    parameter START_EXECUTION_OPCODE = 7'b0001011; // custom-0 opcode
    parameter PRINT_OPCODE = 7'b0101011; // custom-1 opcode
    
    localparam CLKS_PER_BIT = CLK_FREQUENCY / BAUD_RATE;

    // Signals from instruction_fetcher to instruction_memory 
    wire new_instruction_given;
    wire [31:0] new_instruction;

    // Signal from CPU to instruction_memory
    wire [31:0] instruction_address;

    // Signal from instruction_memory to CPU
    wire start_execution;
    wire [31:0] instruction_from_IMem0, instruction_from_IMem1;

    instruction_fetcher #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .START_EXECUTION_OPCODE(START_EXECUTION_OPCODE)
    ) instruction_fetcher (
        .clk(clk),
        .reset(reset),
        .uart_input(uart_input),

        .start_execution(start_execution),
        .new_instruction_given(new_instruction_given),
        .new_instruction(new_instruction)
    );

    IMem #(
        .IMEM_SIZE(MEM_SIZE)
    ) instruction_memory (
        .clk(clk),
        .reset(reset),
        .instruction_address(instruction_address),
        .new_instruction_given(new_instruction_given),
        .new_instruction(new_instruction),

        .instruction0(instruction_from_IMem0),
        .instruction1(instruction_from_IMem1)
    );

    CPU #(
        .PRINT_OPCODE(PRINT_OPCODE),
        .START_EXECUTION_OPCODE(START_EXECUTION_OPCODE),
        .IMEM_SIZE(MEM_SIZE),
        .DMEM_SIZE(MEM_SIZE),
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .BUFFER_SIZE(BUFFER_SIZE),
        .MAX_BITS_TO_SEND(MAX_BITS_TO_SEND),
        .NEXT_PC_PREDICTOR_BUFFER_SIZE(NEXT_PC_PREDICTOR_BUFFER_SIZE),
        .GLOBAL_HISTORY_REGISTER_SIZE(GLOBAL_HISTORY_REGISTER_SIZE),
        .RETURN_ADDRESS_STACK_SIZE(RETURN_ADDRESS_STACK_SIZE),
        .REGISTER_COUNT(REGISTER_COUNT),
        .PROGRAM_START_ADDRESS(PROGRAM_START_ADDRESS)
    ) core (
        .clk(clk),
        .reset(reset),
        .start_execution(start_execution),
        .instruction_from_IMem0(instruction_from_IMem0),
        .instruction_from_IMem1(instruction_from_IMem1),

        .instruction_address(instruction_address),
        .uart_output(uart_output)
    );

endmodule

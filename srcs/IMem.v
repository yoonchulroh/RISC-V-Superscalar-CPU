`timescale 1ns / 1ps

module IMem #(
    parameter IMEM_SIZE = 400 // in bytes, should be a multiple of 8
) (
    input clk,
    input reset,

    input [31:0] instruction_address, // lower 2 bits are ignored
    input new_instruction_given, // should be a pulse
    input [31:0] new_instruction,

    output reg [31:0] instruction0,
    output reg [31:0] instruction1
);

    localparam MAX_IMEM_ADDRESS = IMEM_SIZE - 4;

    // Should be inferred as BRAM
    reg [31:0] BRAM_instructions0 [(IMEM_SIZE / 8) - 1 : 0];
    reg [31:0] BRAM_instructions1 [(IMEM_SIZE / 8) - 1 : 0];
    reg [$clog2(IMEM_SIZE / 8) - 1 : 0] BRAM_instructions_address0;
    reg [$clog2(IMEM_SIZE / 8) - 1 : 0] BRAM_instructions_address1;
    reg [31:0] BRAM_instructions_data_to_write0;
    reg [31:0] BRAM_instructions_data_to_write1;
    reg BRAM_instructions_read0, BRAM_instructions_read1, BRAM_instructions_write0, BRAM_instructions_write1;
    reg [31:0] BRAM_instructions_readdata0;
    reg [31:0] BRAM_instructions_readdata1;

    reg [31:0] invalid_address_start;

    reg latched_reset;
    reg [31:0] latched_instruction_address;
    reg latched_BRAM_instructions_read0, latched_BRAM_instructions_read1;

    always @(*) begin
        BRAM_instructions_read0 = 0;
        BRAM_instructions_read1 = 0;
        BRAM_instructions_write0 = 0;
        BRAM_instructions_write1 = 0;

        if (new_instruction_given) begin
            BRAM_instructions_address0 = invalid_address_start >> 3; 
            BRAM_instructions_address1 = invalid_address_start >> 3;
        end
        else begin
            BRAM_instructions_address0 = (instruction_address[2] == 1) ? (instruction_address >> 3) + 1 : (instruction_address >> 3);
            BRAM_instructions_address1 = instruction_address >> 3;
        end

        BRAM_instructions_data_to_write0 = new_instruction;
        BRAM_instructions_data_to_write1 = new_instruction;

        if (latched_reset) ;
        else begin
            if (new_instruction_given && invalid_address_start <= MAX_IMEM_ADDRESS) begin
                if (invalid_address_start[2] == 1) BRAM_instructions_write1 = 1;
                else BRAM_instructions_write0 = 1;
            end
            else begin
                if (instruction_address[2] == 0) begin
                    if (instruction_address < invalid_address_start) BRAM_instructions_read0 = 1;
                    if ((instruction_address < invalid_address_start - 4) && invalid_address_start != 0) BRAM_instructions_read1 = 1;
                end
                else begin
                    if (instruction_address < invalid_address_start) BRAM_instructions_read1 = 1;
                    if ((instruction_address < invalid_address_start - 4) && invalid_address_start != 0) BRAM_instructions_read0 = 1;
                end
            end
        end
    end

    always @(posedge clk) latched_reset <= reset;

    always @(negedge clk) begin
        if (latched_reset) begin
            invalid_address_start <= 0;
        end
        else begin
            if (new_instruction_given && invalid_address_start <= MAX_IMEM_ADDRESS) invalid_address_start <= invalid_address_start + 4;
        end

        latched_instruction_address <= instruction_address;
        latched_BRAM_instructions_read0 <= BRAM_instructions_read0;
        latched_BRAM_instructions_read1 <= BRAM_instructions_read1;

        if (BRAM_instructions_read0) BRAM_instructions_readdata0 <= BRAM_instructions0[BRAM_instructions_address0];
        if (BRAM_instructions_read1) BRAM_instructions_readdata1 <= BRAM_instructions1[BRAM_instructions_address1];
        if (BRAM_instructions_write0) BRAM_instructions0[BRAM_instructions_address0] <= BRAM_instructions_data_to_write0;
        if (BRAM_instructions_write1) BRAM_instructions1[BRAM_instructions_address1] <= BRAM_instructions_data_to_write1;
    end

    always @(*) begin
        if (latched_instruction_address[2] == 0) begin
            instruction0 = (latched_BRAM_instructions_read0) ? BRAM_instructions_readdata0 : 19;
            instruction1 = (latched_BRAM_instructions_read1) ? BRAM_instructions_readdata1 : 19;
        end
        else begin
            instruction0 = (latched_BRAM_instructions_read1) ? BRAM_instructions_readdata1 : 19;
            instruction1 = (latched_BRAM_instructions_read0) ? BRAM_instructions_readdata0 : 19;
        end
    end 

endmodule
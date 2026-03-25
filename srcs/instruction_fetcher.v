`timescale 1ns / 1ps

module instruction_fetcher #(
    parameter CLKS_PER_BIT = 10416,
    parameter START_EXECUTION_OPCODE = 7'b0001011
) (
    input clk,
    input reset,
    input uart_input,

    output reg start_execution, // pulses when new instruction opcode matches START_EXECUTION_OPCODE
    output reg new_instruction_given, // pulses when new instruction arrives
    output reg [31:0] new_instruction // only valid when new_instruction_given is asserted
);

    reg [1:0] instruction_byte_index;

    wire new_byte_given;
    wire [7:0] new_byte;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) byte_receiver (
        .clk(clk),
        .uart_input(uart_input),
        .reset(reset),

        .new_byte_given(new_byte_given),
        .new_byte(new_byte)
    );

    always @(posedge clk) begin
        if (reset) begin
            start_execution <= 0;
            new_instruction_given <= 0;
            instruction_byte_index <= 0;
        end
        else begin
            start_execution <= 0;
            new_instruction_given <= 0;

            if (new_byte_given) begin
                new_instruction[instruction_byte_index * 8 +: 8] <= new_byte;
                if (instruction_byte_index == 2'b11) begin
                    if (new_instruction[6:0] == START_EXECUTION_OPCODE) start_execution <= 1;
                    new_instruction_given <= 1;
                    instruction_byte_index <= 0;
                end
                else instruction_byte_index <= instruction_byte_index + 1;
            end
        end
    end

endmodule
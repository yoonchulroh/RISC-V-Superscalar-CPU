`timescale 1ns / 1ps

module register_file #(
    parameter REGISTER_COUNT = 32
) (
    input clk,
    input reset,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_read10,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_read20,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_read11,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_read21,

    input write_enable0,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_write0,
    input [31:0] data_to_write0,

    input write_enable1,
    input [$clog2(REGISTER_COUNT) - 1 : 0] register_to_write1,
    input [31:0] data_to_write1,

    output reg [31:0] IDEX0_readdata1,
    output reg [31:0] IDEX0_readdata2,
    output reg [31:0] IDEX1_readdata1,
    output reg [31:0] IDEX1_readdata2
);
    
    integer i;

    reg [31:0] registers [REGISTER_COUNT - 1 : 0];

    always @(posedge clk) begin
        IDEX0_readdata1 <= registers[register_to_read10];
        IDEX0_readdata2 <= registers[register_to_read20];
        IDEX1_readdata1 <= registers[register_to_read11];
        IDEX1_readdata2 <= registers[register_to_read21];

        if (register_to_read10 == register_to_write0 && write_enable0 && register_to_write0 != 0) IDEX0_readdata1 <= data_to_write0;
        if (register_to_read20 == register_to_write0 && write_enable0 && register_to_write0 != 0) IDEX0_readdata2 <= data_to_write0;
        if (register_to_read11 == register_to_write0 && write_enable0 && register_to_write0 != 0) IDEX1_readdata1 <= data_to_write0;
        if (register_to_read21 == register_to_write0 && write_enable0 && register_to_write0 != 0) IDEX1_readdata2 <= data_to_write0;

        if (register_to_read10 == register_to_write1 && write_enable1 && register_to_write1 != 0) IDEX0_readdata1 <= data_to_write1;
        if (register_to_read20 == register_to_write1 && write_enable1 && register_to_write1 != 0) IDEX0_readdata2 <= data_to_write1;
        if (register_to_read11 == register_to_write1 && write_enable1 && register_to_write1 != 0) IDEX1_readdata1 <= data_to_write1;
        if (register_to_read21 == register_to_write1 && write_enable1 && register_to_write1 != 0) IDEX1_readdata2 <= data_to_write1;
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < REGISTER_COUNT; i = i + 1) registers[i] <= 0;
        end
        else begin
            if (write_enable0 && register_to_write0 != 0) begin
                registers[register_to_write0] <= data_to_write0;
            end

            if (write_enable1 && register_to_write1 != 0) begin
                registers[register_to_write1] <= data_to_write1;
            end
        end
    end

endmodule
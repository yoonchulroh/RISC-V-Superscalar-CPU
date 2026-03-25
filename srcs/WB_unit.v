`timescale 1ns / 1ps

module WB_unit #(
    parameter CLKS_PER_BIT = 10416,
    parameter BUFFER_SIZE = 200,
    parameter MAX_BITS_TO_SEND = 32,
    parameter REGISTER_COUNT = 32
) (
    input clk,
    input reset,
    input CPU_state,

    input MEMWB0_regwrite, MEMWB0_print,

    input MEMWB1_regwrite, MEMWB1_print,

    input [31:0] MEMWB0_instruction, MEMWB0_pcplusfour, MEMWB0_ALU_result,
    input [1:0] MEMWB0_toreg,
    input [31:0] MEMWB0_printdata, MEMWB0_DMem_readdata,
    input [31:0] MEMWB0_CSR_value,

    input [31:0] MEMWB1_instruction, MEMWB1_pcplusfour, MEMWB1_ALU_result,
    input [1:0] MEMWB1_toreg,
    input [31:0] MEMWB1_printdata, MEMWB1_DMem_readdata,
    input [31:0] MEMWB1_CSR_value,

    output uart_output,

    output register_file_write_enable0,
    output [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_write0,
    output [31:0] register_file_data_to_write0,

    output register_file_write_enable1,
    output [$clog2(REGISTER_COUNT) - 1 : 0] register_file_register_to_write1,
    output [31:0] register_file_data_to_write1, 

    output [4:0] forwarding_MEMWB0_rd,
    output forwarding_MEMWB0_rw,
    output [4:0] forwarding_MEMWB1_rd,
    output forwarding_MEMWB1_rw
);

    // Signals for multiple_byte_sender
    reg multiple_byte_sender_send_data;
    reg [MAX_BITS_TO_SEND - 1 : 0] multiple_byte_sender_data;
    reg [$clog2(MAX_BITS_TO_SEND + 1) - 1 : 0] multiple_byte_sender_number_of_bits_to_send;

    multiple_byte_sender #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .BUFFER_SIZE(BUFFER_SIZE),
        .MAX_BITS_TO_SEND(MAX_BITS_TO_SEND)
    ) multiple_byte_sender_inst (
        .clk(clk),
        .reset(reset),
        .send_data(multiple_byte_sender_send_data),
        .data(multiple_byte_sender_data),
        .number_of_bits_to_send(multiple_byte_sender_number_of_bits_to_send),

        .uart_output(uart_output)
    );

    always @(posedge clk) begin
        if (reset || CPU_state == 0) begin
            multiple_byte_sender_send_data <= 0;
        end
        else begin
            multiple_byte_sender_send_data <= 0;
            if (MEMWB0_print) begin
                multiple_byte_sender_send_data <= 1;
                case (MEMWB0_instruction[14:12])
                    0: begin
                        multiple_byte_sender_data <= MEMWB0_printdata;
                        multiple_byte_sender_number_of_bits_to_send <= 32;
                    end
                    1: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[7:0];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    2: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[15:8];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    3: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[23:16];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    4: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[31:24];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    5: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[15:0];
                        multiple_byte_sender_number_of_bits_to_send <= 16;
                    end
                    6: begin
                        multiple_byte_sender_data <= MEMWB0_printdata[31:16];
                        multiple_byte_sender_number_of_bits_to_send <= 16;
                    end
                    default: ;
                endcase
               
            end
            else if (MEMWB1_print) begin
                multiple_byte_sender_send_data <= 1;
                case (MEMWB0_instruction[14:12])
                    0: begin
                        multiple_byte_sender_data <= MEMWB1_printdata;
                        multiple_byte_sender_number_of_bits_to_send <= 32;
                    end
                    1: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[7:0];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    2: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[15:8];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    3: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[23:16];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    4: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[31:24];
                        multiple_byte_sender_number_of_bits_to_send <= 8;
                    end
                    5: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[15:0];
                        multiple_byte_sender_number_of_bits_to_send <= 16;
                    end
                    6: begin
                        multiple_byte_sender_data <= MEMWB1_printdata[31:16];
                        multiple_byte_sender_number_of_bits_to_send <= 16;
                    end
                    default: ;
                endcase
            end
        end
    end

    assign register_file_write_enable0 = MEMWB0_regwrite;
    assign register_file_register_to_write0 = MEMWB0_instruction[11:7];
    assign register_file_data_to_write0 = (MEMWB0_toreg[0] == 1) ? ((MEMWB0_toreg[1] == 1) ? MEMWB0_CSR_value : MEMWB0_DMem_readdata) : ((MEMWB0_toreg[1] == 1) ? MEMWB0_pcplusfour : MEMWB0_ALU_result);

    assign register_file_write_enable1 = MEMWB1_regwrite;
    assign register_file_register_to_write1 = MEMWB1_instruction[11:7];
    assign register_file_data_to_write1 = (MEMWB1_toreg[0] == 1) ? ((MEMWB1_toreg[1] == 1) ? MEMWB1_CSR_value : MEMWB1_DMem_readdata) : ((MEMWB1_toreg[1] == 1) ? MEMWB1_pcplusfour : MEMWB1_ALU_result);

    assign forwarding_MEMWB0_rd = MEMWB0_instruction[11:7];
    assign forwarding_MEMWB0_rw = MEMWB0_regwrite;
    assign forwarding_MEMWB1_rd = MEMWB1_instruction[11:7];
    assign forwarding_MEMWB1_rw = MEMWB1_regwrite;

endmodule
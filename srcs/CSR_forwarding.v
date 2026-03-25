`timescale 1ns / 1ps

module CSR_forwarding (
    input IDEX0_CSR_file_write, IDEX1_CSR_file_write,
    input [2:0] IDEX0_CSR_to_write, IDEX1_CSR_to_write,
    input [2:0] ID0_CSR_value_select, ID1_CSR_value_select,

    output reg forward_EX0_to_ID0, forward_EX1_to_ID0,
    output reg forward_EX0_to_ID1, forward_EX1_to_ID1
);

    always @(*) begin
        forward_EX0_to_ID0 = 0;
        forward_EX1_to_ID0 = 0;
        forward_EX0_to_ID1 = 0;
        forward_EX1_to_ID1 = 0;

        if (IDEX1_CSR_file_write && (IDEX1_CSR_to_write == ID0_CSR_value_select)) forward_EX1_to_ID0 = 1;
        else if (IDEX0_CSR_file_write && (IDEX0_CSR_to_write == ID0_CSR_value_select)) forward_EX0_to_ID0 = 1;

        if (IDEX1_CSR_file_write && (IDEX1_CSR_to_write == ID1_CSR_value_select)) forward_EX1_to_ID1 = 1;
        else if (IDEX0_CSR_file_write && (IDEX0_CSR_to_write == ID1_CSR_value_select)) forward_EX0_to_ID1 = 1;
    end

endmodule
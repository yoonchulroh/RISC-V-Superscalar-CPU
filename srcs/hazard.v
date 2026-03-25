`timescale 1ns / 1ps

module hazard (
    input [4:0] rs10, rs20, rs11, rs21, rd0, rd1, // from ID stage
    input rw0, rw1, // from ID stage
    input memuse0, memuse1, // from ID stage
    input print0, print1, // from ID stage
    input decoding_multiply, // from main ID
    input decoding_atomic, // from main ID
    input CSR_file_write_in_main_ID, // from main ID
    input [2:0] CSR_to_write_in_main_ID, // from main ID
    input multiply_in_sub_ID, // from sub ID
    input atomic_in_sub_ID, // from sub ID
    input [2:0] CSR_value_select_in_sub_ID, // from sub ID
    input [4:0] IDEX0_rd, IDEX1_rd, // from EX stage
    input IDEX0_memread, IDEX1_memread, // from EX stage
    input EX0_multiplying, EX1_multiplying, // from EX stage
    input EXBR0_wrong_speculation, EXBR1_wrong_speculation, // from BR stage
    input EXBR0_trap, EXBR1_trap, // from BR stage

    output reg [1:0] pcwrite,
    output reg IFID_bubble, IFID_stall, IFID_separate,
    output reg IDEX0_bubble, EXBR0_bubble, BRMEM0_bubble,
    output reg IDEX1_bubble, EXBR1_bubble, BRMEM1_bubble,
    output reg invalidate_reserve
);

    always @(*) begin
        pcwrite = 0;
        IFID_bubble = 0;
        IFID_stall = 0;
        IFID_separate = 0;

        IDEX0_bubble = 0;
        IDEX1_bubble = 0;
        EXBR0_bubble = 0;
        EXBR1_bubble = 0;
        BRMEM0_bubble = 0;
        BRMEM1_bubble = 0;

        invalidate_reserve = 0;

        if (EXBR0_wrong_speculation || EXBR0_trap) begin
            pcwrite = 1;
            IFID_bubble = 1;
            IDEX0_bubble = 1;
            IDEX1_bubble = 1;
            EXBR0_bubble = 1;
            EXBR1_bubble = 1;
            BRMEM1_bubble = 1;
            invalidate_reserve = 1;
        end
        else if (EXBR1_wrong_speculation || EXBR1_trap) begin
            pcwrite = 2;
            IFID_bubble = 1;
            IDEX0_bubble = 1;
            IDEX1_bubble = 1;
            EXBR0_bubble = 1;
            EXBR1_bubble = 1;
            invalidate_reserve = 1;
        end
        else if ((IDEX0_memread && IDEX0_rd != 0 && (IDEX0_rd == rs10 || IDEX0_rd == rs20))
              || (IDEX1_memread && IDEX1_rd != 0 && (IDEX1_rd == rs10 || IDEX1_rd == rs20))
              || EX0_multiplying || EX1_multiplying) begin
            // Both instructions in ID stage stall
            pcwrite = 3;
            IFID_stall = 1;
            IDEX0_bubble = 1;
            IDEX1_bubble = 1;
        end
        else if (decoding_atomic) begin
            // main ID unit is decoding atomic instruction
            pcwrite = 3;
            IFID_stall = 1;
            IDEX1_bubble = 1;
        end
        else if ((rw0 && rd0 != 0 && (rd0 == rs11 || rd0 == rs21))
              || (IDEX0_memread && IDEX0_rd != 0 && (IDEX0_rd == rs11 || IDEX0_rd == rs21))
              || (IDEX1_memread && IDEX1_rd != 0 && (IDEX1_rd == rs11 || IDEX1_rd == rs21))
              || (memuse0 && memuse1)
              || (print0 && print1)
              || decoding_multiply
              || multiply_in_sub_ID
              || atomic_in_sub_ID
              || (CSR_file_write_in_main_ID && (CSR_to_write_in_main_ID == CSR_value_select_in_sub_ID))) begin
            // Instruction 0 in ID stage proceeds, and instruction 1 in ID stage stalls. Next instructions for ID stage is (nop + current instruction 1)
            pcwrite = 3;
            IFID_separate = 1;
            IDEX1_bubble = 1;
        end
    end

endmodule
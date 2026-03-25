`timescale 1ns / 1ps

module forwarding (
    input [4:0] rs10, rs11, rs20, rs21, EXBR0_rd, EXBR1_rd, BRMEM0_rd, BRMEM1_rd, MEMWB0_rd, MEMWB1_rd,
    input EXBR0_rw, EXBR1_rw,
    input BRMEM0_rw, BRMEM1_rw,
    input MEMWB0_rw, MEMWB1_rw,

    output reg [1:0] forwardA0, forwardB0, forwardA1, forwardB1,
    output reg forward_from_other_sideA0, forward_from_other_sideB0, forward_from_other_sideA1, forward_from_other_sideB1
);

    always @(*) begin
        forward_from_other_sideA0 = 0;
        forward_from_other_sideB0 = 0;
        forward_from_other_sideA1 = 0;
        forward_from_other_sideB1 = 0;

        if      (rs10 == EXBR1_rd && EXBR1_rd != 0 && EXBR1_rw) begin
            forwardA0 = 1;
            forward_from_other_sideA0 = 1;
        end
        else if (rs10 == EXBR0_rd && EXBR0_rd != 0 && EXBR0_rw) begin
            forwardA0 = 1;
        end
        else if (rs10 == BRMEM1_rd && BRMEM1_rd != 0 && BRMEM1_rw) begin
            forwardA0 = 2;
            forward_from_other_sideA0 = 1;
        end
        else if (rs10 == BRMEM0_rd && BRMEM0_rd != 0 && BRMEM0_rw) begin
            forwardA0 = 2;
        end
        else if (rs10 == MEMWB1_rd && MEMWB1_rd != 0 && MEMWB1_rw) begin
            forwardA0 = 3;
            forward_from_other_sideA0 = 1;
        end
        else if (rs10 == MEMWB0_rd && MEMWB0_rd != 0 && MEMWB0_rw) begin
            forwardA0 = 3;
        end
        else forwardA0 = 0;

        if      (rs11 == EXBR1_rd && EXBR1_rd != 0 && EXBR1_rw) begin
            forwardA1 = 1;
        end
        else if (rs11 == EXBR0_rd && EXBR0_rd != 0 && EXBR0_rw) begin
            forwardA1 = 1;
            forward_from_other_sideA1 = 1;
        end
        else if (rs11 == BRMEM1_rd && BRMEM1_rd != 0 && BRMEM1_rw) begin
            forwardA1 = 2;
        end
        else if (rs11 == BRMEM0_rd && BRMEM0_rd != 0 && BRMEM0_rw) begin
            forwardA1 = 2;
            forward_from_other_sideA1 = 1;
        end
        else if (rs11 == MEMWB1_rd && MEMWB1_rd != 0 && MEMWB1_rw) begin
            forwardA1 = 3;
        end
        else if (rs11 == MEMWB0_rd && MEMWB0_rd != 0 && MEMWB0_rw) begin
            forwardA1 = 3;
            forward_from_other_sideA1 = 1;
        end
        else forwardA1 = 0;

        if      (rs20 == EXBR1_rd && EXBR1_rd != 0 && EXBR1_rw) begin
            forwardB0 = 1;
            forward_from_other_sideB0 = 1;
        end
        else if (rs20 == EXBR0_rd && EXBR0_rd != 0 && EXBR0_rw) begin
            forwardB0 = 1;
        end
        else if (rs20 == BRMEM1_rd && BRMEM1_rd != 0 && BRMEM1_rw) begin
            forwardB0 = 2;
            forward_from_other_sideB0 = 1;
        end
        else if (rs20 == BRMEM0_rd && BRMEM0_rd != 0 && BRMEM0_rw) begin
            forwardB0 = 2;
        end
        else if (rs20 == MEMWB1_rd && MEMWB1_rd != 0 && MEMWB1_rw) begin
            forwardB0 = 3;
            forward_from_other_sideB0 = 1;
        end
        else if (rs20 == MEMWB0_rd && MEMWB0_rd != 0 && MEMWB0_rw) begin
            forwardB0 = 3;
        end
        else forwardB0 = 0;

        if      (rs21 == EXBR1_rd && EXBR1_rd != 0 && EXBR1_rw) begin
            forwardB1 = 1;
        end
        else if (rs21 == EXBR0_rd && EXBR0_rd != 0 && EXBR0_rw) begin
            forwardB1 = 1;
            forward_from_other_sideB1 = 1;
        end
        else if (rs21 == BRMEM1_rd && BRMEM1_rd != 0 && BRMEM1_rw) begin
            forwardB1 = 2;
        end
        else if (rs21 == BRMEM0_rd && BRMEM0_rd != 0 && BRMEM0_rw) begin
            forwardB1 = 2;
            forward_from_other_sideB1 = 1;
        end
        else if (rs21 == MEMWB1_rd && MEMWB1_rd != 0 && MEMWB1_rw) begin
            forwardB1 = 3;
        end
        else if (rs21 == MEMWB0_rd && MEMWB0_rd != 0 && MEMWB0_rw) begin
            forwardB1 = 3;
            forward_from_other_sideB1 = 1;
        end
        else forwardB1 = 0;        
    end

endmodule
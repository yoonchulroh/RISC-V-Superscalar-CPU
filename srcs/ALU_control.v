`timescale 1ns / 1ps

module ALU_control (
    input add,
    input immediate,
    input atomic,
    input [2:0] funct3,
    input [6:0] funct7,

    output reg [3:0] operation
);

    localparam [3:0] AND = 4'b0000,
                     OR = 4'b0001,
                     ADD = 4'b0010,
                     SUB = 4'b0011,
                     SLT = 4'b0100,
                     SLTU = 4'b0101,
                     SLL = 4'b0110,
                     SRL = 4'b0111,
                     SRA = 4'b1000,
                     XOR = 4'b1001,
                     SWAP = 4'b1010,
                     MAX = 4'b1011,
                     MIN = 4'b1100,
                     MAXU = 4'b1101,
                     MINU = 4'b1110,
                     NULL = 4'b1111;

    always @(*) begin
        operation = NULL;

        if (add) operation = ADD;
        else if (atomic) case (funct7[6:2])
            0: operation = ADD;
            1: operation = SWAP;
            4: operation = XOR;
            8: operation = OR;
            12: operation = AND;
            16: operation = MIN;
            20: operation = MAX;
            24: operation = MINU;
            28: operation = MAXU;
            default: operation = NULL;
        endcase
        else case (funct3)
            3'b000: begin
                if (immediate || funct7 == 0) operation = ADD;
                else operation = SUB;
            end
            3'b001: operation = SLL;
            3'b010: operation = SLT;
            3'b011: operation = SLTU;
            3'b100: operation = XOR;
            3'b101: begin
                if (funct7 == 0) operation = SRL;
                else operation = SRA;
            end
            3'b110: operation = OR;
            3'b111: operation = AND;
        endcase
    end

endmodule
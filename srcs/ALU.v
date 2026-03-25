`timescale 1ns / 1ps

module ALU (
    input [3:0] operation,
    input [31:0] inputx,
    input [31:0] inputy,

    output reg [31:0] result
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
        result = 0;

        case (operation)
            AND: result = inputx & inputy;
            OR: result = inputx | inputy;
            ADD: result = inputx + inputy;
            SUB: result = inputx - inputy;
            SLT: result = ($signed(inputx) < $signed(inputy)) ? 1 : 0;
            SLTU: result = (inputx < inputy) ? 1 : 0;
            SLL: result = inputx << inputy[4:0];
            SRL: result = inputx >> inputy[4:0];
            SRA: result = $signed(inputx) >>> inputy[4:0];
            XOR: result = inputx ^ inputy;
            SWAP: result = inputy;
            MAX: result = ($signed(inputx) > $signed(inputy)) ? inputx : inputy;
            MIN: result = ($signed(inputx) < $signed(inputy)) ? inputx : inputy;
            MAXU: result = (inputx > inputy) ? inputx : inputy;
            MINU: result = (inputx < inputy) ? inputx : inputy;
            default: result = 0;
        endcase
    end

endmodule
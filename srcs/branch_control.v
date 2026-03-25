`timescale 1ns / 1ps

module branch_control (
    input branch,
    input [2:0] funct3,
    input [31:0] inputx,
    input [31:0] inputy,

    output taken);

    reg condition;

    assign taken = condition && branch;

    always @(*) begin
        case (funct3)
            3'b000: condition = (inputx == inputy) ? 1 : 0;
            3'b001: condition = (inputx != inputy) ? 1 : 0;
            3'b100: condition = ($signed(inputx) < $signed(inputy)) ? 1 : 0;
            3'b101: condition = ($signed(inputx) >= $signed(inputy)) ? 1 : 0;
            3'b110: condition = (inputx < inputy) ? 1 : 0;
            3'b111: condition = (inputx >= inputy) ? 1 : 0;
            default: condition = 0;
        endcase
    end

endmodule
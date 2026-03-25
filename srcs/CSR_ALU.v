`timescale 1ns / 1ps

module CSR_ALU (
    input [31:0] CSR_value,
    input [31:0] rs1_value,
    input [31:0] rs1,
    input [2:0] funct3,
    input trap,
    input [31:0] pc,

    output reg [31:0] result
);

    always @(*) begin
        result = 0;

        if (trap) result = pc;
        else case (funct3)
            1: result = rs1_value; // csrrw
            2: result = CSR_value | rs1_value; // csrrs
            3: result = CSR_value & (~rs1_value); // csrrc
            5: result = rs1; // csrrwi
            6: result = CSR_value | rs1; // csrrsi
            7: result = CSR_value & ~rs1; // csrrci
        endcase
    end

endmodule
`timescale 1ns / 1ps

module ImmediateGenerator (
    input [31:0] instruction,
    output reg [31:0] immediate_value
);

    always @(*) begin
        case (instruction[6:0])
            // I-Format (I-type Arithmetic, Load, JALR)
            7'b0010011, 7'b0000011, 7'b1100111: 
                immediate_value = {{20{instruction[31]}}, instruction[31:20]};
            
            // S-Format (Store)
            7'b0100011: 
                immediate_value = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-Format (Branch)
            7'b1100011: 
                immediate_value = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-Format (LUI, AUIPC)
            7'b0110111, 7'b0010111: 
                immediate_value = {instruction[31:12], 12'b0};

            // J-Format (JAL)
            7'b1101111: 
                immediate_value = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            // Atomic
            7'b0101111:
                immediate_value = 32'b0;

            default: 
                immediate_value = 32'b0;
        endcase
    end

endmodule
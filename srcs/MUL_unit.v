`timescale 1ns / 1ps

module MUL_unit (
    input clk,
    input reset,
    input CPU_state,
    input hazard_EXBR_bubble,

    input multiply,
    input [2:0] funct3,
    input [31:0] inputx,
    input [31:0] inputy,

    output multiplying,
    output reg result_ready,
    output reg [31:0] result 
);

    // Stage 1
    reg stage1_multiplying;
    reg [2:0] stage1_funct3;
    reg [31:0] stage1_inputx, stage1_inputy;

    // Stage 2
    reg stage2_multiplying;
    reg [2:0] stage2_funct3;
    reg [31:0] stage2_x0y0_partialmul, stage2_x16y0_partialmul_lower, stage2_x0y16_partialmul_lower;
    reg [31:0] stage2_x16y0_partialmul_upper, stage2_x0y16_partialmul_upper, stage2_x16y16_partialmul;
    reg [31:0] stage2_inputx, stage2_inputy;

    // Stage 3
    reg stage3_multiplying;
    reg [2:0] stage3_funct3;
    reg [31:0] stage3_lower_result;
    reg [1:0] stage3_carry;
    reg [31:0] stage3_upper_result;
    reg [31:0] stage3_inputx, stage3_inputy;

    // Division
    reg dividing;
    reg [62:0] divisor, remainder;
    reg [31:0] quotient;
    reg [4:0] iterations;
    reg sign_different;
    reg dividend_negative;
    reg output_remainder;

    assign multiplying = multiply || stage1_multiplying || stage2_multiplying || stage3_multiplying || dividing;

    always @(posedge clk) begin
        if (reset || CPU_state == 0 || hazard_EXBR_bubble) begin
            stage1_multiplying <= 0;
            stage2_multiplying <= 0;
            stage3_multiplying <= 0;
            dividing <= 0;
            result_ready <= 0;
        end
        else begin
            // multiplication
            stage1_multiplying <= multiply && (funct3[2] == 0);
            stage1_funct3 <= funct3;
            stage1_inputx <= inputx;
            stage1_inputy <= inputy;

            stage2_multiplying <= stage1_multiplying;
            stage2_funct3 <= stage1_funct3;
            stage2_x0y0_partialmul <= stage1_inputx[15:0] * stage1_inputy[15:0];
            stage2_x16y0_partialmul_lower <= (stage1_inputx[31:16] * stage1_inputy[15:0]) << 16;
            stage2_x0y16_partialmul_lower <= (stage1_inputx[15:0] * stage1_inputy[31:16]) << 16;
            stage2_x16y0_partialmul_upper <= (stage1_inputx[31:16] * stage1_inputy[15:0]) >> 16;
            stage2_x0y16_partialmul_upper <= (stage1_inputx[15:0] * stage1_inputy[31:16]) >> 16;
            stage2_x16y16_partialmul <= stage1_inputx[31:16] * stage1_inputy[31:16];
            stage2_inputx <= stage1_inputx;
            stage2_inputy <= stage1_inputy;

            stage3_multiplying <= stage2_multiplying;
            stage3_funct3 <= stage2_funct3;
            {stage3_carry, stage3_lower_result} <= stage2_x0y0_partialmul + stage2_x16y0_partialmul_lower + stage2_x0y16_partialmul_lower;
            stage3_upper_result <= stage2_x16y16_partialmul + stage2_x16y0_partialmul_upper + stage2_x0y16_partialmul_upper;
            stage3_inputx <= stage2_inputx;
            stage3_inputy <= stage2_inputy;

            result_ready <= stage3_multiplying;
            case (stage3_funct3)
                3'b000: result <= stage3_lower_result;
                3'b001: result <= stage3_upper_result + stage3_carry - ((stage3_inputx[31] == 1) ? stage3_inputy : 0) - ((stage3_inputy[31] == 1) ? stage3_inputx : 0);
                3'b010: result <= stage3_upper_result + stage3_carry - ((stage3_inputx[31] == 1) ? stage3_inputy : 0);
                3'b011: result <= stage3_upper_result + stage3_carry;
                default: result <= 0;
            endcase

            // division
            if (multiply && funct3[2] == 1) begin
                dividing <= 1;
                quotient = 0;
                iterations <= 0;
                output_remainder <= funct3[1];

                if (funct3[0] == 0 && inputy[31] == 1) divisor <= {(~inputy + 1), 31'b0};
                else divisor <= {inputy, 31'b0};

                if (funct3[0] == 0 && inputx[31] == 1) remainder = {31'b0, (~inputx + 1)};
                else remainder = {31'b0, inputx};

                sign_different <= (funct3[0] == 0) && (inputx[31] ^ inputy[31]);
                dividend_negative <= (funct3[0] == 0) && (inputx[31] == 1);
            end
            else if (dividing) begin
                if (remainder >= divisor) begin
                    remainder = remainder - divisor;
                    quotient = {quotient[30:0], 1'b1};
                end
                else begin
                    remainder = remainder;
                    quotient = {quotient[30:0], 1'b0};
                end

                if (iterations == 31) begin
                    result_ready <= 1;
                    if (output_remainder) begin
                        if (dividend_negative) result <= ~remainder[31:0] + 1;
                        else result <= remainder[31:0];
                    end
                    else begin
                        if (sign_different) result <= ~quotient + 1;
                        else result <= quotient;
                    end
                    dividing <= 0;
                end
                else result_ready <= 0;

                divisor <= (divisor >> 1);
                iterations <= iterations + 1;
                // $display("Remainder: %b, Divisor: %b, Quotient: %b", remainder, divisor, quotient);
            end
        end
    end

endmodule
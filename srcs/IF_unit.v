`timescale 1ns / 1ps

module IF_unit #(
    parameter IMEM_SIZE = 400
) (
    input clk,
    input reset,
    input CPU_state,
    input hazard_IFID_stall, hazard_IFID_bubble, hazard_IFID_separate,

    input [31:0] pc,
    input [31:0] instruction_from_IMem0,
    input [31:0] instruction_from_IMem1,
    input [31:0] next_pc_predictor_predicted_target0,
    input [31:0] next_pc_predictor_predicted_target1,

    // IFID0
    output reg [31:0] IFID0_pc,
    output reg [31:0] IFID0_instruction,
    output reg IFID0_flush_upon_wrong_speculation,
    output reg [31:0] IFID0_speculated_next_pc,
    output reg IFID0_instruction_access_fault, IFID0_instruction_misaligned,

    // IFID1
    output reg [31:0] IFID1_pc,
    output reg [31:0] IFID1_instruction,
    output reg IFID1_flush_upon_wrong_speculation,
    output reg [31:0] IFID1_speculated_next_pc,
    output reg IFID1_instruction_access_fault, IFID1_instruction_misaligned,

    // wires
    output [31:0] instruction_address
);

    always @(posedge clk) begin
        if (reset || CPU_state == 0 || hazard_IFID_bubble) begin
            IFID0_instruction <= 19;
            IFID0_pc <= 0;
            IFID0_flush_upon_wrong_speculation <= 0;
            IFID0_speculated_next_pc <= 0;
            IFID0_instruction_access_fault <= 0;
            IFID0_instruction_misaligned <= 0;

            IFID1_instruction <= 19;
            IFID1_pc <= 0;
            IFID1_flush_upon_wrong_speculation <= 0;
            IFID1_speculated_next_pc <= 0;
            IFID1_instruction_access_fault <= 0;
            IFID1_instruction_misaligned <= 0;
        end
        else if (hazard_IFID_stall) begin
            IFID0_instruction <= IFID0_instruction;
            IFID0_pc <= IFID0_pc;
            IFID0_flush_upon_wrong_speculation <= IFID0_flush_upon_wrong_speculation;
            IFID0_speculated_next_pc <= IFID0_speculated_next_pc;
            IFID0_instruction_access_fault <= IFID0_instruction_access_fault;
            IFID0_instruction_misaligned <= IFID0_instruction_misaligned;

            IFID1_instruction <= IFID1_instruction;
            IFID1_pc <= IFID1_pc;
            IFID1_flush_upon_wrong_speculation <= IFID1_flush_upon_wrong_speculation;
            IFID1_speculated_next_pc <= IFID1_speculated_next_pc;
            IFID1_instruction_access_fault <= IFID1_instruction_access_fault;
            IFID1_instruction_misaligned <= IFID1_instruction_misaligned;
        end
        else if (hazard_IFID_separate) begin
            IFID0_instruction <= IFID1_instruction;
            IFID0_pc <= IFID1_pc;
            IFID0_flush_upon_wrong_speculation <= IFID1_flush_upon_wrong_speculation;
            IFID0_speculated_next_pc <= IFID1_speculated_next_pc;
            IFID0_instruction_access_fault <= IFID1_instruction_access_fault;
            IFID0_instruction_misaligned <= IFID1_instruction_misaligned;

            IFID1_instruction <= instruction_from_IMem0;
            IFID1_pc <= pc;
            IFID1_flush_upon_wrong_speculation <= 1;
            IFID1_speculated_next_pc <= next_pc_predictor_predicted_target0;
            IFID1_instruction_access_fault <= (pc >= IMEM_SIZE) ? 1 : 0;
            IFID1_instruction_misaligned <= (pc[1:0] == 0) ? 0 : 1;
        end
        else if (next_pc_predictor_predicted_target0 != pc + 4) begin
            IFID0_instruction <= instruction_from_IMem0;
            IFID0_pc <= pc;
            IFID0_flush_upon_wrong_speculation <= 1;
            IFID0_speculated_next_pc <= next_pc_predictor_predicted_target0;
            IFID0_instruction_access_fault <= (pc >= IMEM_SIZE) ? 1 : 0;
            IFID0_instruction_misaligned <= (pc[1:0] == 0) ? 0 : 1;

            IFID1_instruction <= 19;
            IFID1_pc <= 0;
            IFID1_flush_upon_wrong_speculation <= 0;
            IFID1_speculated_next_pc <= 0; 
            IFID1_instruction_access_fault <= 0;
            IFID1_instruction_misaligned <= 0;
        end
        else begin
            IFID0_instruction <= instruction_from_IMem0;
            IFID0_pc <= pc;
            IFID0_flush_upon_wrong_speculation <= 1;
            IFID0_speculated_next_pc <= pc + 4;
            IFID0_instruction_access_fault <= (pc >= IMEM_SIZE) ? 1 : 0;
            IFID0_instruction_misaligned <= (pc[1:0] == 0) ? 0 : 1;

            IFID1_instruction <= instruction_from_IMem1;
            IFID1_pc <= pc + 4;
            IFID1_flush_upon_wrong_speculation <= 1;
            IFID1_speculated_next_pc <= next_pc_predictor_predicted_target1;
            IFID1_instruction_access_fault <= (pc >= IMEM_SIZE - 4) ? 1 : 0;
            IFID1_instruction_misaligned <= (pc[1:0] == 0) ? 0 : 1;
        end
    end

    assign instruction_address = pc;

endmodule